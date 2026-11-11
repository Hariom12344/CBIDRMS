import 'company_model.dart';
import 'customer_model.dart';
import 'quotation_item_model.dart';

class QuotationModel {
  final String id;
  final String quotationNumber;
  final int revisionNumber;
  final String? rootQuotationId;
  final String date;
  final String validTill;
  final String? refNumber;
  final String? termsOfDelivery;

  final CompanyModel company;
  final CustomerPartyModel consignee;
  final CustomerPartyModel buyer;

  final List<QuotationItemModel> items;

  final double subtotal;
  final double discountTotal;
  final double cgstRate;
  final double cgstAmount;
  final double sgstRate;
  final double sgstAmount;
  final double igstRate;
  final double igstAmount;
  final double roundOff;
  final double grandTotal;
  final String amountInWords;

  final String? declarationText;
  final String? termsAndConditions;
  final String status; // DRAFT, SENT, REVISED, APPROVED, REJECTED, CONVERTED
  final String? revisionNotes;
  final String? convertedProjectId;
  final String? shareHistory;

  final List<Map<String, dynamic>>? revisions;

  QuotationModel({
    required this.id,
    required this.quotationNumber,
    this.revisionNumber = 0,
    this.rootQuotationId,
    required this.date,
    required this.validTill,
    this.refNumber,
    this.termsOfDelivery,
    required this.company,
    required this.consignee,
    required this.buyer,
    required this.items,
    required this.subtotal,
    this.discountTotal = 0.0,
    this.cgstRate = 9.0,
    this.cgstAmount = 0.0,
    this.sgstRate = 9.0,
    this.sgstAmount = 0.0,
    this.igstRate = 0.0,
    this.igstAmount = 0.0,
    this.roundOff = 0.0,
    required this.grandTotal,
    required this.amountInWords,
    this.declarationText,
    this.termsAndConditions,
    this.status = 'DRAFT',
    this.revisionNotes,
    this.convertedProjectId,
    this.shareHistory,
    this.revisions,
  });

  factory QuotationModel.fromJson(Map<String, dynamic> json, [List<dynamic>? revisionsRaw]) {
    return QuotationModel(
      id: json['id'] ?? '',
      quotationNumber: json['quotationNumber'] ?? 'TTPL/QTN/2026-27/001',
      revisionNumber: (json['revisionNumber'] as num?)?.toInt() ?? 0,
      rootQuotationId: json['rootQuotationId'],
      date: json['date'] ?? '',
      validTill: json['validTill'] ?? '',
      refNumber: json['refNumber'],
      termsOfDelivery: json['termsOfDelivery'],

      company: CompanyModel.fromJson(json),
      consignee: CustomerPartyModel.fromJsonConsignee(json),
      buyer: CustomerPartyModel.fromJsonBuyer(json),

      items: (json['items'] as List<dynamic>?)
              ?.map((item) => QuotationItemModel.fromJson(item))
              .toList() ??
          [],

      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountTotal: (json['discountTotal'] as num?)?.toDouble() ?? 0.0,
      cgstRate: (json['cgstRate'] as num?)?.toDouble() ?? 9.0,
      cgstAmount: (json['cgstAmount'] as num?)?.toDouble() ?? 0.0,
      sgstRate: (json['sgstRate'] as num?)?.toDouble() ?? 9.0,
      sgstAmount: (json['sgstAmount'] as num?)?.toDouble() ?? 0.0,
      igstRate: (json['igstRate'] as num?)?.toDouble() ?? 0.0,
      igstAmount: (json['igstAmount'] as num?)?.toDouble() ?? 0.0,
      roundOff: (json['roundOff'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
      amountInWords: json['amountInWords'] ?? '',

      declarationText: json['declarationText'],
      termsAndConditions: json['termsAndConditions'],
      status: json['status'] ?? 'DRAFT',
      revisionNotes: json['revisionNotes'],
      convertedProjectId: json['convertedProjectId'],
      shareHistory: json['shareHistory'] is String ? json['shareHistory'] : json['shareHistory']?.toString(),

      revisions: revisionsRaw != null
          ? List<Map<String, dynamic>>.from(revisionsRaw)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'date': date,
      'validTill': validTill,
      'refNumber': refNumber,
      'termsOfDelivery': termsOfDelivery,

      'discountTotal': discountTotal,
      'cgstRate': cgstRate,
      'sgstRate': sgstRate,
      'igstRate': igstRate,

      'declarationText': declarationText,
      'termsAndConditions': termsAndConditions,
      'status': status,
      'revisionNotes': revisionNotes,

      'items': items.map((i) => i.toJson()).toList(),
    };

    map.addAll(company.toJson());
    map.addAll(consignee.toConsigneeJson());
    map.addAll(buyer.toBuyerJson());

    return map;
  }
}
