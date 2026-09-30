import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/database_service.dart';

class KasirPage extends StatefulWidget {
  const KasirPage({super.key});

  @override
  State<KasirPage> createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage> {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _paymentController = TextEditingController();

  String _searchQuery = '';

  final Map<String, CartItem> _cart = {};

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    _paymentController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _paymentController.dispose();
    super.dispose();
  }

  // ============================================================
  // FORMAT RUPIAH
  // ============================================================

  String _formatRupiah(int value) {
    final String number = value.toString();
    String result = '';

    for (int i = 0; i < number.length; i++) {
      final int position = number.length - i;

      result += number[i];

      if (position > 1 && position % 3 == 1) {
        result += '.';
      }
    }

    return 'Rp $result';
  }

  // ============================================================
  // TOTAL
  // ============================================================

  int get _total {
    int total = 0;

    for (final item in _cart.values) {
      total += item.price * item.quantity;
    }

    return total;
  }

  int get _totalItems {
    int total = 0;

    for (final item in _cart.values) {
      total += item.quantity;
    }

    return total;
  }

  int get _payment {
    return int.tryParse(
          _paymentController.text.replaceAll('.', '').trim(),
        ) ??
        0;
  }

  int get _change {
    if (_payment <= _total) {
      return 0;
    }

    return _payment - _total;
  }

  // ============================================================
  // TAMBAH PRODUK
  // ============================================================

  void _addToCart({
    required String productId,
    required String name,
    required int price,
    required int stock,
  }) {
    if (stock <= 0) {
      _showMessage('Stok produk habis.');
      return;
    }

    if (_cart.containsKey(productId)) {
      final item = _cart[productId]!;

      if (item.quantity >= stock) {
        _showMessage(
          'Jumlah ${item.name} tidak boleh melebihi stok.',
        );
        return;
      }

      setState(() {
        item.quantity++;
      });

      return;
    }

    setState(() {
      _cart[productId] = CartItem(
        productId: productId,
        name: name,
        price: price,
        quantity: 1,
        stock: stock,
      );
    });
  }

  // ============================================================
  // TAMBAH JUMLAH
  // ============================================================

  void _increaseQuantity(String productId) {
    final item = _cart[productId];

    if (item == null) return;

    if (item.quantity >= item.stock) {
      _showMessage(
        'Jumlah ${item.name} tidak boleh melebihi stok.',
      );
      return;
    }

    setState(() {
      item.quantity++;
    });
  }

  // ============================================================
  // KURANGI JUMLAH
  // ============================================================

  void _decreaseQuantity(String productId) {
    final item = _cart[productId];

    if (item == null) return;

    if (item.quantity <= 1) {
      setState(() {
        _cart.remove(productId);
      });
      return;
    }

    setState(() {
      item.quantity--;
    });
  }

  // ============================================================
  // HAPUS DARI KERANJANG
  // ============================================================

  void _removeFromCart(String productId) {
    setState(() {
      _cart.remove(productId);
    });
  }

  // ============================================================
  // KONFIRMASI TRANSAKSI
  // ============================================================

