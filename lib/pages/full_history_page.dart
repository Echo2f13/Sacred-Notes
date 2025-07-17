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

class _FullHistoryPageState extends State<FullHistoryPage> {
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

  @override
  void initState() {
    super.initState();
    _loadHistory();
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
            title: const Text("Filter Transactions"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "₹${selectedRange.start.toStringAsFixed(0)} – ₹${selectedRange.end >= sliderMax ? "${sliderMax.toInt()}+" : selectedRange.end.toStringAsFixed(0)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                      const Text("From: "),
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
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text("To: "),
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
                child: const Text("Clear"),
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

    if (didApply && mounted) {
      setState(() {}); // Force rebuild to apply filters
    }
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
      appBar: AppBar(
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
                    decoration: InputDecoration(
                      hintText: "search",
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.search),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _showFilterDialog,
                  child: const Text("filter"),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : grouped.isEmpty
          ? const Center(child: Text("No transactions found"))
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "₹${total.toStringAsFixed(0)}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    ...txns.map((txn) {
                      final user = _userMap[txn.userId];
                      final label = txn.isPayment
                          ? "You Owe ₹${txn.amount.toStringAsFixed(2)}"
                          : "Owe You ₹${txn.amount.toStringAsFixed(2)}";

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: Colors.grey[800],
                        child: ListTile(
                          title: Text(label),
                          subtitle: Text(txn.description),
                          trailing: Text(user?.name ?? 'user'),
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
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
    );
  }
}
