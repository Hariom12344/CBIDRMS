import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/boq_repository.dart';
import '../../domain/models/boq_model.dart';

class BoqState {
  final List<BoqModel> boqs;
  final bool isLoading;
  final String? errorMessage;

  BoqState({
    this.boqs = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  BoqState copyWith({
    List<BoqModel>? boqs,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BoqState(
      boqs: boqs ?? this.boqs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class BoqNotifier extends StateNotifier<BoqState> {
  final BoqRepository _repository = BoqRepository();

  BoqNotifier() : super(BoqState()) {
    fetchBoqs();
  }

  Future<void> fetchBoqs({String? projectId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final boqs = await _repository.getBoqs(projectId: projectId);
      state = state.copyWith(boqs: boqs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<BoqModel?> createBoq({
    required String projectId,
    required List<BoqItemModel> items,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newBoq = await _repository.createBoq(projectId: projectId, items: items);
      state = state.copyWith(
        boqs: [newBoq, ...state.boqs],
        isLoading: false,
      );
      return newBoq;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<BoqModel?> updateBoq({
    required String id,
    required List<BoqItemModel> items,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _repository.updateBoq(id: id, items: items);
      final updatedList = state.boqs.map((b) => b.id == id ? updated : b).toList();
      state = state.copyWith(boqs: updatedList, isLoading: false);
      return updated;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }
}

final boqNotifierProvider = StateNotifierProvider<BoqNotifier, BoqState>((ref) {
  return BoqNotifier();
});
