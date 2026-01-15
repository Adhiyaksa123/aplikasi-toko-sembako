import 'package:flutter/material.dart';
import 'main.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _userName = 'User';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email ?? '';
        _userName = user.userMetadata?['name'] ?? 'User';
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
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
            Icon(Icons.settings),
            SizedBox(width: 8),
            Text('Pengaturan'),
          ],
        ),
      ),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF4CAF50), Colors.green[700]!],
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userEmail,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          _buildSection('Akun'),
          _buildTile(
            icon: Icons.person,
            title: 'Profil',
            subtitle: 'Edit informasi profil',
            onTap: () {},
          ),
          _buildTile(
            icon: Icons.lock,
            title: 'Ubah Password',
            subtitle: 'Ganti password akun',
            onTap: () {},
          ),
          
          _buildSection('Toko'),
          _buildTile(
            icon: Icons.store,
            title: 'Informasi Toko',
            subtitle: 'Detail toko Anda',
            onTap: () {},
          ),
          _buildTile(
            icon: Icons.receipt_long,
            title: 'Riwayat Transaksi',
            subtitle: 'Lihat semua transaksi',
            onTap: () {},
          ),
          _buildTile(
            icon: Icons.assessment,
            title: 'Laporan',
            subtitle: 'Laporan penjualan & stok',
            onTap: () {},
          ),
          
          _buildSection('Aplikasi'),
          _buildTile(
            icon: Icons.notifications,
            title: 'Notifikasi',
            subtitle: 'Pengaturan notifikasi',
            onTap: () {},
          ),
          _buildTile(
            icon: Icons.palette,
            title: 'Tema',
            subtitle: 'Ubah tampilan aplikasi',
            onTap: () {},
          ),
          _buildTile(
            icon: Icons.language,
            title: 'Bahasa',
            subtitle: 'Indonesia',
            onTap: () {},
          ),
          
          _buildSection('Lainnya'),
          _buildTile(
            icon: Icons.help,
            title: 'Bantuan',
            subtitle: 'FAQ & Support',
            onTap: () {},
          ),
          _buildTile(
            icon: Icons.info,
            title: 'Tentang',
            subtitle: 'Versi 1.0.0',
            onTap: () {},
          ),
          _buildTile(
            icon: Icons.policy,
            title: 'Kebijakan Privasi',
            subtitle: 'Baca kebijakan privasi',
            onTap: () {},
          ),
          
          const SizedBox(height: 16),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          Center(
            child: Column(
              children: [
                const Text(
                  'Toko Sembako',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Powered by Supabase',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF4CAF50)),
      ),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}