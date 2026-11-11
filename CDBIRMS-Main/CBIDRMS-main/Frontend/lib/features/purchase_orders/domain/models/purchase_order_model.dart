class PoItemModel {
  final String? id;
  final String itemName;
  final String unit;
  final double quantity;
  final double unitPrice;
  double get totalAmount => quantity * unitPrice;

  PoItemModel({
    this.id,
    required this.itemName,
    this.unit = 'nos',
    required this.quantity,
    required this.unitPrice,
  });

  factory PoItemModel.fromJson(Map<String, dynamic> json) {
    return PoItemModel(
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

class PurchaseOrderModel {
  final String id;
  final int? vendorId;
  final String vendorName;
  final String projectId;
  final String projectName;
  final String? boqId;
  final List<PoItemModel> items;
  final double totalAmount;
  final String status; // Draft, Approved, Ordered, Delivered, Cancelled
  final String date;
  final String? createdAt;

  PurchaseOrderModel({
    required this.id,
    this.vendorId,
    required this.vendorName,
    required this.projectId,
    required this.projectName,
    this.boqId,
    this.items = const [],
    required this.totalAmount,
    required this.status,
    required this.date,
    this.createdAt,
  });

  factory PurchaseOrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    final parsedItems = rawItems.map((i) => PoItemModel.fromJson(i as Map<String, dynamic>)).toList();

    final vendorMap = json['vendor'] is Map ? json['vendor'] as Map<String, dynamic> : {};
    final projectMap = json['project'] is Map ? json['project'] as Map<String, dynamic> : {};

    final vName = json['vendorName']?.toString() ?? vendorMap['companyName']?.toString() ?? 'Vendor';
    final pName = json['projectName']?.toString() ?? projectMap['name']?.toString() ?? 'Project';

    final computedTotal = (json['totalAmount'] is num)
        ? (json['totalAmount'] as num).toDouble()
        : parsedItems.fold(0.0, (sum, item) => sum + item.totalAmount);

    return PurchaseOrderModel(
      id: json['id']?.toString() ?? '',
      vendorId: json['vendorId'] is int ? json['vendorId'] : int.tryParse(json['vendorId']?.toString() ?? ''),
      vendorName: vName,
      projectId: json['projectId']?.toString() ?? '',
      projectName: pName,
      boqId: json['boqId']?.toString(),
      items: parsedItems,
      totalAmount: computedTotal,
      status: json['status']?.toString() ?? 'Draft',
      date: json['date']?.toString() ?? '',
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (vendorId != null) 'vendorId': vendorId,
      'vendorName': vendorName,
      'projectId': projectId,
      'projectName': projectName,
      if (boqId != null) 'boqId': boqId,
      'items': items.map((i) => i.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'date': date,
    };
  }
}
