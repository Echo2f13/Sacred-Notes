import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../models/user.dart';
import 'user_page.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage>
    with SingleTickerProviderStateMixin {
  List<User> _allUsers = [];
  List<User> _filteredUsers = [];
  late AnimationController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final db = DBHelper.instance;
    final users = await db.getUsers();
    setState(() {
      _allUsers = users;
      _filteredUsers = users;
    });
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers
          .where((user) => user.name.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _createUser() async {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color.fromARGB(255, 18, 18, 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color.fromRGBO(18, 18, 18, 1),
                Color.fromRGBO(30, 30, 30, 1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add New User',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mobileController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Mobile',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white70),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      backgroundColor: const Color.fromARGB(255, 42, 161, 131),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final mobile = mobileController.text.trim();
                      if (name.isNotEmpty) {
                        final db = DBHelper.instance;
                        await db.insertUser(User(name: name, mobile: mobile));
                        await _loadUsers();
                        Navigator.pop(context);
                      }
                    },
                    child: const Text(
                      'Create',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
        title: const Text(
          'All Users',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                  builder: (_, __) => CustomPaint(
                    size: MediaQuery.of(context).size,
                    painter: _StarfieldPainter(_controller.value),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 110),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => UserPage(user: user)),
                      ).then((_) => _loadUsers()),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromRGBO(255, 255, 255, 0.03),
                              Color.fromRGBO(255, 255, 255, 0.015),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: Colors.white10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: GestureDetector(
        onTap: _createUser,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color.fromARGB(255, 0, 251, 255),
                Color.fromARGB(255, 120, 100, 255),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white),
        ),
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
