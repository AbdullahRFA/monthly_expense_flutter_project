import 'dart:async'; // Import for TimeoutException
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/expense_model.dart';

class ExpenseRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  // Reduced timeout ensures UI doesn't hang in "Lie-fi"
  final Duration _offlineTimeout = const Duration(seconds: 2);

  ExpenseRepository(this._firestore, this.userId);

  // Helper to handle offline writes safely
  Future<void> _safeCommit(WriteBatch batch) async {
    try {
      await batch.commit().timeout(_offlineTimeout);
    } on TimeoutException {
      // Ignore timeout. Data is written to local cache (Persistence enabled).
      // The SDK will sync it when connection is stable.
    }
  }

  // 1. ADD EXPENSE (ACID: Expense Doc + Wallet Balance)
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

    // Atomic Writes
    batch.set(expenseRef, newExpense.toMap());
    batch.update(walletRef, {
      'currentBalance': FieldValue.increment(-amount),
    });

    await _safeCommit(batch);
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
        .snapshots(includeMetadataChanges: true) // Update on local changes too
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ExpenseModel.fromMap(doc.data());
      }).toList();
    });
  }

  // 3. DELETE EXPENSE (ACID)
  Future<void> deleteExpense({
    required String walletId,
    required String expenseId,
    required double amount
  }) async {
    final batch = _firestore.batch();

    final walletRef = _firestore.collection('users').doc(userId).collection('wallets').doc(walletId);
    final expenseRef = walletRef.collection('expenses').doc(expenseId);

    batch.update(walletRef, {
      'currentBalance': FieldValue.increment(amount)
    });
    batch.delete(expenseRef);

    await _safeCommit(batch);
  }

  // 4. EDIT EXPENSE (ACID)
  Future<void> updateExpense({
    required String walletId,
    required ExpenseModel oldExpense,
    required ExpenseModel newExpense,
  }) async {
    final batch = _firestore.batch();

    final walletRef = _firestore.collection('users').doc(userId).collection('wallets').doc(walletId);
    final expenseRef = walletRef.collection('expenses').doc(oldExpense.id);

    final difference = oldExpense.amount - newExpense.amount;

    batch.update(expenseRef, newExpense.toMap());

    if (difference != 0) {
      batch.update(walletRef, {
        'currentBalance': FieldValue.increment(difference),
      });
    }

    await _safeCommit(batch);
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