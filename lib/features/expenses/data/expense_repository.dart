import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/expense_model.dart';

class ExpenseRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  ExpenseRepository(this._firestore, this.userId);

  // 1. ADD EXPENSE (Offline Compatible)
  Future<void> addExpense({
    required String walletId,
    required String title,
    required double amount,
    required String category,
    required DateTime date,
  }) async {
    final batch = _firestore.batch();

    final walletRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .doc(walletId);

    final expenseRef = walletRef.collection('expenses').doc();

    final newExpense = ExpenseModel(
      id: expenseRef.id,
      title: title,
      amount: amount,
      category: category,
      date: date,
    );

    // Write Expense
    batch.set(expenseRef, newExpense.toMap());

    // Update Balance Atomically (Works Offline)
    batch.update(walletRef, {
      'currentBalance': FieldValue.increment(-amount),
    });

    await batch.commit();
  }

  // 2. GET EXPENSES
  Stream<List<ExpenseModel>> getExpenses(String walletId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .doc(walletId)
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ExpenseModel.fromMap(doc.data());
      }).toList();
    });
  }

  // 3. DELETE EXPENSE (Offline Compatible)
  Future<void> deleteExpense({
    required String walletId,
    required String expenseId,
    required double amount
  }) async {
    final batch = _firestore.batch();

    final walletRef = _firestore.collection('users').doc(userId).collection('wallets').doc(walletId);
    final expenseRef = walletRef.collection('expenses').doc(expenseId);

    // Restore Balance
    batch.update(walletRef, {
      'currentBalance': FieldValue.increment(amount)
    });

    // Delete Expense
    batch.delete(expenseRef);

    await batch.commit();
  }

  // 4. EDIT EXPENSE (Offline Compatible)
  Future<void> updateExpense({
    required String walletId,
    required ExpenseModel oldExpense,
    required ExpenseModel newExpense,
  }) async {
    final batch = _firestore.batch();

    final walletRef = _firestore.collection('users').doc(userId).collection('wallets').doc(walletId);
    final expenseRef = walletRef.collection('expenses').doc(oldExpense.id);

    final difference = oldExpense.amount - newExpense.amount;

    // Update Expense Doc
    batch.update(expenseRef, newExpense.toMap());

    // Adjust Balance if amount changed
    if (difference != 0) {
      batch.update(walletRef, {
        'currentBalance': FieldValue.increment(difference),
      });
    }

    await batch.commit();
  }
}

// ---------------- PROVIDERS ----------------

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final firestore = ref.read(firebaseFirestoreProvider);
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) throw Exception("No user logged in");

  return ExpenseRepository(firestore, user.uid);
});

final expenseListProvider = StreamProvider.family<List<ExpenseModel>, String>((ref, walletId) {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getExpenses(walletId);
});