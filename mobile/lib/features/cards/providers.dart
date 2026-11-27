import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/providers.dart';
import 'card_repository.dart';

final cardRepositoryProvider = FutureProvider<CardRepository>((ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return CardRepository(db, ref.watch(clockProvider));
});

final cardsProvider = StreamProvider<List<CardEntry>>((ref) async* {
  yield* (await ref.watch(cardRepositoryProvider.future)).watchAll();
});

/// Bill settings for one card, read again whenever the cards change.
final billProvider = FutureProvider.family<CardBillSetting?, int>((
  ref,
  cardId,
) async {
  ref.watch(cardsProvider);
  return (await ref.watch(cardRepositoryProvider.future)).billFor(cardId);
});
