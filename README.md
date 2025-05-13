# 🚀Litespeed Exporter Mini🚀

Litespeed Expoerter mini yang saya buat ini adalah script bash yang melakukan pengecekan jumlah req_processing pada file .rtreport yang dihasilnya oleh Litespeed Webserver itu sendiri.
Karena script ini nantinya bertujuan untuk membantu memonitoring req_processing webserver. Tentunya nanti dapat digunakan untuk memantau req_processing jika ada serangan DDOS ke salah satu vhost perdomain di server.

---

## ⚙️ Cara Kerja Singkat

1. **Script membaca file `.rtreport`** yang dimilik Litespeed (default: `/tmp/lshttpd/.rtreport`) atau (`/dev/shm/lsws/status/.rtreport`).
2. **Memfilter baris** yang mengandung `REQ_RATE` dan mengambil data mulai baris ke-6.
3. **Menampilkan data** VHost yang memiliki nilai `REQ_PROCESSING` lebih dari 800 misalnya (Bisa disesuikan dengan kebutuhan).
4. **Mengirim notifikasi Telegram** Jika ada `REQ_PROCESSING` pada vhost domain yang memiliki nilai misalnya 800 request maka akan mengirimkan notifikasi ke telegram.

---

## ⚒️ Cara Penggunaan

1. **Clone repository** ini dan masuk ke direktori `litespeed-exporter`:
   ```bash
   git clone https://github.com/nocturnalismee/litespeed-exporter-mini
   cd litespeed-exporter
   chmod -x req_processing.sh
   ```

2. **Edit konfigurasi Telegram** di dalam script:
   ```bash
   nano req_processing.sh
   TBT="masukan telegram bot anda disni" # Token Bot Telegram
   TCID="masukan telegram chat id anda disini" # Chat ID dari Telegram
   MTID="masukan message thread id anda sini" # message_thread_id dari Telegram
   ```
   > Dapatkan token bot dari [@BotFather](https://t.me/BotFather) dan chat ID dari Telegram Anda.

3. **Jalankan script:**
   ```bash
   ./req_processing.sh
   ```

4. **(Opsional) Tambahkan ke cronjob** untuk monitoring otomatis setiap 15 menit:
   ```
   */15 * * * * /path/to/litespeed_exporter.sh
   ```
  > Untuk cronjob silahkan disesuaikan dengan kebutuhan dan kemampuan server.
---


## 📄 Lisensi

MIT License © 2024 Arief (nocturnalismee)

---

## 🤝 Kontribusi

Menerima Kontribusi, saran, dan perbaikan!  
Silakan buat pull request atau issue di repository ini.

---

## 📞 Kontak

- Github: [nocturnalismee](https://github.com/nocturnalismee)
