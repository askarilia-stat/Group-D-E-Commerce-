DROP DATABASE IF EXISTS db_marketplace;
CREATE DATABASE IF NOT EXISTS db_marketplace;
USE db_marketplace;

-- 1. Tabel VOUCHER 
CREATE TABLE Voucher (
    kode_voucher    VARCHAR(20)     NOT NULL,
    jenis_diskon    VARCHAR(30)     NOT NULL CHECK (jenis_diskon IN ('persentase', 'nominal')),
    nilai_diskon    DECIMAL(10,2)   NOT NULL CHECK (nilai_diskon > 0),
    minimal_belanja DECIMAL(12,2)   NOT NULL DEFAULT 0,
    tanggal_mulai   DATE            NOT NULL,
    tanggal_berakhir DATE           NOT NULL,
    status          ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif',
    CONSTRAINT pk_voucher PRIMARY KEY (kode_voucher),
    CONSTRAINT chk_tgl_voucher CHECK (tanggal_berakhir >= tanggal_mulai)
);


-- 2. Tabel KATEGORI

CREATE TABLE Kategori (
    id_kategori         INT             NOT NULL AUTO_INCREMENT,
    nama_kategori       VARCHAR(100)    NOT NULL,
    deskripsi_kategori  TEXT,
    CONSTRAINT pk_kategori PRIMARY KEY (id_kategori),
    CONSTRAINT uq_nama_kategori UNIQUE (nama_kategori)
);


-- 3. Tabel PELANGGAN

CREATE TABLE Pelanggan (
    id_pelanggan    INT             NOT NULL AUTO_INCREMENT,
    nama            VARCHAR(100)    NOT NULL,
    email           VARCHAR(100)    NOT NULL,
    no_hp           VARCHAR(20),
    tanggal_daftar  DATE            NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT pk_pelanggan PRIMARY KEY (id_pelanggan),
    CONSTRAINT uq_email_pelanggan UNIQUE (email)
);


-- 4. Tabel PENJUAL

CREATE TABLE Penjual (
    id_penjual      INT             NOT NULL AUTO_INCREMENT,
    nama_toko       VARCHAR(100)    NOT NULL,
    nama_penjual    VARCHAR(100)    NOT NULL,
    email_penjual   VARCHAR(100)    NOT NULL,
    no_hp           VARCHAR(20),
    alamat_toko     VARCHAR(255),
    CONSTRAINT pk_penjual PRIMARY KEY (id_penjual),
    CONSTRAINT uq_email_penjual UNIQUE (email_penjual),
    CONSTRAINT uq_nama_toko UNIQUE (nama_toko)
);


-- 5. Tabel PRODUK

