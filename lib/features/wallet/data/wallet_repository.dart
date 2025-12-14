import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/wallet_model.dart';
import '../../auth/data/auth_repository.dart';
import '../../expenses/domain/expense_model.dart'; // Import Expense Model

class WalletRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  WalletRepository(this._firestore, this.userId);

  // 1. CREATE WALLET (With Smart Rollover Transaction)
  Future<void> addWallet({
    required String name,
    required double monthlyBudget,
    double rolloverAmount = 0.0,
    String? sourceWalletId,   // ID of the old wallet
    String? sourceWalletName, // Name of the old wallet
  }) async {
    // We use a Transaction to ensure both wallets update together, or fail together.
    return _firestore.runTransaction((transaction) async {
      final userRef = _firestore.collection('users').doc(userId);
      final newWalletRef = userRef.collection('wallets').doc();
      final now = DateTime.now();

      // --- STEP 1: HANDLE SOURCE WALLET (The Old One) ---
      if (sourceWalletId != null && rolloverAmount > 0) {
        final sourceWalletRef = userRef.collection('wallets').doc(sourceWalletId);
        final sourceExpenseRef = sourceWalletRef.collection('expenses').doc();

        // Check if source wallet still exists
        final sourceSnapshot = await transaction.get(sourceWalletRef);
        if (sourceSnapshot.exists) {
          // A. Deduct Money from Old Wallet
          transaction.update(sourceWalletRef, {
            'currentBalance': FieldValue.increment(-rolloverAmount),
          });

          // B. Add "Expense" Record to Old Wallet
          final deductionRecord = ExpenseModel(
            id: sourceExpenseRef.id,
            title: "Rollover to $name", // "Rollover to November"
            amount: rolloverAmount,
            category: "Others",
            date: now,
          );
          transaction.set(sourceExpenseRef, deductionRecord.toMap());
        }
      }

      // --- STEP 2: HANDLE NEW WALLET (The Destination) ---

      // A. Create the New Wallet
      // Starting Balance = Budget + Rollover
      final newWallet = WalletModel(
        id: newWalletRef.id,
        name: name,
        monthlyBudget: monthlyBudget,
        currentBalance: monthlyBudget + rolloverAmount,
        month: now.month,
        year: now.year,
      );
      transaction.set(newWalletRef, newWallet.toMap());

      // B. Add "Income" Record to New Wallet (Only if there was a rollover)
      if (sourceWalletName != null && rolloverAmount > 0) {
        final newExpenseRef = newWalletRef.collection('expenses').doc();

        final incomeRecord = ExpenseModel(
          id: newExpenseRef.id,
          title: "Rollover from $sourceWalletName", // "Rollover from October"
          amount: -rolloverAmount, // Negative = Income (Green)
          category: "Others",
          date: now,
        );
        transaction.set(newExpenseRef, incomeRecord.toMap());
      }
    });
  }

  // 2. GET ALL WALLETS
  Stream<List<WalletModel>> getWallets() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .orderBy('year', descending: true)
        .orderBy('month', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return WalletModel.fromMap(doc.data());
      }).toList();
    });
  }

  // 3. GET SINGLE WALLET
  Stream<WalletModel> getWallet(String walletId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .doc(walletId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        throw Exception("Wallet deleted");
      }
      return WalletModel.fromMap(doc.data() as Map<String, dynamic>);
    });
  }

  // 4. EDIT WALLET
  Future<void> updateWallet({
    required WalletModel oldWallet,
    required String newName,
    required double newBudget,
  }) async {
    final double difference = newBudget - oldWallet.monthlyBudget;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .doc(oldWallet.id)
        .update({
      'name': newName,
      'monthlyBudget': newBudget,
      'currentBalance': FieldValue.increment(difference),
    });
  }

  // 5. DELETE WALLET
  Future<void> deleteWallet(String walletId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .doc(walletId)
        .delete();
  }
}

// ---------------- PROVIDERS ----------------

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final firestore = ref.read(firebaseFirestoreProvider);
  final user = ref.read(firebaseAuthProvider).currentUser;

  if (user == null) {
    throw Exception("User must be logged in to access WalletRepository");
  }

  return WalletRepository(firestore, user.uid);
});

final walletListProvider = StreamProvider<List<WalletModel>>((ref) {
  final repository = ref.watch(walletRepositoryProvider);
  return repository.getWallets();
});

final walletStreamProvider = StreamProvider.family<WalletModel, String>((ref, walletId) {
  final repository = ref.watch(walletRepositoryProvider);
  return repository.getWallet(walletId);
});