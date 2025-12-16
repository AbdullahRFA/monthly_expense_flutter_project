import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/todo_model.dart';

class TodoRepository {
  final FirebaseFirestore _firestore;
  final String userId;
  TodoRepository(this._firestore, this.userId);

  Stream<List<TodoModel>> getTodos() {
    return _firestore.collection('users').doc(userId).collection('todos')
        .orderBy('date', descending: true).snapshots()
        .map((snap) => snap.docs.map((doc) => TodoModel.fromMap(doc.data())).toList());
  }

  Future<void> addTodo(String title) async {
    final doc = _firestore.collection('users').doc(userId).collection('todos').doc();
    await doc.set(TodoModel(id: doc.id, title: title, isCompleted: false, date: DateTime.now()).toMap());
  }

  Future<void> toggleTodo(String id, bool currentStatus) async {
    await _firestore.collection('users').doc(userId).collection('todos').doc(id)
        .update({'isCompleted': !currentStatus});
  }

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