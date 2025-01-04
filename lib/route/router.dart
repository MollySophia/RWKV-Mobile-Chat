import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:chat/config.dart';
import 'package:chat/route/page_key.dart';

BuildContext? getContext() {
  return getNavigatorKey().currentState?.context;
}

GlobalKey<NavigatorState> getNavigatorKey() {
  return _navigatorKey;
}

final _navigatorKey = GlobalKey<NavigatorState>(debugLabel: "root");

final kRouter = GoRouter(
  debugLogDiagnostics: false,
  navigatorKey: _navigatorKey,
  initialLocation: () {
    if (Config.offlineChat) {
      return PageKey.chat.path;
    }
    return PageKey.chat.path;
  }(),
  routes: [
    ...PageKey.values.map((e) => e.route),
  ],
);
