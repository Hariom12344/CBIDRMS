class DesignModel {
  final String id;
  final String title;
  final String projectName;
  final String version;
  final String approvalStatus; // Pending, Approved, Revision Needed
  final String uploadedBy;
  final String date;

  DesignModel({
    required this.id,
    required this.title,
    required this.projectName,
    required this.version,
    required this.approvalStatus,
    required this.uploadedBy,
    required this.date,
  });
}
