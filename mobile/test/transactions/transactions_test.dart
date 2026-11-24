import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/db/app_database.dart';
import 'package:paisa_vault/core/db/encrypted_executor.dart';
import 'package:paisa_vault/core/db/key_store.dart';
import 'package:paisa_vault/core/providers.dart';
import 'package:paisa_vault/features/pipeline/extraction_pipeline.dart';
import 'package:paisa_vault/features/sms/raw_message_repository.dart';
import 'package:paisa_vault/features/transactions/add_message_screen.dart';
import 'package:paisa_vault/features/transactions/format.dart';
import 'package:paisa_vault/features/transactions/providers.dart';
import 'package:paisa_vault/features/transactions/signing_expiry.dart';
import 'package:paisa_vault/features/transactions/processing_service.dart';
import 'package:paisa_vault/features/transactions/rule_amount.dart';
import 'package:paisa_vault/features/transactions/transaction_detail_screen.dart';
import 'package:paisa_vault/features/transactions/transaction_repository.dart';
import 'package:paisa_vault/features/transactions/transactions_screen.dart';
import 'package:paisa_vault/services/sms_source.dart';
import 'package:paisa_vault/testing/fakes.dart';

// Invented messages, not real customer messages.
const withMerchant =
    'Rs 250.00 spent on HDFC Bank Card x1234 at ZOMATO on 12-10-26.';
const noMerchant =
    'Rs 499.00 debited from A/c XX1234 on 20-11-26. UPI Ref 123456789012';
const goodReply =
    '{"merchant": "SOME SHOP", "category": "Shopping", "channel": "UPI"}';

