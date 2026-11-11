import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/document_repository.dart';
import '../../domain/models/document_model.dart';

class DocumentState {
  final List<DocumentModel> documents;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final String selectedCategory; // ALL, CONTRACT, FLOOR_PLAN, INVOICE, REFERENCE, OTHER
  final String? selectedProjectId;

  DocumentState({
    this.documents = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedCategory = 'ALL',
    this.selectedProjectId,
  });

  DocumentState copyWith({
    List<DocumentModel>? documents,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    String? selectedCategory,
    String? selectedProjectId,
  }) {
    return DocumentState(
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedProjectId: selectedProjectId ?? this.selectedProjectId,
    );
  }
}

class DocumentNotifier extends StateNotifier<DocumentState> {
  final DocumentRepository _repository;

  DocumentNotifier({DocumentRepository? repository})
      : _repository = repository ?? DocumentRepository(),
        super(DocumentState()) {
    fetchDocuments();
  }

  Future<void> fetchDocuments() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _repository.getDocuments(
        projectId: state.selectedProjectId,
        search: state.searchQuery,
        category: state.selectedCategory,
      );
      final List<DocumentModel> docs = res['documents'] as List<DocumentModel>? ?? [];
      state = state.copyWith(documents: docs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    fetchDocuments();
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
    fetchDocuments();
  }

  void setProject(String? projectId) {
    state = state.copyWith(selectedProjectId: projectId);
    fetchDocuments();
  }

  Future<bool> uploadDocument({
    required String title,
    required String projectId,
    required String category,
    required String fileType,
    required String fileSize,
    String? fileUrl,
    PlatformFile? pickedFile,
  }) async {
    try {
      final newDoc = await _repository.createDocument(
        title: title,
        projectId: projectId,
        category: category,
        fileType: fileType,
        fileSize: fileSize,
        fileUrl: fileUrl,
        pickedFile: pickedFile,
      );
      state = state.copyWith(documents: [newDoc, ...state.documents]);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>?> downloadDocument(String id) async {
    try {
      return await _repository.downloadDocument(id);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  Future<bool> deleteDocument(String id) async {
    try {
      await _repository.deleteDocument(id);
      state = state.copyWith(
        documents: state.documents.where((d) => d.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final documentProvider = StateNotifierProvider<DocumentNotifier, DocumentState>((ref) {
  return DocumentNotifier();
});
