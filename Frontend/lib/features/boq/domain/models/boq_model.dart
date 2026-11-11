class BoqItemModel {
  final String itemName;
  final int quantity;
  final double unitPrice;
  double get totalAmount => quantity * unitPrice;

  BoqItemModel({
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
  });

  factory BoqItemModel.fromJson(Map<String, dynamic> json) {
    return BoqItemModel(
      itemName: json['itemName'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unitPrice'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
    };
  }
}

class BoqModel {
  final String id;
  final String projectName;
  final List<BoqItemModel> items;
  final String createdAt;

  double get totalCost => items.fold(0.0, (sum, item) => sum + item.totalAmount);

  BoqModel({
    required this.id,
    required this.projectName,
    required this.items,
    required this.createdAt,
  });

  factory BoqModel.fromJson(Map<String, dynamic> json) {
    return BoqModel(
      id: json['id']?.toString() ?? '',
      projectName: json['projectName'] ?? '',
      items: (json['items'] as List? ?? []).map((i) => BoqItemModel.fromJson(i)).toList(),
      createdAt: json['createdAt'] ?? '',
    );
  }
}
