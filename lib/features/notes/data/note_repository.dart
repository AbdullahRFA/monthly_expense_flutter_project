import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/note_model.dart';

class NoteRepository {
  final FirebaseFirestore _firestore;
  final String userId;
  NoteRepository(this._firestore, this.userId);

  Stream<List<NoteModel>> getNotes() {
    return _firestore.collection('users').doc(userId).collection('notes')
        .orderBy('date', descending: true).snapshots()
        .map((snap) => snap.docs.map((doc) => NoteModel.fromMap(doc.data())).toList());
  }

  Future<void> addNote(String title, String content) async {
    final doc = _firestore.collection('users').doc(userId).collection('notes').doc();
    await doc.set(NoteModel(id: doc.id, title: title, content: content, date: DateTime.now()).toMap());
  }

  Future<void> deleteNote(String id) async {
    await _firestore.collection('users').doc(userId).collection('notes').doc(id).delete();
  }
}

final noteRepositoryProvider = Provider((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) throw Exception("No User");
  return NoteRepository(FirebaseFirestore.instance, user.uid);
});

final noteListProvider = StreamProvider((ref) => ref.watch(noteRepositoryProvider).getNotes());