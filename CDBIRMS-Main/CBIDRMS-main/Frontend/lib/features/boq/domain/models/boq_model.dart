class BoqItemModel {
  final String? id;
  final String itemName;
  final String unit;
  final double quantity;
  final double unitPrice;
  double get totalAmount => quantity * unitPrice;

  BoqItemModel({
    this.id,
    required this.itemName,
    this.unit = 'nos',
    required this.quantity,
    required this.unitPrice,
  });

  factory BoqItemModel.fromJson(Map<String, dynamic> json) {
    return BoqItemModel(
      id: json['id']?.toString(),
      itemName: json['itemName']?.toString() ?? '',
      unit: json['unit']?.toString() ?? 'nos',
      quantity: (json['quantity'] is num) ? (json['quantity'] as num).toDouble() : 1.0,
      unitPrice: (json['unitPrice'] is num) ? (json['unitPrice'] as num).toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'itemName': itemName,
      'unit': unit,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
    };
  }
}

class BoqModel {
  final String id;
  final String projectId;
  final String projectName;
  final List<BoqItemModel> items;
  final double totalCost;
  final String createdAt;

  BoqModel({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.items,
    required this.totalCost,
    required this.createdAt,
  });

  factory BoqModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    final parsedItems = rawItems.map((i) => BoqItemModel.fromJson(i as Map<String, dynamic>)).toList();
    final computedCost = (json['totalCost'] is num)
        ? (json['totalCost'] as num).toDouble()
        : parsedItems.fold(0.0, (sum, item) => sum + item.totalAmount);

    return BoqModel(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      projectName: json['projectName']?.toString() ?? 'Project',
      items: parsedItems,
      totalCost: computedCost,
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}
