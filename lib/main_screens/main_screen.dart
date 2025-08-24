import 'package:flutter/material.dart';

abstract class IMainScreen extends Widget {
  const IMainScreen({super.key});

  IconData icon();
  String title();
}