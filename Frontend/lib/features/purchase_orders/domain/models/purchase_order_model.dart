class PurchaseOrderModel {
  final String id;
  final String vendorName;
  final String projectName;
  final double totalAmount;
  final String status; // Draft, Approved, Ordered, Delivered, Cancelled
  final String date;

  PurchaseOrderModel({
    required this.id,
    required this.vendorName,
    required this.projectName,
    required this.totalAmount,
    required this.status,
    required this.date,
  });
}
