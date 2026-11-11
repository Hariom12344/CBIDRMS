import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/design_repository.dart';
import '../../domain/models/design_model.dart';

class DesignState {
  final List<DesignModel> designs;
  final bool isLoading;
  final bool isUploading;
  final double uploadProgress;
  final String? errorMessage;
  final String searchQuery;
  final String selectedCategory; // ALL, FLOOR_PLAN, THREE_D_RENDER, CAD_DRAWING, ELEVATION, OTHER
  final String? selectedProjectId;

  DesignState({
    this.designs = const [],
    this.isLoading = false,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedCategory = 'ALL',
    this.selectedProjectId,
  });

  DesignState copyWith({
    List<DesignModel>? designs,
    bool? isLoading,
    bool? isUploading,
    double? uploadProgress,
    String? errorMessage,
    String? searchQuery,
    String? selectedCategory,
    String? selectedProjectId,
  }) {
    return DesignState(
      designs: designs ?? this.designs,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedProjectId: selectedProjectId ?? this.selectedProjectId,
    );
  }
}

class DesignNotifier extends StateNotifier<DesignState> {
  final DesignRepository _repository;

  DesignNotifier({DesignRepository? repository})
      : _repository = repository ?? DesignRepository(),
        super(DesignState()) {
    fetchDesigns();
  }

  Future<void> fetchDesigns() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _repository.getDesigns(
        projectId: state.selectedProjectId,
        category: state.selectedCategory,
        search: state.searchQuery,
      );
      final List<DesignModel> docs = res['designs'] as List<DesignModel>? ?? [];
      state = state.copyWith(designs: docs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    fetchDesigns();
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
    fetchDesigns();
  }

  void setProject(String? projectId) {
    state = state.copyWith(selectedProjectId: projectId);
    fetchDesigns();
  }

  Future<bool> uploadDesign({
    required String title,
    required String projectId,
    required String category,
    required String fileType,
    required String fileSize,
    String? fileUrl,
    PlatformFile? pickedFile,
  }) async {
    state = state.copyWith(isUploading: true, uploadProgress: 0.0, errorMessage: null);
    try {
      final newDesign = await _repository.createDesign(
        title: title,
        projectId: projectId,
        category: category,
        fileType: fileType,
        fileSize: fileSize,
        fileUrl: fileUrl,
        pickedFile: pickedFile,
        onSendProgress: (sent, total) {
          if (total > 0) {
            state = state.copyWith(uploadProgress: sent / total);
          }
        },
      );
      state = state.copyWith(
        designs: [newDesign, ...state.designs],
        isUploading: false,
        uploadProgress: 1.0,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isUploading: false, uploadProgress: 0.0, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> uploadRevision({
    required String parentId,
    String? title,
    String? category,
    String? fileType,
    String? fileSize,
    PlatformFile? pickedFile,
    bool isMajorVersion = false,
  }) async {
    state = state.copyWith(isUploading: true, uploadProgress: 0.0, errorMessage: null);
    try {
      final newRev = await _repository.createRevision(
        parentId: parentId,
        title: title,
        category: category,
        fileType: fileType,
        fileSize: fileSize,
        pickedFile: pickedFile,
        isMajorVersion: isMajorVersion,
        onSendProgress: (sent, total) {
          if (total > 0) {
            state = state.copyWith(uploadProgress: sent / total);
          }
        },
      );
      state = state.copyWith(
        designs: state.designs.map((d) => d.id == parentId ? newRev : d).toList(),
        isUploading: false,
        uploadProgress: 1.0,
      );
      fetchDesigns();
      return true;
    } catch (e) {
      state = state.copyWith(isUploading: false, uploadProgress: 0.0, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> approveDesign({
    required String id,
    required String action, // APPROVE, REQUEST_REVISION
    String? note,
  }) async {
    try {
      final updated = await _repository.approveDesign(
        id: id,
        action: action,
        note: note,
      );
      state = state.copyWith(
        designs: state.designs.map((d) => d.id == id ? updated : d).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>?> downloadDesign(String id) async {
    try {
      return await _repository.downloadDesign(id);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDesignDetails(String id) async {
    try {
      return await _repository.getDesignById(id);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }
}

final designProvider = StateNotifierProvider<DesignNotifier, DesignState>((ref) {
  return DesignNotifier();
});
