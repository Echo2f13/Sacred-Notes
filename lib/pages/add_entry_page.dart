import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db_helper.dart';
import '../models/user.dart';
import '../models/transaction_record.dart';

class AddEntryPage extends StatefulWidget {
  const AddEntryPage({super.key});

  @override
  State<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends State<AddEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final DBHelper db = DBHelper.instance;

  List<User> _users = [];
  User? _selectedUser;
  bool _isPayment = false;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await db.getUsers();
    setState(() {
      _users = users;
      _selectedUser = users.isNotEmpty ? users.first : null;
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate() && _selectedUser != null) {
      final txn = TransactionRecord(
        userId: _selectedUser!.id!,
        amount: double.parse(_amountController.text),
        isPayment: _isPayment,
        description: _descController.text.trim(),
        date: _selectedDate,
      );

      await db.insertTransaction(txn);
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Entry")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
          ? const Center(child: Text("No users found. Add a user first."))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    DropdownButtonFormField<User>(
                      value: _selectedUser,
                      items: _users
                          .map(
                            (u) => DropdownMenuItem(
                              value: u,
                              child: Text('${u.name} (${u.mobile})'),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _selectedUser = val),
                      decoration: const InputDecoration(
                        labelText: "Select User",
                      ),
                      validator: (val) => val == null ? 'Select a user' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: "Amount (₹)",
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty)
                          return "Enter amount";
                        if (double.tryParse(val) == null)
                          return "Invalid number";
                        return null;
                      },
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
                      decoration: const InputDecoration(
                        labelText: "Description",
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? "Enter description"
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Date: ${DateFormat.yMMMd().format(_selectedDate)}",
                        ),
                        TextButton(
                          onPressed: _pickDate,
                          child: const Text("Pick Date"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("Save"),
                      onPressed: _saveTransaction,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
