# GET FIT GYM — UTS Pemrograman Multiplatform

Aplikasi kebugaran Flutter untuk menjelajahi gerakan olahraga, menyusun satu jadwal yang berisi banyak gerakan, serta menyimpan jadwal dan riwayat latihan secara lokal.

## Identitas Mahasiswa

| Data | Keterangan |
|---|---|
| Nama | Faril Isra Albiansyah |
| NIM | 240605110087 |
| Kelas | A |
| Mata Kuliah | Pemrograman Multiplatform |
| Program Studi | Teknik Informatika |
| Fakultas | Sains dan Teknologi |
| Universitas | UIN Maulana Malik Ibrahim Malang |
| Tahun | 2026 |

## Deskripsi Aplikasi

GET FIT GYM membantu pengguna mencari referensi gerakan melalui ExerciseDB OSS API, melihat detail dan GIF latihan, membuat jadwal multi-gerakan, mengatur set/repetisi/beban, dan memindahkan sesi yang selesai ke riwayat. Jadwal dan riwayat disimpan di SQLite sehingga tetap tersedia setelah aplikasi ditutup dan dapat dibaca tanpa internet. Preferensi tema gelap/terang disimpan dengan SharedPreferences.

Versi UTS ini berjalan mandiri tanpa Firebase, login, Firestore, atau server lokal seperti XAMPP.

## Fitur Utama

- Katalog latihan dari ExerciseDB OSS API.
- Pencarian nama latihan dan filter bagian tubuh/target otot.
- Pagination berbasis cursor API.
- Detail latihan, target otot, peralatan, instruksi, dan media GIF jika tersedia.
- Loading state, pesan kesalahan jaringan, tombol retry, dan fallback input latihan manual.
- Pembuatan satu jadwal yang dapat memuat banyak gerakan.
- Pemilihan gerakan langsung dari katalog API ke form jadwal.
- Pengaturan set, repetisi, berat, urutan, dan catatan setiap gerakan.
- Daftar jadwal berstatus Direncanakan dan riwayat berstatus Selesai.
- CRUD jadwal dan riwayat menggunakan SQLite.
- Relasi one-to-many antara sesi latihan dan item gerakan.
- Penghapusan item anak secara cascade saat sesi dihapus.
- Dark/Light Mode dengan SharedPreferences.
- Data SQLite dan preferensi tema tetap tersedia secara offline.
- Antarmuka responsif untuk layar 320–600 logical pixel, text scale hingga 2.0x, dan keyboard virtual.

## Teknologi dan Package

- Flutter dan Dart.
- `get` untuk navigasi dan state reaktif.
- `http` sebagai HTTP client untuk ExerciseDB OSS API.
- `sqflite` untuk basis data SQLite lokal.
- `path` untuk membentuk lokasi file database secara portabel.
- `shared_preferences` untuk preferensi tema.
- `cupertino_icons` untuk ikon bergaya Cupertino.
- `translator` sebagai dependensi utilitas terdaftar pada project.
- ExerciseDB OSS API: https://oss.exercisedb.dev/

Daftar versi dependency yang tepat tersedia di `pubspec.yaml` dan `pubspec.lock`.

## Implementasi Asynchronous Programming

Operasi jaringan dan penyimpanan tidak memblokir thread antarmuka. Project menggunakan `Future`, `async`, dan `await` untuk request API, transaksi SQLite, serta pembacaan/penulisan preferensi tema.

Contoh ringkasan alur request katalog API (disederhanakan, bukan salinan fungsi lengkap) dari `lib/service/exercise_api_service.dart`:

```dart
Future<ExerciseApiResponse> fetchExercises({int limit = 20}) async {
  final uri = Uri.parse('$baseUrl/exercises').replace(
    queryParameters: {'limit': limit.clamp(1, 25).toString()},
  );
  final response = await _client
      .get(uri, headers: {'Accept': 'application/json'})
      .timeout(timeout);
  return _handleResponse(response);
}
```

Contoh akses SharedPreferences dari `lib/service/theme_preference_service.dart`:

```dart
Future<bool?> readDarkMode() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(ThemePreferenceService.preferenceKey);
}
```

Contoh ringkasan inisialisasi SQLite (disederhanakan; implementasi asli juga mengaktifkan foreign key, onCreate, dan onUpgrade) dari `lib/database/database_helper.dart`:

```dart
Future<Database> _initDatabase() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, databaseName);
  return await openDatabase(path, version: databaseVersion);
}
```

## Implementasi Data Persistence

### SharedPreferences

- Menyimpan nilai boolean dengan key `getfit_theme_is_dark`.
- Nilai ditulis ketika pengguna memilih Dark/Light Mode.
- Preferensi dibaca kembali ketika aplikasi dibuka sehingga tema tetap konsisten.
- Tidak memerlukan koneksi internet.

### SQLite

Database `local_workout_database.db` menggunakan skema versi 3. Tabel utama:

- `workout_sessions`: judul sesi, tanggal terjadwal, status, waktu pembuatan, dan waktu selesai.
- `workout_exercises`: gerakan milik sesi, ID ExerciseDB, target otot, peralatan, set, repetisi, berat, catatan, dan posisi.
- `local_workout_logs`: kompatibilitas catatan latihan lokal versi awal.

