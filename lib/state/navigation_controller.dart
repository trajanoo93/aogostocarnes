// lib/state/nagivation_controller.dart

import 'package:flutter/material.dart';

class NavigationController {
  static final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
  static Function(int)? changeTab;
}
