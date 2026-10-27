abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const onboarding = '/onboarding';
  static const shopEdit = '/shop/edit';

  static const dashboard = '/dashboard';
  static const billing = '/billing';
  static const billingNew = '/billing/new';
  static String invoice(String id) => '/billing/$id';
  static String invoicePreview(String id) => '/billing/$id/preview';
  static String invoiceReturn(String id) => '/billing/$id/return';
  static String creditNote(String id) => '/billing/credit-notes/$id';
  static const products = '/products';
  static const productNew = '/products/new';
  static String productEdit(String id) => '/products/$id/edit';
  static const customers = '/customers';
  static const customerNew = '/customers/new';
  static const customerOutstanding = '/customers/outstanding';
  static String customerAccount(String id) => '/customers/$id';
  static String customerEdit(String id) => '/customers/$id/edit';
  static String customerStatement(String id) => '/customers/$id/statement';
  static const inventory = '/inventory';
  static const purchaseNew = '/inventory/purchases/new';
  static String purchase(String id) => '/inventory/purchases/$id';
  static String stockHistory(String productId) => '/inventory/stock/$productId';
  static const reports = '/reports';
  static const settings = '/settings';
}
