import 'package:flutter/material.dart';
import 'main.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase.from('products').select().order('stock');
      setState(() {
        _products = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.storage),
            SizedBox(width: 8),
            Text('Manajemen Stok'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text('Tidak ada produk'))
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.orange[50],
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${_products.where((p) => (p['stock'] ?? 0) < 10).length} produk dengan stok menipis',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return _buildStockCard(product);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStockCard(Map<String, dynamic> product) {
    final stock = product['stock'] ?? 0;
    final isLowStock = stock < 10;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isLowStock ? Colors.red[50] : Colors.green[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isLowStock ? Icons.warning : Icons.check_circle,
            color: isLowStock ? Colors.red : Colors.green,
            size: 30,
          ),
        ),
        title: Text(
          product['name'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Kategori: ${product['category'] ?? ''}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.inventory_2,
                  size: 16,
                  color: isLowStock ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  'Stok: $stock',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isLowStock ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () => _updateStock(product, -1),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.green),
              onPressed: () => _updateStock(product, 1),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStock(Map<String, dynamic> product, int change) async {
    final newStock = (product['stock'] ?? 0) + change;
    if (newStock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok tidak boleh negatif')),
      );
      return;
    }

    try {
      await supabase.from('products').update({'stock': newStock}).eq('id', product['id']);
      _loadProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengupdate stok: $e')),
      );
    }
  }
}