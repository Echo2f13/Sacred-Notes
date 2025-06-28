class TransactionRecord {
  final int? id;
  final int userId;
  final double amount;
  final bool isPayment;
  final String description;
  final DateTime date;
  final int? categoryId;

  TransactionRecord({
    this.id,
    required this.userId,
    required this.amount,
    required this.isPayment,
    required this.description,
    required this.date,
    this.categoryId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'amount': amount,
        'is_payment': isPayment ? 1 : 0,
        'description': description,
        'date': date.toIso8601String(),
        'category_id': categoryId,
      };

  factory TransactionRecord.fromMap(Map<String, dynamic> m) =>
      TransactionRecord(
        id: m['id'],
        userId: m['user_id'],
        amount: m['amount'],
        isPayment: m['is_payment'] == 1,
        description: m['description'],
        date: DateTime.parse(m['date']),
        categoryId: m['category_id'],
      );
}
