import 'package:flutter/material.dart';
import 'package:vu_mcqs_app/bootstrap.dart';
import 'package:vu_mcqs_app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Bootstrap.initialize();
  runApp(const MyApp());
}
