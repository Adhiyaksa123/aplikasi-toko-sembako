import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'product_page.dart';
import 'stock_page.dart';
import 'cashier_page.dart';
import 'settings_page.dart';
import 'customer_page.dart';
import 'main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final _searchController = TextEditingController();
  String _selectedTab = 'Semua';
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  
  // Kategori Sembako
  final List<String> _sembakoCategories = [
    'Beras',
    'Minyak Goreng',
    'Gula & Garam',
    'Mie Instan',
    'Teh & Kopi',
    'Telur',
    'Bumbu Dapur',
    'Sabun & Deterjen',
    'Minuman',
    'Toiletries',
    'Makanan Ringan',
    'Keperluan Bayi',
    'Kebutuhan Wanita',
  ];
  
  // Kategori Alat Rumah Tangga
  final List<String> _alatRTCategories = [
    'Peralatan RT',
  ];

  // Semua kategori untuk dropdown
  List<String> get _allCategories {
    return [..._sembakoCategories, ..._alatRTCategories];
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('products')
          .select()
          .order('name');
      
      setState(() {
        _products = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnackBar('Error memuat produk: $e', Colors.red);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    var filtered = _products;
    
    if (_selectedTab == 'Sembako') {
      filtered = filtered.where((p) => _sembakoCategories.contains(p['category'])).toList();
    } else if (_selectedTab == 'Alat Rumah Tangga') {
      filtered = filtered.where((p) => _alatRTCategories.contains(p['category'])).toList();
    }
    
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((p) {
        final name = p['name'].toString().toLowerCase();
        final barcode = (p['barcode'] ?? '').toString().toLowerCase();
        final search = _searchController.text.toLowerCase();
        return name.contains(search) || barcode.contains(search);
      }).toList();
    }
    
    return filtered;
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // CREATE - Tambah Produk Baru
  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final barcodeController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    String selectedCategory = _allCategories[0];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_box, color: Color(0xFF4CAF50)),
              SizedBox(width: 8),
              Text('Tambah Produk Baru'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Produk *',
                    prefixIcon: Icon(Icons.inventory),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'Barcode (opsional)',
                    prefixIcon: Icon(Icons.qr_code),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategori *',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                  items: _allCategories
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Harga *',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                    prefixText: 'Rp ',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stockController,
                  decoration: const InputDecoration(
                    labelText: 'Stok *',
                    prefixIcon: Icon(Icons.inventory_2),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    priceController.text.isEmpty ||
                    stockController.text.isEmpty) {
                  _showSnackBar('Mohon isi semua field yang wajib (*)', Colors.orange);
                  return;
                }

                try {
                  await supabase.from('products').insert({
                    'name': nameController.text.trim(),
                    'barcode': barcodeController.text.trim().isEmpty 
                        ? null 
                        : barcodeController.text.trim(),
                    'category': selectedCategory,
                    'price': int.parse(priceController.text),
                    'stock': int.parse(stockController.text),
                  });

                  Navigator.pop(context);
                  _showSnackBar('✅ Produk berhasil ditambahkan', Colors.green);
                  _loadProducts();
                } catch (e) {
                  _showSnackBar('Error menambah produk: $e', Colors.red);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
              ),
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // UPDATE - Edit Produk
  void _showEditProductDialog(Map<String, dynamic> product) {
    final nameController = TextEditingController(text: product['name']);
    final barcodeController = TextEditingController(text: product['barcode'] ?? '');
    final priceController = TextEditingController(text: product['price'].toString());
    final stockController = TextEditingController(text: product['stock'].toString());
    String selectedCategory = product['category'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit, color: Color(0xFF2196F3)),
              SizedBox(width: 8),
              Text('Edit Produk'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Produk *',
                    prefixIcon: Icon(Icons.inventory),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'Barcode (opsional)',
                    prefixIcon: Icon(Icons.qr_code),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategori *',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                  items: _allCategories
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Harga *',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                    prefixText: 'Rp ',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stockController,
                  decoration: const InputDecoration(
                    labelText: 'Stok *',
                    prefixIcon: Icon(Icons.inventory_2),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    priceController.text.isEmpty ||
                    stockController.text.isEmpty) {
                  _showSnackBar('Mohon isi semua field yang wajib (*)', Colors.orange);
                  return;
                }

                try {
                  await supabase.from('products').update({
                    'name': nameController.text.trim(),
                    'barcode': barcodeController.text.trim().isEmpty 
                        ? null 
                        : barcodeController.text.trim(),
                    'category': selectedCategory,
                    'price': int.parse(priceController.text),
                    'stock': int.parse(stockController.text),
                  }).eq('id', product['id']);

                  Navigator.pop(context);
                  _showSnackBar('✅ Produk berhasil diupdate', Colors.green);
                  _loadProducts();
                } catch (e) {
                  _showSnackBar('Error mengupdate produk: $e', Colors.red);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
              ),
              child: const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // DELETE - Hapus Produk
  void _showDeleteConfirmation(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Konfirmasi Hapus'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Apakah Anda yakin ingin menghapus produk ini?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Kategori: ${product['category']}'),
                  Text('Harga: Rp ${_formatNumber(product['price'])}'),
                  Text('Stok: ${product['stock']}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Data yang dihapus tidak dapat dikembalikan!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await supabase.from('products').delete().eq('id', product['id']);
                
                Navigator.pop(context);
                _showSnackBar('✅ Produk berhasil dihapus', Colors.green);
                _loadProducts();
              } catch (e) {
                Navigator.pop(context);
                _showSnackBar('Error menghapus produk: $e', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomePage(),
      const ProductPage(),
      const StockPage(),
      const CashierPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: const Color(0xFF4CAF50),
              elevation: 0,
              title: const Row(
                children: [
                  Icon(Icons.store, size: 24),
                  SizedBox(width: 8),
                  Text('Toko Sembako', style: TextStyle(fontSize: 20)),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.people),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CustomerPage()),
                    );
                  },
                  tooltip: 'Pelanggan',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadProducts,
                  tooltip: 'Refresh',
                ),
              ],
            )
          : null,
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Produk',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storage_outlined),
            activeIcon: Icon(Icons.storage),
            label: 'Stok',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale_outlined),
            activeIcon: Icon(Icons.point_of_sale),
            label: 'Kasir',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Setting',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _showAddProductDialog,
              backgroundColor: const Color(0xFF4CAF50),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Produk'),
            )
          : null,
    );
  }

  Widget _buildHomePage() {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Cari produk atau barcode...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF4CAF50)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Main Category Tabs
                Row(
                  children: [
                    Expanded(
                      child: _buildMainTabButton('Semua', Icons.apps),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMainTabButton('Sembako', Icons.shopping_basket),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMainTabButton('Alat Rumah Tangga', Icons.home_repair_service),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Product Count Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredProducts.length} Produk',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'Total: ${_products.length}',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          // Product List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Memuat produk...'),
                      ],
                    ),
                  )
                : _filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inbox, size: 80, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'Produk tidak ditemukan'
                                  : 'Belum ada produk',
                              style: const TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                            if (_searchController.text.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                child: const Text('Hapus Pencarian'),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          return _buildProductCard(_filteredProducts[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTabButton(String label, IconData icon) {
    final isSelected = _selectedTab == label;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final isLowStock = product['stock'] < 10;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.inventory_2,
            color: Color(0xFF4CAF50),
            size: 32,
          ),
        ),
        title: Text(
          product['name'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                product['category'],
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue[700],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  isLowStock ? Icons.warning_amber : Icons.check_circle,
                  size: 14,
                  color: isLowStock ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  'Stok: ${product['stock']}${isLowStock ? " ⚠️" : ""}',
                  style: TextStyle(
                    color: isLowStock ? Colors.orange : Colors.grey[600],
                    fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Rp ${_formatNumber(product['price'])}',
              style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            if (product['barcode'] != null && product['barcode'].toString().isNotEmpty)
              Text(
                'Barcode: ${product['barcode']}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF2196F3)),
              onPressed: () => _showEditProductDialog(product),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(product),
              tooltip: 'Hapus',
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(dynamic number) {
    if (number == null) return '0';
    final numStr = number.toString().split('.')[0];
    return numStr.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}