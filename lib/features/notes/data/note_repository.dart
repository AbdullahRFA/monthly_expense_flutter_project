import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/note_model.dart';

class NoteRepository {
  final FirebaseFirestore _firestore;
  final String userId;
  final Duration _offlineTimeout = const Duration(seconds: 2);

  NoteRepository(this._firestore, this.userId);

  Stream<List<NoteModel>> getNotes() {
    return _firestore.collection('users').doc(userId).collection('notes')
        .orderBy('lastEdited', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((snap) => snap.docs.map((doc) => NoteModel.fromMap(doc.data())).toList());
  }

  Stream<NoteModel> getNote(String id) {
    return _firestore.collection('users').doc(userId).collection('notes').doc(id)
        .snapshots(includeMetadataChanges: true)
        .map((doc) {
      if (!doc.exists) throw Exception("Note deleted");
      return NoteModel.fromMap(doc.data()!);
    });
  }

  Future<void> addNote(String title, String content, int colorValue) async {
    final doc = _firestore.collection('users').doc(userId).collection('notes').doc();
    final now = DateTime.now();
    try {
      await doc.set(NoteModel(
          id: doc.id,
          title: title,
          content: content,
          date: now,
          lastEdited: now,
          colorValue: colorValue
      ).toMap()).timeout(_offlineTimeout);
    } on TimeoutException {
      // Queued
    }
  }

  Future<void> updateNote(NoteModel note) async {
    try {
      await _firestore.collection('users').doc(userId).collection('notes').doc(note.id).update({
        'title': note.title,
        'content': note.content,
        'colorValue': note.colorValue,
        'lastEdited': Timestamp.fromDate(DateTime.now()),
      }).timeout(_offlineTimeout);
    } on TimeoutException {
      // Queued
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      await _firestore.collection('users').doc(userId).collection('notes').doc(id).delete().timeout(_offlineTimeout);
    } on TimeoutException {
      // Queued
    }
  }
}

final noteRepositoryProvider = Provider((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) throw Exception("No User");
  return NoteRepository(FirebaseFirestore.instance, user.uid);
});

final noteListProvider = StreamProvider((ref) => ref.watch(noteRepositoryProvider).getNotes());

final noteStreamProvider = StreamProvider.family<NoteModel, String>((ref, id) {
  return ref.watch(noteRepositoryProvider).getNote(id);
});