import 'package:flutter/material.dart';
import 'screens/bin_list_page.dart';

void main() {
  runApp(const AtikApp());
}

class AtikApp extends StatelessWidget {
  const AtikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atık Doluluk Takip',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF4F6FB), // hafif gri arka plan
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: false,
        ),
      ),

      home: const BinListPage(), // <-- bizim liste ekranı
    );
  }
}
