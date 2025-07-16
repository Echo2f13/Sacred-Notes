class TransactionRecord {
  final int? id;
  final int userId;
  final double amount;
  final bool isPayment;
  final String description;
  final DateTime date;

  TransactionRecord({
    this.id,
    required this.userId,
    required this.amount,
    required this.isPayment,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'amount': amount,
    'is_payment': isPayment ? 1 : 0,
    'description': description,
    'date': date.toIso8601String(),
  };

  factory TransactionRecord.fromMap(Map<String, dynamic> map) =>
      TransactionRecord(
        id: map['id'],
        userId: map['user_id'],
        amount: map['amount'],
        isPayment: map['is_payment'] == 1,
        description: map['description'],
        date: DateTime.parse(map['date']),
      );
}
