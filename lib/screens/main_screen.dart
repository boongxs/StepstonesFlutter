import 'dart:io';
import 'package:flutter/material.dart';
import 'main_screen_desktop.dart';
import 'main_screen_mobile.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      return const MainScreenMobile();
    } else {
      return const MainScreenDesktop();
    }
  }
}