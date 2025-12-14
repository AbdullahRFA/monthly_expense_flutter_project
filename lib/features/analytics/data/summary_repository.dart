import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../../expenses/domain/expense_model.dart';
import '../../wallet/domain/wallet_model.dart';

class SummaryRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  SummaryRepository(this._firestore, this.userId);

  // FETCH ALL EXPENSES GLOBALLY (Across all wallets)
  Future<List<ExpenseModel>> getAllExpensesGlobal() async {
    try {
      // 1. Get All Wallets first
      final walletSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wallets')
          .get();

      List<ExpenseModel> allExpenses = [];

      // 2. Loop through each wallet and fetch its expenses
      // (This is okay for personal apps with <50 wallets. For massive scale, use Collection Groups)
      for (var doc in walletSnapshot.docs) {
        final walletId = doc.id;
        final expenseSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('wallets')
            .doc(walletId)
            .collection('expenses')
            .get();

        final expenses = expenseSnapshot.docs
            .map((e) => ExpenseModel.fromMap(e.data()))
            .toList();

        allExpenses.addAll(expenses);
      }

      return allExpenses;
    } catch (e) {
      throw Exception("Failed to fetch global summary: $e");
    }
  }
}

// PROVIDERS
final summaryRepositoryProvider = Provider<SummaryRepository>((ref) {
  final firestore = ref.read(firebaseFirestoreProvider);
  final user = ref.read(firebaseAuthProvider).currentUser;
  if (user == null) throw Exception("No user");
  return SummaryRepository(firestore, user.uid);
});

final globalExpensesProvider = FutureProvider<List<ExpenseModel>>((ref) async {
  return ref.read(summaryRepositoryProvider).getAllExpensesGlobal();
});