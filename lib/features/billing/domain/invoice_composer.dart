import 'package:billforge/features/billing/domain/bill_calculator.dart';
import 'package:billforge/features/billing/domain/cart_line.dart';
import 'package:billforge/features/billing/domain/discount.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/shop_tax_context.dart';
import 'package:billforge/features/customers/domain/customer.dart';

/// Turns a cart into the exact draft invoice that gets stored.
InvoiceDetail composeInvoice({
  required String id,
  required List<CartLine> lines,
  required Discount billDiscount,
  required Customer? customer,
  required ShopTaxContext shop,
  required DateTime createdAt,
  required DateTime now,
}) {
  final interState = shop.isInterState(customer);
  final totals = calculateBill(
    lines: lines,
    billDiscount: billDiscount,
    interState: interState,
    pricesIncludeTax: shop.pricesIncludeTax,
    chargesTax: shop.chargesTax,
  );

  final invoice = Invoice(
    id: id,
    status: InvoiceStatus.draft,
    customerId: customer?.id,
    customerName: customer?.name,
    customerPhone: customer?.phone,
    customerGstin: customer?.gstin,
    placeOfSupply: shop.placeOfSupplyFor(customer),
    isInterState: interState,
    pricesIncludeTax: shop.pricesIncludeTax,
    billDiscount: billDiscount,
    discountPaise: totals.discountPaise,
    taxablePaise: totals.taxablePaise,
    cgstPaise: totals.cgstPaise,
    sgstPaise: totals.sgstPaise,
    igstPaise: totals.igstPaise,
    roundOffPaise: totals.roundOffPaise,
    grandTotalPaise: totals.grandTotalPaise,
    createdAt: createdAt,
    updatedAt: now,
  );

  final items = <InvoiceItem>[
    for (var i = 0; i < lines.length; i++)
      InvoiceItem(
        id: '$id-${i + 1}',
        invoiceId: id,
        position: i,
        productId: lines[i].productId,
        name: lines[i].name,
        hsnCode: lines[i].hsnCode,
        unit: lines[i].unit,
        qtyMilli: lines[i].qtyMilli,
        unitPricePaise: lines[i].unitPricePaise,
        discount: lines[i].discount,
        gstRatePercent: shop.chargesTax ? lines[i].gstRatePercent : 0,
        discountPaise: totals.lines[i].discountPaise,
        taxablePaise: totals.lines[i].taxablePaise,
        cgstPaise: totals.lines[i].cgstPaise,
        sgstPaise: totals.lines[i].sgstPaise,
        igstPaise: totals.lines[i].igstPaise,
        totalPaise: totals.lines[i].totalPaise,
      ),
  ];

  return InvoiceDetail(invoice: invoice, items: items);
}
