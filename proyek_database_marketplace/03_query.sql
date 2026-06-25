USE db_marketplace;

-- Query 1: Daftar Produk Beserta Harga dan Stok
SELECT
    id_produk,
    nama_produk,
    harga_produk,
    stok_produk
FROM Produk
WHERE stok_produk > 0
ORDER BY harga_produk ASC;

-- Query 2: Daftar Pelanggan yang Mendaftar di Tahun 2026
SELECT
    id_pelanggan,
    nama,
    email,
    no_hp,
    tanggal_daftar
FROM Pelanggan
WHERE YEAR(tanggal_daftar) = 2026
ORDER BY tanggal_daftar ASC;

-- Query 3: Voucher yang Masih Aktif pada Saat Ini
SELECT
    kode_voucher,
    jenis_diskon,
    nilai_diskon,
    minimal_belanja,
    tanggal_berakhir
FROM Voucher
WHERE status = 'aktif'
  AND tanggal_berakhir >= CURRENT_DATE
ORDER BY tanggal_berakhir ASC;


-- Query 4: Detail Pesanan Lengkap dengan Informasi Pelanggan, Produk, Pembayaran, dan Voucher Diskon
SELECT
    p.id_pesanan,
    pl.nama                                                 AS nama_pelanggan,
    pr.nama_produk,
    dp.jumlah_pesanan,
    dp.harga_satuan,
    dp.subtotal                                             AS subtotal_kotor,
    -- Menampilkan kode voucher (jika tidak pakai, muncul 'Tidak Menggunakan')
    COALESCE(p.kode_voucher, 'Tidak Menggunakan')            AS voucher_dipakai,
    -- Menampilkan nominal potongan diskon berdasarkan jenisnya
    COALESCE(
        CASE 
            WHEN v.jenis_diskon = 'persentase' THEN CONCAT(v.nilai_diskon, '%')
            WHEN v.jenis_diskon = 'nominal' THEN CONCAT('Rp ', FORMAT(v.nilai_diskon, 0))
        END, 'Rp 0'
    ) AS nilai_diskon,
    -- Total bayar akhir pada tingkat pesanan setelah dipotong voucher
    p.total_harga                                           AS total_bayar_bersih,
    p.status_pesanan,
    COALESCE(pb.metode_pembayaran, 'Belum Memilih')          AS metode_pembayaran,
    COALESCE(pb.status_pembayaran, 'belum_bayar')           AS status_pembayaran,
    COALESCE(pg.status_pengiriman, 'Belum Ada Pengiriman')  AS status_pengiriman
FROM Pesanan p
JOIN Pelanggan pl       ON p.id_pelanggan = pl.id_pelanggan
JOIN Detail_Pesanan dp  ON p.id_pesanan   = dp.id_pesanan
JOIN Produk pr          ON dp.id_produk   = pr.id_produk
LEFT JOIN Voucher v     ON p.kode_voucher = v.kode_voucher
LEFT JOIN Pembayaran pb ON p.id_pesanan   = pb.id_pesanan
LEFT JOIN Pengiriman pg ON p.id_pesanan   = pg.id_pesanan
ORDER BY p.id_pesanan, dp.id_detail_pesanan;

-- Query 5: Produk Terlaris Berdasarkan Total Penjualan per Kategori
WITH RankProdukTerlaris AS (
    SELECT
        k.nama_kategori,
        pr.nama_produk,
        pj.nama_toko          AS nama_toko,
        SUM(dp.jumlah_pesanan) AS total_unit_terjual,
        SUM(dp.subtotal)       AS total_pendapatan,
        -- Memberikan nomor urut 1 untuk pendapatan terbesar di setiap kategori
        ROW_NUMBER() OVER (
            PARTITION BY k.nama_kategori 
            ORDER BY SUM(dp.subtotal) DESC
        ) AS ranking
    FROM Produk pr
    JOIN Kategori k ON pr.id_kategori = k.id_kategori
    JOIN Penjual  pj ON pr.id_penjual = pj.id_penjual
    JOIN Detail_Pesanan dp ON pr.id_produk = dp.id_produk
    JOIN Pesanan p ON dp.id_pesanan = p.id_pesanan
    WHERE p.status_pesanan != 'dibatalkan'
    GROUP BY k.id_kategori, k.nama_kategori, pr.id_produk, pr.nama_produk, pj.nama_toko
)
SELECT
    nama_kategori,
    nama_produk,
    nama_toko,
    total_unit_terjual,
    total_pendapatan
FROM RankProdukTerlaris
WHERE ranking = 1
ORDER BY total_pendapatan DESC;

-- Query 6: Riwayat Transaksi Pelanggan Lengkap dengan Alamat Pengiriman dan Kurir
SELECT
    pl.id_pelanggan,
    pl.nama                 AS nama_pelanggan,
    p.id_pesanan,
    p.tanggal_pesanan,
    p.total_harga,
    p.status_pesanan,
    a.alamat_lengkap,
    a.kota,
    a.provinsi,
    pg.jasa_kurir,
    pg.nomor_resi,
    pg.status_pengiriman
FROM Pelanggan pl
JOIN Pesanan p  ON pl.id_pelanggan = p.id_pelanggan
JOIN Alamat  a  ON p.id_alamat     = a.id_alamat
LEFT JOIN Pengiriman pg ON p.id_pesanan = pg.id_pesanan
ORDER BY pl.id_pelanggan, p.tanggal_pesanan DESC;

