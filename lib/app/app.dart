import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'responsive_shell.dart';
import '../features/password/password_controller.dart';
import '../features/password/password_service.dart';

class NetUtilityApp extends StatelessWidget {
  const NetUtilityApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Controllers are provided here so every screen can use Consumer<T>.
    // Phase 6 will expand this into a MultiProvider with all controllers.
    return ChangeNotifierProvider(
      create: (_) => PasswordController(service: PasswordService()),
      child: MaterialApp(
        title: 'Net Utility Toolkit',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0D47A1),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0D47A1),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.dark,
        home: const ResponsiveShell(),
      ),
    );
  }
}
