import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vu_mcqs_app/theme/app_theme.dart';
import 'package:vu_mcqs_app/providers/auth_provider.dart' as auth_provider;
import 'package:vu_mcqs_app/providers/theme_provider.dart';
import 'package:vu_mcqs_app/screen/auth_wrapper.dart';
import 'package:vu_mcqs_app/services/connectivity_listener_service.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ConnectivityListenerService _connectivityListener = ConnectivityListenerService();

  @override
  void initState() {
    super.initState();
    // Start listening to connectivity changes
    _connectivityListener.startListening();
  }

  @override
  void dispose() {
    // Stop listening when app is disposed
    _connectivityListener.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => auth_provider.AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Vu MCQs',
            debugShowCheckedModeBanner: false,
            locale: const Locale('en', 'US'),
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}
