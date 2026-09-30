import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'produk.dart';
import 'kasir.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _currentIndex = 0;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // NAVIGASI
  // ============================================================

  void _goToDashboard() {
    setState(() {
      _currentIndex = 0;
    });
  }

  void _goToProduk() {
    setState(() {
      _currentIndex = 1;
    });
  }

  void _goToKasir() {
    setState(() {
      _currentIndex = 2;
    });
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
  // USER
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots();
  }

  // ============================================================
  // JUMLAH PRODUK
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> _productsStream() {
    return _firestore
        .collection('products')
        .snapshots();
  }

  // ============================================================
  // JUMLAH PELANGGAN
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> _customersStream() {
    return _firestore
        .collection('customers')
        .snapshots();
  }

  // ============================================================
  // TRANSAKSI HARI INI
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _todayTransactionsStream() {
    final now = DateTime.now();

    final startOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final endOfDay = DateTime(
      now.year,
      now.month,
      now.day + 1,
    );

    return _firestore
        .collection('transactions')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where(
          'createdAt',
          isLessThan: Timestamp.fromDate(endOfDay),
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }

  // ============================================================
  // TOTAL PENJUALAN HARI INI
  // ============================================================

  int _calculateTodaySales(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    int total = 0;

    for (final document in snapshot.docs) {
      final data = document.data();
      final value = data['total'];

      if (value is int) {
        total += value;
      } else if (value is double) {
        total += value.toInt();
      } else if (value is num) {
        total += value.toInt();
      }
    }

    return total;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: _currentIndex == 0
          ? AppBar(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'Kasir Online',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Belum ada notifikasi.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.notifications_none,
                  ),
                ),
              ],
            )
          : null,

      // ========================================================
      // BODY
      // ========================================================

      body: _currentIndex == 0
          ? _buildDashboard()
          : _currentIndex == 1
              ? const ProdukPage()
              : _currentIndex == 2
                  ? const KasirPage()
                  : _buildDashboard(),

      // ========================================================
      // BOTTOM NAVIGATION
      // ========================================================

      bottomNavigationBar: Container(
        height: 78,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // ==================================================
              // DASHBOARD
              // ==================================================

              Expanded(
                child: _BottomNavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'Dashboard',
                  selected: _currentIndex == 0,
                  enabled: true,
                  onTap: _goToDashboard,
                ),
              ),

              // ==================================================
              // PRODUK
              // ==================================================

              Expanded(
                child: _BottomNavItem(
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2,
                  label: 'Produk',
                  selected: _currentIndex == 1,
                  enabled: true,
                  onTap: _goToProduk,
                ),
              ),

              // ==================================================
              // KASIR
              // ==================================================

              Expanded(
                child: _BottomNavItem(
                  icon: Icons.point_of_sale_outlined,
                  activeIcon: Icons.point_of_sale,
                  label: 'Kasir',
                  selected: _currentIndex == 2,
                  enabled: true,
                  onTap: _goToKasir,
                  isMainMenu: true,
                ),
              ),

              // ==================================================
              // RIWAYAT
              // ==================================================

              Expanded(
                child: _BottomNavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  label: 'Riwayat',
                  selected: false,
                  enabled: false,
                  onTap: null,
                ),
              ),

              // ==================================================
              // PROFIL
              // ==================================================

              Expanded(
                child: _BottomNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profil',
                  selected: false,
                  enabled: false,
                  onTap: null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DASHBOARD CONTENT
  // ============================================================

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // WELCOME
            // ==================================================

            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _userStream(),
              builder: (context, snapshot) {
                String name = 'Pengguna';

                if (snapshot.hasData &&
                    snapshot.data!.exists) {
                  final data = snapshot.data!.data();

                  if (data != null &&
                      data['name'] != null &&
                      data['name']
                          .toString()
                          .trim()
                          .isNotEmpty) {
                    name = data['name'].toString();
                  }
                }

                return Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selamat Datang 👋',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Dashboard Kasir',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // ==================================================
            // STATISTICS
            // ==================================================

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _todayTransactionsStream(),
              builder: (
                context,
                transactionSnapshot,
              ) {
                final int transactionCount =
                    transactionSnapshot.hasData
                        ? transactionSnapshot
                            .data!
                            .docs
                            .length
                        : 0;

                final int todaySales =
                    transactionSnapshot.hasData
                        ? _calculateTodaySales(
                            transactionSnapshot.data!,
                          )
                        : 0;

                return StreamBuilder<
                    QuerySnapshot<Map<String, dynamic>>>(
                  stream: _productsStream(),
                  builder: (
                    context,
                    productSnapshot,
                  ) {
                    final int productCount =
                        productSnapshot.hasData
                            ? productSnapshot
                                .data!
                                .docs
                                .length
                            : 0;

                    return StreamBuilder<
                        QuerySnapshot<Map<String, dynamic>>>(
                      stream: _customersStream(),
                      builder: (
                        context,
                        customerSnapshot,
                      ) {
                        final int customerCount =
                            customerSnapshot.hasData
                                ? customerSnapshot
                                    .data!
                                    .docs
                                    .length
                                : 0;

                        return GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.45,
                          children: [
                            StatCard(
                              title: 'Penjualan Hari Ini',
                              value: _formatRupiah(
                                todaySales,
                              ),
                              icon: Icons.trending_up,
                              iconColor:
                                  const Color(0xFF2563EB),
                              backgroundColor:
                                  const Color(0xFFEFF6FF),
                            ),
                            StatCard(
                              title: 'Transaksi',
                              value:
                                  transactionCount.toString(),
                              icon: Icons.receipt_long,
                              iconColor:
                                  const Color(0xFF16A34A),
                              backgroundColor:
                                  const Color(0xFFF0FDF4),
                            ),
                            StatCard(
                              title: 'Produk',
                              value:
                                  productCount.toString(),
                              icon: Icons.inventory_2,
                              iconColor:
                                  const Color(0xFFF59E0B),
                              backgroundColor:
                                  const Color(0xFFFFFBEB),
                            ),
                            StatCard(
                              title: 'Pelanggan',
                              value:
                                  customerCount.toString(),
                              icon: Icons.people,
                              iconColor:
                                  const Color(0xFF9333EA),
                              backgroundColor:
                                  const Color(0xFFFAF5FF),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 28),

            // ==================================================
            // TRANSAKSI TERBARU
            // ==================================================

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transaksi Terbaru',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),

                // Riwayat belum dibuat
                const Text(
                  'Riwayat',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ==================================================
            // TRANSAKSI FIRESTORE
            // ==================================================

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('transactions')
                  .orderBy(
                    'createdAt',
                    descending: true,
                  )
                  .limit(5)
                  .snapshots(),
              builder: (
                context,
                snapshot,
              ) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Belum dapat mengambil data transaksi.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 50,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Belum ada transaksi.',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: snapshot.data!.docs.map(
                    (document) {
                      final data = document.data();

                      final String invoice =
                          (data['invoice'] ??
                                  document.id)
                              .toString();

                      final String customer =
                          (data['customerName'] ??
                                  'Pelanggan Umum')
                              .toString();

                      final int total =
                          data['total'] is int
                              ? data['total'] as int
                              : data['total'] is double
                                  ? (data['total']
                                          as double)
                                      .toInt()
                                  : data['total'] is num
                                      ? (data['total']
                                              as num)
                                          .toInt()
                                      : 0;

                      String time = '-';

                      if (data['createdAt']
                          is Timestamp) {
                        final timestamp =
                            data['createdAt'] as Timestamp;

                        final date =
                            timestamp.toDate();

                        final hour = date.hour
                            .toString()
                            .padLeft(2, '0');

                        final minute = date.minute
                            .toString()
                            .padLeft(2, '0');

                        time = '$hour:$minute';
                      }

                      return TransactionItem(
                        transactionId: invoice,
                        customer: customer,
                        amount:
                            _formatRupiah(total),
                        time: time,
                      );
                    },
                  ).toList(),
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// BOTTOM NAVIGATION ITEM
// ============================================================

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final bool enabled;
  final bool isMainMenu;
  final VoidCallback? onTap;

  const _BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.isMainMenu = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;

    if (!enabled) {
      color = Colors.grey.shade400;
    } else if (selected) {
      color = const Color(0xFF2563EB);
    } else {
      color = Colors.grey;
    }

    return InkWell(
      onTap: enabled ? onTap : null,
      child: SizedBox(
        height: 78,
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            if (isMainMenu)
              Container(
                width: selected ? 46 : 42,
                height: selected ? 46 : 42,
                decoration: BoxDecoration(
                  color: !enabled
                      ? const Color(0xFFF1F1F1)
                      : selected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                  boxShadow: selected
                      ? const [
                          BoxShadow(
                            color: Color(0x332563EB),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  selected ? activeIcon : icon,
                  color: !enabled
                      ? Colors.grey.shade400
                      : selected
                          ? Colors.white
                          : const Color(0xFF2563EB),
                  size: 23,
                ),
              )
            else
              Icon(
                selected ? activeIcon : icon,
                color: color,
                size: 23,
              ),

            const SizedBox(height: 4),

            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STAT CARD
// ============================================================

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius:
                  BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TRANSACTION ITEM
// ============================================================

class TransactionItem extends StatelessWidget {
  final String transactionId;
  final String customer;
  final String amount;
  final String time;

  const TransactionItem({
    super.key,
    required this.transactionId,
    required this.customer,
    required this.amount,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: Color(0xFF2563EB),
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  transactionId,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  customer,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.bold,
                  color: Color(0xFF16A34A),
                ),
              ),

              const SizedBox(height: 4),

              Text(
                time,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}