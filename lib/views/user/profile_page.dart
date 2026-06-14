import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_register_page.dart';
import '../widgets/unila_logo_widget.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userDetails = authProvider.userDetails ?? {};
    
    final String name = userDetails['nama'] ?? 'Pengguna';
    final String email = userDetails['email'] ?? 'email@unila.ac.id';
    final String phone = userDetails['telepon'] ?? '-';
    final String role = userDetails['role'] == 'admin' ? 'Administrator' : 'Pengguna Umum';

    final primaryColor = const Color(0xFF1976D2);
    final darkColor = const Color(0xFF0D47A1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: darkColor,
        elevation: 0,
      ),
      body: Container(
        color: const Color(0xFFF5F7FA),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Header Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: const Color(0xFFE3F2FD),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        role,
                        style: TextStyle(
                          fontSize: 13,
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Detail Profile Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Akun',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const Divider(height: 24),
                      _buildProfileItem(Icons.email_outlined, 'Alamat Email', email),
                      const Divider(height: 24),
                      _buildProfileItem(Icons.phone_outlined, 'Nomor Telepon', phone),
                      const Divider(height: 24),
                      _buildProfileItem(Icons.security, 'Level Akses', role),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // App Credits Info
              Center(
                child: Column(
                  children: [
                    const UnilaLogoWidget(size: 44),
                    const SizedBox(height: 8),
                    Text(
                      'SiParku Unila v1.0.0',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Universitas Lampung',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Logout Button
              ElevatedButton.icon(
                onPressed: () async {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginRegisterPage()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('KELUAR AKUN', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String val) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1976D2), size: 22),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 2),
            Text(
              val,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        )
      ],
    );
  }
}
