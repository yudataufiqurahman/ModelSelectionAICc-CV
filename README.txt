DASHBOARD R SHINY - MODEL SELECTION AIC/CV (CCPP)
=================================================

ISI FOLDER
----------
app.R                          Dashboard Shiny. Hanya membaca hasil_analisis_dashboard.rds,
                               tidak menghitung model apa pun.
hasil_analisis_dashboard.rds   Hasil analisis asli dari Folds5x2_pp.xlsx
                               (10-fold CV, Random Forest 200/500 pohon, seed 42).
R.Rmd                          Analisis asli + bagian akhir "Ekspor hasil untuk dashboard
                               Shiny" yang menulis berkas .rds.
R.html                         Hasil knit R.Rmd.
www/                           (Opsional) taruh robot_avatar_small.png untuk avatar
                               Analysis Assistant. Jika kosong dipakai emoji robot.

MENJALANKAN DASHBOARD
---------------------
1. Instal paket (sekali saja), di R atau RStudio:

     install.packages(c("shiny", "bslib", "plotly"))

2. Pastikan app.R dan hasil_analisis_dashboard.rds berada di folder yang sama.

3. Jalankan salah satu cara berikut.

   Cara A - RStudio:
     Buka app.R, lalu klik tombol "Run App".

   Cara B - Konsol R:

     setwd("D:/FASTTRACK S2/REGRESI/PROJECT/dashboard_rshiny")
     shiny::runApp()

   Catatan: di R, path Windows memakai garis miring biasa (/) atau garis miring
   terbalik ganda (\\). Jangan memakai satu garis miring terbalik (\).

FITUR DASHBOARD
---------------
01 Eksplorasi Data        Ringkasan data, dataset (10 record pertama + tombol Download
                          full dataset CSV), statistik deskriptif, distribusi, korelasi,
                          scatter PE vs prediktor, VIF, outlier IQR.
02 Analisis Model         Tab Polinomial & Interaksi, GAM, Random Forest. Slider parameter
                          dan slider jumlah data test.
03 Evaluasi & Perbandingan  Scorecard, perbandingan AICc/CV antar sheet, pengaruh
                          pengacakan, model terbaik per sheet.
04 Diagnostik & Inferensi Diagnostik residual, inferensi, benchmark Random Forest,
                          pembahasan.
Tombol robot (pojok kanan bawah) membuka Analysis Assistant.

LOGIKA SLIDER (Grafik 2 di halaman 02 dan grafik model terbaik di halaman 03)
-----------------------------------------------------------------------------
Mengikuti lab interaktif pada file HTML Bayesian: panel "Kontrol" di kiri, grafik, kartu
metrik, dan teks interpretasi di kanan. Setiap slider memakai oninput di browser, sehingga
semuanya diperbarui seketika tanpa memanggil server:
  1. nilai semua slider dibaca dan ditulis di samping labelnya;
  2. Test RMSE dan R2 dihitung ulang pada N data test pertama;
  3. grafik SVG digambar ulang (data test, model aktif, dan model terbaik CV sebagai
     pembanding putus-putus);
  4. kartu metrik, label kelas (misalnya "Penalti kuat"), dan teks interpretasi diperbarui.
Slider parameter memilih model/faktor sp/mtry dari hasil yang sudah dihitung di R.Rmd,
bukan melatih ulang model di browser.

MEMBUAT ULANG HASIL ANALISIS (OPSIONAL)
---------------------------------------
1. Taruh Folds5x2_pp.xlsx di folder yang sama dengan R.Rmd.
2. Jalankan:

     rmarkdown::render("R.Rmd")

   Hasilnya: R.html dan hasil_analisis_dashboard.rds.
   Pada 1 core waktunya sekitar 35 menit; bagian ekspor grid slider (GAM dan RF)
   adalah yang terlama.
3. Salin hasil_analisis_dashboard.rds yang baru ke folder app.R.

Paket untuk R.Rmd: readxl, dplyr, tidyr, ggplot2, mgcv, ranger, car, lmtest,
sandwich, knitr, rmarkdown.

MASALAH UMUM
------------
- Muncul "Hasil analisis belum tersedia": hasil_analisis_dashboard.rds tidak berada satu
  folder dengan app.R, atau working directory salah. Cek dengan list.files().
- Error "there is no package called ...": jalankan ulang install.packages di atas.
- Error font_collection tidak ditemukan: perbarui bslib dengan install.packages("bslib").
