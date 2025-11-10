import 'package:flutter/material.dart';

class DataSettingsScreen extends StatelessWidget {
  const DataSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Data Settings'),
        ),
        body: const Center(
          child: Text('Data Settings Screen'),
        ),
      );
}
