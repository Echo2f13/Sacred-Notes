import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../models/user.dart';
import '../models/transaction_record.dart';
import 'users_page.dart';
import 'edit_transaction_page.dart';

class UserPage extends StatefulWidget {
  final User user;

  const UserPage({super.key, required this.user});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  late User _user;
  List<TransactionRecord> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final db = DBHelper.instance;
    final txns = await db.getTransactions(_user.id!);
    txns.sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      _transactions = txns;
      _loading = false;
    });
  }

  void _editUserDialog() {
    final nameController = TextEditingController(text: _user.name);
    final mobileController = TextEditingController(text: _user.mobile);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: mobileController,
              decoration: const InputDecoration(labelText: 'Mobile'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _confirmDeleteUser,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newMobile = mobileController.text.trim();
              if (newName.isNotEmpty) {
                final updatedUser = User(
                  id: _user.id,
                  name: newName,
                  mobile: newMobile,
                );
                await DBHelper.instance.insertUser(updatedUser);
                setState(() => _user = updatedUser);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
        actions: [
          IconButton(onPressed: _editUserDialog, icon: const Icon(Icons.edit)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    title: Text(
                      _user.name,
                      style: const TextStyle(fontSize: 18),
                    ),
                    subtitle: Text(_user.mobile),
                  ),
                ),
                const Text(
                  'Transactions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (_transactions.isEmpty) const Text("No transactions yet."),
                ..._transactions.map((txn) {
                  final isOwed = !txn.isPayment;
                  final amountStr = '₹${txn.amount.toStringAsFixed(2)}';
                  final label = isOwed
                      ? 'Owe You $amountStr'
                      : 'You Owe $amountStr';
                  final color = isOwed ? Colors.greenAccent : Colors.redAccent;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.grey[850],
                    child: ListTile(
                      title: Text(label, style: TextStyle(color: color)),
                      subtitle: Text(txn.description),
                      trailing: Text(
                        '${txn.date.day} ${_monthName(txn.date.month)} ${txn.date.year}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EditTransactionPage(transaction: txn),
                          ),
                        ).then((_) => _loadTransactions());
                      },
                    ),
                  );
                }),
              ],
            ),
    );
  }

  String _monthName(int month) {
    const names = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month];
  }

  void _confirmDeleteUser() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to delete this user and all their transactions?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // close confirmation
              await _deleteUserAndTransactions();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUserAndTransactions() async {
    final db = DBHelper.instance;
    final id = _user.id!;
    final database = await db.database;

    await database.transaction((txn) async {
      await txn.delete('transactions', where: 'user_id = ?', whereArgs: [id]);
      await txn.delete('users', where: 'id = ?', whereArgs: [id]);
    });

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const UsersPage()),
        (route) => route.isFirst,
      );
    }
  }
}
