import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/todo_model.dart';

class TodoRepository {
  final FirebaseFirestore _firestore;
  final String userId;
  final Duration _offlineTimeout = const Duration(seconds: 2);

  TodoRepository(this._firestore, this.userId);

  Stream<List<TodoModel>> getTodos() {
    return _firestore.collection('users').doc(userId).collection('todos')
        .orderBy('isCompleted', descending: false)
        .orderBy('priority', descending: true)
        .orderBy('date', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((snap) => snap.docs.map((doc) => TodoModel.fromMap(doc.data())).toList());
  }

  Stream<TodoModel> getTodo(String id) {
    return _firestore.collection('users').doc(userId).collection('todos').doc(id)
        .snapshots(includeMetadataChanges: true)
        .map((doc) {
      if (!doc.exists) throw Exception("Task deleted");
      return TodoModel.fromMap(doc.data()!);
    });
  }

  Future<void> addTodo({
    required String title,
    required String description,
    required DateTime? dueDate,
    required TodoPriority priority,
  }) async {
    final doc = _firestore.collection('users').doc(userId).collection('todos').doc();
    final todo = TodoModel(
      id: doc.id,
      title: title,
      description: description,
      isCompleted: false,
      date: DateTime.now(),
      dueDate: dueDate,
      priority: priority,
    );
    try {
      await doc.set(todo.toMap()).timeout(_offlineTimeout);
    } on TimeoutException {
      // Queued
    }
  }

  Future<void> updateTodo(TodoModel todo) async {
    try {
      await _firestore.collection('users').doc(userId).collection('todos').doc(todo.id)
          .update(todo.toMap()).timeout(_offlineTimeout);
    } on TimeoutException {
      // Queued
    }
  }

  Future<void> toggleTodo(String id, bool currentStatus) async {
    // Note: We don't necessarily need a timeout here as it's a small update,
    // but consistency is good.
    try {
      await _firestore.collection('users').doc(userId).collection('todos').doc(id)
          .update({'isCompleted': !currentStatus}).timeout(_offlineTimeout);
    } on TimeoutException {
      // Queued
    }
  }

  Future<void> deleteTodo(String id) async {
    try {
      await _firestore.collection('users').doc(userId).collection('todos').doc(id).delete().timeout(_offlineTimeout);
    } on TimeoutException {
      // Queued
    }
  }
}

// ... existing providers ...
final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) throw Exception("No User");
  return TodoRepository(FirebaseFirestore.instance, user.uid);
});

final todoListProvider = StreamProvider((ref) => ref.watch(todoRepositoryProvider).getTodos());

final todoStreamProvider = StreamProvider.family<TodoModel, String>((ref, id) {
  return ref.watch(todoRepositoryProvider).getTodo(id);
});