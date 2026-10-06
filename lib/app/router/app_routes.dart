abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const onboarding = '/onboarding';
  static const shopEdit = '/shop/edit';

  static const dashboard = '/dashboard';
  static const billing = '/billing';
  static const products = '/products';
  static const productNew = '/products/new';
  static String productEdit(String id) => '/products/$id/edit';
  static const customers = '/customers';
  static const customerNew = '/customers/new';
  static String customerEdit(String id) => '/customers/$id/edit';
  static const inventory = '/inventory';
  static const reports = '/reports';
  static const settings = '/settings';
}
