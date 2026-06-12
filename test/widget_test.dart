import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ptirecycle/main.dart';

void main() {
  testWidgets('App launches and shows login page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RecycleConnectApp());

    // Verify that login page is shown with new text
    expect(find.text('Selamat Datang'), findsOneWidget);
    expect(find.text('Masuk ke akun Anda'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Daftar'), findsOneWidget);
  });

  testWidgets('Navigate to register page', (WidgetTester tester) async {
    await tester.pumpWidget(const RecycleConnectApp());

    // Tap the register text and trigger a frame
    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();

    // Verify that register page is shown with new text
    expect(find.text('Buat Akun Baru'), findsOneWidget);
    expect(find.text('Isi data diri Anda'), findsOneWidget);
    expect(find.text('Nama Lengkap'), findsOneWidget);
    expect(find.text('Konfirmasi Password'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });

  testWidgets('Login and navigate to dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const RecycleConnectApp());

    // Tap login button and trigger a frame
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    // Verify that dashboard is shown with new text
    expect(find.text('Selamat Datang,'), findsOneWidget);
    expect(find.text('Kelompok 5'), findsOneWidget);
    expect(find.text('Total Saldo'), findsOneWidget);
    expect(find.text('Layanan Cepat'), findsOneWidget);
  });

  testWidgets('Bottom navigation works correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const RecycleConnectApp());

    // Login first
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    // Tap on Prices tab
    await tester.tap(find.byIcon(Icons.attach_money_outlined));
    await tester.pumpAndSettle();

    // Verify Prices page is shown
    expect(find.text('Harga Sampah Terkini'), findsOneWidget);
    expect(find.text('PLASTIK'), findsOneWidget);
    expect(find.text('KERTAS'), findsOneWidget);

    // Tap on Upload tab
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    // Verify Upload page is shown
    expect(find.text('Upload Sampah'), findsOneWidget);
    expect(find.text('Foto Sampah'), findsOneWidget);
    expect(find.text('Detail Sampah'), findsOneWidget);

    // Tap on History tab
    await tester.tap(find.byIcon(Icons.history_outlined));
    await tester.pumpAndSettle();

    // Verify History page is shown
    expect(find.text('Riwayat Transaksi'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);

    // Tap on Profile tab
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    // Verify Profile page is shown
    expect(find.text('Kelompok 5'), findsOneWidget);
    expect(find.text('Edit Profil'), findsOneWidget);
    expect(find.text('Metode Penarikan'), findsOneWidget);
  });

  testWidgets('Upload page functionality', (WidgetTester tester) async {
    await tester.pumpWidget(const RecycleConnectApp());

    // Login and navigate to upload page
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    // Verify upload page elements
    expect(find.text('Upload Sampah'), findsOneWidget);
    expect(find.text('Foto Sampah'), findsOneWidget);
    expect(find.text('Tap untuk mengambil foto'), findsOneWidget);
    expect(find.text('Detail Sampah'), findsOneWidget);
    expect(find.text('Jenis Sampah'), findsOneWidget);
    expect(find.text('Berat (kg)'), findsOneWidget);
    expect(find.text('Lokasi Penjemputan'), findsOneWidget);

    // Test dropdown functionality
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();

    // Should see dropdown items
    expect(find.text('Plastik PET'), findsNWidgets(2)); // One in dropdown, one as selected value
    expect(find.text('Plastik HDPE'), findsOneWidget);
    expect(find.text('Kertas Koran'), findsOneWidget);
  });

  testWidgets('Profile page functionality', (WidgetTester tester) async {
    await tester.pumpWidget(const RecycleConnectApp());

    // Login and navigate to profile page
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    // Verify profile page elements
    expect(find.text('Kelompok 5'), findsNWidgets(2)); // One in header, one in profile
    expect(find.text('kelompok5@email.com'), findsOneWidget);
    expect(find.text('Edit Profil'), findsOneWidget);
    expect(find.text('Metode Penarikan'), findsOneWidget);
    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.text('Bantuan & FAQ'), findsOneWidget);
    expect(find.text('Kebijakan Privasi'), findsOneWidget);
    expect(find.text('Tentang Aplikasi'), findsOneWidget);
    expect(find.text('Keluar'), findsOneWidget);

    // Test edit profile dialog
    await tester.tap(find.text('Edit Profil'));
    await tester.pumpAndSettle();
    
    // Verify edit profile dialog appears
    expect(find.text('Edit Profil'), findsOneWidget);
    expect(find.text('Nama Lengkap'), findsOneWidget);
    expect(find.text('Simpan'), findsOneWidget);

    // Close the dialog
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
  });

  testWidgets('Prices page displays categories correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const RecycleConnectApp());

    // Login and navigate to prices page
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.attach_money_outlined));
    await tester.pumpAndSettle();

    // Verify categories and items
    expect(find.text('PLASTIK'), findsOneWidget);
    expect(find.text('KERTAS'), findsOneWidget);
    expect(find.text('LOGAM & LAINNYA'), findsOneWidget);
    
    expect(find.text('Plastik PET'), findsOneWidget);
    expect(find.text('Kertas Koran'), findsOneWidget);
    expect(find.text('Kaleng Aluminium'), findsOneWidget);
    expect(find.text('Elektronik'), findsOneWidget);

    // Verify price displays
    expect(find.text('Rp 3.500/kg'), findsOneWidget);
    expect(find.text('Rp 2.000/kg'), findsOneWidget);
    expect(find.text('Rp 4.500/kg'), findsOneWidget);
    expect(find.text('Rp 5.000/kg'), findsOneWidget);
  });

  testWidgets('History page filter functionality', (WidgetTester tester) async {
    await tester.pumpWidget(const RecycleConnectApp());

    // Login and navigate to history page
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.history_outlined));
    await tester.pumpAndSettle();

    // Verify initial state shows all transactions
    expect(find.text('TRX001'), findsOneWidget);
    expect(find.text('TRX002'), findsOneWidget);
    expect(find.text('TRX003'), findsOneWidget);

    // Filter by completed transactions
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();
    
    // Should only show completed transactions
    expect(find.text('TRX001'), findsOneWidget);
    expect(find.text('TRX003'), findsOneWidget);
    expect(find.text('TRX006'), findsOneWidget);
    expect(find.text('TRX002'), findsNothing); // This should be filtered out

    // Filter by in-progress transactions
    await tester.tap(find.text('Proses'));
    await tester.pumpAndSettle();
    
    // Should only show in-progress transactions
    expect(find.text('TRX002'), findsOneWidget);
    expect(find.text('TRX005'), findsOneWidget);
    expect(find.text('TRX001'), findsNothing); // This should be filtered out

    // Filter by cancelled transactions
    await tester.tap(find.text('Dibatalkan'));
    await tester.pumpAndSettle();
    
    // Should only show cancelled transactions
    expect(find.text('TRX004'), findsOneWidget);
    expect(find.text('TRX001'), findsNothing); // This should be filtered out

    // Go back to all transactions
    await tester.tap(find.text('Semua'));
    await tester.pumpAndSettle();
    
    // Should show all transactions again
    expect(find.text('TRX001'), findsOneWidget);
    expect(find.text('TRX002'), findsOneWidget);
    expect(find.text('TRX003'), findsOneWidget);
  });

  testWidgets('Home page service cards navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const RecycleConnectApp());

    // Login first
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    // Test navigation from service cards
    await tester.tap(find.text('Upload'));
    await tester.pumpAndSettle();
    expect(find.text('Upload Sampah'), findsOneWidget);

    // Go back to home using bottom navigation
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Harga'));
    await tester.pumpAndSettle();
    expect(find.text('Harga Sampah Terkini'), findsOneWidget);

    // Go back to home using bottom navigation
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();
    expect(find.text('Riwayat Transaksi'), findsOneWidget);

    // Go back to home using bottom navigation
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
  });

  testWidgets('Profile page logout functionality', (WidgetTester tester) async {
    await tester.pumpWidget(const RecycleConnectApp());

    // Login and navigate to profile page
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    // Tap logout
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();

    // Confirm logout dialog - tap the second "Keluar" button (in dialog)
    final logoutButtons = find.text('Keluar');
    expect(logoutButtons, findsNWidgets(2));
    await tester.tap(logoutButtons.last);
    await tester.pumpAndSettle();

    // Verify we're back to login page
    expect(find.text('Selamat Datang'), findsOneWidget);
    expect(find.text('Masuk ke akun Anda'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });

  testWidgets('Register page navigation back to login', (WidgetTester tester) async {
    await tester.pumpWidget(const RecycleConnectApp());

    // Go to register page
    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();

    // Tap back to login using the back arrow
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Verify we're back to login page
    expect(find.text('Selamat Datang'), findsOneWidget);
    expect(find.text('Masuk ke akun Anda'), findsOneWidget);
  });

  testWidgets('Upload page form validation', (WidgetTester tester) async {
    await tester.pumpWidget(const RecycleConnectApp());

    // Login and navigate to upload page
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    // Try to submit without photo
    await tester.tap(find.text('Kirim Permintaan Penjualan'));
    await tester.pump();

    // Should show snackbar error for missing photo
    expect(find.text('Harap ambil foto sampah terlebih dahulu'), findsOneWidget);

    // Tap photo area to "upload" photo
    await tester.tap(find.text('Tap untuk mengambil foto'));
    await tester.pumpAndSettle();

    // Try to submit without weight
    await tester.tap(find.text('Kirim Permintaan Penjualan'));
    await tester.pump();

    // Should show snackbar error for missing weight
    expect(find.text('Harap masukkan berat sampah'), findsOneWidget);

    // Enter weight - find the weight text field (second text field)
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(1), '5');
    await tester.pump();

    // Now should be able to submit successfully
    await tester.tap(find.text('Kirim Permintaan Penjualan'));
    await tester.pump();

    // Should show success snackbar and navigate back
    expect(find.text('Permintaan penjualan berhasil dikirim!'), findsOneWidget);
  });

  testWidgets('Home page balance card and navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const RecycleConnectApp());

    // Login first
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    // Verify balance card elements
    expect(find.text('Rp 2.450.000'), findsOneWidget);
    expect(find.text('Tarik Saldo'), findsOneWidget);

    // Test profile navigation from avatar
    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();
    expect(find.text('Kelompok 5'), findsNWidgets(2));

    // Go back to home using bottom navigation
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
  });

  testWidgets('New pages navigation from home', (WidgetTester tester) async {
    await tester.pumpWidget(const RecycleConnectApp());

    // Login first
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    // Test Jemput navigation
    await tester.tap(find.text('Jemput'));
    await tester.pumpAndSettle();
    expect(find.text('Jadwal Penjemputan'), findsOneWidget);
    
    // Go back to home
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Test Statistik navigation
    await tester.tap(find.text('Statistik'));
    await tester.pumpAndSettle();
    expect(find.text('Statistik'), findsOneWidget);
    
    // Go back to home
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Test Notif navigation
    await tester.tap(find.text('Notif'));
    await tester.pumpAndSettle();
    expect(find.text('Notifikasi'), findsOneWidget);
    
    // Go back to home
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Test Bantuan navigation
    await tester.tap(find.text('Bantuan'));
    await tester.pumpAndSettle();
    expect(find.text('Bantuan & FAQ'), findsOneWidget);
    
    // Go back to home
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
  });

  testWidgets('Withdrawal page functionality', (WidgetTester tester) async {
    await tester.pumpWidget(const RecycleConnectApp());

    // Login first
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    // Navigate to withdrawal page from balance card
    await tester.tap(find.text('Tarik Saldo'));
    await tester.pumpAndSettle();

    // Verify withdrawal page elements
    expect(find.text('Tarik Saldo'), findsOneWidget);
    expect(find.text('Saldo Tersedia'), findsOneWidget);
    expect(find.text('Rp 2.450.000'), findsOneWidget);
    expect(find.text('Jumlah Penarikan'), findsOneWidget);
    expect(find.text('Metode Penarikan'), findsOneWidget);
    expect(find.text('BRI'), findsOneWidget);
    expect(find.text('DANA'), findsOneWidget);

    // Test amount chips
    await tester.tap(find.text('Rp 50.000'));
    await tester.pump();
    
    // Test payment method selection
    await tester.tap(find.text('DANA'));
    await tester.pump();

    // Try to submit withdrawal
    await tester.tap(find.text('Tarik Sekarang'));
    await tester.pumpAndSettle();

    // Should show confirmation dialog
    expect(find.text('Konfirmasi Penarikan'), findsOneWidget);
  });

  testWidgets('Pickup page form functionality', (WidgetTester tester) async {
    await tester.pumpWidget(const RecycleConnectApp());

    // Login first
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    // Navigate to pickup page from service card
    await tester.tap(find.text('Jemput'));
    await tester.pumpAndSettle();

    // Verify pickup page elements
    expect(find.text('Jadwal Penjemputan'), findsOneWidget);
    expect(find.text('Detail Sampah'), findsOneWidget);
    expect(find.text('Jenis Sampah'), findsOneWidget);
    expect(find.text('Berat (kg)'), findsOneWidget);
    expect(find.text('Jadwal Penjemputan'), findsNWidgets(2));
    expect(find.text('Alamat Penjemputan'), findsOneWidget);

    // Test form submission validation
    await tester.tap(find.text('Jadwalkan Penjemputan'));
    await tester.pump();

    // Should show validation errors
    expect(find.text('Harap masukkan berat sampah'), findsOneWidget);
    expect(find.text('Harap masukkan alamat penjemputan'), findsOneWidget);
  });

  testWidgets('History page detail functionality', (WidgetTester tester) async {
    await tester.pumpWidget(const RecycleConnectApp());

    // Login and navigate to history page
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.history_outlined));
    await tester.pumpAndSettle();

    // Tap on detail button for first transaction
    final detailButtons = find.text('Detail');
    await tester.tap(detailButtons.first);
    await tester.pumpAndSettle();

    // Verify detail modal appears
    expect(find.text('Detail Transaksi'), findsOneWidget);
    expect(find.text('ID Transaksi'), findsOneWidget);
    expect(find.text('Rincian Harga'), findsOneWidget);
    expect(find.text('Harga per kg'), findsOneWidget);

    // Close the modal
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
  });

  testWidgets('Profile page new menu items navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const RecycleConnectApp());

    // Login and navigate to profile page
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    // Test navigation to new pages
    await tester.tap(find.text('Metode Penarikan'));
    await tester.pumpAndSettle();
    expect(find.text('Tarik Saldo'), findsOneWidget);
    
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Notifikasi'));
    await tester.pumpAndSettle();
    expect(find.text('Notifikasi'), findsOneWidget);
    
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Statistik'));
    await tester.pumpAndSettle();
    expect(find.text('Statistik'), findsOneWidget);
    
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bantuan & FAQ'));
    await tester.pumpAndSettle();
    expect(find.text('Bantuan & FAQ'), findsOneWidget);
    
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kebijakan Privasi'));
    await tester.pumpAndSettle();
    expect(find.text('Kebijakan Privasi'), findsOneWidget);
    
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
  });
}