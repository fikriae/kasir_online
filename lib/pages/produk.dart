import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/database_service.dart';

class ProdukPage extends StatefulWidget {
  const ProdukPage({super.key});

  @override
  State<ProdukPage> createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage> {
  final DatabaseService _databaseService = DatabaseService();

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // =========================
  // FORM TAMBAH / EDIT PRODUK
  // =========================

  void _showProductForm({
    String? productId,
    String? currentName,
    int? currentPrice,
    int? currentStock,
    String? currentCategory,
  }) {
    final nameController =
        TextEditingController(text: currentName ?? '');

    final priceController = TextEditingController(
      text: currentPrice?.toString() ?? '',
    );

    final stockController = TextEditingController(
      text: currentStock?.toString() ?? '',
    );

    final categoryController =
        TextEditingController(text: currentCategory ?? '');

    final bool isEdit = productId != null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            isEdit ? 'Edit Produk' : 'Tambah Produk',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nama Produk',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Harga',
                    prefixIcon: Icon(Icons.payments_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Stok',
                    prefixIcon: Icon(Icons.inventory_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    prefixIcon: Icon(Icons.category_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),

            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final price =
                    int.tryParse(priceController.text.trim());
                final stock =
                    int.tryParse(stockController.text.trim());
                final category =
                    categoryController.text.trim();

                if (name.isEmpty ||
                    price == null ||
                    stock == null ||
                    category.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Semua data produk harus diisi dengan benar.',
                      ),
                    ),
                  );
                  return;
                }

                try {
                  if (isEdit) {
                    await _databaseService.updateProduct(
                      productId: productId,
                      name: name,
                      price: price,
                      stock: stock,
                      category: category,
                    );
                  } else {
                    await _databaseService.addProduct(
                      name: name,
                      price: price,
                      stock: stock,
                      category: category,
                    );
                  }

                  if (!context.mounted) return;

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEdit
                            ? 'Produk berhasil diperbarui.'
                            : 'Produk berhasil ditambahkan.',
                      ),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Terjadi kesalahan: $e',
                      ),
                    ),
                  );
                }
              },
              child: Text(
                isEdit ? 'Simpan' : 'Tambah',
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // HAPUS PRODUK
  // =========================

  void _deleteProduct(
    String productId,
    String productName,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Produk'),
          content: Text(
            'Apakah Anda yakin ingin menghapus "$productName"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  await _databaseService.deleteProduct(productId);

                  if (!context.mounted) return;

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Produk berhasil dihapus.',
                      ),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Gagal menghapus produk: $e',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // FORMAT RUPIAH
  // =========================

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Produk',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          // =========================
          // SEARCH
          // =========================

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
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // =========================
          // LIST PRODUK
          // =========================

          Expanded(
            child: StreamBuilder<
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
                        'Terjadi kesalahan:\n${snapshot.error}',
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
                          'Tambahkan produk pertama Anda.',
                        ),
                      ],
                    ),
                  );
                }

                final products = snapshot.data!.docs.where((doc) {
                  final data = doc.data();

                  final name =
                      (data['name'] ?? '')
                          .toString()
                          .toLowerCase();

                  final category =
                      (data['category'] ?? '')
                          .toString()
                          .toLowerCase();

                  return name.contains(_searchQuery) ||
                      category.contains(_searchQuery);
                }).toList();

                if (products.isEmpty) {
                  return const Center(
                    child: Text(
                      'Produk tidak ditemukan.',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    100,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final document = products[index];

                    final data = document.data();

                    final String name =
                        (data['name'] ?? '').toString();

                    final int price =
                        (data['price'] ?? 0) as int;

                    final int stock =
                        (data['stock'] ?? 0) as int;

                    final String category =
                        (data['category'] ?? '').toString();

                    return Card(
                      margin: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.inventory_2,
                                color: Theme.of(context)
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
                                      fontWeight:
                                          FontWeight.bold,
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
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    'Stok: $stock',
                                    style: TextStyle(
                                      color: stock <= 5
                                          ? Colors.red
                                          : Colors.green,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showProductForm(
                                    productId: document.id,
                                    currentName: name,
                                    currentPrice: price,
                                    currentStock: stock,
                                    currentCategory:
                                        category,
                                  );
                                }

                                if (value == 'delete') {
                                  _deleteProduct(
                                    document.id,
                                    name,
                                  );
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Hapus'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // =========================
      // TAMBAH PRODUK
      // =========================

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showProductForm();
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      ),
    );
  }
}