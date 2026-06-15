-- Database Schema for SiParku (Sistem Informasi Parkir Terpadu Unila)
-- Sesuai dengan model data yang ada di Flutter (lib/models & lib/providers)

CREATE DATABASE IF NOT EXISTS siparku_db;
USE siparku_db;

-- Tabel Users (Berdasarkan data _mockUsers di AuthProvider)
CREATE TABLE users (
    uid VARCHAR(255) PRIMARY KEY,
    nama VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    telepon VARCHAR(50) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'user' COMMENT 'admin | user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabel Parking Zones (Berdasarkan ParkingZone model)
CREATE TABLE parking_zones (
    id VARCHAR(255) PRIMARY KEY,
    nama VARCHAR(255) NOT NULL,
    deskripsi TEXT NOT NULL,
    latitude DOUBLE NOT NULL,
    longitude DOUBLE NOT NULL,
    totalSlots INT NOT NULL
);

-- Tabel Parking Slots (Berdasarkan ParkingSlot model)
CREATE TABLE parking_slots (
    id VARCHAR(255) PRIMARY KEY,
    zoneId VARCHAR(255) NOT NULL,
    kode VARCHAR(50) NOT NULL,
    isOccupied BOOLEAN NOT NULL DEFAULT FALSE,
    vehiclePlate VARCHAR(20),
    type VARCHAR(50) NOT NULL COMMENT 'Mobil | Motor',
    FOREIGN KEY (zoneId) REFERENCES parking_zones(id) ON DELETE CASCADE
);

-- Tabel Parking Officers (Berdasarkan ParkingOfficer model)
CREATE TABLE parking_officers (
    id VARCHAR(255) PRIMARY KEY,
    nama VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    telepon VARCHAR(50) NOT NULL,
    zoneId VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'Aktif' COMMENT 'Aktif | Tidak Aktif',
    FOREIGN KEY (zoneId) REFERENCES parking_zones(id) ON DELETE RESTRICT
);

-- Tabel Parking History (Berdasarkan ParkingHistory model)
-- Menyimpan zoneName dan slotCode sebagai referensi historis agar data tidak hilang jika zone/slot dihapus
CREATE TABLE parking_history (
    id VARCHAR(255) PRIMARY KEY,
    userId VARCHAR(255) NOT NULL,
    zoneName VARCHAR(255) NOT NULL,
    slotCode VARCHAR(50) NOT NULL,
    checkInTime DATETIME NOT NULL,
    checkOutTime DATETIME,
    latitude DOUBLE NOT NULL,
    longitude DOUBLE NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'Selesai' COMMENT 'Aktif | Selesai',
    FOREIGN KEY (userId) REFERENCES users(uid) ON DELETE CASCADE
);

-- Tabel Parking Reports (Berdasarkan ParkingReport model)
CREATE TABLE parking_reports (
    id VARCHAR(255) PRIMARY KEY,
    userId VARCHAR(255) NOT NULL,
    userEmail VARCHAR(255) NOT NULL,
    deskripsi TEXT NOT NULL,
    fotoUrl VARCHAR(255),
    status VARCHAR(50) NOT NULL DEFAULT 'Pending' COMMENT 'Pending | Diproses | Selesai',
    createdAt DATETIME NOT NULL,
    FOREIGN KEY (userId) REFERENCES users(uid) ON DELETE CASCADE
);

-- ==========================================
-- DUMMY DATA SEEDING (Sesuai dengan mock data di Provider)
-- ==========================================

INSERT INTO users (uid, nama, email, telepon, role) VALUES
('user_default', 'Najla Nafisha', 'user@unila.ac.id', '081234567890', 'user'),
('admin_default', 'Admin SiParku', 'admin@unila.ac.id', '089876543210', 'admin');

INSERT INTO parking_zones (id, nama, deskripsi, latitude, longitude, totalSlots) VALUES
('fmipa', 'Parkiran FMIPA', 'Area parkir Fakultas Matematika dan Ilmu Pengetahuan Alam', -5.366613, 105.244286, 15),
('fkip', 'Parkiran FKIP', 'Area parkir Fakultas Keguruan dan Ilmu Pendidikan', -5.366752, 105.245564, 20),
('fk', 'Parkiran FK', 'Area parkir Fakultas Kedokteran', -5.367506, 105.246625, 10),
('shuttle', 'Parkiran Shuttle Unila', 'Area parkir dekat Shuttle Bus Universitas Lampung', -5.368093, 105.241798, 10);

-- Seeding some dummy officers
INSERT INTO parking_officers (id, nama, email, telepon, zoneId, status) VALUES
('officer_1', 'Budi Santoso', 'budi.santoso@unila.ac.id', '081234567890', 'fmipa', 'Aktif'),
('officer_2', 'Ahmad Hidayat', 'ahmad.hidayat@unila.ac.id', '082198765432', 'fkip', 'Aktif');

-- Insert 1 dummy report
INSERT INTO parking_reports (id, userId, userEmail, deskripsi, fotoUrl, status, createdAt) VALUES
('report_1', 'user_default', 'user@unila.ac.id', 'Mobil Fortuner Hitam BE 8888 AA parkir serong menghalangi slot', NULL, 'Pending', DATE_SUB(NOW(), INTERVAL 2 HOUR));
