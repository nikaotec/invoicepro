import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';

/// Device type based on screen width
enum DeviceType { mobile, tablet, desktop }

/// Responsive layout utilities
class ResponsiveLayout {
  /// Get device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < AppDimensions.breakpointMobile) {
      return DeviceType.mobile;
    } else if (width < AppDimensions.breakpointTablet) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Check if device is mobile
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }

  /// Check if device is tablet or larger
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop;
  }

  /// Check if device is tablet or larger (for NavigationRail)
  static bool isTabletOrLarger(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= AppDimensions.breakpointMobile;
  }

  /// Get responsive value based on device type
  static T getResponsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Get number of columns for grid based on device type
  static int getGridColumns(BuildContext context) {
    return getResponsiveValue(context, mobile: 1, tablet: 2, desktop: 3);
  }

  /// Get horizontal padding based on device type
  static double getHorizontalPadding(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: AppDimensions.spacingLg,
      tablet: AppDimensions.spacingXl,
      desktop: AppDimensions.spacing2xl,
    );
  }

  /// Get maximum content width for centered layouts
  static double getMaxContentWidth(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: double.infinity,
      tablet: AppDimensions.maxContentWidthMd,
      desktop: AppDimensions.maxContentWidthLg,
    );
  }
}

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveLayout.getDeviceType(context);
    return builder(context, deviceType);
  }
}

/// Adaptive layout widget that switches between mobile and tablet layouts
class AdaptiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const AdaptiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        switch (deviceType) {
          case DeviceType.mobile:
            return mobile;
          case DeviceType.tablet:
            return tablet ?? mobile;
          case DeviceType.desktop:
            return desktop ?? tablet ?? mobile;
        }
      },
    );
  }
}
