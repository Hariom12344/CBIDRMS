class CompanyModel {
  final String name;
  final String? logoUrl;
  final String address;
  final String phone;
  final String? email;
  final String? gstin;
  final String? pan;

  CompanyModel({
    required this.name,
    this.logoUrl,
    required this.address,
    required this.phone,
    this.email,
    this.gstin,
    this.pan,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      name: json['companyName'] ?? json['name'] ?? 'TechSolutions & Trade Private Limited',
      logoUrl: json['companyLogoUrl'] ?? json['logoUrl'],
      address: json['companyAddress'] ?? json['address'] ?? 'Plot No. 42, Tech Park Phase 2, Hinjewadi, Pune, Maharashtra 411057',
      phone: json['companyPhone'] ?? json['phone'] ?? '+91 90116 94002',
      email: json['companyEmail'] ?? json['email'] ?? 'contact@techsolutions.com',
      gstin: json['companyGstin'] ?? json['gstin'] ?? '27AAACT1234F1Z5',
      pan: json['pan'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyName': name,
      'companyLogoUrl': logoUrl,
      'companyAddress': address,
      'companyPhone': phone,
      'companyEmail': email,
      'companyGstin': gstin,
      'pan': pan,
    };
  }
}
