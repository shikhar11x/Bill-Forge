/// Caps that keep every product below 2^53 (what web numbers hold exactly):
/// 9,999.999 units x ₹10,00,000 per unit.
const kMaxStockQtyMilli = 9999999;
const kMaxUnitCostPaise = 100000000;

/// Quantity (thousandths) x unit cost (paise), rounded half up to a paisa.
int purchaseLineTotal(int qtyMilli, int unitCostPaise) =>
    (qtyMilli * unitCostPaise + 500) ~/ 1000;
