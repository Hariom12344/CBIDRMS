class QuotationItemModel {
  String? id;
  int srNo;
  String description;
  String? hsnSac;
  double quantity;
  String uom;
  double rate;
  double discountPercent;
  double discountAmount;
  double amount;

  QuotationItemModel({
    this.id,
    required this.srNo,
    required this.description,
    this.hsnSac,
    required this.quantity,
    this.uom = 'NOS',
    required this.rate,
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
    required this.amount,
  });

  void recalculateAmount() {
    double raw = quantity * rate;
    if (discountPercent > 0) {
      discountAmount = raw * (discountPercent / 100);
    }
    amount = (raw - discountAmount).clamp(0.0, double.infinity);
  }

  factory QuotationItemModel.fromJson(Map<String, dynamic> json) {
    return QuotationItemModel(
      id: json['id'],
      srNo: (json['srNo'] as num?)?.toInt() ?? 1,
      description: json['description'] ?? '',
      hsnSac: json['hsnSac'],
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      uom: json['uom'] ?? 'NOS',
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'srNo': srNo,
      'description': description,
      'hsnSac': hsnSac,
      'quantity': quantity,
      'uom': uom,
      'rate': rate,
      'discountPercent': discountPercent,
      'discountAmount': discountAmount,
      'amount': amount,
    };
  }
}
