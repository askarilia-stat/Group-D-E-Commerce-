USE db_marketplace;
DELIMITER $$

-- 1. VALIDASI KETERSEDIAAN STOK SEBELUM TRANSAKSI DISIMPAN
DROP TRIGGER IF EXISTS trg_validasi_stok_sebelum_insert$$
CREATE TRIGGER trg_validasi_stok_sebelum_insert
BEFORE INSERT ON Detail_Pesanan
FOR EACH ROW
BEGIN
    DECLARE v_stok INT;
    SELECT stok_produk INTO v_stok FROM Produk WHERE id_produk = NEW.id_produk;
    IF v_stok < NEW.jumlah_pesanan THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Proses Gagal: Stok produk yang tersedia tidak mencukupi!';
    ELSE
        UPDATE Produk SET stok_produk = stok_produk - NEW.jumlah_pesanan WHERE id_produk = NEW.id_produk;
    END IF;
END$$

-- 2. RESTOCK OTOMATIS SAAT PEMBATALAN PESANAN
DROP TRIGGER IF EXISTS trg_restock_pembatalan$$
CREATE TRIGGER trg_restock_pembatalan
AFTER UPDATE ON Pesanan
FOR EACH ROW
BEGIN
    -- Jalankan logika hanya jika status berubah menjadi 'dibatalkan'
    IF NEW.status_pesanan = 'dibatalkan' AND OLD.status_pesanan != 'dibatalkan' THEN
        BEGIN
            DECLARE done INT DEFAULT 0;
            DECLARE v_id_produk INT;
            DECLARE v_jumlah INT;
            
            -- Deklarasi Cursor di dalam blok lokal agar aman
            DECLARE cur_detail CURSOR FOR 
                SELECT id_produk, jumlah_pesanan FROM Detail_Pesanan WHERE id_pesanan = NEW.id_pesanan;
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

            OPEN cur_detail;
            read_loop: LOOP
                FETCH cur_detail INTO v_id_produk, v_jumlah;
                IF done THEN 
                    LEAVE read_loop; 
                END IF;
                UPDATE Produk SET stok_produk = stok_produk + v_jumlah WHERE id_produk = v_id_produk;
            END LOOP read_loop;
            CLOSE cur_detail;
        END;
    END IF;
END$$

DELIMITER ;

-- Tes 1: Menguji Trigger Validasi Stok (Akan menolak jika stok tidak mencukupi)
-- Bersihkan sisa data tes sebelumnya
DELETE FROM Detail_Pesanan WHERE id_pesanan = 999;
DELETE FROM Pesanan WHERE id_pesanan = 999;

-- Masukkan data pesanan utama kembali
INSERT INTO Pesanan (id_pesanan, id_pelanggan, id_alamat, total_harga, status_pesanan) 
VALUES (999, 1, 1, 9998000, 'menunggu_pembayaran');

-- Sekarang tes beli dengan jumlah sedikit (hanya 2 unit, asumsi stok produk ID 1 aman)
INSERT INTO Detail_Pesanan (id_pesanan, id_produk, jumlah_pesanan, harga_satuan, subtotal)
VALUES (999, 1, 2, 4999000, 9998000);

-- Tes 2: Menguji Fitur Restock Otomatis saat Pesanan Dibatalkan

-- 1. Cek stok awal produk sebelum pesanan dibatalkan
-- (Kita cek produk yang ada di dalam id_pesanan = 17)
SELECT p.id_produk, p.nama_produk, p.stok_produk 
FROM Produk p
JOIN Detail_Pesanan dp ON p.id_produk = dp.id_produk
WHERE dp.id_pesanan = 17;