IncomingSms sms(String body, DateTime at) =>
    IncomingSms(sender: '', body: body, receivedAt: at);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;
  late AppDatabase db;
  late FakeClock clock;
  late RawMessageRepository raw;
  late TransactionRepository repo;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pv_tx');
    db = AppDatabase(openEncrypted(File('${dir.path}/main.db'), randomKey()));
    clock = FakeClock(DateTime(2026, 11, 21, 12));
    raw = RawMessageRepository(db, clock);
    repo = TransactionRepository(db, clock);
  });
  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  ProcessingService service({FakeLlmEngine? llm}) => ProcessingService(
    db,
    repo,
    categories: defaultCategories,
    engineFactory: llm == null ? null : () async => llm,
  );

  group('typed amounts', () {
    test('rupeesToPaise accepts normal input and rejects the rest', () {
      expect(rupeesToPaise('499'), 49900);
      expect(rupeesToPaise(' 499.5 '), 49950);
      expect(rupeesToPaise('1,250.00'), 125000);
      expect(rupeesToPaise('abc'), isNull);
      expect(rupeesToPaise(''), isNull);
    });
  });

  group('formatting', () {
    test('Indian grouping', () {
      expect(formatRupees(49900), '499.00');
      expect(formatRupees(123456), '1,234.56');
      expect(formatRupees(12345678), '1,23,456.78');
      expect(formatRupees(10000050), '1,00,000.50');
      expect(formatRupees(5), '0.05');
    });
    test('signed amount and date', () {
      expect(signedAmount(125000, Direction.debit), '-₹1,250.00');
      expect(signedAmount(125000, Direction.credit), '+₹1,250.00');
      expect(formatDate(DateTime(2026, 11, 2)), '2 Nov 2026');
    });
  });

  group('processing', () {
    test(
      'a new message becomes a transaction and is marked processed',
      () async {
        await raw.save(sms(withMerchant, DateTime(2026, 11, 21, 10)));
        final r = await service(llm: FakeLlmEngine([goodReply])).processNew();
        expect(r.transactions, 1);
        final t = await db.select(db.transactions).getSingle();
        expect(t.amountPaise, 25000);
        expect(t.merchant, 'ZOMATO'); // rule beats the model
        expect(t.bankCode, 'HDFC');
        expect(t.last4, '1234');
        expect(t.occurredAt, DateTime(2026, 10, 12));
        expect(t.rawMessageId, isNotNull);
        expect(
          (await db.select(db.rawMessages).getSingle()).status,
          RawMessageStatus.processed,
        );
      },
    );

    test('with no model, a message whose merchant the rules cannot find needs checking', () async {
      await raw.save(sms(noMerchant, DateTime(2026, 11, 21, 10)));
      await service().processNew();
      final t = await db.select(db.transactions).getSingle();
      expect(t.status, TransactionStatus.pleaseConfirm);
      expect(t.confirmReason, 'no_model');
      expect(t.merchant, isNull);
      expect(t.modelId, isNull);
    });

    test(
      'with no model, a message whose merchant the rules found is confirmed',
      () async {
        await raw.save(sms(withMerchant, DateTime(2026, 11, 21, 10)));
        await service().processNew();
        expect(
          (await db.select(db.transactions).getSingle()).status,
          TransactionStatus.confirmed,
        );
      },
    );

    test('a message with no amount is ignored and not retried', () async {
      await raw.save(
        sms('Your account was credited', DateTime(2026, 11, 21, 10)),
      );
      final first = await service().processNew();
      expect(first.skipped, 1);
      expect((await service().processNew()).skipped, 0);
      expect(
        (await db.select(db.rawMessages).getSingle()).status,
        RawMessageStatus.ignored,
      );
      expect(await db.select(db.transactions).get(), isEmpty);
    });

    test('running twice does not duplicate transactions', () async {
      await raw.save(sms(withMerchant, DateTime(2026, 11, 21, 10)));
      final s = service();
      await s.processNew();
      await s.processNew();
      expect((await db.select(db.transactions).get()).length, 1);
    });
  });

  group('model lifetime', () {
    test('the model is not loaded when nothing is waiting', () async {
      var loads = 0;
      final s = ProcessingService(
        db,
        repo,
        categories: defaultCategories,
        engineFactory: () async {
          loads++;
          return FakeLlmEngine([goodReply]);
        },
      );
      await s.processNew();
      expect(loads, 0);
    });

    test('the model is freed after the batch', () async {
      await raw.save(sms(noMerchant, DateTime(2026, 11, 21, 10)));
      final llm = FakeLlmEngine([goodReply]);
      await service(llm: llm).processNew();
      expect(llm.prompts.length, 1);
      expect(llm.loaded, false);
    });

    test('the model is freed even if saving fails midway', () async {
      await raw.save(sms(noMerchant, DateTime(2026, 11, 21, 10)));
      final llm = FakeLlmEngine([goodReply]);
      final s = ProcessingService(
        db,
        _FailingTransactionRepository(db, clock),
        categories: defaultCategories,
        engineFactory: () async => llm..loaded = true,
      );
      await expectLater(s.processNew(), throwsA(anything));
      expect(llm.loaded, false);
    });

    test(
      'a model that fails to load falls back to rules and needs checking',
      () async {
        await raw.save(sms(noMerchant, DateTime(2026, 11, 21, 10)));
        final s = ProcessingService(
          db,
          repo,
          categories: defaultCategories,
          engineFactory: () async => throw Exception('out of memory'),
        );
        await s.processNew();
        final t = await db.select(db.transactions).getSingle();
        expect(t.status, TransactionStatus.pleaseConfirm);
        expect(t.amountPaise, 49900);
      },
    );

    test('a model answer that is just the bank name is dropped', () async {
      await raw.save(sms(noMerchant, DateTime(2026, 11, 21, 10)));
      final llm = FakeLlmEngine([
        '{"merchant": "HDFC Bank", "category": "Other", "channel": "UPI"}',
      ]);
      await service(llm: llm).processNew();
      final t = await db.select(db.transactions).getSingle();
      expect(t.merchant, isNull);
      expect(t.categoryName, 'Other');
    });
  });

  group('re-check when a model arrives', () {
    test(
      'transactions made without a model are filled in once one is installed',
      () async {
        await raw.save(sms(noMerchant, DateTime(2026, 11, 21, 10)));
        await service().processNew(); // no model
        expect(
          (await db.select(db.transactions).getSingle()).status,
          TransactionStatus.pleaseConfirm,
        );

        await service(llm: FakeLlmEngine([goodReply]))
            .processNew(); // model now available
        final t = await db.select(db.transactions).getSingle();
        expect(t.merchant, 'SOME SHOP');
        expect(t.categoryName, 'Shopping');
        expect(t.status, TransactionStatus.confirmed);
        expect(t.confirmReason, isNull);
        expect(t.modelId, 'fake-model');
        expect(t.amountPaise, 49900); // rule fields unchanged
      },
    );

    test('a transaction the user corrected is never overwritten', () async {
      await raw.save(sms(noMerchant, DateTime(2026, 11, 21, 10)));
      await service().processNew();
      final id = (await db.select(db.transactions).getSingle()).id;
      await repo.correct(
        id,
        merchant: 'RAJU STORES',
        categoryName: 'Groceries',
      );
      await service(llm: FakeLlmEngine([goodReply])).processNew();
      final t = await db.select(db.transactions).getSingle();
      expect(t.merchant, 'RAJU STORES');
      expect(t.categoryName, 'Groceries');
    });

    test('a model that fails leaves it to be tried again later', () async {
      await raw.save(sms(noMerchant, DateTime(2026, 11, 21, 10)));
      await service().processNew();
      await service(llm: FakeLlmEngine([Exception('boom')])).processNew();
      expect(
        (await db.select(db.transactions).getSingle()).confirmReason,
        'no_model',
      );
    });
  });

  group('accounts and duplicates', () {
    const upiA =
        'Rs 499.00 debited from HDFC Bank A/c XX1234 on 20-11-26. UPI Ref 123456789012';
    const upiB =
        'HDFC Bank: Rs 499.00 debited from A/c XX1234 on 20-11-26 UPI Ref 123456789012. Not you? Call support';

    Future<void> run(List<String> bodies) async {
      var i = 0;
      for (final b in bodies) {
        await raw.save(sms(b, DateTime(2026, 11, 21, 10, i++ * 10)));
      }
      await service(llm: FakeLlmEngine([goodReply, goodReply, goodReply]))
          .processNew();
    }

    test('transactions are linked to one account by bank and last 4', () async {
      await run([
        withMerchant,
        upiA.replaceAll('123456789012', '999999999999'),
      ]);
      final txns = await db.select(db.transactions).get();
      expect(txns, hasLength(2));
      expect(txns.every((t) => t.accountId != null), isTrue);
      expect(txns[0].accountId, txns[1].accountId);
      final accounts = await db.select(db.accounts).get();
      expect(accounts, hasLength(1));
      expect(accounts.single.last4, '1234');
      expect(accounts.single.status, AccountStatus.pending);
      final banks = await db.select(db.banks).get();
      expect(banks.single.code, 'HDFC');
    });

    test('a different last 4 is a different account', () async {
      await run([withMerchant, withMerchant.replaceAll('1234', '5678')]);
      expect(await db.select(db.accounts).get(), hasLength(2));
    });

    test('a message without bank or last 4 has no account', () async {
      await run(['Rs 120.00 spent at SOME SHOP on 12-10-26.']);
      final t = (await db.select(db.transactions).get()).single;
      expect(t.accountId, isNull);
      expect(await db.select(db.accounts).get(), isEmpty);
    });

    test(
      'the same transaction reported twice with a reference is stored once',
      () async {
        await run([upiA, upiB]);
        expect(await db.select(db.transactions).get(), hasLength(1));
        // both messages are finished, none left waiting
        final left =
            await (db.select(db.rawMessages)..where(
                  (m) => m.status.equals(RawMessageStatus.newMessage.name),
                ))
                .get();
        expect(left, isEmpty);
      },
    );

    test('identical payments without a reference are both kept', () async {
      await run([
        'Rs 50.00 spent on HDFC Bank Card x1234 at CHAI on 12-10-26.',
        'Rs 50.00 spent on HDFC Bank Card x1234 at CHAI stall on 12-10-26.',
      ]);
      expect(await db.select(db.transactions).get(), hasLength(2));
    });

    test('a missing last 4 is filled in once the rules can read it', () async {
      await run([
        'Rs 250.00 spent on HDFC Bank Card (1234) at ZOMATO on 12-10-26.',
      ]);
      await (db.update(db.transactions)).write(
        const TransactionsCompanion(last4: Value(null), accountId: Value(null)),
      );
      expect(await repo.refillRuleFields(), 1);
      expect(await repo.linkUnlinked(), 1);
      final t = (await db.select(db.transactions).get()).single;
      expect(t.last4, '1234');
      expect(t.accountId, isNotNull);
      // nothing left to fill
      expect(await repo.refillRuleFields(), 0);
    });

    test('earlier transactions without an account get linked', () async {
      await run([withMerchant]);
      await (db.update(db.transactions))
          .write(const TransactionsCompanion(accountId: Value(null)));
      expect(await repo.linkUnlinked(), 1);
      expect(
        (await db.select(db.transactions).get()).single.accountId,
        isNotNull,
      );
    });
  });

  group('signing expiry', () {
    test('whole days left', () {
      final now = DateTime(2026, 11, 24, 12);
      expect(daysUntil(DateTime(2026, 12, 1, 12), now), 7);
      expect(daysUntil(DateTime(2026, 11, 26, 6), now), 1);
      expect(daysUntil(DateTime(2026, 11, 24, 18), now), 0);
      expect(daysUntil(DateTime(2026, 11, 23, 12), now), -1);
    });
  });

  group('add a pasted message', () {
    testWidgets('a pasted bank SMS becomes a transaction', (t) async {
      late ProviderContainer c;
      c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith((ref) async => db),
          clockProvider.overrideWithValue(clock),
          processingServiceProvider.overrideWith(
            (ref) async => service(llm: FakeLlmEngine([goodReply])),
          ),
        ],
      );
      late WidgetRef captured;
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            home: Consumer(
              builder: (_, ref, _) {
                captured = ref;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      Future<AddMessageResult> add(String text) async =>
          (await t.runAsync(() => addPastedMessage(captured, text)))!;

      expect(await add('   '), AddMessageResult.empty);
      expect(await add('Your OTP is 123456'), AddMessageResult.notATransaction);
      expect(await add(withMerchant), AddMessageResult.added);
      final rows = await t.runAsync(() => db.select(db.transactions).get());
      expect(rows, hasLength(1));
      expect(rows!.single.merchant, 'ZOMATO');
      // the same text again right away is not added twice
      expect(await add(withMerchant), AddMessageResult.repeat);
      expect(
        await t.runAsync(() => db.select(db.transactions).get()),
        hasLength(1),
      );

      await t.pumpWidget(const SizedBox());
      c.dispose();
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await t.pump(const Duration(seconds: 1));
    });
  });

  group('corrections', () {
    test('an edit confirms the transaction and marks it corrected', () async {
      await raw.save(sms(noMerchant, DateTime(2026, 11, 21, 10)));
      await service().processNew();
      final id = (await db.select(db.transactions).getSingle()).id;
      await repo.correct(
        id,
        merchant: 'RAJU STORES',
        categoryName: 'Groceries',
        amountPaise: 50000,
      );
      final t = await db.select(db.transactions).getSingle();
      expect(t.merchant, 'RAJU STORES');
      expect(t.categoryName, 'Groceries');
      expect(t.amountPaise, 50000);
      expect(t.status, TransactionStatus.confirmed);
      expect(t.userCorrected, true);
    });
  });

  group('screens', () {
    ProviderContainer? container;

    Future<void> pump(WidgetTester t, Widget home) async {
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith((ref) async => db),
          clockProvider.overrideWithValue(clock),
        ],
      );
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: container!,
          child: MaterialApp(home: home),
        ),
      );
    }

    // Bounded pumps: a loading spinner animates forever, so pumpAndSettle would never return.
    Future<void> settle(WidgetTester t) async {
      for (var i = 0; i < 4; i++) {
        // The database runs outside the test clock, so give it real time.
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await t.pump(const Duration(milliseconds: 100));
      }
    }

    // Remove the screen and let drift's query-cleanup timer run, so no timer is left pending.
    Future<void> finish(WidgetTester t) async {
      await t.pumpWidget(const SizedBox());
      container?.dispose(); // cancels the live queries now, inside the test
      container = null;
      for (var i = 0; i < 3; i++) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await t.pump(const Duration(seconds: 1));
      }
    }

    testWidgets('empty list says so', (t) async {
      await pump(t, const TransactionsScreen());
      await settle(t);
      expect(find.textContaining('No transactions yet'), findsOneWidget);
      await finish(t);
    });

    testWidgets('list shows merchant, amount, bank and a check flag', (
      t,
    ) async {
      await t.runAsync(() async {
        await raw.save(sms(withMerchant, DateTime(2026, 11, 21, 10)));
        await raw.save(sms(noMerchant, DateTime(2026, 11, 21, 11)));
        await service().processNew();
      });
      await pump(t, const TransactionsScreen());
      await settle(t);
      expect(find.text('ZOMATO'), findsOneWidget);
      expect(find.text('-₹250.00'), findsOneWidget);
      expect(find.text('Unknown merchant'), findsOneWidget);
      expect(find.text('Please check'), findsOneWidget);
      expect(find.textContaining('HDFC'), findsWidgets);
      await finish(t);
    });

    testWidgets(
      'detail shows every field and the original message, and the edit sheet checks input',
      (t) async {
        t.view.physicalSize = const Size(800, 2600);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        late int id;
        await t.runAsync(() async {
          await raw.save(sms(noMerchant, DateTime(2026, 11, 21, 10)));
          await service().processNew();
          id = (await db.select(db.transactions).getSingle()).id;
        });
        await pump(t, TransactionDetailScreen(id: id));
        await settle(t);
        expect(find.text('-₹499.00'), findsOneWidget);
        expect(find.text('20 Nov 2026'), findsOneWidget);
        expect(find.text('123456789012'), findsOneWidget);
        expect(
          find.text('Not found'),
          findsWidgets,
        ); // merchant and category are missing
        expect(find.textContaining('No merchant found yet'), findsOneWidget);
        expect(find.text(noMerchant), findsOneWidget); // original message

        // The edit sheet opens pre-filled and refuses a bad amount.
        await t.tap(find.text('Correct something'));
        await t.pump(const Duration(milliseconds: 500));
        expect(find.text('Correct transaction'), findsOneWidget);
        await t.enterText(find.widgetWithText(TextField, 'Amount (₹)'), 'abc');
        // Call the button directly: the sheet sits partly off the test screen.
        t
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
            .onPressed!();
        await t.pump(const Duration(milliseconds: 100));
        expect(find.textContaining('Enter an amount'), findsOneWidget);
        await finish(t);
      },
    );
  });
}

class _FailingTransactionRepository extends TransactionRepository {
  _FailingTransactionRepository(super.db, super.clock);
  @override
  Future<int> insertExtracted(
    ExtractedTransaction t, {
    required int rawMessageId,
    required DateTime receivedAt,
  }) async => throw StateError('disk full');
}
