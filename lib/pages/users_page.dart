import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../models/user.dart';
import 'user_page.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final DBHelper db = DBHelper.instance;
  final TextEditingController _searchController = TextEditingController();

  List<User> _allUsers = [];
  List<User> _filteredUsers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadUsers() async {
    final users = await db.getUsers();
    setState(() {
      _allUsers = users;
      _filteredUsers = users;
      _loading = false;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        return user.name.toLowerCase().contains(query) ||
            user.mobile.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _showAddUserDialog() async {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add New User"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: mobileController,
              decoration: const InputDecoration(labelText: "Mobile"),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Add"),
            onPressed: () async {
              final name = nameController.text.trim();
              final mobile = mobileController.text.trim();
              if (name.isNotEmpty) {
                await db.insertUser(User(name: name, mobile: mobile));
                Navigator.pop(context);
                _loadUsers();
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Users")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search users",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredUsers.isEmpty
                      ? const Center(child: Text("No users found"))
                      : ListView.builder(
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            return ListTile(
                              title: Text(user.name),
                              subtitle: Text(user.mobile),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UserPage(user: user),
                                  ),
                                ).then((_) => _loadUsers());
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: const Icon(Icons.add),
        tooltip: 'Add User',
      ),
    );
  }
}
