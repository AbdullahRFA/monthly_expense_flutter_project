import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/savings_goal_model.dart';
import '../../expenses/domain/expense_model.dart';

class SavingsRepository {
  final FirebaseFirestore _firestore;
  final String userId;
  final Duration _offlineTimeout = const Duration(seconds: 2);

  SavingsRepository(this._firestore, this.userId);

  Future<void> _safeCommit(WriteBatch batch) async {
    try {
      await batch.commit().timeout(_offlineTimeout);
    } on TimeoutException {
      // Queued
    }
  }

  // 1. ADD GOAL
  Future<void> addGoal({required String title, required double targetAmount, required DateTime deadline}) async {
    final docRef = _firestore.collection('users').doc(userId).collection('savings_goals').doc();
    final goal = SavingsGoalModel(
      id: docRef.id,
      title: title,
      targetAmount: targetAmount,
      currentSaved: 0,
      deadline: deadline,
    );
    try {
      await docRef.set(goal.toMap()).timeout(_offlineTimeout);
    } on TimeoutException {
      // Queued
    }
  }

  // 2. DEPOSIT (ACID)
  Future<void> depositToGoal({required String walletId, required String goalId, required String goalTitle, required double amount}) async {
    final batch = _firestore.batch();
    final walletRef = _firestore.collection('users').doc(userId).collection('wallets').doc(walletId);
    final goalRef = _firestore.collection('users').doc(userId).collection('savings_goals').doc(goalId);
    final expenseRef = walletRef.collection('expenses').doc();

    batch.update(walletRef, {'currentBalance': FieldValue.increment(-amount)});
    batch.update(goalRef, {'currentSaved': FieldValue.increment(amount)});

    final depositExpense = ExpenseModel(
      id: expenseRef.id, title: "Deposit: $goalTitle", amount: amount, category: "Savings", date: DateTime.now(),
    );
    batch.set(expenseRef, depositExpense.toMap());

    await _safeCommit(batch);
  }

  // 3. WITHDRAW (ACID)
  Future<void> withdrawFromGoal({required String goalId, required String goalTitle, required String walletId, required double amount}) async {
    final batch = _firestore.batch();
    final walletRef = _firestore.collection('users').doc(userId).collection('wallets').doc(walletId);
    final goalRef = _firestore.collection('users').doc(userId).collection('savings_goals').doc(goalId);
    final expenseRef = walletRef.collection('expenses').doc();

    batch.update(goalRef, {'currentSaved': FieldValue.increment(-amount)});
    batch.update(walletRef, {'currentBalance': FieldValue.increment(amount)});

    final refundExpense = ExpenseModel(
      id: expenseRef.id, title: "Withdraw: $goalTitle", amount: -amount, category: "Savings", date: DateTime.now(),
    );
    batch.set(expenseRef, refundExpense.toMap());

    await _safeCommit(batch);
  }

  // 4. GET GOALS
  Stream<List<SavingsGoalModel>> getGoals() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('savings_goals')
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
      return snapshot.docs.map((doc) => SavingsGoalModel.fromMap(doc.data())).toList();
    });
  }

  // 5. DELETE GOAL (Safe Cache Read + ACID)
  Future<void> deleteGoal({required String goalId, String? refundWalletId}) async {
    final goalRef = _firestore.collection('users').doc(userId).collection('savings_goals').doc(goalId);

    // IMPORTANT: Read from CACHE first to avoid hanging on low connectivity
    // if cache is empty (unlikely if we just clicked it), try server.
    DocumentSnapshot<Map<String, dynamic>> goalSnapshot;
    try {
      goalSnapshot = await goalRef.get(const GetOptions(source: Source.cache));
      if (!goalSnapshot.exists) {
        // Fallback to server/default if somehow not in cache
        goalSnapshot = await goalRef.get();
      }
    } catch(e) {
      // If cache read fails, return to avoid crash
      return;
    }

    if (!goalSnapshot.exists) return;

    final batch = _firestore.batch();
    final double savedAmount = (goalSnapshot.data()?['currentSaved'] ?? 0).toDouble();
    final String goalTitle = goalSnapshot.data()?['title'] ?? 'Goal';

    // Refund logic atomic with delete
    if (savedAmount > 0 && refundWalletId != null) {
      final walletRef = _firestore.collection('users').doc(userId).collection('wallets').doc(refundWalletId);
      final expenseRef = walletRef.collection('expenses').doc();

      batch.update(walletRef, {'currentBalance': FieldValue.increment(savedAmount)});

      final refundExpense = ExpenseModel(
        id: expenseRef.id, title: "Refund: $goalTitle", amount: -savedAmount, category: "Savings", date: DateTime.now(),
      );
      batch.set(expenseRef, refundExpense.toMap());
    }
    batch.delete(goalRef);

    await _safeCommit(batch);
  }
}

final savingsRepositoryProvider = Provider<SavingsRepository>((ref) {
  final firestore = ref.read(firebaseFirestoreProvider);
  final authState = ref.watch(authStateProvider);
  return SavingsRepository(firestore, authState.value!.uid);
});

final savingsListProvider = StreamProvider<List<SavingsGoalModel>>((ref) {
  return ref.watch(savingsRepositoryProvider).getGoals();
});