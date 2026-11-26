import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/db/app_database.dart';
import 'package:paisa_vault/core/db/encrypted_executor.dart';
import 'package:paisa_vault/core/db/key_store.dart';
import 'package:paisa_vault/features/budgets/budget_repository.dart';
import 'package:paisa_vault/services/notifier.dart';
import 'package:paisa_vault/testing/fakes.dart';

class RecordingNotifier implements AlertNotifier {
  final shown = <(String, String)>[];
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async => shown.add((title, body));
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;
  late AppDatabase db;
  late FakeClock clock;
  late BudgetRepository repo;
  var n = 0;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pv_budget');
    db = AppDatabase(openEncrypted(File('${dir.path}/main.db'), randomKey()));
    clock = FakeClock(DateTime(2026, 11, 10, 12));
    repo = BudgetRepository(db, clock);
    n = 0;
  });
  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  Future<void> spend(
    int rs,
    String category, {
    DateTime? on,
    Direction direction = Direction.debit,
    bool selfTransfer = false,
  }) async {
    final day = on ?? DateTime(2026, 11, 5);
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            amountPaise: rs * 100,
            direction: direction,
            categoryName: Value(category),
            selfTransfer: Value(selfTransfer),
            fingerprint: 'f${n++}',
            occurredAt: day,
            createdAt: day,
          ),
        );
  }

  test(
    'spending counts this month, this category, money out, not own transfers',
    () async {
      await spend(300, 'Food');
      await spend(200, 'Food', on: DateTime(2026, 11, 30, 23, 59));
      await spend(999, 'Food', on: DateTime(2026, 10, 31)); // last month
      await spend(999, 'Food', on: DateTime(2026, 12, 1)); // next month
      await spend(999, 'Bills');
      await spend(999, 'Food', direction: Direction.credit);
      await spend(999, 'Food', selfTransfer: true);
      expect(await repo.spent('Food', clock.now()), 50000);
    },
  );

  test(
    'each level fires once, and only the highest when spending jumps',
    () async {
      await repo.save('Food', 100000); // Rs 1,000
      await spend(600, 'Food');
      expect(await repo.newAlerts(), isEmpty); // 60%

      await spend(100, 'Food'); // 70%
      var a = await repo.newAlerts();
      expect(a.map((x) => x.threshold), [70]);
      expect(await repo.newAlerts(), isEmpty); // not again

      await spend(250, 'Food'); // 95%: crosses 80 and 90 together
      a = await repo.newAlerts();
      expect(a.map((x) => x.threshold), [90]); // only the highest
      expect(await repo.newAlerts(), isEmpty); // 80 is recorded as done

      await spend(100, 'Food'); // 105%
      expect((await repo.newAlerts()).map((x) => x.threshold), [100]);
      await spend(100, 'Food');
      expect(await repo.newAlerts(), isEmpty);
    },
  );

  test('a new month fires the levels again', () async {
    await repo.save('Food', 100000);
    await spend(800, 'Food');
    expect((await repo.newAlerts()).map((x) => x.threshold), [80]);
    clock.current = DateTime(2026, 12, 3);
    expect(await repo.newAlerts(), isEmpty); // December has no spending yet
    await spend(900, 'Food', on: DateTime(2026, 12, 2));
    expect((await repo.newAlerts()).map((x) => x.threshold), [90]);
  });

  test('changing a limit and removing a budget', () async {
    await repo.save('Food', 100000);
    await repo.save('Food', 200000); // same category: one budget, new limit
    var all = await repo.statuses();
    expect(all, hasLength(1));
    expect(all.single.budget.limitPaise, 200000);
    await repo.remove(all.single.budget.id);
    all = await repo.statuses();
    expect(all, isEmpty);
  });

  test('the notification names the category and level only', () async {
    final notifier = RecordingNotifier();
    await repo.save('Food', 100000);
    await spend(850, 'Food');
    final shown = await BudgetAlerter(repo, notifier).run();
    expect(shown, 1);
    final (title, body) = notifier.shown.single;
    expect(title, 'Food budget');
    expect(body, contains('80%'));
    expect(body + title, isNot(contains('850')));
    expect(await BudgetAlerter(repo, notifier).run(), 0);
  });
}
