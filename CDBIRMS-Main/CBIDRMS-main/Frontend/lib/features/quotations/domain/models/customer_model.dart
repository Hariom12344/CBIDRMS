class CustomerPartyModel {
  final String name;
  final String address;
  final String? gstin;
  final String? contactPerson;
  final String? mobile;

  CustomerPartyModel({
    required this.name,
    required this.address,
    this.gstin,
    this.contactPerson,
    this.mobile,
  });

  factory CustomerPartyModel.fromJsonConsignee(Map<String, dynamic> json) {
    return CustomerPartyModel(
      name: json['consigneeName'] ?? '',
      address: json['consigneeAddress'] ?? '',
      gstin: json['consigneeGstin'],
      contactPerson: json['consigneeContact'],
      mobile: json['consigneeMobile'],
    );
  }

  factory CustomerPartyModel.fromJsonBuyer(Map<String, dynamic> json) {
    return CustomerPartyModel(
      name: json['buyerName'] ?? '',
      address: json['buyerAddress'] ?? '',
      gstin: json['buyerGstin'],
      contactPerson: json['buyerContact'],
      mobile: json['buyerMobile'],
    );
  }

  Map<String, dynamic> toConsigneeJson() {
    return {
      'consigneeName': name,
      'consigneeAddress': address,
      'consigneeGstin': gstin,
      'consigneeContact': contactPerson,
      'consigneeMobile': mobile,
    };
  }

  Map<String, dynamic> toBuyerJson() {
    return {
      'buyerName': name,
      'buyerAddress': address,
      'buyerGstin': gstin,
      'buyerContact': contactPerson,
      'buyerMobile': mobile,
    };
  }
}
