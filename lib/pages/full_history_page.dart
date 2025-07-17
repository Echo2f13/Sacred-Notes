// full_history_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db_helper.dart';
import '../models/user.dart';
import '../models/transaction_record.dart';
import 'user_page.dart';

class FullHistoryPage extends StatefulWidget {
  const FullHistoryPage({super.key});

  @override
  State<FullHistoryPage> createState() => _FullHistoryPageState();
}

class _FullHistoryPageState extends State<FullHistoryPage>
    with SingleTickerProviderStateMixin {
  final DBHelper db = DBHelper.instance;
  final TextEditingController _searchController = TextEditingController();

  List<TransactionRecord> _allTxns = [];
  Map<int, User> _userMap = {};
  bool _loading = true;
  String _search = "";

  DateTime? _fromDate;
  DateTime? _toDate;
  double? _minAmount;
  double? _maxAmount;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final users = await db.getUsers();
    final Map<int, User> uMap = {for (var u in users) u.id!: u};

    final List<TransactionRecord> txns = [];
    for (final user in users) {
      final uTxns = await db.getTransactions(user.id!);
      txns.addAll(uTxns);
    }

    txns.sort((a, b) => b.date.compareTo(a.date));

    setState(() {
      _userMap = uMap;
      _allTxns = txns;
      _loading = false;
    });
  }

  Future<void> _showFilterDialog() async {
    double sliderMin = 0;
    double sliderMax = 3000;
    RangeValues selectedRange = RangeValues(
      _minAmount ?? sliderMin,
      _maxAmount ?? sliderMax,
    );

    DateTime? localFrom = _fromDate;
    DateTime? localTo = _toDate;

    bool didApply = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              "Filter Transactions",
              style: TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "₹${selectedRange.start.toStringAsFixed(0)} – ₹${selectedRange.end >= sliderMax ? "${sliderMax.toInt()}+" : selectedRange.end.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  RangeSlider(
                    values: selectedRange,
                    min: sliderMin,
                    max: sliderMax,
                    divisions: 60,
                    labels: RangeLabels(
                      "₹${selectedRange.start.toStringAsFixed(0)}",
                      "₹${selectedRange.end.toStringAsFixed(0)}",
                    ),
                    onChanged: (range) {
                      setDialogState(() {
                        selectedRange = range;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        "From:",
                        style: TextStyle(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: localFrom ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => localFrom = picked);
                          }
                        },
                        child: Text(
                          localFrom != null
                              ? DateFormat('d MMM y').format(localFrom!)
                              : 'Any',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        "To:",
                        style: TextStyle(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: localTo ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => localTo = picked);
                          }
                        },
                        child: Text(
                          localTo != null
                              ? DateFormat('d MMM y').format(localTo!)
                              : 'Any',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  didApply = true;
                  _fromDate = null;
                  _toDate = null;
                  _minAmount = null;
                  _maxAmount = null;
                  Navigator.pop(context);
                },
                child: const Text(
                  "Clear",
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  didApply = true;
                  _fromDate = localFrom;
                  _toDate = localTo;
                  _minAmount = selectedRange.start;
                  _maxAmount = selectedRange.end;
                  Navigator.pop(context);
                },
                child: const Text("Apply"),
              ),
            ],
          ),
        );
      },
    );

    if (didApply && mounted) setState(() {});
  }

  List<TransactionRecord> _applyFilters(List<TransactionRecord> txns) {
    return txns.where((txn) {
      final amt = txn.amount;
      final date = txn.date;

      final matchesAmount =
          (_minAmount == null || amt >= _minAmount!) &&
          (_maxAmount == null || amt <= _maxAmount!);

      final matchesDate =
          (_fromDate == null || !date.isBefore(_fromDate!)) &&
          (_toDate == null || !date.isAfter(_toDate!));

      return matchesAmount && matchesDate;
    }).toList();
  }

  Map<String, List<TransactionRecord>> _groupByDate(
    List<TransactionRecord> txns,
  ) {
    final Map<String, List<TransactionRecord>> grouped = {};
    for (final txn in txns) {
      final dateStr = DateFormat('d MMMM yyyy').format(txn.date);
      grouped.putIfAbsent(dateStr, () => []).add(txn);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final filteredTxns = _allTxns.where((txn) {
      final user = _userMap[txn.userId];
      if (user == null) return false;
      final query = _search.toLowerCase();
      return user.name.toLowerCase().contains(query) ||
          txn.description.toLowerCase().contains(query);
    }).toList();

    final filteredAndFiltered = _applyFilters(filteredTxns);
    final grouped = _groupByDate(filteredAndFiltered);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("History"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _search = val),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "search",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white54,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _showFilterDialog,
                  icon: const Icon(Icons.filter_list),
                  label: const Text("Filter"),
                ),
              ],
            ),
          ),
        ),
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
                        Color.fromRGBO(0, 49, 80, 0.247),
                        Colors.black,
                        Color.fromRGBO(46, 0, 65, 0.102),
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
              : grouped.isEmpty
              ? const Center(
                  child: Text(
                    "No transactions found",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: grouped.entries.map((entry) {
                    final dateLabel = entry.key;
                    final txns = entry.value;
                    final total = txns.fold<double>(
                      0.0,
                      (sum, txn) =>
                          sum + (txn.isPayment ? -txn.amount : txn.amount),
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dateLabel,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "₹${total.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...txns.map((txn) {
                          final user = _userMap[txn.userId];
                          final label = txn.isPayment
                              ? "₹${txn.amount.toStringAsFixed(2)}"
                              : "₹${txn.amount.toStringAsFixed(2)}";

                          return GestureDetector(
                            onTap: () {
                              if (user != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UserPage(user: user),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(0.08),
                                    Colors.black.withOpacity(0.04),
                                    Colors.black.withOpacity(0.08),
                                  ],
                                ),
                                border: Border.all(
                                  color: txn.isPayment
                                      ? const Color.fromRGBO(255, 0, 0, 0.2)
                                      : const Color.fromRGBO(16, 185, 129, 0.2),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        label,
                                        style: TextStyle(
                                          color: txn.isPayment
                                              ? Colors.redAccent
                                              : Colors.greenAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        DateFormat(
                                          'dd MMM yyyy',
                                        ).format(txn.date),
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      txn.description,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    user?.name ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  }).toList(),
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
