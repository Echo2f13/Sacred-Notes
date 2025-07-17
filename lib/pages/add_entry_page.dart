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

class _AddEntryPageState extends State<AddEntryPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final DBHelper db = DBHelper.instance;

  List<User> _users = [];
  User? _selectedUser;
  bool _isPayment = false;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  bool _loading = true;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _loadUsers();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          "Add Entry",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromRGBO(0, 49, 80, 0.247),
                    Colors.black,
                    Color.fromRGBO(46, 0, 65, 0.102),
                  ],
                ),
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
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
              ? const Center(
                  child: Text(
                    "No users found. Add a user first.",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        DropdownButtonFormField<User>(
                          value: _selectedUser,
                          dropdownColor: Colors.grey[900],
                          style: const TextStyle(color: Colors.white),
                          items: _users
                              .map(
                                (u) => DropdownMenuItem(
                                  value: u,
                                  child: Text(
                                    '${u.name} (${u.mobile})',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedUser = val),
                          decoration: const InputDecoration(
                            labelText: "Select User",
                            labelStyle: TextStyle(color: Colors.white60),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            ),
                          ),
                          validator: (val) =>
                              val == null ? 'Select a user' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: "Amount (₹)",
                            labelStyle: TextStyle(color: Colors.white60),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return "Enter amount";
                            }
                            if (double.tryParse(val) == null) {
                              return "Invalid number";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "You Owe",
                              style: TextStyle(
                                color: !_isPayment
                                    ? Colors.white38
                                    : Colors.redAccent,
                                fontWeight: _isPayment
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            Switch(
                              activeColor: Colors.greenAccent,
                              inactiveThumbColor: Colors.redAccent,
                              inactiveTrackColor: Colors.red.withOpacity(0.5),
                              value: !_isPayment,
                              onChanged: (val) =>
                                  setState(() => _isPayment = !val),
                            ),
                            Text(
                              "Owe You",
                              style: TextStyle(
                                color: !_isPayment
                                    ? Colors.greenAccent
                                    : Colors.white38,
                                fontWeight: _isPayment
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: "Description",
                            labelStyle: TextStyle(color: Colors.white60),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            ),
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
                              style: const TextStyle(color: Colors.white70),
                            ),
                            TextButton(
                              onPressed: _pickDate,
                              child: const Text("Pick Date"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          label: const Text("Save"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              37,
                              235,
                              57,
                            ),
                            foregroundColor: Colors.black,
                          ),
                          onPressed: _saveTransaction,
                        ),
                      ],
                    ),
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
