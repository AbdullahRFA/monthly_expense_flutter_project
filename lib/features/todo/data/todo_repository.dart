import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/todo_model.dart';
import '../domain/task_group_model.dart';

class TodoRepository {
  final FirebaseFirestore _firestore;
  final String userId;
  final Duration _offlineTimeout = const Duration(seconds: 2);

  TodoRepository(this._firestore, this.userId);

  // ================= TASK GROUPS (WALLETS) =================

  // Get All Groups
  Stream<List<TaskGroupModel>> getTaskGroups() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('task_groups')
        .orderBy('createdAt', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((snap) => snap.docs.map((doc) => TaskGroupModel.fromMap(doc.data())).toList());
  }

  // Add Group
  Future<void> addTaskGroup({
    required String title,
    required String description,
    required DateTime date,
  }) async {
    final doc = _firestore.collection('users').doc(userId).collection('task_groups').doc();
    final group = TaskGroupModel(
      id: doc.id,
      title: title,
      description: description,
      createdAt: date,
    );
    try {
      await doc.set(group.toMap()).timeout(_offlineTimeout);
    } on TimeoutException {
      // Queued
    }
  }

  // Update Group
  Future<void> updateTaskGroup(TaskGroupModel group) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('task_groups')
          .doc(group.id)
          .update(group.toMap())
          .timeout(_offlineTimeout);
    } on TimeoutException {
      // Queued
    }
  }

  // Delete Group (And recursively delete sub-tasks ideally, but for now just the group doc)
  Future<void> deleteTaskGroup(String groupId) async {
    try {
      // Note: In a real production app, you'd want a Cloud Function to recursively delete the 'todos' subcollection.
      // Here we just delete the parent. The subcollection becomes orphaned but inaccessible.
      await _firestore.collection('users').doc(userId).collection('task_groups').doc(groupId).delete().timeout(_offlineTimeout);
    } on TimeoutException {
      // Queued
    }
  }

  // ================= TODOS (Inside Groups) =================

  // Get Todos for a specific Group
  Stream<List<TodoModel>> getTodos(String groupId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('task_groups')
        .doc(groupId)
        .collection('todos')
        .orderBy('isCompleted', descending: false)
        .orderBy('priority', descending: true)
        .orderBy('date', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((snap) => snap.docs.map((doc) => TodoModel.fromMap(doc.data())).toList());
  }

  // Get Single Todo
  Stream<TodoModel> getTodo(String groupId, String todoId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('task_groups')
        .doc(groupId)
        .collection('todos')
        .doc(todoId)
        .snapshots(includeMetadataChanges: true)
        .map((doc) {
      if (!doc.exists) throw Exception("Task deleted");
      return TodoModel.fromMap(doc.data()!);
    });
  }

  // Add Todo
  Future<void> addTodo({
    required String groupId,
    required String title,
    required String description,
    required DateTime? dueDate,
    required TodoPriority priority,
  }) async {
    final doc = _firestore
        .collection('users')
        .doc(userId)
        .collection('task_groups')
        .doc(groupId)
        .collection('todos')
        .doc();

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

  // Update Todo
  Future<void> updateTodo(String groupId, TodoModel todo) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('task_groups')
          .doc(groupId)
          .collection('todos')
          .doc(todo.id)
          .update(todo.toMap())
          .timeout(_offlineTimeout);
    } on TimeoutException {
      // Queued
    }
  }

  // Toggle Complete
  Future<void> toggleTodo(String groupId, String todoId, bool currentStatus) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('task_groups')
          .doc(groupId)
          .collection('todos')
          .doc(todoId)
          .update({'isCompleted': !currentStatus}).timeout(_offlineTimeout);
    } on TimeoutException {
      // Queued
    }
  }

  // Delete Todo
  Future<void> deleteTodo(String groupId, String todoId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('task_groups')
          .doc(groupId)
          .collection('todos')
          .doc(todoId)
          .delete()
          .timeout(_offlineTimeout);
    } on TimeoutException {
      // Queued
    }
  }
}

// ================= PROVIDERS =================

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) throw Exception("No User");
  return TodoRepository(FirebaseFirestore.instance, user.uid);
});

// Provider for the list of GROUPS
final taskGroupListProvider = StreamProvider<List<TaskGroupModel>>((ref) {
  return ref.watch(todoRepositoryProvider).getTaskGroups();
});

// Provider for the list of TASKS (Family provider requires groupId)
final todoListProvider = StreamProvider.family<List<TodoModel>, String>((ref, groupId) {
  return ref.watch(todoRepositoryProvider).getTodos(groupId);
});

// Provider for a single TASK (Family requires Tuple or distinct args - using a custom class or just passing id manually in widget)
// Ideally we pass a simple object, but here we can keep it simple:
// We will access repo directly in the UI for single streams or create a specific provider if needed.
final singleTodoStreamProvider = StreamProvider.family<TodoModel, ({String groupId, String todoId})>((ref, args) {
  return ref.watch(todoRepositoryProvider).getTodo(args.groupId, args.todoId);
});