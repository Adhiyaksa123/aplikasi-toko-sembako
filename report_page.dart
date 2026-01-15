import 'package:flutter/material.dart';
import 'main.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  bool _isLoading = true;
  Map<String, dynamic> _reportData = {};
  String _selectedPeriod = 'Hari Ini';
  final List<String> _periods = ['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Tahun Ini'];

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    try {
      // Load transactions
      final transactions = await supabase.from('transactions').select();
      
      // Load products
      final products = await supabase.from('products').select();
      
      // Calculate report data
      final totalRevenue = transactions.fold<int>(0, (sum, t) => sum + (t['total_amount'] as int));
      final totalTransactions = transactions.length;
      final lowStockProducts = products.where((p) => (p['stock'] as int) < 10).length;
      final totalProducts = products.length;
      
      setState(() {
        _reportData = {
          'totalRevenue': totalRevenue,
          'totalTransactions': totalTransactions,
          'lowStockProducts': lowStockProducts,
          'totalProducts': totalProducts,
          'averageTransaction': totalTransactions > 0 ? (totalRevenue / totalTransactions).round() : 0,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat laporan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.assessment),
            SizedBox(width: 8),
            Text('Laporan & Analitik'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReportData,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export laporan dalam pengembangan')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReportData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period Selector
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _periods.map((period) {
                          final isSelected = _selectedPeriod == period;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(period),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() => _selectedPeriod = period);
                              },
                              selectedColor: const Color(0xFF4CAF50),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Revenue Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFF4CAF50), Colors.green[700]!],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Pendapatan',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              Icon(
                                Icons.trending_up,
                                color: Colors.white.withOpacity(0.8),
                                size: 28,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Rp ${_reportData['totalRevenue'] ?? 0}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedPeriod,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Stats Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _buildStatCard(
                          'Total Transaksi',
                          '${_reportData['totalTransactions'] ?? 0}',
                          Icons.receipt_long,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Rata-rata',
                          'Rp ${_reportData['averageTransaction'] ?? 0}',
                          Icons.analytics,
                          Colors.purple,
                        ),
                        _buildStatCard(
                          'Total Produk',
                          '${_reportData['totalProducts'] ?? 0}',
                          Icons.inventory_2,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          'Stok Menipis',
                          '${_reportData['lowStockProducts'] ?? 0}',
                          Icons.warning,
                          Colors.red,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Top Products Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Produk Terlaris',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Lihat Semua'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _buildTopProductsList(),
                    
                    const SizedBox(height: 24),
                    
                    // Sales Chart
                    const Text(
                      'Grafik Penjualan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _buildSalesChart(),
                    
                    const SizedBox(height: 24),
                    
                    // Quick Actions
                    const Text(
                      'Aksi Cepat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            'Export PDF',
                            Icons.picture_as_pdf,
                            Colors.red,
                            () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Export PDF dalam pengembangan')),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            'Export Excel',
                            Icons.table_chart,
                            Colors.green,
                            () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Export Excel dalam pengembangan')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsList() {
    final topProducts = [
      {'name': 'Buku Tulis 38 Lembar', 'sales': 45, 'revenue': 157500},
      {'name': 'Pensil 2B Faber', 'sales': 38, 'revenue': 95000},
      {'name': 'Beras 5kg', 'sales': 25, 'revenue': 1625000},
      {'name': 'Minyak Goreng 2L', 'sales': 20, 'revenue': 700000},
    ];

    return Column(
      children: topProducts.map((product) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green[100],
              child: const Icon(Icons.star, color: Color(0xFF4CAF50)),
            ),
            title: Text(
              product['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${product['sales']} terjual'),
            trailing: Text(
              'Rp ${product['revenue']}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSalesChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Penjualan 7 Hari Terakhir',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Icon(Icons.show_chart, color: Colors.green[700]),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildChartBar('Sen', 0.6),
                  _buildChartBar('Sel', 0.8),
                  _buildChartBar('Rab', 0.5),
                  _buildChartBar('Kam', 0.9),
                  _buildChartBar('Jum', 1.0),
                  _buildChartBar('Sab', 0.7),
                  _buildChartBar('Min', 0.4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartBar(String label, double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 30,
          height: 150 * height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[400]!, const Color(0xFF4CAF50)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}