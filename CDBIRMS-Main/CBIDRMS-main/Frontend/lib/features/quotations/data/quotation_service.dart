import '../domain/models/quotation_model.dart';
import 'repositories/quotation_repository.dart';

class QuotationService {
  final QuotationRepository _repository;

  QuotationService({QuotationRepository? repository})
      : _repository = repository ?? QuotationRepository();

  Future<List<QuotationModel>> fetchQuotations({String? search, String? status}) {
    return _repository.fetchQuotations(search: search, status: status);
  }

  Future<QuotationModel> fetchQuotationById(String id) {
    return _repository.fetchQuotationById(id);
  }

  Future<QuotationModel> createQuotation(Map<String, dynamic> data) {
    return _repository.createQuotation(data);
  }

  Future<QuotationModel> updateQuotation(String id, Map<String, dynamic> data) {
    return _repository.updateQuotation(id, data);
  }

  Future<QuotationModel> createRevision(String id, Map<String, dynamic> data) {
    return _repository.createRevision(id, data);
  }

  Future<QuotationModel> duplicateQuotation(String id) {
    return _repository.duplicateQuotation(id);
  }

  Future<void> deleteQuotation(String id) {
    return _repository.deleteQuotation(id);
  }

  Future<Map<String, dynamic>> shareQuotation(String id, String channel) {
    return _repository.shareQuotation(id, channel);
  }

  Future<Map<String, dynamic>> convertToProject(String id) {
    return _repository.convertToProject(id);
  }
}
