class VendorModel {
  final String id;
  final String companyName;
  final String contactPerson;
  final String email;
  final String phone;
  final List<String> materialsSupplied;

  VendorModel({
    required this.id,
    required this.companyName,
    required this.contactPerson,
    required this.email,
    required this.phone,
    required this.materialsSupplied,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      id: json['id']?.toString() ?? '',
      companyName: json['companyName'] ?? '',
      contactPerson: json['contactPerson'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      materialsSupplied: List<String>.from(json['materialsSupplied'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyName': companyName,
      'contactPerson': contactPerson,
      'email': email,
      'phone': phone,
      'materialsSupplied': materialsSupplied,
    };
  }
}
