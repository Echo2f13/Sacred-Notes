import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/add_entry_page.dart';
import 'pages/history_page.dart';
import 'pages/profile_page.dart';
import 'pages/edit_profile_page.dart';

void main() {
  runApp(SacredNotesApp());
}

class SacredNotesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sacred Notes',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (_) => HomePage(),
        '/add': (_) => AddEntryPage(),
        '/history': (_) => HistoryPage(),
        '/profile': (_) => ProfilePage(),
        '/edit': (_) => EditProfilePage(),
      },
    );
  }
}
