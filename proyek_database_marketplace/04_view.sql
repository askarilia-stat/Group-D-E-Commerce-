USE db_marketplace;

-- View Ringkasan Transaksi Utama
CREATE OR REPLACE VIEW v_ringkasan_pesanan AS
SELECT
    p.id_pesanan,
    p.tanggal_pesanan,
    pl.nama AS nama_pelanggan,
    p.total_harga,
    p.status_pesanan,
    a.kota AS kota_tujuan
FROM Pesanan p
JOIN Pelanggan pl ON p.id_pelanggan = pl.id_pelanggan
JOIN Alamat a     ON p.id_alamat    = a.id_alamat;

-- View Analisis Stok Produk Terhadap Kategori
CREATE OR REPLACE VIEW v_stok_kategori_analisis AS
SELECT 
    k.nama_kategori,
    COUNT(p.id_produk) AS variasi_produk,
    SUM(p.stok_produk) AS total_stok_tersedia
FROM Produk p
JOIN Kategori k ON p.id_kategori = k.id_kategori
GROUP BY k.nama_kategori;

-- UJI COBA VIEW
-- 1. Menguji View Ringkasan Transaksi Utama
SELECT * FROM v_ringkasan_pesanan;

-- 2. Menguji View Analisis Stok Produk Terhadap Kategori
SELECT * FROM v_stok_kategori_analisis;