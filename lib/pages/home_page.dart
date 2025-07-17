import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db_helper.dart';
import '../models/user.dart';
import 'add_entry_page.dart';
import 'full_history_page.dart';
import 'users_page.dart';
import 'user_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  List<User> _users = [];
  Map<int, double> _balances = {};
  Map<int, String> _lastDescriptions = {};
  Map<int, DateTime> _lastDates = {};
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
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

      final net = txns.fold(
        0.0,
        (sum, txn) => sum + (txn.isPayment ? -txn.amount : txn.amount),
      );

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

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Home',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UsersPage()),
              );
            },
          ),
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

          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 120),
            children: [
              const Text(
                'Net Balance',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, letterSpacing: 1),
              ),
              ShaderMask(
                shaderCallback: (Rect bounds) {
                  return (netBalance < 0
                          ? const LinearGradient(
                              colors: [
                                Color.fromARGB(255, 255, 141, 211),
                                Color.fromARGB(255, 255, 0, 0),
                                Color.fromARGB(255, 254, 166, 102),
                              ],
                            )
                          : const LinearGradient(
                              colors: [
                                Color.fromARGB(255, 0, 251, 4),
                                Color.fromARGB(255, 139, 250, 231),
                                Color.fromARGB(255, 131, 114, 244),
                              ],
                            ))
                      .createShader(bounds);
                },
                child: Text(
                  '₹${netBalance.toStringAsFixed(2)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _trendBox(
                    '+₹${_balances.values.where((v) => v > 0).fold(0.0, (a, b) => a + b).toStringAsFixed(0)}',
                    Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _trendBox(
                    '-₹${_balances.values.where((v) => v < 0).fold(0.0, (a, b) => a + b).abs().toStringAsFixed(0)}',
                    Colors.red,
                  ),
                ],
              ),
              const SizedBox(width: 24, height: 30), // Horizontal space
              _sectionTitle('what you owe', Colors.red),
              ...owe.map((u) => _debtCard(u, _balances[u.id!]!)),
              _sectionTitle("what you're owed", Colors.green),
              ...owed.map((u) => _debtCard(u, _balances[u.id!]!)),
            ],
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _gradientButton(
            icon: Icons.history,
            colors: [
              Color.fromARGB(255, 242, 137, 72),
              Color.fromARGB(255, 188, 27, 27),
            ],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FullHistoryPage()),
            ),
          ),
          const SizedBox(height: 12),
          _gradientButton(
            icon: Icons.add,
            colors: [
              Color.fromARGB(255, 8, 178, 144),
              Color.fromARGB(255, 37, 235, 57),
            ],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEntryPage()),
            ).then((_) => _loadData()),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, Color underlineColor) {
    return Container(
      margin: const EdgeInsets.only(top: 30),

      // margin: const EdgeInsets.only(top: 20)
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,

        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 1,
            width: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [underlineColor, underlineColor.withOpacity(0.2)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _debtCard(User user, double amount) {
    final isOwed = amount > 0;
    final labelColor = isOwed
        ? const Color.fromARGB(255, 70, 220, 97)
        : const Color.fromARGB(255, 252, 68, 68);
    final description = _lastDescriptions[user.id!] ?? '';
    final date = _lastDates[user.id!];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UserPage(user: user)),
      ).then((_) => _loadData()),
      child: Container(
        // margin: const EdgeInsets.symmetric(vertical: 4),
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isOwed
                ? [
                    Color.fromRGBO(0, 0, 0, 0.098),
                    Color.fromRGBO(0, 0, 0, 0.047),
                    Color.fromRGBO(0, 0, 0, 0.098),
                  ]
                : [
                    Color.fromRGBO(0, 0, 0, 0.098),
                    Color.fromRGBO(0, 0, 0, 0.047),
                    Color.fromRGBO(0, 0, 0, 0.098),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isOwed
                ? Color.fromRGBO(16, 185, 129, 0.2)
                : Color.fromRGBO(255, 0, 0, 0.2),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Amount + Date
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${amount.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    color: labelColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),
                if (date != null)
                  Text(
                    DateFormat('dd MMM yyyy').format(date),
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
              ],
            ),
            // Middle: Description centered
            Expanded(
              child: Center(
                child: Text(
                  description,
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

            const SizedBox(width: 0),

            // Right: User Name
            Text(
              user.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trendBox(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _gradientButton({
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: colors),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.4),
              blurRadius: 25,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white),
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
