USE db_marketplace;

DELIMITER $$

-- 1. Transaksi Berdasarkan Periode Waktu
DROP PROCEDURE IF EXISTS sp_transaksi_periode;
CREATE PROCEDURE sp_transaksi_periode(IN tgl_mulai DATE, IN tgl_selesai DATE)
BEGIN
    SELECT * FROM Pesanan 
    WHERE DATE(tanggal_pesanan) BETWEEN tgl_mulai AND tgl_selesai;
END$$

-- 2. Hitung Omzet Bulanan Eksekutif
DROP PROCEDURE IF EXISTS sp_omzet_bulanan;
CREATE PROCEDURE sp_omzet_bulanan()
BEGIN
    SELECT 
        DATE_FORMAT(tanggal_pesanan, '%Y-%m') AS bulan,
        SUM(total_harga) AS total_omzet
    FROM Pesanan WHERE status_pesanan != 'dibatalkan'
    GROUP BY DATE_FORMAT(tanggal_pesanan, '%Y-%m');
END$$

-- 3. Total Penjualan Per Kategori
DROP PROCEDURE IF EXISTS sp_total_penjualan_kategori;
CREATE PROCEDURE sp_total_penjualan_kategori()
BEGIN
    SELECT k.nama_kategori, SUM(dp.subtotal) AS total_penjualan
    FROM Detail_Pesanan dp
    JOIN Produk p ON dp.id_produk = p.id_produk
    JOIN Kategori k ON p.id_kategori = k.id_kategori
    GROUP BY k.nama_kategori;
END$$

-- 4. Tambah Transaksi / Buat Pesanan Baru
DROP PROCEDURE IF EXISTS sp_tambah_transaksi;
CREATE PROCEDURE sp_tambah_transaksi(
    IN p_id_pelanggan INT, IN p_id_alamat INT, IN p_total DECIMAL(14,2), IN p_voucher VARCHAR(20)
)
BEGIN
    INSERT INTO Pesanan (id_pelanggan, id_alamat, total_harga, kode_voucher, status_pesanan)
    VALUES (p_id_pelanggan, p_id_alamat, p_total, p_voucher, 'menunggu_pembayaran');
END$$

-- 5. Menampilkan Produk Terlaris
DROP PROCEDURE IF EXISTS sp_produk_terlaris;
CREATE PROCEDURE sp_produk_terlaris()
BEGIN
    SELECT p.nama_produk, SUM(dp.jumlah_pesanan) AS total_terjual
    FROM Detail_Pesanan dp
    JOIN Produk p ON dp.id_produk = p.id_produk
    GROUP BY p.id_produk, p.nama_produk
    ORDER BY total_terjual DESC LIMIT 5;
END$$

-- 6. Riwayat Transaksi Spesifik Pelanggan
DROP PROCEDURE IF EXISTS sp_riwayat_pelanggan;
CREATE PROCEDURE sp_riwayat_pelanggan(IN p_id_pelanggan INT)
BEGIN

    SELECT id_pesanan, tanggal_pesanan, total_harga, status_pesanan 
    FROM Pesanan WHERE id_pelanggan = p_id_pelanggan;
END$$

DELIMITER ;

USE db_marketplace;
-- Menguji seluruh prosedur operasional dan analitis eksekutif
CALL sp_transaksi_periode('2026-01-01', '2026-12-31');
CALL sp_omzet_bulanan();
CALL sp_total_penjualan_kategori();
CALL sp_tambah_transaksi(1, 1, 150000.00, NULL);
CALL sp_produk_terlaris();
CALL sp_riwayat_pelanggan(1);