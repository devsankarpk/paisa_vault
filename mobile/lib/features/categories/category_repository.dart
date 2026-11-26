import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../core/db/app_database.dart';

enum CategoryResult { ok, empty, exists, fixed, notFound }

class CategoryRepository {
  CategoryRepository(this._db, this._clock);
  final AppDatabase _db;
  final Clock _clock;

  /// Every category, in list order, including hidden ones.
  Stream<List<Category>> watchAll() => (_db.select(
    _db.categories,
  )..orderBy([(c) => OrderingTerm.asc(c.sortOrder)])).watch();

  /// Names offered for new transactions: not hidden.
  Stream<List<String>> watchVisibleNames() => watchAll().map(
    (l) => [
      for (final c in l)
        if (!c.hidden) c.name,
    ],
  );

  /// The same names as [watchVisibleNames], read once.
  Future<List<String>> visibleNames() => watchVisibleNames().first;

  Future<Category?> _byName(String name) =>
      (_db.select(_db.categories)
            ..where((c) => c.name.lower().equals(name.trim().toLowerCase())))
          .getSingleOrNull();

  Future<CategoryResult> add(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) return CategoryResult.empty;
    if (await _byName(clean) != null) return CategoryResult.exists;
    // New expense categories go after the other expense ones, before Income and Transfer.
    final all = await _db.select(_db.categories).get();
    final position = all.where((c) => c.kind == CategoryKind.expense).length;
    await _db.transaction(() async {
      for (final c in all.where((c) => c.sortOrder >= position)) {
        await (_db.update(_db.categories)..where((x) => x.id.equals(c.id)))
            .write(CategoriesCompanion(sortOrder: Value(c.sortOrder + 1)));
      }
      await _db
          .into(_db.categories)
          .insert(
            CategoriesCompanion.insert(
              name: clean,
              kind: CategoryKind.expense,
              sortOrder: Value(position),
              createdAt: _clock.now(),
            ),
          );
    });
    return CategoryResult.ok;
  }

  /// Renames a category everywhere it is used: transactions, merchant rules, budgets.
  Future<CategoryResult> rename(String from, String to) async {
    final clean = to.trim();
    if (clean.isEmpty) return CategoryResult.empty;
    final cat = await _byName(from);
    if (cat == null) return CategoryResult.notFound;
    if (cat.kind != CategoryKind.expense) return CategoryResult.fixed;
    final clash = await _byName(clean);
    if (clash != null && clash.id != cat.id) return CategoryResult.exists;
    await _db.transaction(() async {
      await (_db.update(_db.categories)..where((c) => c.id.equals(cat.id)))
          .write(CategoriesCompanion(name: Value(clean)));
      await (_db.update(_db.transactions)
            ..where((t) => t.categoryName.equals(cat.name)))
          .write(TransactionsCompanion(categoryName: Value(clean)));
      await (_db.update(_db.merchantRules)
            ..where((r) => r.categoryName.equals(cat.name)))
          .write(MerchantRulesCompanion(categoryName: Value(clean)));
      await (_db.update(_db.budgets)
            ..where((b) => b.categoryName.equals(cat.name)))
          .write(BudgetsCompanion(categoryName: Value(clean)));
      await (_db.update(_db.budgetAlertLog)
            ..where((l) => l.categoryName.equals(cat.name)))
          .write(BudgetAlertLogCompanion(categoryName: Value(clean)));
    });
    return CategoryResult.ok;
  }

  /// Hides or shows a category. Old transactions keep it; it is just not offered any more.
  Future<CategoryResult> setHidden(String name, bool hidden) async {
    final cat = await _byName(name);
    if (cat == null) return CategoryResult.notFound;
    if (cat.kind != CategoryKind.expense) return CategoryResult.fixed;
    await (_db.update(_db.categories)..where((c) => c.id.equals(cat.id))).write(
      CategoriesCompanion(hidden: Value(hidden)),
    );
    return CategoryResult.ok;
  }
}
