import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/lead_repository.dart';
import '../../domain/models/lead_model.dart';
import '../../../projects/domain/models/project_model.dart';
import '../../../projects/presentation/providers/project_provider.dart';

class LeadsState {
  final List<LeadModel> leads;
  final bool isLoading;
  final bool isMutating;
  final String? errorMessage;
  final String selectedStatusFilter; // 'All', 'New', 'Contacted', 'Meeting Scheduled', 'Proposal Sent', 'Won', 'Lost'
  final String searchQuery;

  LeadsState({
    this.leads = const [],
    this.isLoading = false,
    this.isMutating = false,
    this.errorMessage,
    this.selectedStatusFilter = 'All',
    this.searchQuery = '',
  });

  List<LeadModel> get filteredLeads {
    return leads.where((lead) {
      final matchesStatus = selectedStatusFilter == 'All' || lead.status == selectedStatusFilter;
      final query = searchQuery.trim().toLowerCase();
      if (query.isEmpty) return matchesStatus;

      final matchesSearch = lead.clientName.toLowerCase().contains(query) ||
          lead.id.toLowerCase().contains(query) ||
          lead.propertyType.toLowerCase().contains(query) ||
          lead.phone.toLowerCase().contains(query) ||
          lead.assignedTo.toLowerCase().contains(query);

      return matchesStatus && matchesSearch;
    }).toList();
  }

  LeadsState copyWith({
    List<LeadModel>? leads,
    bool? isLoading,
    bool? isMutating,
    String? errorMessage,
    String? selectedStatusFilter,
    String? searchQuery,
  }) {
    return LeadsState(
      leads: leads ?? this.leads,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: errorMessage,
      selectedStatusFilter: selectedStatusFilter ?? this.selectedStatusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class LeadsNotifier extends StateNotifier<LeadsState> {
  final LeadRepository _repository = LeadRepository();
  final Ref _ref;

  LeadsNotifier(this._ref) : super(LeadsState()) {
    fetchLeads();
  }

  // Fetch all leads from API
  Future<void> fetchLeads({String? status}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repository.getLeads(status: status ?? state.selectedStatusFilter);
      state = state.copyWith(leads: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setStatusFilter(String filter) {
    state = state.copyWith(selectedStatusFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  // Create a new lead
  Future<LeadModel?> createLead({
    required String clientName,
    String? email,
    String? phone,
    String? propertyType,
    double? estimatedBudget,
    String? assignedTo,
  }) async {
    state = state.copyWith(isMutating: true, errorMessage: null);
    try {
      final newLead = await _repository.createLead(
        clientName: clientName,
        email: email,
        phone: phone,
        propertyType: propertyType,
        estimatedBudget: estimatedBudget,
        assignedTo: assignedTo,
      );

      state = state.copyWith(
        leads: [newLead, ...state.leads],
        isMutating: false,
      );
      return newLead;
    } catch (e) {
      state = state.copyWith(isMutating: false, errorMessage: e.toString());
      return null;
    }
  }

  // Update existing lead
  Future<LeadModel?> updateLead({
    required String leadId,
    required Map<String, dynamic> updateData,
  }) async {
    state = state.copyWith(isMutating: true, errorMessage: null);
    try {
      final updatedLead = await _repository.updateLead(leadId, updateData);

      final updatedList = state.leads.map((l) {
        return l.id == leadId ? updatedLead : l;
      }).toList();

      state = state.copyWith(leads: updatedList, isMutating: false);
      return updatedLead;
    } catch (e) {
      state = state.copyWith(isMutating: false, errorMessage: e.toString());
      return null;
    }
  }

  // Delete lead
  Future<bool> deleteLead({
    required String leadId,
  }) async {
    state = state.copyWith(isMutating: true, errorMessage: null);
    try {
      await _repository.deleteLead(leadId);

      final updatedList = state.leads.where((l) => l.id != leadId).toList();
      state = state.copyWith(leads: updatedList, isMutating: false);
      return true;
    } catch (e) {
      state = state.copyWith(isMutating: false, errorMessage: e.toString());
      return false;
    }
  }

  // Convert a Lead into a Project
  Future<ProjectModel?> convertLeadToProject({
    required String leadId,
  }) async {
    state = state.copyWith(isMutating: true, errorMessage: null);
    try {
      final result = await _repository.convertToProject(leadId);
      final updatedLead = result['lead'] as LeadModel;
      final createdProject = result['project'] as ProjectModel;

      final updatedLeads = state.leads.map((l) {
        return l.id == leadId ? updatedLead : l;
      }).toList();

      state = state.copyWith(leads: updatedLeads, isMutating: false);

      _ref.read(projectNotifierProvider.notifier).addProjectToList(createdProject);
      return createdProject;
    } catch (e) {
      state = state.copyWith(isMutating: false, errorMessage: e.toString());
      return null;
    }
  }
}

final leadsNotifierProvider = StateNotifierProvider<LeadsNotifier, LeadsState>((ref) {
  return LeadsNotifier(ref);
});
