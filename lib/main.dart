import 'package:flutter/material.dart';

void main() {
  runApp(const NovaApp());
}

class NovaApp extends StatelessWidget {
  const NovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nova',
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: const Color(0xFF071329),
        appBar: AppBar(
          title: const Text('Nova ✨'),
          backgroundColor: const Color(0xFF071329),
        ),
        body: const Center(
          child: Text(
            '✨ Nova VPN',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
