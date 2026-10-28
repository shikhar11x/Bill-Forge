import 'package:drift/drift.dart' show Value;

import 'package:billforge/core/database/app_database.dart';
import 'package:billforge/features/billing/domain/credit_note.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';
import 'package:billforge/features/products/domain/product_unit.dart';

CreditNote creditNoteFromRow(CreditNoteRow r) => CreditNote(
  id: r.id,
  creditNoteNumber: r.creditNoteNumber,
  invoiceId: r.invoiceId,
  invoiceNumber: r.invoiceNumber,
  customerId: r.customerId,
  customerName: r.customerName,
  customerPhone: r.customerPhone,
  customerGstin: r.customerGstin,
  placeOfSupply: r.placeOfSupply,
  isInterState: r.isInterState,
  reason: ReturnReason.fromName(r.reason),
  note: r.note,
  isCancellation: r.isCancellation,
  restocked: r.restocked,
  taxablePaise: r.taxablePaise,
  cgstPaise: r.cgstPaise,
  sgstPaise: r.sgstPaise,
  igstPaise: r.igstPaise,
  roundOffPaise: r.roundOffPaise,
  totalPaise: r.totalPaise,
  appliedPaise: r.appliedPaise,
  refundPaise: r.refundPaise,
  refundMethod: r.refundMethod == null
      ? null
      : PaymentMethod.fromName(r.refundMethod!),
  issuedAt: r.issuedAt,
);

CreditNotesCompanion creditNoteToCompanion(CreditNote n) =>
    CreditNotesCompanion(
      id: Value(n.id),
      creditNoteNumber: Value(n.creditNoteNumber),
      invoiceId: Value(n.invoiceId),
      invoiceNumber: Value(n.invoiceNumber),
      customerId: Value(n.customerId),
      customerName: Value(n.customerName),
      customerPhone: Value(n.customerPhone),
      customerGstin: Value(n.customerGstin),
      placeOfSupply: Value(n.placeOfSupply),
      isInterState: Value(n.isInterState),
      reason: Value(n.reason.name),
      note: Value(n.note),
      isCancellation: Value(n.isCancellation),
      restocked: Value(n.restocked),
      taxablePaise: Value(n.taxablePaise),
      cgstPaise: Value(n.cgstPaise),
      sgstPaise: Value(n.sgstPaise),
      igstPaise: Value(n.igstPaise),
      roundOffPaise: Value(n.roundOffPaise),
      totalPaise: Value(n.totalPaise),
      appliedPaise: Value(n.appliedPaise),
      refundPaise: Value(n.refundPaise),
      refundMethod: Value(n.refundMethod?.name),
      issuedAt: Value(n.issuedAt),
    );

CreditNoteItem creditNoteItemFromRow(CreditNoteItemRow r) => CreditNoteItem(
  id: r.id,
  creditNoteId: r.creditNoteId,
  invoiceItemId: r.invoiceItemId,
  position: r.position,
  productId: r.productId,
  name: r.name,
  hsnCode: r.hsnCode,
  unit: ProductUnit.fromName(r.unit),
  qtyMilli: r.qtyMilli,
  unitPricePaise: r.unitPricePaise,
  gstRatePercent: r.gstRatePercent,
  taxablePaise: r.taxablePaise,
  cgstPaise: r.cgstPaise,
  sgstPaise: r.sgstPaise,
  igstPaise: r.igstPaise,
  totalPaise: r.totalPaise,
);

CreditNoteItemsCompanion creditNoteItemToCompanion(CreditNoteItem i) =>
    CreditNoteItemsCompanion(
      id: Value(i.id),
      creditNoteId: Value(i.creditNoteId),
      invoiceItemId: Value(i.invoiceItemId),
      position: Value(i.position),
      productId: Value(i.productId),
      name: Value(i.name),
      hsnCode: Value(i.hsnCode),
      unit: Value(i.unit.name),
      qtyMilli: Value(i.qtyMilli),
      unitPricePaise: Value(i.unitPricePaise),
      gstRatePercent: Value(i.gstRatePercent),
      taxablePaise: Value(i.taxablePaise),
      cgstPaise: Value(i.cgstPaise),
      sgstPaise: Value(i.sgstPaise),
      igstPaise: Value(i.igstPaise),
      totalPaise: Value(i.totalPaise),
    );
