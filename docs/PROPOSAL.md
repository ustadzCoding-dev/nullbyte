# NULLBYTE — Proposal Pengembangan Game Edukasi Cybersecurity

---

## 1. Eksekutif Summary & Business Plan

- **Nama Aplikasi:** NULLBYTE — Terminal CTF Game for Beginners
- **Visi:** Menjadi platform gamifikasi utama di Indonesia untuk memperkenalkan pola pikir cybersecurity kepada pemula melalui pengalaman bermain yang terasa seperti "menjadi hacker" — tanpa kewalahan, tanpa risiko, dan tanpa membaca teori panjang.
- **Tagline:** *"Hack the learning curve."*
- **Target Audiens:** Pemuda usia 16–30 tahun di Indonesia yang penasaran dengan hacking, Linux, dan command line. Mahasiswa informatika yang ingin belajar offensive security secara praktis. Guru/dosen yang mencari media pembelajaran interaktif.
- **Value Proposition:**
  - **Game-first, bukan course-first** — pemain belajar lewat aksi, bukan penjelasan panjang
  - **Terminal fantasy yang aman** — command terasa nyata, tapi sistem disederhanakan agar ramah pemula
  - **Short session mastery** — satu level selesai dalam 10–20 menit
  - **Guided tension** — hint bertingkat mencegah pemain tersesat terlalu lama
  - **Offline-first** — bisa dimainkan tanpa koneksi internet

> *"NULLBYTE harus membuat pemain pemula merasa pintar, tegang, dan terus maju lewat terminal challenge yang jelas."*

---

## 2. Analisis Kompetitor (SWOT)

| Kategori | Deskripsi |
|----------|-----------|
| **Strengths (Kekuatan)** | UI/UX terminal-first yang intuitif; alur pembelajaran terstruktur (kill chain progression); hint bertingkat yang mencegah frustrasi; offline-first; konten edukasi relevan dengan skenario nyata; cross-platform (Android + iOS) |
| **Weaknesses (Kelemahan)** | Brand awareness masih nol; konten terbatas pada 3 mission di V1; bergantung pada daya tarik niche (cybersecurity) |
| **Opportunities (Peluang)** | Defisit 20.000+ profesional cybersecurity di Indonesia (BSSN 2024); belum ada game CTF mobile berbahasa Indonesia; tren gamifikasi edukasi naik; potensi kolaborasi kampus dan lembaga pelatihan |
| **Threats (Ancaman)** | Platform CTF mapan (TryHackMe, HackTheBox) bisa merilis mobile app; persepsi "game hacking" mengajarkan hal negatif; perubahan kebijakan app store terhadap konten hacking |

**Positioning:** NULLBYTE bukan kompetitor TryHackMe atau HackTheBox — NULLBYTE adalah **pintu masuk** menuju platform-platform tersebut.

---

## 3. Analisis Teknis (Arsitektur & Fitur)

- **Tech Stack:**
  - **Frontend:** Flutter (Dart) — cross-platform Android & iOS dari satu codebase
  - **State Management:** Riverpod — type-safe, testable, dependency injection
  - **Backend:** PocketBase — open-source, single-binary, auth + CRUD built-in
  - **Cloud Hosting:** NevaCloud — data center Indonesia, latency rendah, compliance PDP
  - **Local Storage:** Hive — NoSQL offline-first untuk progression, profile, session state
  - **Game Engine:** Flame (Canvas) — rendering network map + audio engine
  - **Navigation:** go_router — declarative routing dengan deep link support

- **Arsitektur:**
  ```
  Flutter App (Riverpod + Hive + Flame)
       │
  Repository Layer (HiveRepository + PocketBase API)
       │
  PocketBase (NevaCloud) → Auth / Progress Sync / Leaderboard
  ```

- **Fitur Utama (MVP — V1):**
  - **Terminal Simulator** — Input command Linux (nmap, curl, ssh, sudo, dll.) dengan output disimulasikan sesuai konteks level
  - **Kill Chain Progression** — RECON → ENUM → EXPLOIT → FOOTHOLD → PRIVESC → FLAG
  - **Network Map** — Visualisasi topologi jaringan yang ter-update saat host ditemukan
  - **Hint System Bertingkat** — 3 level hint; hint 1 gratis, hint 2-3 mengurangi score
  - **Flag Verification** — SHA-256 hash; format `nullbyte{mX_lY_description}`
  - **3 Mission, 15 Level** — Network Recon (M1), Web Exploitation (M2), Privilege Escalation (M3)
  - **108 Dictionary Entries** + **28 Achievements**

- **Infrastruktur NevaCloud:**

  | Komponen | Spesifikasi | Biaya/bulan |
  |----------|-------------|-------------|
  | PocketBase Server | 1 vCPU, 1 GB RAM, 20 GB SSD | ~Rp 75.000 |
  | Object Storage | 5 GB (audio & update) | ~Rp 25.000 |
  | CDN | NevaCloud edge nodes | ~Rp 50.000 |
  | **Total** | | **~Rp 150.000/bulan** |

---

## 4. Strategi Monetisasi

### 4.1 Freemium Model

| Tier | Harga | Fitur |
|------|-------|-------|
| **Free** | Rp 0 | 3 mission (15 level), dictionary, achievements, local save |
| **Pro** | Rp 249.000/tahun | Cloud sync, leaderboard, seasonal challenges, profile badges |

Target konversi: 3–5% dari pengguna aktif ke tier Pro.

### 4.2 Institutional Partnership (B2B)

- Lisensi kampus untuk mata kuliah keamanan jaringan/web
- Harga: Rp 3.000.000/tahun per kampus (unlimited student seats)
- Value add: Dashboard dosen, custom mission pack
- Target: 5 kampus di tahun pertama

### 4.3 In-App Advertising (Terbatas)

- Iklan **hanya** di non-gameplay screens (main menu, mission select)
- **Tidak ada iklan** selama active session — menjaga immersion
- Hanya iklan dikurasi dari brand teknologi/edukasi
- Format: Banner ringan

### Proyeksi Revenue Tahun 1

| Sumber | Estimasi |
|--------|----------|
| Freemium conversion | Rp 50.000.000 |
| B2B Institutional | Rp 15.000.000 |
| In-App Ads | Rp 15.000.000 |
| **Total** | **~Rp 80.000.000** |

*Proyeksi berdasarkan asumsi 20.000 download tahun pertama, 15% MAU.*

---

*Proposal ini disusun sebagai dokumen perencanaan pengembangan NULLBYTE — game edukasi cybersecurity berbasis terminal untuk pemula.*
