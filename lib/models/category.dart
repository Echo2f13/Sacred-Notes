class Category {
  final int? id;
  final String name;
  final String type; // 'income' or 'expense'

  Category({this.id, required this.name, required this.type});

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
      };

  factory Category.fromMap(Map<String, dynamic> m) => Category(
        id: m['id'],
        name: m['name'],
        type: m['type'],
      );
}
