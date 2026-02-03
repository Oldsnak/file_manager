// lib/main.dart

import 'package:flutter/material.dart';
import 'app.dart';
import 'core/dependency_injection.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DependencyInjection.init();
  runApp(const MyApp());
}
