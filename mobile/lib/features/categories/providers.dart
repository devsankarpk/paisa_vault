import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/providers.dart';
import 'category_repository.dart';

final categoryRepositoryProvider = FutureProvider<CategoryRepository>((
  ref,
) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return CategoryRepository(db, ref.watch(clockProvider));
});

/// All categories including hidden, for the management screen.
final allCategoriesProvider = StreamProvider<List<Category>>((ref) async* {
  yield* (await ref.watch(categoryRepositoryProvider.future)).watchAll();
});

/// Names to offer for a new transaction (hidden ones left out). Income and Transfer included.
final categoryNamesProvider = StreamProvider<List<String>>((ref) async* {
  yield* (await ref.watch(categoryRepositoryProvider.future))
      .watchVisibleNames();
});

/// The visible names, or the starting list while the database is still opening.
List<String> namesOrDefault(AsyncValue<List<String>> v) =>
    v.asData?.value ?? [...seedExpenseCategories, 'Income', 'Transfer'];

/// Every name including hidden ones, for filtering old transactions.
final allNamesProvider = Provider<AsyncValue<List<String>>>((ref) {
  return ref
      .watch(allCategoriesProvider)
      .whenData((l) => [for (final c in l) c.name]);
});
