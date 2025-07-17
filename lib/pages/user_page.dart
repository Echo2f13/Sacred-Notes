import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

class _UserPageState extends State<UserPage>
    with SingleTickerProviderStateMixin {
  late User _user;
  List<TransactionRecord> _transactions = [];
  bool _loading = true;
  late AnimationController _controller;
  Future<void> _settleUser() async {
    final db = DBHelper.instance;

    final netBalance = _transactions.fold<double>(
      0.0,
      (sum, txn) => sum + (txn.isPayment ? -txn.amount : txn.amount),
    );

    if (netBalance == 0.0) return;

    final newTxn = TransactionRecord(
      userId: _user.id!,
      amount: netBalance.abs(),
      isPayment: netBalance > 0, // You Owe if net > 0
      description:
          "Settled ${DateFormat('dd MMM yyyy').format(DateTime.now())}",
      date: DateTime.now(),
    );

    await db.insertTransaction(newTxn);
    await _loadTransactions();
  }

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _loadTransactions();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        backgroundColor: Colors.grey[900],
        title: const Text('Edit User', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: Colors.white60),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            TextField(
              controller: mobileController,
              decoration: const InputDecoration(
                labelText: 'Mobile',
                labelStyle: TextStyle(color: Colors.white60),
              ),
              style: const TextStyle(color: Colors.white),
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
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('User Details'),
        actions: [
          IconButton(onPressed: _editUserDialog, icon: const Icon(Icons.edit)),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.fromRGBO(0, 49, 80, 0.25),
                        Colors.black,
                        Color.fromRGBO(46, 0, 65, 0.1),
                      ],
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (_, child) {
                    return CustomPaint(
                      size: MediaQuery.of(context).size,
                      painter: _StarfieldPainter(_controller.value),
                    );
                  },
                ),
              ],
            ),
          ),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 120, 16, 16),
                  children: [
                    Card(
                      color: Colors.black.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          _user.name,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          _user.mobile,
                          style: const TextStyle(color: Colors.white60),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_transactions.isNotEmpty)
                      Builder(
                        builder: (context) {
                          final netBalance = _transactions.fold<double>(
                            0.0,
                            (sum, txn) =>
                                sum +
                                (txn.isPayment ? -txn.amount : txn.amount),
                          );
                          final isDisabled = netBalance == 0.0;

                          return ElevatedButton.icon(
                            onPressed: isDisabled ? null : _settleUser,
                            icon: const Icon(Icons.done),
                            label: const Text("Settle"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDisabled
                                  ? Colors.grey[800]
                                  : Colors.greenAccent[700],
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[900],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 20),
                    const Text(
                      'Transactions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_transactions.isEmpty)
                      const Text(
                        "No transactions yet.",
                        style: TextStyle(color: Colors.white60),
                      ),
                    ..._transactions.map((txn) {
                      final isOwed = !txn.isPayment;
                      final amountStr = '₹${txn.amount.toStringAsFixed(2)}';
                      // final label = isOwed
                      //     ? 'Owe You $amountStr'
                      //     : 'You Owe $amountStr';
                      final borderColor = isOwed
                          ? const Color.fromRGBO(16, 185, 129, 0.2)
                          : const Color.fromRGBO(255, 0, 0, 0.2);
                      final labelColor = isOwed
                          ? const Color.fromARGB(255, 70, 220, 97)
                          : const Color.fromARGB(255, 252, 68, 68);

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditTransactionPage(transaction: txn),
                            ),
                          ).then((_) => _loadTransactions());
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color.fromRGBO(0, 0, 0, 0.098),
                                Color.fromRGBO(0, 0, 0, 0.047),
                                Color.fromRGBO(0, 0, 0, 0.098),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Amount + Date
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    amountStr,
                                    style: TextStyle(
                                      color: labelColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(txn.date),
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              // Description centered
                              Expanded(
                                child: Center(
                                  child: Text(
                                    txn.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color.fromARGB(196, 255, 255, 255),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
        ],
      ),
    );
  }

  void _confirmDeleteUser() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Confirm Delete',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this user and all their transactions?',
          style: TextStyle(color: Colors.white70),
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

class _StarfieldPainter extends CustomPainter {
  final double progress;
  _StarfieldPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    final paint = Paint()..color = Colors.white.withOpacity(0.015);
    for (int i = 0; i < 150; i++) {
      final dx = (size.width * (i / 150) + progress * 30) % size.width;
      final dy =
          (size.height * ((150 - i) / 150) + progress * 15) % size.height;
      canvas.drawCircle(Offset(dx, dy), 0.7, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
