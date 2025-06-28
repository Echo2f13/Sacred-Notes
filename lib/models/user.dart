class User {
  final int? id;
  final String name;
  final String mobile;

  User({this.id, required this.name, required this.mobile});

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'mobile': mobile,
      };

  factory User.fromMap(Map<String, dynamic> m) => User(
        id: m['id'],
        name: m['name'],
        mobile: m['mobile'],
      );
}
