import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../models/user.dart';
import '../models/transaction_record.dart';
import 'add_entry_page.dart';
import 'full_history_page.dart';
import 'user_page.dart';
import 'users_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DBHelper db = DBHelper.instance;
  Map<User, double> userBalances = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }

  Future<void> _loadBalances() async {
    final users = await db.getUsers();
    final Map<User, double> balances = {};

    for (final user in users) {
      final txns = await db.getTransactions(user.id!);
      double balance = 0.0;
      for (final txn in txns) {
        balance += txn.isPayment ? -txn.amount : txn.amount;
      }
      if (balance != 0.0) {
        balances[user] = balance;
      }
    }

    setState(() {
      userBalances = balances;
      isLoading = false;
    });
  }

  void _goToAddEntry() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEntryPage()),
    ).then((_) => _loadBalances());
  }

  void _goToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FullHistoryPage()),
    );
  }

  void _goToUserPage(User user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserPage(user: user)),
    ).then((_) => _loadBalances());
  }

  @override
  Widget build(BuildContext context) {
    double total = userBalances.values.fold(0.0, (a, b) => a + b);

    final oweList = userBalances.entries.where((e) => e.value < 0).toList();
    final owedList = userBalances.entries.where((e) => e.value > 0).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("₹${total.toStringAsFixed(2)}  balance"),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: 'View All Users',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UsersPage()),
              ).then((_) => _loadBalances());
            },
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                if (oweList.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      "what you owe",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...oweList.map(
                    (entry) => _buildUserTile(entry.key, entry.value),
                  ),
                ],
                if (owedList.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      "what you're owed",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...owedList.map(
                    (entry) => _buildUserTile(entry.key, entry.value),
                  ),
                ],
              ],
            ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "history",
            onPressed: _goToHistory,
            child: const Icon(Icons.history),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: "add",
            onPressed: _goToAddEntry,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(User user, double balance) {
    final isOwed = balance > 0;
    final amountStr = "₹${balance.abs().toStringAsFixed(2)}";
    final label = isOwed ? "Owes You $amountStr" : "You Owe $amountStr";
    final color = isOwed ? Colors.greenAccent : Colors.redAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        tileColor: Colors.grey[800],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(label, style: TextStyle(color: color)),
        subtitle: Text(user.name),
        trailing: Text(user.mobile, style: const TextStyle(fontSize: 12)),
        onTap: () => _goToUserPage(user),
      ),
    );
  }
}
