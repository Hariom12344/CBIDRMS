class SiteUpdateModel {
  final String id;
  final String projectName;
  final String supervisorName;
  final String updateDate;
  final String description;
  final String issueReported;
  final bool photosAttached;

  SiteUpdateModel({
    required this.id,
    required this.projectName,
    required this.supervisorName,
    required this.updateDate,
    required this.description,
    required this.issueReported,
    this.photosAttached = true,
  });
}
