import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/parking_provider.dart';
import '../auth/login_register_page.dart';
import '../widgets/unila_logo_widget.dart';
import './zone_crud_page.dart';
import './slot_crud_page.dart';
import './officer_crud_page.dart';
import './report_management_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedMenuIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final darkColor = const Color(0xFF0D47A1);

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;

    // List of menu pages
    final List<Widget> pages = [
      _buildDashboardHome(isMobile),
      const ZoneCrudPage(),
      const SlotCrudPage(),
      const OfficerCrudPage(),
      const ReportManagementPage(),
    ];

    final List<String> menuTitles = [
      'Dashboard Ringkasan',
      'Zona Parkir',
      'Slot Parkir',
      'Petugas Parkir',
      'Laporan Pengguna',
    ];

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              title: Text(
                menuTitles[_selectedMenuIndex],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              backgroundColor: darkColor,
              iconTheme: const IconThemeData(color: Colors.white),
            )
          : null,
      drawer: isMobile
          ? Drawer(
              child: _buildSidebarContent(
                authProvider,
                darkColor,
                isDrawer: true,
              ),
            )
          : null,
      body: isMobile
          ? pages[_selectedMenuIndex]
          : Row(
              children: [
                // Sidebar (Biru Gelap)
                Container(
                  width: 240,
                  color: darkColor,
                  child: _buildSidebarContent(
                    authProvider,
                    darkColor,
                    isDrawer: false,
                  ),
                ),

                // Main Content Area (Kanan)
                Expanded(
                  child: Container(
                    color: const Color(0xFFF5F7FA),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Content Header
                        Container(
                          padding: const EdgeInsets.all(20),
                          color: Colors.white,
                          child: SafeArea(
                            bottom: false,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  menuTitles[_selectedMenuIndex],
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: darkColor,
                                  ),
                                ),
                                Text(
                                  'Halo, ${authProvider.userDetails?['nama'] ?? 'Admin'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1),

                        // Dynamic Body View
                        Expanded(child: pages[_selectedMenuIndex]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSidebarContent(
    AuthProvider authProvider,
    Color darkColor, {
    required bool isDrawer,
  }) {
    return Container(
      color: darkColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo & Title
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const UnilaLogoWidget(size: 60, isWhite: true),
                  const SizedBox(height: 12),
                  const Text(
                    'SiParku Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'Sistem Parkir Terpadu',
                    style: TextStyle(color: Colors.blue[100], fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: Colors.white24, height: 1),

          // Navigation Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildMenuItem(0, Icons.dashboard, 'Dashboard', isDrawer),
                _buildMenuItem(1, Icons.layers, 'Zona Parkir', isDrawer),
                _buildMenuItem(2, Icons.local_parking, 'Slot Parkir', isDrawer),
                _buildMenuItem(3, Icons.people, 'Petugas Parkir', isDrawer),
                _buildMenuItem(4, Icons.feedback, 'Laporan Pengguna', isDrawer),
              ],
            ),
          ),

          // Logout Menu
          const Divider(color: Colors.white24, height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white70),
            title: const Text(
              'Keluar Panel',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginRegisterPage(),
                  ),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String title, bool isDrawer) {
    bool isSelected = _selectedMenuIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.white : Colors.white70),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedMenuIndex = index;
          });
          if (isDrawer) {
            Navigator.pop(context); // Close the drawer on tap
          }
        },
      ),
    );
  }

  // Dashboard ringkasan stats
  Widget _buildDashboardHome(bool isMobile) {
    final parkingProvider = Provider.of<ParkingProvider>(context);
    final zonesCount = parkingProvider.zones.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ikhtisar Sistem Real-Time',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),

          // Grid Stats Cards
          GridView.count(
            crossAxisCount: isMobile ? 1 : 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: isMobile ? 3.0 : 2.2,
            children: [
              _buildStatCard(
                'TOTAL ZONA',
                '$zonesCount',
                Icons.layers,
                Colors.blue,
              ),
              _buildStatCard(
                'OCCUPANCY RATE',
                '32%',
                Icons.pie_chart,
                Colors.orange,
              ),
              _buildStatCard(
                'PETUGAS AKTIF',
                '3 Orang',
                Icons.supervisor_account,
                Colors.green,
              ),
              _buildStatCard(
                'LAPORAN ADUAN',
                '1 Pending',
                Icons.warning_amber,
                Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  val,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}
