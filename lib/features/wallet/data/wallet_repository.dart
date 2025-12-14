import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/wallet_model.dart';
import '../../auth/data/auth_repository.dart';
import '../../expenses/domain/expense_model.dart';

class WalletRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  WalletRepository(this._firestore, this.userId);

  // 1. CREATE WALLET (Offline Compatible using Batch)
  Future<void> addWallet({
    required String name,
    required double monthlyBudget,
    double rolloverAmount = 0.0,
    String? sourceWalletId,
    String? sourceWalletName,
  }) async {
    // Use Batch instead of Transaction for offline support
    final batch = _firestore.batch();

    final userRef = _firestore.collection('users').doc(userId);
    final newWalletRef = userRef.collection('wallets').doc();
    final now = DateTime.now();

    // --- STEP 1: HANDLE SOURCE WALLET ---
    if (sourceWalletId != null && rolloverAmount > 0) {
      final sourceWalletRef = userRef.collection('wallets').doc(sourceWalletId);
      final sourceExpenseRef = sourceWalletRef.collection('expenses').doc();

      // Decrement balance using FieldValue (safe for offline)
      batch.update(sourceWalletRef, {
        'currentBalance': FieldValue.increment(-rolloverAmount),
      });

      final deductionRecord = ExpenseModel(
        id: sourceExpenseRef.id,
        title: "Rollover to $name",
        amount: rolloverAmount,
        category: "Others",
        date: now,
      );
      batch.set(sourceExpenseRef, deductionRecord.toMap());
    }

    // --- STEP 2: HANDLE NEW WALLET ---
    final newWallet = WalletModel(
      id: newWalletRef.id,
      name: name,
      monthlyBudget: monthlyBudget,
      currentBalance: monthlyBudget + rolloverAmount,
      month: now.month,
      year: now.year,
    );
    batch.set(newWalletRef, newWallet.toMap());

    if (sourceWalletName != null && rolloverAmount > 0) {
      final newExpenseRef = newWalletRef.collection('expenses').doc();

      final incomeRecord = ExpenseModel(
        id: newExpenseRef.id,
        title: "Rollover from $sourceWalletName",
        amount: -rolloverAmount, // Negative amount usually implies income in your logic?
        // Or if you track positive expenses, this logically adds funds.
        // Based on previous logic, let's keep consistency.
        category: "Others",
        date: now,
      );
      batch.set(newExpenseRef, incomeRecord.toMap());
    }

    // Commit all changes locally (and sync when online)
    await batch.commit();
  }

  // 2. GET ALL WALLETS
  Stream<List<WalletModel>> getWallets() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .orderBy('year', descending: true)
        .orderBy('month', descending: true)
        .snapshots() // snapshots() works offline automatically
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
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

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