import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/savings_goal_model.dart';
import '../../expenses/domain/expense_model.dart';

class SavingsRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  SavingsRepository(this._firestore, this.userId);

  // 1. ADD GOAL
  Future<void> addGoal({
    required String title,
    required double targetAmount,
    required DateTime deadline,
  }) async {
    final docRef = _firestore.collection('users').doc(userId).collection('savings_goals').doc();

    final goal = SavingsGoalModel(
      id: docRef.id,
      title: title,
      targetAmount: targetAmount,
      currentSaved: 0,
      deadline: deadline,
    );

    await docRef.set(goal.toMap());
  }

  // 2. DEPOSIT MONEY (Offline Compatible)
  Future<void> depositToGoal({
    required String walletId,
    required String goalId,
    required String goalTitle,
    required double amount,
  }) async {
    final batch = _firestore.batch();

    final walletRef = _firestore.collection('users').doc(userId).collection('wallets').doc(walletId);
    final goalRef = _firestore.collection('users').doc(userId).collection('savings_goals').doc(goalId);
    final expenseRef = walletRef.collection('expenses').doc();

    // OPTIONAL: You can try to read balance here to validate funds.
    // In strict offline mode, if you want to be safe, you might skip validation or rely on cached data.
    // Here we proceed optimistically.

    // Deduct from Wallet
    batch.update(walletRef, {
      'currentBalance': FieldValue.increment(-amount),
    });

    // Add to Goal
    batch.update(goalRef, {
      'currentSaved': FieldValue.increment(amount),
    });

    // Record Transaction
    final depositExpense = ExpenseModel(
      id: expenseRef.id,
      title: "Deposit: $goalTitle",
      amount: amount,
      category: "Savings",
      date: DateTime.now(),
    );
    batch.set(expenseRef, depositExpense.toMap());

    await batch.commit();
  }

  // 3. GET GOALS
  Stream<List<SavingsGoalModel>> getGoals() {
    return _firestore.collection('users').doc(userId).collection('savings_goals').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => SavingsGoalModel.fromMap(doc.data())).toList();
    });
  }

  // 4. DELETE GOAL (Offline Compatible)
  Future<void> deleteGoal({required String goalId, String? refundWalletId}) async {
    // Note: Deleting requires knowing the current 'savedAmount' to refund it.
    // We must read the document first.
    final goalRef = _firestore.collection('users').doc(userId).collection('savings_goals').doc(goalId);

    // Attempt to read (will look in cache first if offline)
    final goalSnapshot = await goalRef.get();

    if (!goalSnapshot.exists) return;

    final batch = _firestore.batch();
    final double savedAmount = (goalSnapshot.data()?['currentSaved'] ?? 0).toDouble();
    final String goalTitle = goalSnapshot.data()?['title'] ?? 'Goal';

    if (savedAmount > 0 && refundWalletId != null) {
      final walletRef = _firestore.collection('users').doc(userId).collection('wallets').doc(refundWalletId);
      final expenseRef = walletRef.collection('expenses').doc();

      batch.update(walletRef, {
        'currentBalance': FieldValue.increment(savedAmount),
      });

      final refundExpense = ExpenseModel(
        id: expenseRef.id,
        title: "Refund: $goalTitle",
        amount: -savedAmount,
        category: "Savings",
        date: DateTime.now(),
      );
      batch.set(expenseRef, refundExpense.toMap());
    }

    batch.delete(goalRef);
    await batch.commit();
  }
}

// PROVIDERS
final savingsRepositoryProvider = Provider<SavingsRepository>((ref) {
  final firestore = ref.read(firebaseFirestoreProvider);
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) throw Exception("No user");
  return SavingsRepository(firestore, user.uid);
});

final savingsListProvider = StreamProvider<List<SavingsGoalModel>>((ref) {
  return ref.watch(savingsRepositoryProvider).getGoals();
});