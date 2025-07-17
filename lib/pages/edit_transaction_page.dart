import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_record.dart';
import '../db_helper.dart';

class EditTransactionPage extends StatefulWidget {
  final TransactionRecord transaction;

  const EditTransactionPage({super.key, required this.transaction});

  @override
  State<EditTransactionPage> createState() => _EditTransactionPageState();
}

class _EditTransactionPageState extends State<EditTransactionPage>
    with SingleTickerProviderStateMixin {
  late TextEditingController _amountController;
  late TextEditingController _descController;
  late DateTime _selectedDate;
  late bool _isPayment;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final txn = widget.transaction;
    _amountController = TextEditingController(text: txn.amount.toString());
    _descController = TextEditingController(text: txn.description);
    _selectedDate = txn.date;
    _isPayment = txn.isPayment;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _updateTransaction() async {
    final amount = double.tryParse(_amountController.text.trim());
    final desc = _descController.text.trim();

    if (amount == null || amount <= 0 || desc.isEmpty) return;

    final updatedTxn = TransactionRecord(
      id: widget.transaction.id,
      userId: widget.transaction.userId,
      amount: amount,
      isPayment: _isPayment,
      description: desc,
      date: _selectedDate,
    );

    final db = DBHelper.instance;
    final database = await db.database;

    await database.update(
      'transactions',
      updatedTxn.toMap(),
      where: 'id = ?',
      whereArgs: [updatedTxn.id],
    );

    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _deleteTransaction() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Delete Transaction",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Are you sure you want to delete this transaction?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = DBHelper.instance;
      final database = await db.database;

      await database.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [widget.transaction.id],
      );

      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Edit Transaction"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromRGBO(0, 49, 80, 0.25),
                        Colors.black,
                        Color.fromRGBO(46, 0, 65, 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 120, 16, 16),
            child: ListView(
              children: [
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Amount (₹)",
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "You Owe",
                      style: TextStyle(color: Colors.white70),
                    ),
                    Switch(
                      value: !_isPayment,
                      activeColor: Colors.greenAccent,
                      inactiveThumbColor: Colors.redAccent,
                      inactiveTrackColor: Colors.red[200],
                      onChanged: (val) => setState(() => _isPayment = !val),
                    ),
                    const Text(
                      "Owe You",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Description",
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Date: ${DateFormat.yMMMd().format(_selectedDate)}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    TextButton(
                      onPressed: _pickDate,
                      child: const Text("Pick Date"),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("Update"),
                  onPressed: _updateTransaction,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text("Delete"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: _deleteTransaction,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
