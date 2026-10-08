import 'package:flutter/material.dart';
import '../router/app_router.dart';

class NavigationService {
  static GlobalKey<NavigatorState> get navigatorKey =>
      AppRouter.rootNavigatorKey;

  static BuildContext? get context => navigatorKey.currentContext;
}
