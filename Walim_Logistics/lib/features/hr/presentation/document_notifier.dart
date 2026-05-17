import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/document_repository.dart';
import '../domain/models/document_model.dart';
import '../../auth/presentation/auth_notifier.dart';

final documentRepositoryProvider = Provider((ref) {
  final supabase = ref.watch(supabaseProvider);
  return DocumentRepository(supabase);
});

class DocumentState {
  final List<DigitalDocument> documents;
  final bool isLoading;
  final String? error;

  const DocumentState({
    this.documents = const [],
    this.isLoading = false,
    this.error,
  });

  DocumentState copyWith({
    List<DigitalDocument>? documents,
    bool? isLoading,
    String? error,
  }) {
    return DocumentState(
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DocumentNotifier extends StateNotifier<DocumentState> {
  final DocumentRepository _repository;
  final String profileId;

  DocumentNotifier(this._repository, this.profileId)
      : super(const DocumentState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    if (profileId.isEmpty) {
      state = state.copyWith(isLoading: false, documents: []);
      return;
    }
    try {
      state = state.copyWith(isLoading: true, error: null);
      final rows = await _repository.getDocuments(profileId);
      final docs = rows.map((row) => DigitalDocument.fromJson(row)).toList();
      state = state.copyWith(documents: docs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _load();

  Future<void> upsertDocument(DigitalDocument doc) async {
    try {
      final isNew = doc.status == 'Missing';
      await _repository.upsertDocument(
        profileId: profileId,
        id: isNew ? null : doc.id,
        title: doc.title,
        type: doc.type,
        status: isNew ? 'Valid' : doc.status,
        expiryDate: doc.expiryDate,
        fileUrl: doc.fileUrl,
        notes: doc.notes,
      );
      await _load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteDocument(String id) async {
    try {
      await _repository.deleteDocument(id);
      state = state.copyWith(
        documents: state.documents.where((d) => d.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> requestRenewal(String id) async {
    try {
      await _repository.updateStatus(id, 'Pending Renewal');
      await _load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> approveRenewal(String id, DateTime newExpiry) async {
    try {
      await _repository.updateStatus(id, 'Valid', expiryDate: newExpiry);
      await _load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final documentProvider =
    StateNotifierProvider<DocumentNotifier, DocumentState>((ref) {
  final repo = ref.watch(documentRepositoryProvider);
  final profile = ref.watch(authProvider).profile;
  return DocumentNotifier(repo, profile?.id ?? '');
});
