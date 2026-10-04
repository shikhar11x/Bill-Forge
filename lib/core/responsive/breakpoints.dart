enum ScreenSize {
  mobile,
  tablet,
  desktop;

  bool get isMobile => this == ScreenSize.mobile;
  bool get isTablet => this == ScreenSize.tablet;
  bool get isDesktop => this == ScreenSize.desktop;
}

abstract final class Breakpoints {
  /// Mobile: width < 600
  static const double tabletMin = 600;

  /// Tablet: 600 to 1024 inclusive. Desktop: width > 1024
  static const double desktopMin = 1024;

  static ScreenSize fromWidth(double width) {
    if (width < tabletMin) return ScreenSize.mobile;
    if (width <= desktopMin) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }
}