import 'package:flutter/material.dart';
import 'ui/race_simulator_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'F1 Race Simulator',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: F1RaceSimulator(),
      debugShowCheckedModeBanner: false,
    );
  }
}
