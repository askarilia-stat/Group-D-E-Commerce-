USE db_marketplace;

DELIMITER $$

-- 1. Mengitung Total Bersih Belanjaan Pelanggan
CREATE FUNCTION fn_total_belanja(p_id_pelanggan INT) 
RETURNS DECIMAL(14,2)
DETERMINISTIC
BEGIN
    DECLARE v_total DECIMAL(14,2);
    SELECT COALESCE(SUM(total_harga), 0) INTO v_total FROM Pesanan 
    WHERE id_pelanggan = p_id_pelanggan AND status_pesanan != 'dibatalkan';
    RETURN v_total;
END$$

-- 2. Hitung Nilai Potongan Diskon Voucher Belanja
CREATE FUNCTION fn_hitung_diskon_voucher(p_kode_voucher VARCHAR(20), p_subtotal DECIMAL(14,2))
RETURNS DECIMAL(14,2)
DETERMINISTIC
BEGIN
    DECLARE v_jenis VARCHAR(30);
    DECLARE v_nilai DECIMAL(10,2);
    DECLARE v_potongan DECIMAL(14,2) DEFAULT 0;
    
    SELECT jenis_diskon, nilai_diskon INTO v_jenis, v_nilai FROM Voucher WHERE kode_voucher = p_kode_voucher;
    
    IF v_jenis = 'persentase' THEN
        SET v_potongan = p_subtotal * (v_nilai / 100);
    ELSEIF v_jenis = 'nominal' THEN
        SET v_potongan = v_nilai;
    END IF;
    RETURN v_potongan;
END$$

-- 3. Klasifikasi Leveling Loyalitas Pelanggan (CRM)
CREATE FUNCTION fn_kategori_pelanggan(p_id_pelanggan INT)
RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN
    DECLARE v_total_belanja DECIMAL(14,2);
    DECLARE v_kategori VARCHAR(50);
    
    SET v_total_belanja = fn_total_belanja(p_id_pelanggan);
    
    IF v_total_belanja > 5000000 THEN
        SET v_kategori = 'Platinum Core Customer';
    ELSEIF v_total_belanja BETWEEN 1500000 AND 5000000 THEN
        SET v_kategori = 'Gold Regular Customer';
    ELSE
        SET v_kategori = 'Silver Customer';
    END IF;
    RETURN v_kategori;
END$$

DELIMITER ;

USE db_marketplace;

-- Menguji eksekusi fungsionalitas nilai balik skalar
SELECT 
    id_pelanggan, 
    nama, 
    fn_total_belanja(id_pelanggan) AS total_belanjaan,
    fn_kategori_pelanggan(id_pelanggan) AS level_loyalitas
FROM Pelanggan LIMIT 5;

-- [UJI FUNGSI 1] Menghitung Total Bersih Belanjaan Pelanggan
SELECT 
    id_pelanggan, 
    nama, 
    fn_total_belanja(id_pelanggan) AS total_belanjaan
FROM Pelanggan 
LIMIT 5;


-- [UJI FUNGSI 2] Menghitung Potongan Diskon Voucher Belanja
-- (Disimulasikan dengan asumsi nilai belanjaan/subtotal sebesar Rp 500.000,00)
SELECT 
    kode_voucher,
    jenis_diskon,
    nilai_diskon,
    500000.00 AS simulasi_subtotal,
    fn_hitung_diskon_voucher(kode_voucher, 500000.00) AS nominal_potongan_diskon
FROM Voucher;


-- [UJI FUNGSI 3] Mengklasifikasikan Leveling Loyalitas CRM Pelanggan
SELECT 
    id_pelanggan, 
    nama, 
    fn_kategori_pelanggan(id_pelanggan) AS level_loyalitas
FROM Pelanggan 
LIMIT 5;