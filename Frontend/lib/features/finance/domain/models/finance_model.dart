class InvoiceModel {
  final String id;
  final String clientName;
  final double amount;
  final String dueDate;
  final String status; // PAID, PENDING, OVERDUE

  InvoiceModel({
    required this.id,
    required this.clientName,
    required this.amount,
    required this.dueDate,
    required this.status,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id']?.toString() ?? '',
      clientName: json['clientName'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      dueDate: json['dueDate'] ?? '',
      status: json['status'] ?? 'PENDING',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientName': clientName,
      'amount': amount,
      'dueDate': dueDate,
      'status': status,
    };
  }
}
