import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/todo_model.dart';

class TodoRepository {
  final FirebaseFirestore _firestore;
  final String userId;
  TodoRepository(this._firestore, this.userId);

  // GET LIST (Sorted)
  Stream<List<TodoModel>> getTodos() {
    return _firestore.collection('users').doc(userId).collection('todos')
        .orderBy('isCompleted', descending: false)
        .orderBy('priority', descending: true)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => TodoModel.fromMap(doc.data())).toList());
  }

  // GET SINGLE (For Detail Screen)
  Stream<TodoModel> getTodo(String id) {
    return _firestore.collection('users').doc(userId).collection('todos').doc(id)
        .snapshots()
        .map((doc) {
      if (!doc.exists) throw Exception("Task deleted");
      return TodoModel.fromMap(doc.data()!);
    });
  }

  // CREATE
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
    await doc.set(todo.toMap());
  }

  // UPDATE
  Future<void> updateTodo(TodoModel todo) async {
    await _firestore.collection('users').doc(userId).collection('todos').doc(todo.id)
        .update(todo.toMap());
  }

  // TOGGLE STATUS
  Future<void> toggleTodo(String id, bool currentStatus) async {
    await _firestore.collection('users').doc(userId).collection('todos').doc(id)
        .update({'isCompleted': !currentStatus});
  }

  // DELETE
  Future<void> deleteTodo(String id) async {
    await _firestore.collection('users').doc(userId).collection('todos').doc(id).delete();
  }
}

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) throw Exception("No User");
  return TodoRepository(FirebaseFirestore.instance, user.uid);
});

final todoListProvider = StreamProvider((ref) => ref.watch(todoRepositoryProvider).getTodos());

// NEW: Single Todo Provider
final todoStreamProvider = StreamProvider.family<TodoModel, String>((ref, id) {
  return ref.watch(todoRepositoryProvider).getTodo(id);
});