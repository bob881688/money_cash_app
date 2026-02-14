import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'log_page.dart';

void main() async {
  // 因為 main() 內有 await（dotenv.load），先確保 Flutter 的 binding 已初始化。
  // 這是 Flutter 官方建議的寫法，避免某些平台上出現初始化時序問題。
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        scaffoldBackgroundColor: Color.fromARGB(255, 31, 31, 31),
        colorScheme: ColorScheme.fromSeed(
          onSurface: Color.fromARGB(255, 187, 187, 187),
          seedColor: const Color.fromARGB(255, 0, 0, 0),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF151515),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color.fromARGB(255, 187, 187, 187),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        listTileTheme: const ListTileThemeData(
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 16),
          textColor: Colors.white,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: Color.fromARGB(255, 187, 187, 187)),
        ),
      ),

      home: const LogPage(),
    );
  }
}