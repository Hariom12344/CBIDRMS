class PaymentModel {
  final String id;
  final String invoiceId;
  final double amount;
  final String date;
  final String method; // CASH, BANK_TRANSFER, CHEQUE, UPI, OTHER
  final String? note;

  PaymentModel({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.date,
    this.method = 'BANK_TRANSFER',
    this.note,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id']?.toString() ?? '',
      invoiceId: json['invoiceId']?.toString() ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      date: json['date'] ?? '',
      method: json['method'] ?? 'BANK_TRANSFER',
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'amount': amount,
      'date': date,
      'method': method,
      'note': note,
    };
  }
}

class InvoiceModel {
  final String id;
  final String projectId;
  final String clientName;
  final double amount;
  final double pendingAmount;
  final String dueDate;
  final String status; // PAID, PENDING, OVERDUE
  final List<PaymentModel> payments;

  InvoiceModel({
    required this.id,
    this.projectId = '',
    required this.clientName,
    required this.amount,
    required this.pendingAmount,
    required this.dueDate,
    required this.status,
    this.payments = const [],
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final rawPayments = json['payments'] as List? ?? [];
    final paymentsList = rawPayments.map((p) => PaymentModel.fromJson(p as Map<String, dynamic>)).toList();

    return InvoiceModel(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      clientName: json['clientName'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      pendingAmount: json['pendingAmount'] != null ? (json['pendingAmount'] as num).toDouble() : (json['amount'] ?? 0.0).toDouble(),
      dueDate: json['dueDate'] ?? '',
      status: json['status'] ?? 'PENDING',
      payments: paymentsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'clientName': clientName,
      'amount': amount,
      'pendingAmount': pendingAmount,
      'dueDate': dueDate,
      'status': status,
      'payments': payments.map((p) => p.toJson()).toList(),
    };
  }
}

class ExpenseModel {
  final String id;
  final String projectId;
  final String category; // MATERIAL, LABOR, VENDOR_PAYMENT, OTHER
  final double amount;
  final String date;
  final String? note;
  final int? recordedBy;

  ExpenseModel({
    required this.id,
    required this.projectId,
    required this.category,
    required this.amount,
    required this.date,
    this.note,
    this.recordedBy,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      category: json['category'] ?? 'OTHER',
      amount: (json['amount'] ?? 0.0).toDouble(),
      date: json['date'] ?? '',
      note: json['note'],
      recordedBy: json['recordedBy'] is int ? json['recordedBy'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'category': category,
      'amount': amount,
      'date': date,
      'note': note,
      'recordedBy': recordedBy,
    };
  }
}

class ProjectBudgetModel {
  final String projectId;
  final double? budget;
  final double spent;
  final double? remaining;

  ProjectBudgetModel({
    required this.projectId,
    this.budget,
    required this.spent,
    this.remaining,
  });

  factory ProjectBudgetModel.fromJson(Map<String, dynamic> json) {
    return ProjectBudgetModel(
      projectId: json['projectId']?.toString() ?? '',
      budget: json['budget'] != null ? (json['budget'] as num).toDouble() : null,
      spent: (json['spent'] ?? 0.0).toDouble(),
      remaining: json['remaining'] != null ? (json['remaining'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'budget': budget,
      'spent': spent,
      'remaining': remaining,
    };
  }
}
