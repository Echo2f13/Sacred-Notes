class User {
  final int? id;
  final String name;
  final String mobile;

  User({this.id, required this.name, required this.mobile});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'mobile': mobile};

  factory User.fromMap(Map<String, dynamic> map) =>
      User(id: map['id'], name: map['name'], mobile: map['mobile']);
}
