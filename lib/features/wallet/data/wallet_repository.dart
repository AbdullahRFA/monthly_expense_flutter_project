import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/wallet_model.dart';
import '../../auth/data/auth_repository.dart';
import '../../expenses/domain/expense_model.dart';

class WalletRepository {
  final FirebaseFirestore _firestore;
  final String userId;
  final Duration _offlineTimeout = const Duration(seconds: 2);

  WalletRepository(this._firestore, this.userId);

  Future<void> _safeCommit(WriteBatch batch) async {
    try {
      await batch.commit().timeout(_offlineTimeout);
    } on TimeoutException {
      // Treat as queued
    }
  }

  // 1. CREATE WALLET
  Future<String> addWallet({
    required String name,
    required double monthlyBudget,
    double rolloverAmount = 0.0,
    String? sourceWalletId,
    String? sourceWalletName,
  }) async {
    final batch = _firestore.batch();
    final userRef = _firestore.collection('users').doc(userId);
    final newWalletRef = userRef.collection('wallets').doc();
    final now = DateTime.now();

    // Rollover Logic (Atomic)
    if (sourceWalletId != null && rolloverAmount > 0) {
      final sourceWalletRef = userRef.collection('wallets').doc(sourceWalletId);
      final sourceExpenseRef = sourceWalletRef.collection('expenses').doc();

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

    final newWallet = WalletModel(
      id: newWalletRef.id,
      name: name,
      monthlyBudget: monthlyBudget,
      currentBalance: monthlyBudget + rolloverAmount,
      month: now.month,
      year: now.year,
    );
    batch.set(newWalletRef, newWallet.toMap());

    // Record Income (Atomic)
    if (sourceWalletName != null && rolloverAmount > 0) {
      final newExpenseRef = newWalletRef.collection('expenses').doc();
      final incomeRecord = ExpenseModel(
        id: newExpenseRef.id,
        title: "Rollover from $sourceWalletName",
        amount: -rolloverAmount,
        category: "Others",
        date: now,
      );
      batch.set(newExpenseRef, incomeRecord.toMap());
    }

    await _safeCommit(batch);
    return newWalletRef.id;
  }

  // 2. TRANSFER FUNDS (ACID)
  Future<void> transferFunds({
    required String sourceWalletId,
    required String sourceWalletName,
    required String destWalletId,
    required String destWalletName,
    required double amount,
  }) async {
    final batch = _firestore.batch();
    final userRef = _firestore.collection('users').doc(userId);
    final now = DateTime.now();

    final sourceRef = userRef.collection('wallets').doc(sourceWalletId);
    final sourceExpRef = sourceRef.collection('expenses').doc();

    batch.update(sourceRef, {'currentBalance': FieldValue.increment(-amount)});
    batch.set(sourceExpRef, ExpenseModel(
      id: sourceExpRef.id,
      title: "Transfer to $destWalletName",
      amount: amount,
      category: "Transfer",
      date: now,
    ).toMap());

    final destRef = userRef.collection('wallets').doc(destWalletId);
    final destExpRef = destRef.collection('expenses').doc();

    batch.update(destRef, {
      'currentBalance': FieldValue.increment(amount),
      // Optional: 'monthlyBudget': FieldValue.increment(amount),
    });

    batch.set(destExpRef, ExpenseModel(
      id: destExpRef.id,
      title: "Transfer from $sourceWalletName",
      amount: -amount,
      category: "Transfer",
      date: now,
    ).toMap());

    await _safeCommit(batch);
  }

  // 3. GET WALLETS
  Stream<List<WalletModel>> getWallets() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .orderBy('year', descending: true)
        .orderBy('month', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
      return snapshot.docs.map((doc) => WalletModel.fromMap(doc.data())).toList();
    });
  }

  Stream<WalletModel> getWallet(String walletId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .doc(walletId)
        .snapshots(includeMetadataChanges: true)
        .map((doc) {
      if (!doc.exists) throw Exception("Wallet deleted");
      return WalletModel.fromMap(doc.data() as Map<String, dynamic>);
    });
  }

  // 5. UPDATE WALLET
  Future<void> updateWallet({
    required WalletModel oldWallet,
    required String newName,
    required double newBudget,
  }) async {
    final double difference = newBudget - oldWallet.monthlyBudget;
    final docRef = _firestore.collection('users').doc(userId).collection('wallets').doc(oldWallet.id);

    // Use .timeout logic for single update too
    try {
      await docRef.update({
        'name': newName,
        'monthlyBudget': newBudget,
        'currentBalance': FieldValue.increment(difference),
      }).timeout(_offlineTimeout);
    } on TimeoutException {
      // Queued
    }
  }

  // 6. DELETE WALLET
  Future<void> deleteWallet(String walletId) async {
    try {
      await _firestore.collection('users').doc(userId).collection('wallets').doc(walletId).delete().timeout(_offlineTimeout);
    } on TimeoutException {
      // Queued
    }
  }
}

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final firestore = ref.read(firebaseFirestoreProvider);
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) throw Exception("User must be logged in");
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