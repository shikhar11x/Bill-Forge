import 'package:billforge/features/customers/domain/customer.dart';
import 'package:billforge/features/shop/domain/shop_profile.dart';

/// The shop facts that decide how a bill is taxed.
class ShopTaxContext {
  const ShopTaxContext({
    required this.shopState,
    required this.pricesIncludeTax,
    required this.chargesTax,
  });

  factory ShopTaxContext.fromShop(ShopProfile shop) => ShopTaxContext(
    shopState: shop.state,
    pricesIncludeTax: shop.pricesIncludeTax,
    chargesTax: shop.gstRegistration.chargesTax,
  );

  final String shopState;
  final bool pricesIncludeTax;
  final bool chargesTax;

  /// The customer's state, or the shop's own when unknown (walk-in).
  String placeOfSupplyFor(Customer? customer) {
    final state = customer?.state;
    return (state != null && state.isNotEmpty) ? state : shopState;
  }

  /// Supplies to another state attract IGST instead of CGST+SGST.
  bool isInterState(Customer? customer) =>
      chargesTax && placeOfSupplyFor(customer) != shopState;
}
