import 'package:drift/drift.dart' show Value;

import 'package:billforge/core/database/app_database.dart';
import 'package:billforge/features/billing/domain/discount.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';
import 'package:billforge/features/products/domain/product_unit.dart';

Invoice invoiceFromRow(InvoiceRow r) => Invoice(
  id: r.id,
  invoiceNumber: r.invoiceNumber,
  status: InvoiceStatus.fromName(r.status),
  customerId: r.customerId,
  customerName: r.customerName,
  customerPhone: r.customerPhone,
  customerGstin: r.customerGstin,
  placeOfSupply: r.placeOfSupply,
  isInterState: r.isInterState,
  pricesIncludeTax: r.pricesIncludeTax,
  billDiscount: Discount(
    DiscountType.fromName(r.billDiscountType),
    r.billDiscountValue,
  ),
  discountPaise: r.discountPaise,
  taxablePaise: r.taxablePaise,
  cgstPaise: r.cgstPaise,
  sgstPaise: r.sgstPaise,
  igstPaise: r.igstPaise,
  roundOffPaise: r.roundOffPaise,
  grandTotalPaise: r.grandTotalPaise,
  paidPaise: r.paidPaise,
  issuedAt: r.issuedAt,
  createdAt: r.createdAt,
  updatedAt: r.updatedAt,
);

InvoicesCompanion invoiceToCompanion(Invoice i) => InvoicesCompanion(
  id: Value(i.id),
  invoiceNumber: Value(i.invoiceNumber),
  status: Value(i.status.name),
  customerId: Value(i.customerId),
  customerName: Value(i.customerName),
  customerPhone: Value(i.customerPhone),
  customerGstin: Value(i.customerGstin),
  placeOfSupply: Value(i.placeOfSupply),
  isInterState: Value(i.isInterState),
  pricesIncludeTax: Value(i.pricesIncludeTax),
  billDiscountType: Value(i.billDiscount.type.name),
  billDiscountValue: Value(i.billDiscount.value),
  discountPaise: Value(i.discountPaise),
  taxablePaise: Value(i.taxablePaise),
  cgstPaise: Value(i.cgstPaise),
  sgstPaise: Value(i.sgstPaise),
  igstPaise: Value(i.igstPaise),
  roundOffPaise: Value(i.roundOffPaise),
  grandTotalPaise: Value(i.grandTotalPaise),
  paidPaise: Value(i.paidPaise),
  issuedAt: Value(i.issuedAt),
  createdAt: Value(i.createdAt),
  updatedAt: Value(i.updatedAt),
);

InvoiceItem itemFromRow(InvoiceItemRow r) => InvoiceItem(
  id: r.id,
  invoiceId: r.invoiceId,
  position: r.position,
  productId: r.productId,
  name: r.name,
  hsnCode: r.hsnCode,
  unit: ProductUnit.fromName(r.unit),
  qtyMilli: r.qtyMilli,
  unitPricePaise: r.unitPricePaise,
  discount: Discount(DiscountType.fromName(r.discountType), r.discountValue),
  gstRatePercent: r.gstRatePercent,
  discountPaise: r.discountPaise,
  taxablePaise: r.taxablePaise,
  cgstPaise: r.cgstPaise,
  sgstPaise: r.sgstPaise,
  igstPaise: r.igstPaise,
  totalPaise: r.totalPaise,
);

InvoiceItemsCompanion itemToCompanion(InvoiceItem i) => InvoiceItemsCompanion(
  id: Value(i.id),
  invoiceId: Value(i.invoiceId),
  position: Value(i.position),
  productId: Value(i.productId),
  name: Value(i.name),
  hsnCode: Value(i.hsnCode),
  unit: Value(i.unit.name),
  qtyMilli: Value(i.qtyMilli),
  unitPricePaise: Value(i.unitPricePaise),
  discountType: Value(i.discount.type.name),
  discountValue: Value(i.discount.value),
  gstRatePercent: Value(i.gstRatePercent),
  discountPaise: Value(i.discountPaise),
  taxablePaise: Value(i.taxablePaise),
  cgstPaise: Value(i.cgstPaise),
  sgstPaise: Value(i.sgstPaise),
  igstPaise: Value(i.igstPaise),
  totalPaise: Value(i.totalPaise),
);

InvoicePayment paymentFromRow(InvoicePaymentRow r) => InvoicePayment(
  id: r.id,
  invoiceId: r.invoiceId,
  method: PaymentMethod.fromName(r.method),
  amountPaise: r.amountPaise,
  paidAt: r.paidAt,
);