-- Query 7: Performa Penjual – Pendapatan dan Ulasan Rata-rata per Toko
SELECT
    pj.id_penjual,
    pj.nama_toko,
    COUNT(DISTINCT pr.id_produk)    AS jumlah_produk,
    COUNT(DISTINCT p.id_pesanan)    AS jumlah_transaksi,
    SUM(dp.subtotal)                AS total_penjualan,
    ROUND(AVG(u.rating), 2)         AS rata_rata_rating,
    COUNT(u.id_ulasan)              AS jumlah_ulasan
FROM Penjual pj
JOIN Produk  pr ON pj.id_penjual = pr.id_penjual
LEFT JOIN Detail_Pesanan dp ON pr.id_produk = dp.id_produk
LEFT JOIN Pesanan p  ON dp.id_pesanan = p.id_pesanan AND p.status_pesanan != 'dibatalkan'
LEFT JOIN Ulasan u   ON pr.id_produk  = u.id_produk
GROUP BY pj.id_penjual, pj.nama_toko
ORDER BY total_penjualan DESC;

-- Query 8: Pelanggan dengan Total Belanja di Atas Rata-Rata (Subquery)
-- LANGKAH 1: Tampilkan nilai rata-rata belanja global per pelanggan terlebih dahulu
SELECT 
    'Rata-rata Belanja Global' AS indikator,
    ROUND(AVG(total_per_pelanggan), 2) AS nilai_rata_rata_rupiah
FROM (
    SELECT id_pelanggan, SUM(total_harga) AS total_per_pelanggan
    FROM Pesanan
    WHERE status_pesanan NOT IN ('dibatalkan', 'menunggu_pembayaran')
    GROUP BY id_pelanggan
) sub_avg_global;
-- LANGKAH 2: Tampilkan daftar pelanggan yang total belanjanya di atas rata-rata tersebut
SELECT
    pl.id_pelanggan,
    pl.nama,
    pl.email,
    SUM(p.total_harga) AS total_belanja_pelanggan
FROM Pelanggan pl
JOIN Pesanan p ON pl.id_pelanggan = p.id_pelanggan
WHERE p.status_pesanan NOT IN ('dibatalkan', 'menunggu_pembayaran')
GROUP BY pl.id_pelanggan, pl.nama, pl.email
HAVING SUM(p.total_harga) > (
    -- Subquery pembanding dinamis
    SELECT AVG(total_per_pelanggan)
    FROM (
        SELECT id_pelanggan, SUM(total_harga) AS total_per_pelanggan
        FROM Pesanan
        WHERE status_pesanan NOT IN ('dibatalkan', 'menunggu_pembayaran')
        GROUP BY id_pelanggan
    ) sub_avg
)
ORDER BY total_belanja_pelanggan DESC;

-- Query 9: Produk Paling Banyak Diulas dengan Rating Terbaik (CTE)
WITH StatsUlasan AS (
    SELECT
        u.id_produk,
        COUNT(u.id_ulasan)      AS jumlah_ulasan,
        ROUND(AVG(u.rating), 2) AS avg_rating,
        MIN(u.rating)           AS rating_terendah,
        MAX(u.rating)           AS rating_tertinggi
    FROM Ulasan u
    GROUP BY u.id_produk
),
RankUlasan AS (
    SELECT
        su.*,
        pr.nama_produk,
        pj.nama_toko,
        k.nama_kategori,
        -- Mengganti RANK() menjadi ROW_NUMBER() agar ranking tidak ada yang double
        ROW_NUMBER() OVER (ORDER BY su.avg_rating DESC, su.jumlah_ulasan DESC) AS ranking
    FROM StatsUlasan su
    JOIN Produk  pr ON su.id_produk   = pr.id_produk
    JOIN Penjual pj ON pr.id_penjual  = pj.id_penjual
    JOIN Kategori k ON pr.id_kategori = k.id_kategori
)
SELECT
    ranking,
    nama_produk,
    nama_toko,
    nama_kategori,
    jumlah_ulasan,
    avg_rating,
    rating_terendah,
    rating_tertinggi
FROM RankUlasan
WHERE jumlah_ulasan >= 1
ORDER BY ranking;

-- Query 10: Ringkasan Penjualan per Bulan dengan Filter Minimum Transaksi
SELECT
    YEAR(p.tanggal_pesanan)                         AS tahun,
    MONTH(p.tanggal_pesanan)                        AS bulan,
    DATE_FORMAT(p.tanggal_pesanan, '%M %Y')         AS nama_bulan,
    COUNT(p.id_pesanan)                             AS total_pesanan,
    SUM(p.total_harga)                              AS total_pendapatan,
    ROUND(AVG(p.total_harga), 2)                    AS rata_rata_nilai_pesanan,
    MAX(p.total_harga)                              AS nilai_pesanan_tertinggi,
    MIN(p.total_harga)                              AS nilai_pesanan_terendah,
    COUNT(DISTINCT p.id_pelanggan)                  AS jumlah_pelanggan_unik
FROM Pesanan p
WHERE p.status_pesanan = 'selesai'
GROUP BY
    YEAR(p.tanggal_pesanan),
    MONTH(p.tanggal_pesanan),
    DATE_FORMAT(p.tanggal_pesanan, '%M %Y')
HAVING COUNT(p.id_pesanan) >= 2
ORDER BY tahun, bulan;