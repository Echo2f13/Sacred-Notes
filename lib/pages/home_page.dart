// home_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db_helper.dart';
import '../models/user.dart';
import 'add_entry_page.dart';
import 'full_history_page.dart';
import 'users_page.dart';
import 'user_page.dart';
import 'dart:ui';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  List<User> _users = [];
  Map<int, double> _balances = {};
  Map<int, String> _lastDescriptions = {};
  Map<int, DateTime> _lastDates = {};
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 60))..repeat();
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final db = DBHelper.instance;
    final users = await db.getUsers();
    final balances = <int, double>{};
    final descriptions = <int, String>{};
    final dates = <int, DateTime>{};

    for (final user in users) {
      final txns = await db.getTransactions(user.id!);
      if (txns.isEmpty) continue;
      txns.sort((a, b) => b.date.compareTo(a.date));
      final latest = txns.first;
      final net = txns.fold(0.0, (sum, txn) => sum + (txn.isPayment ? -txn.amount : txn.amount));
      if (net != 0.0) {
        balances[user.id!] = net;
        descriptions[user.id!] = latest.description;
        dates[user.id!] = latest.date;
      }
    }

    setState(() {
      _users = users;
      _balances = balances;
      _lastDescriptions = descriptions;
      _lastDates = dates;
    });
  }

  double get netBalance => _balances.values.fold(0.0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final owed = _users.where((u) => (_balances[u.id!] ?? 0) > 0).toList();
    final owe = _users.where((u) => (_balances[u.id!] ?? 0) < 0).toList();

    final pages = [
      _mainPage(owe, owed),
      const UsersPage(),
      const FullHistoryPage(),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(toolbarHeight: 0),
      body: pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5A8DEE),
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEntryPage()),
        ).then((_) => _loadData()),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF1C1C28),
        selectedItemColor: const Color(0xFF5A8DEE),
        unselectedItemColor: Colors.white54,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }

  Widget _mainPage(List<User> owe, List<User> owed) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1C1C28), Color(0xFF232334)],
            ),
          ),
        ),
        ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 100),
          children: [
            _frostedBalanceCard(),
            const SizedBox(height: 24),
            _trendBoxRow(),
            const SizedBox(height: 40),
            _sectionTitle('You Owe Others', Colors.redAccent),
            ...owe.map((u) => _debtCard(u, _balances[u.id!]!)),
            const SizedBox(height: 24),
            _sectionTitle('Others Owe You', Colors.greenAccent),
            ...owed.map((u) => _debtCard(u, _balances[u.id!]!)),
          ],
        ),
      ],
    );
  }

  Widget _frostedBalanceCard() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white.withOpacity(0.1),
            ),
            child: Column(
              children: [
                Text('₹${netBalance.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white)),
                const SizedBox(height: 6),
                const Text('Net Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _trendBoxRow() {
    final totalOwed = _balances.values.where((v) => v > 0).fold(0.0, (a, b) => a + b);
    final totalOwe = _balances.values.where((v) => v < 0).fold(0.0, (a, b) => a + b).abs();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _trendBox('+₹${totalOwed.toStringAsFixed(0)}', Colors.greenAccent),
        const SizedBox(width: 8),
        _trendBox('-₹${totalOwe.toStringAsFixed(0)}', Colors.redAccent),
      ],
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 6, height: 24, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 12),
          Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _debtCard(User user, double amount) {
    final isOwed = amount > 0;
    final labelColor = isOwed ? Colors.greenAccent : Colors.redAccent;
    final description = _lastDescriptions[user.id!] ?? '';
    final date = _lastDates[user.id!];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2C3A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('₹${amount.abs().toStringAsFixed(2)}',
                  style: TextStyle(color: labelColor, fontWeight: FontWeight.bold, fontSize: 16)),
              if (date != null)
                Text(DateFormat('dd MMM yyyy').format(date),
                    style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(user.name, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _trendBox(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.08),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}