
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

void main() {
  runApp(HBWFCApp());
}

class HBWFCApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HBWFC Overlijst',
      theme: ThemeData(
        primaryColor: Color(0xFF2E8B3A),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF2E8B3A),
          foregroundColor: Colors.white,
        ),
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('HBWFC Overlijst')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 56)),
                child: Text('Scannen', style: TextStyle(fontSize: 18)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ScanSessionScreen())),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 56)),
                child: Text('Historie', style: TextStyle(fontSize: 18)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Voor de rest van ScanSessionScreen, SessionResultScreen en HistoryScreen
// gebruik je de code uit de eerdere versie (omdat deze te lang is om hier volledig te herhalen)