`workout_sessions` memiliki relasi one-to-many ke `workout_exercises` melalui `session_id`. Foreign key menggunakan `ON DELETE CASCADE`. Penyimpanan sesi beserta seluruh gerakannya dilakukan dalam transaksi untuk mencegah data parsial. Implementasi mencakup create, read, update, delete, migrasi non-destruktif, perubahan status Direncanakan/Selesai, dan akses offline.

## Persyaratan Instalasi

- Git.
- Flutter SDK yang kompatibel dengan Dart SDK `^3.10.1`.
- Dart SDK dari instalasi Flutter.
- Android SDK dan Android Emulator atau perangkat Android fisik.
- VS Code, Android Studio, IntelliJ IDEA, atau IDE lain yang mendukung Flutter.
- Koneksi internet untuk mengunduh package dan mengambil katalog/GIF ExerciseDB.

Firebase dan XAMPP tidak diperlukan.

## Tutorial Instalasi

1. Clone repository:

```bash
git clone https://github.com/Farilzzz/UTS-Pemrograman-Multiplatform-GET-FIT-GYM.git
```

2. Masuk ke folder project:

```bash
cd UTS-Pemrograman-Multiplatform-GET-FIT-GYM
```

3. Periksa environment Flutter:

```bash
flutter doctor
```

4. Unduh dependency:

```bash
flutter pub get
```

5. Nyalakan Android Emulator atau hubungkan perangkat Android dengan USB debugging aktif.

6. Pastikan perangkat terbaca:

```bash
flutter devices
```

7. Jalankan aplikasi:

```bash
flutter run
```

Jika tersedia lebih dari satu perangkat:

```bash
flutter run -d <device-id>
```

8. Build APK debug yang telah diverifikasi:

```bash
flutter build apk --debug
```

APK debug dihasilkan di:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

Build release dapat dilakukan dengan:

```bash
flutter build apk --release
```

Untuk distribusi nyata, konfigurasi signing release milik pengembang terlebih dahulu. Repository ini tidak menyertakan keystore atau kredensial signing.

## Panduan Penggunaan

1. Buka GET FIT GYM; aplikasi langsung menampilkan Beranda tanpa login.
2. Pilih **Jelajahi Latihan** untuk membuka katalog ExerciseDB.
3. Gunakan pencarian dan filter untuk menemukan gerakan.
4. Ketuk kartu latihan untuk melihat detail, target otot, instruksi, dan GIF jika tersedia.
5. Kembali ke Beranda lalu pilih **Jadwal & Riwayat**.
6. Tekan **Buat Jadwal**, isi nama sesi dan tanggal.
7. Tekan **Tambah Latihan**, pilih gerakan dari katalog API, lalu ulangi untuk menambahkan beberapa gerakan.
8. Atur set, repetisi, berat, dan catatan setiap gerakan.
9. Tekan **Simpan Jadwal**. Satu sesi beserta seluruh gerakannya disimpan ke SQLite.
10. Buka kartu jadwal untuk melihat detail atau mengedit sesi.
11. Tandai sesi sebagai selesai untuk memindahkannya ke tab Riwayat.
12. Buka **Pengaturan** untuk mengganti tema gelap/terang.

Jika katalog online tidak dapat diakses, data jadwal/riwayat tetap tersedia dan gerakan dapat dimasukkan secara manual.

## Pengujian

Perintah verifikasi:

```bash
flutter analyze --no-fatal-infos
flutter test
flutter build apk --debug
```

Hasil aktual sebelum publikasi:

- `flutter pub get`: berhasil.
- `flutter analyze --no-fatal-infos`: `No issues found`.
- `flutter test`: 193 test lulus, 0 gagal.
- `flutter build apk --debug`: berhasil menghasilkan APK debug.
- Pengujian publikasi menggunakan unit/widget tests deterministik, bukan pengujian koneksi API live atau E2E emulator baru. Tests meliputi kontrak persistence, offline history, tema, loading/error/retry, picker, dan multi-gerakan.
- Responsive widget tests mencakup 320x568, 360x640, 412x915, dan 600x960; text scale 1.0x, 1.5x, 2.0x; serta keyboard virtual.

Folder `test/` disertakan agar pengujian dapat dijalankan ulang.

## Catatan Penggunaan Offline

- SQLite sepenuhnya lokal dan tetap dapat dibaca/ditulis tanpa internet.
- SharedPreferences sepenuhnya lokal dan tetap bekerja tanpa internet.
- Katalog latihan ExerciseDB serta GIF online membutuhkan koneksi internet.
- Saat request gagal, aplikasi menampilkan pesan kesalahan dan aksi **Coba Lagi** tanpa menghapus data lokal.
- Pengguna tetap dapat menambahkan latihan manual ketika koneksi tidak tersedia.

## Dukungan Platform

Android adalah target terverifikasi. Source iOS disertakan sebagai bagian project Flutter, tetapi belum diuji dengan Xcode. Template Web, Windows, Linux, dan macOS tidak dipublikasikan: dukungan SQLite dan toolchain platform tersebut belum diverifikasi.

## Identitas Pengembang

Faril Isra Albiansyah  
NIM 240605110087  
Kelas A  
Teknik Informatika — UIN Maulana Malik Ibrahim Malang  
2026
