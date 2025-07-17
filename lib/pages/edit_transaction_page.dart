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

class _EditTransactionPageState extends State<EditTransactionPage> {
  late TextEditingController _amountController;
  late TextEditingController _descController;
  late DateTime _selectedDate;
  late bool _isPayment;

  @override
  void initState() {
    super.initState();
    final txn = widget.transaction;
    _amountController = TextEditingController(text: txn.amount.toString());
    _descController = TextEditingController(text: txn.description);
    _selectedDate = txn.date;
    _isPayment = txn.isPayment;
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
        title: const Text("Delete Transaction"),
        content: const Text(
          "Are you sure you want to delete this transaction?",
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
      appBar: AppBar(title: const Text("Edit Transaction")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: "Amount (₹)"),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("You Owe"),
                Switch(
                  value: !_isPayment,
                  onChanged: (val) => setState(() => _isPayment = !val),
                ),
                const Text("Owe You"),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Date: ${DateFormat.yMMMd().format(_selectedDate)}"),
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
    );
  }
}
