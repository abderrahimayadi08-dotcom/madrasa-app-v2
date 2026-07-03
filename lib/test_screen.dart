import 'package:flutter/material.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('اختبار')),
        body: const Center(
          child: Text('التطبيق يشتغل!'),
        ),
      ),
    );
  }
}
