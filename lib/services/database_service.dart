import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // USERS
  // ============================================================

  Future<void> createUser({
    required String uid,
    required String name,
    required String email,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // PRODUCTS
  // ============================================================

  Future<String> addProduct({
    required String name,
    required int price,
    required int stock,
    required String category,
  }) async {
    final document =
        await _firestore.collection('products').add({
      'name': name,
      'price': price,
      'stock': stock,
      'category': category,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  Future<void> updateProduct({
    required String productId,
    required String name,
    required int price,
    required int stock,
    required String category,
  }) async {
    await _firestore
        .collection('products')
        .doc(productId)
        .update({
      'name': name,
      'price': price,
      'stock': stock,
      'category': category,
    });
  }

  Future<void> deleteProduct(String productId) async {
    await _firestore
        .collection('products')
        .doc(productId)
        .delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> productsStream() {
    return _firestore
        .collection('products')
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }

  // ============================================================
  // CUSTOMERS
  // ============================================================

  Future<String> addCustomer({
    required String name,
    required String phone,
    required String address,
  }) async {
    final document =
        await _firestore.collection('customers').add({
      'name': name,
      'phone': phone,
      'address': address,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> customersStream() {
    return _firestore
        .collection('customers')
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }

  // ============================================================
  // TRANSACTIONS
  // ============================================================

  Future<String> createTransaction({
    required String invoice,
    required String customerId,
    required String customerName,
    required int total,
    required int payment,
    required int change,
    required String cashierId,
    required String cashierName,
    required List<Map<String, dynamic>> items,
  }) async {
    final document =
        await _firestore.collection('transactions').add({
      'invoice': invoice,
      'customerId': customerId,
      'customerName': customerName,
      'total': total,
      'payment': payment,
      'change': change,
      'cashierId': cashierId,
      'cashierName': cashierName,
      'items': items,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  // ============================================================
  // TRANSACTIONS STREAM
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> transactionsStream() {
    return _firestore
        .collection('transactions')
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }

  // ============================================================
  // PROCESS SALE
  // SIMPAN TRANSAKSI + KURANGI STOK
  // ============================================================

  Future<String> processSale({
    required String invoice,
    required String customerId,
    required String customerName,
    required int total,
    required int payment,
    required int change,
    required String cashierId,
    required String cashierName,
    required List<Map<String, dynamic>> items,
  }) async {
    if (items.isEmpty) {
      throw Exception(
        'Tidak ada produk dalam transaksi.',
      );
    }

    if (payment < total) {
      throw Exception(
        'Pembayaran kurang dari total transaksi.',
      );
    }

    final transactionRef =
        _firestore.collection('transactions').doc();

    await _firestore.runTransaction(
      (transaction) async {
        // ======================================================
        // 1. AMBIL SEMUA PRODUK
        // ======================================================

        final Map<String, DocumentSnapshot<
            Map<String, dynamic>>> productSnapshots = {};

        for (final item in items) {
          final productId =
              item['productId']?.toString();

          if (productId == null ||
              productId.isEmpty) {
            throw Exception(
              'ID produk tidak valid.',
            );
          }

          final productRef = _firestore
              .collection('products')
              .doc(productId);

          final productSnapshot =
              await transaction.get(productRef);

          if (!productSnapshot.exists) {
            throw Exception(
              'Produk dengan ID $productId tidak ditemukan.',
            );
          }

          productSnapshots[productId] =
              productSnapshot;
        }

        // ======================================================
        // 2. CEK STOK DAN UPDATE STOK
        // ======================================================

        for (final item in items) {
          final productId =
              item['productId'].toString();

          final productName =
              item['productName']?.toString() ??
                  'Produk';

          final quantity =
              (item['quantity'] as num?)?.toInt() ?? 0;

          if (quantity <= 0) {
            throw Exception(
              'Jumlah produk $productName tidak valid.',
            );
          }

          final productSnapshot =
              productSnapshots[productId]!;

          final data =
              productSnapshot.data();

          if (data == null) {
            throw Exception(
              'Data produk $productName tidak ditemukan.',
            );
          }

          final currentStock =
              (data['stock'] as num?)?.toInt() ?? 0;

          if (currentStock < quantity) {
            throw Exception(
              'Stok $productName tidak mencukupi. '
              'Stok tersedia: $currentStock.',
            );
          }

          final productRef = _firestore
              .collection('products')
              .doc(productId);

          final newStock =
              currentStock - quantity;

          transaction.update(
            productRef,
            {
              'stock': newStock,
            },
          );
        }

        // ======================================================
        // 3. SIMPAN TRANSAKSI
        // ======================================================

        transaction.set(
          transactionRef,
          {
            'invoice': invoice,
            'customerId': customerId,
            'customerName': customerName,
            'total': total,
            'payment': payment,
            'change': change,
            'cashierId': cashierId,
            'cashierName': cashierName,
            'items': items,
            'createdAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );

    return transactionRef.id;
  }
}