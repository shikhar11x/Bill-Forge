import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/core/database/database_providers.dart';
import 'package:billforge/features/billing/data/drift_credit_note_repository.dart';
import 'package:billforge/features/billing/domain/credit_note.dart';
import 'package:billforge/features/billing/domain/credit_note_repository.dart';

final creditNoteRepositoryProvider = Provider<CreditNoteRepository>(
  (ref) => DriftCreditNoteRepository(ref.watch(appDatabaseProvider)),
);

final creditNotesForInvoiceProvider = StreamProvider.autoDispose
    .family<List<CreditNote>, String>(
      (ref, invoiceId) =>
          ref.watch(creditNoteRepositoryProvider).watchForInvoice(invoiceId),
    );

final creditNoteDetailProvider = FutureProvider.autoDispose
    .family<CreditNoteDetail?, String>(
      (ref, id) => ref.watch(creditNoteRepositoryProvider).getDetail(id),
    );

final returnedItemsProvider = FutureProvider.autoDispose
    .family<List<CreditNoteItem>, String>(
      (ref, invoiceId) =>
          ref.watch(creditNoteRepositoryProvider).returnedItems(invoiceId),
    );