CREATE TABLE Produk (
    id_produk       INT             NOT NULL AUTO_INCREMENT,
    id_kategori     INT             NOT NULL,
    id_penjual      INT             NOT NULL,
    nama_produk     VARCHAR(150)    NOT NULL,
    deskripsi_produk TEXT,
    harga_produk    DECIMAL(12,2)   NOT NULL CHECK (harga_produk >= 0),
    stok_produk     INT             NOT NULL DEFAULT 0 CHECK (stok_produk >= 0),
    berat_produk    DECIMAL(8,2)    CHECK (berat_produk > 0),
    gambar_produk   VARCHAR(255),
    CONSTRAINT pk_produk PRIMARY KEY (id_produk),
    CONSTRAINT fk_produk_kategori FOREIGN KEY (id_kategori)
        REFERENCES Kategori(id_kategori) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_produk_penjual FOREIGN KEY (id_penjual)
        REFERENCES Penjual(id_penjual) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE INDEX idx_produk_kategori ON Produk(id_kategori);
CREATE INDEX idx_produk_penjual  ON Produk(id_penjual);


-- 6. Tabel ALAMAT

CREATE TABLE Alamat (
    id_alamat       INT             NOT NULL AUTO_INCREMENT,
    id_pelanggan    INT             NOT NULL,
    label_alamat    VARCHAR(50)     NOT NULL DEFAULT 'Rumah',
    penerima        VARCHAR(100)    NOT NULL,
    no_hp_penerima  VARCHAR(20),
    alamat_lengkap  TEXT            NOT NULL,
    kota            VARCHAR(100)    NOT NULL,
    kode_pos        VARCHAR(10),
    provinsi        VARCHAR(100)    NOT NULL,
    CONSTRAINT pk_alamat PRIMARY KEY (id_alamat),
    CONSTRAINT fk_alamat_pelanggan FOREIGN KEY (id_pelanggan)
        REFERENCES Pelanggan(id_pelanggan) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE INDEX idx_alamat_pelanggan ON Alamat(id_pelanggan);


-- 7. Tabel KERANJANG

CREATE TABLE Keranjang (
    id_keranjang        INT         NOT NULL AUTO_INCREMENT,
    id_pelanggan        INT         NOT NULL,
    id_produk           INT         NOT NULL,
    jumlah              INT         NOT NULL DEFAULT 1 CHECK (jumlah > 0),
    tanggal_ditambahkan DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_keranjang PRIMARY KEY (id_keranjang),
    CONSTRAINT uq_keranjang_item UNIQUE (id_pelanggan, id_produk),
    CONSTRAINT fk_keranjang_pelanggan FOREIGN KEY (id_pelanggan)
        REFERENCES Pelanggan(id_pelanggan) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_keranjang_produk FOREIGN KEY (id_produk)
        REFERENCES Produk(id_produk) ON UPDATE CASCADE ON DELETE CASCADE
);


-- 8. Tabel PESANAN

CREATE TABLE Pesanan (
    id_pesanan      INT             NOT NULL AUTO_INCREMENT,
    id_pelanggan    INT             NOT NULL,
    id_alamat       INT             NOT NULL,
    kode_voucher    VARCHAR(20),
    tanggal_pesanan DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status_pesanan  ENUM('menunggu_pembayaran','diproses','dikirim','selesai','dibatalkan')
                                    NOT NULL DEFAULT 'menunggu_pembayaran',
    total_harga     DECIMAL(12,2)   NOT NULL CHECK (total_harga >= 0),
    CONSTRAINT pk_pesanan PRIMARY KEY (id_pesanan),
    CONSTRAINT fk_pesanan_pelanggan FOREIGN KEY (id_pelanggan)
        REFERENCES Pelanggan(id_pelanggan) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_pesanan_alamat FOREIGN KEY (id_alamat)
        REFERENCES Alamat(id_alamat) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_pesanan_voucher FOREIGN KEY (kode_voucher)
        REFERENCES Voucher(kode_voucher) ON UPDATE CASCADE ON DELETE SET NULL
);

CREATE INDEX idx_pesanan_pelanggan ON Pesanan(id_pelanggan);
CREATE INDEX idx_pesanan_status    ON Pesanan(status_pesanan);


-- 9. Tabel DETAIL PESANAN

CREATE TABLE Detail_Pesanan (
    id_detail_pesanan   INT             NOT NULL AUTO_INCREMENT,
    id_pesanan          INT             NOT NULL,
    id_produk           INT             NOT NULL,
    jumlah_pesanan      INT             NOT NULL CHECK (jumlah_pesanan > 0),
    harga_satuan        DECIMAL(12,2)   NOT NULL CHECK (harga_satuan >= 0),
    subtotal            DECIMAL(12,2)   NOT NULL CHECK (subtotal >= 0),
    CONSTRAINT pk_detail_pesanan PRIMARY KEY (id_detail_pesanan),
    CONSTRAINT fk_detail_pesanan FOREIGN KEY (id_pesanan)
        REFERENCES Pesanan(id_pesanan) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_detail_produk FOREIGN KEY (id_produk)
        REFERENCES Produk(id_produk) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE INDEX idx_detail_pesanan ON Detail_Pesanan(id_pesanan);


-- 10. Tabel PEMBAYARAN

CREATE TABLE Pembayaran (
    id_pembayaran       INT             NOT NULL AUTO_INCREMENT,
    id_pesanan          INT             NOT NULL,
    metode_pembayaran   VARCHAR(50)     NOT NULL,
    jumlah_bayar        DECIMAL(12,2)   NOT NULL CHECK (jumlah_bayar >= 0),
    status_pembayaran   ENUM('menunggu','berhasil','gagal') NOT NULL DEFAULT 'menunggu',
    tanggal_bayar       DATETIME,
    CONSTRAINT pk_pembayaran PRIMARY KEY (id_pembayaran),
    CONSTRAINT uq_pembayaran_pesanan UNIQUE (id_pesanan),
    CONSTRAINT fk_pembayaran_pesanan FOREIGN KEY (id_pesanan)
        REFERENCES Pesanan(id_pesanan) ON UPDATE CASCADE ON DELETE CASCADE
);


-- 11. Tabel PENGIRIMAN

CREATE TABLE Pengiriman (
    id_pengiriman       INT             NOT NULL AUTO_INCREMENT,
    id_pesanan          INT             NOT NULL,
    jasa_kurir          VARCHAR(50)     NOT NULL,
    nomor_resi          VARCHAR(50)     NOT NULL,
    tanggal_kirim       DATETIME,
    status_pengiriman   ENUM('menunggu','dikemas','dikirim','terkirim') NOT NULL DEFAULT 'menunggu',
    CONSTRAINT pk_pengiriman PRIMARY KEY (id_pengiriman),
    CONSTRAINT uq_pengiriman_pesanan UNIQUE (id_pesanan),
    CONSTRAINT uq_nomor_resi UNIQUE (nomor_resi),
    CONSTRAINT fk_pengiriman_pesanan FOREIGN KEY (id_pesanan)
        REFERENCES Pesanan(id_pesanan) ON UPDATE CASCADE ON DELETE CASCADE
);


-- 12. Tabel ULASAN

CREATE TABLE Ulasan (
    id_ulasan       INT     NOT NULL AUTO_INCREMENT,
    id_produk       INT     NOT NULL,
    id_pelanggan    INT     NOT NULL,
    rating          INT     NOT NULL CHECK (rating BETWEEN 1 AND 5),
    komentar        TEXT,
    tanggal_ulasan  DATE    NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT pk_ulasan PRIMARY KEY (id_ulasan),
    CONSTRAINT uq_ulasan_per_produk UNIQUE (id_produk, id_pelanggan),
    CONSTRAINT fk_ulasan_produk FOREIGN KEY (id_produk)
        REFERENCES Produk(id_produk) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_ulasan_pelanggan FOREIGN KEY (id_pelanggan)
        REFERENCES Pelanggan(id_pelanggan) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE INDEX idx_ulasan_produk ON Ulasan(id_produk);