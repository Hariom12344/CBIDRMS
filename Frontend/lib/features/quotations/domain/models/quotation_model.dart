class QuotationModel {
  final String id;
  final String clientName;
  final String projectName;
  final double totalAmount;
  final String date;
  final String status; // Sent, Approved, Converted to Project

  QuotationModel({
    required this.id,
    required this.clientName,
    required this.projectName,
    required this.totalAmount,
    required this.date,
    required this.status,
  });
}
