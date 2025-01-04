import 'package:chat/page/chat.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum PageKey {
  chat;

  String get path => "/$name";

  Widget get widget {
    switch (this) {
      case PageKey.chat:
        return const Chat();
    }
  }

  GoRoute get route => GoRoute(path: path, builder: (_, __) => widget);
}