  Future<void> _processTransaction() async {
    if (_isProcessing) return;

    if (_cart.isEmpty) {
      _showMessage('Keranjang masih kosong.');
      return;
    }

    if (_payment < _total) {
      _showMessage(
        'Pembayaran kurang ${_formatRupiah(_total - _payment)}.',
      );
      return;
    }

    final user = _auth.currentUser;

    if (user == null) {
      _showMessage('Anda belum login.');
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Transaksi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total: ${_formatRupiah(_total)}'),
              const SizedBox(height: 8),
              Text('Bayar: ${_formatRupiah(_payment)}'),
              const SizedBox(height: 8),
              Text(
                'Kembalian: ${_formatRupiah(_change)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Lanjutkan transaksi?',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Proses'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final cashierName =
          user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : user.email ?? 'Kasir';

      final items = _cart.values.map((item) {
        return {
          'productId': item.productId,
          'productName': item.name,
          'price': item.price,
          'quantity': item.quantity,
          'subtotal': item.price * item.quantity,
        };
      }).toList();

      final invoice = _generateInvoice();

      await _databaseService.processSale(
        invoice: invoice,
        customerId: '',
        customerName: 'Umum',
        total: _total,
        payment: _payment,
        change: _change,
        cashierId: user.uid,
        cashierName: cashierName,
        items: items,
      );

      if (!mounted) return;

      setState(() {
        _cart.clear();
        _paymentController.clear();
      });

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
                SizedBox(width: 8),
                Text('Transaksi Berhasil'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invoice: $invoice'),
                const SizedBox(height: 12),
                Text(
                  'Total: ${_formatRupiah(_total)}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Bayar: ${_formatRupiah(_payment)}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Kembalian: ${_formatRupiah(_change)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Selesai'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Transaksi gagal: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // ============================================================
  // INVOICE
  // ============================================================

  String _generateInvoice() {
    final now = DateTime.now();

    String twoDigits(int value) {
      return value.toString().padLeft(2, '0');
    }

    return 'TRX'
        '${now.year}'
        '${twoDigits(now.month)}'
        '${twoDigits(now.day)}'
        '${twoDigits(now.hour)}'
        '${twoDigits(now.minute)}'
        '${twoDigits(now.second)}';
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // INPUT PEMBAYARAN
  // ============================================================

  Widget _buildPaymentSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatRupiah(_total),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _paymentController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Uang Pembayaran',
                hintText: 'Masukkan jumlah uang',
                prefixIcon: const Icon(
                  Icons.payments_outlined,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kembalian',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                Text(
                  _formatRupiah(_change),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _payment >= _total
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isProcessing || _cart.isEmpty
                    ? null
                    : _processTransaction,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.point_of_sale),
                label: Text(
                  _isProcessing
                      ? 'Memproses...'
                      : 'Bayar Sekarang',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // KERANJANG
  // ============================================================

  Widget _buildCart() {
    if (_cart.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Keranjang masih kosong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Pilih produk untuk memulai transaksi.',
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Keranjang ($_totalItems item)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _cart.clear();
                  });
                },
                child: const Text('Kosongkan'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              16,
              4,
              16,
              16,
            ),
            itemCount: _cart.length,
            itemBuilder: (context, index) {
              final item = _cart.values.elementAt(index);

              return Card(
                margin: const EdgeInsets.only(
                  bottom: 10,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.inventory_2,
                          color: Theme.of(context)
                              .colorScheme
                              .primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatRupiah(item.price),
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatRupiah(
                                item.price * item.quantity,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              _decreaseQuantity(
                                item.productId,
                              );
                            },
                            icon: const Icon(
                              Icons.remove_circle_outline,
                            ),
                          ),
                          Text(
                            item.quantity.toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              _increaseQuantity(
                                item.productId,
                              );
                            },
                            icon: const Icon(
                              Icons.add_circle_outline,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          _removeFromCart(item.productId);
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        _buildPaymentSection(),
      ],
    );
  }

  // ============================================================
  // PRODUK
  // ============================================================

  Widget _buildProducts() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _databaseService.productsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Gagal mengambil produk:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 70,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Belum ada produk',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Tambahkan produk terlebih dahulu.',
                ),
              ],
            ),
          );
        }

        final products = snapshot.data!.docs.where((doc) {
          final data = doc.data();

          final name = (data['name'] ?? '')
              .toString()
              .toLowerCase();

          final category = (data['category'] ?? '')
              .toString()
              .toLowerCase();

          return name.contains(_searchQuery) ||
              category.contains(_searchQuery);
        }).toList();

        if (products.isEmpty) {
          return const Center(
            child: Text(
              'Produk tidak ditemukan.',
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            20,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final document = products[index];
            final data = document.data();

            final String name =
                (data['name'] ?? '').toString();

            final int price =
                (data['price'] as num?)?.toInt() ?? 0;

            final int stock =
                (data['stock'] as num?)?.toInt() ?? 0;

            final String category =
                (data['category'] ?? '').toString();

            final bool isOutOfStock = stock <= 0;

            final cartItem = _cart[document.id];

            return Card(
              margin: const EdgeInsets.only(
                bottom: 10,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: isOutOfStock
                    ? null
                    : () {
                        _addToCart(
                          productId: document.id,
                          name: name,
                          price: price,
                          stock: stock,
                        );
                      },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: isOutOfStock
                              ? Colors.grey.shade200
                              : Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.inventory_2,
                          color: isOutOfStock
                              ? Colors.grey
                              : Theme.of(context)
                                  .colorScheme
                                  .primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              category,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatRupiah(price),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isOutOfStock
                                  ? 'Stok habis'
                                  : 'Stok: $stock',
                              style: TextStyle(
                                color: isOutOfStock
                                    ? Colors.red
                                    : stock <= 5
                                        ? Colors.orange
                                        : Colors.green,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (cartItem != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${cartItem.quantity}x',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Icon(
                          isOutOfStock
                              ? Icons.block
                              : Icons.add_circle,
                          color: isOutOfStock
                              ? Colors.grey
                              : Theme.of(context)
                                  .colorScheme
                                  .primary,
                          size: 30,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kasir',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: const Icon(
                  Icons.search,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 46,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(
                      left: 16,
                      right: 6,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                        ),
                        const SizedBox(width: 8),
                        const Text('Pilih Produk'),
                      ],
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(
                    right: 16,
                    left: 6,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_cart.length} produk',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _buildProducts(),
          ),
        ],
      ),
      bottomSheet: _cart.isNotEmpty
          ? null
          : null,
      floatingActionButton: _cart.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (context) {
                    return SizedBox(
                      height: MediaQuery.of(context)
                              .size
                              .height *
                          0.85,
                      child: _buildCart(),
                    );
                  },
                );
              },
              icon: const Icon(
                Icons.shopping_cart,
              ),
              label: Text(
                '${_totalItems} item • ${_formatRupiah(_total)}',
              ),
            )
          : null,
    );
  }
}

// ============================================================
// CART ITEM
// ============================================================

class CartItem {
  final String productId;
  final String name;
  final int price;
  final int stock;

  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.stock,
  });
}