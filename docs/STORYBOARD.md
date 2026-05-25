# NULLBYTE — Game Storyboard

## Deskripsi Game

**NULLBYTE** adalah game simulasi pentest berbasis terminal untuk platform mobile. Pemain berperan sebagai operator baru yang direkrut organisasi maya NULLBYTE — tanpa pengalaman lapangan, hanya ketertarikan pada dunia cybersecurity.

Setiap mission adalah kontrak simulasi yang mengajarkan pola pikir serangan nyata dalam lingkungan aman. Pemain mengetik command di terminal, mengamati output, dan menyelesaikan objective untuk menangkap flag. Tidak ada tombol, tidak ada drag-and-drop — terminal adalah senjata satu-satunya.

**Alur utama:**
```
ONBOARDING → MISSION 1 (Recon) → MISSION 2 (Web Exploit) → MISSION 3 (Privesc) → ENDGAME
```

3 mission, 15 level, progresi linear. Setiap mission terdiri dari 5 level yang meningkat dalam kesulitan.

---

## Scene 1 — Splash Screen

![Splash Screen](images/splash_screen.svg)

Logo NULLBYTE muncul dengan efek glitch/scanline di atas latar gelap hijau. Loading bar mengisi di bawah logo. BGM `main_menu_theme.ogg` mulai diputar.

**Transisi:** → Disclaimer (otomatis setelah loading selesai)

---

## Scene 2 — Disclaimer

![Disclaimer](images/disclaimer.svg)

Peringatan etis ditampilkan di tengah layar dengan ikon shield. Pemain wajib mencentang "I understand and agree" sebelum tombol PROCEED aktif.

**Transisi:** → Auth / Registrasi (setelah setuju)

---

## Scene 3 — Auth / Registrasi

Pemain memasukkan **callsign** (username) atau memilih main sebagai **GUEST**. Tidak ada verifikasi email — offline-first.

**Transisi:** → MainMenu

---

## Scene 4 — MainMenu (Home Base)

![Main Menu](images/main_menu.svg)

Pemain mendarat di sini setiap kali membuka aplikasi. Layar menampilkan:

- **Uptime counter** — berapa lama pemain sudah terdaftar
- **Hero section** — callsign + status operasi + progress bar
- **Primary CTA** — "START MISSION" → navigasi ke Mission Select
- **Stats cards** — total stars, achievements
- **Recent mission** — mission terakhir dimainkan
- **Bottom navigation** — Home, Mission, Dictionary, Achievements, Profile

BGM: `main_menu_theme.ogg` (berbeda dari in-game BGM)

**Transisi:** → Mission Select (tap START MISSION)

---

## Scene 5 — Mission Select

![Mission Select](images/mission_select.svg)

3 mission terdaftar. Hanya mission yang sudah di-unlock bisa dimainkan.

| Mission | Nama | Domain | Unlock |
|---------|------|--------|--------|
| M1 | Network Recon | Network | Default |
| M2 | Web Exploitation | Web | Selesaikan M1 |
| M3 | Privilege Escalation | Network | Selesaikan M2 |

Setiap mission card menampilkan: judul, domain, jumlah level, progress bar, star rating, difficulty indicator, dan status LOCKED/UNLOCKED.

**Transisi:** → Active Session (tap mission → pilih level)

---

## Scene 6 — Active Session (Core Gameplay)

![Active Session](images/active_session.svg)

Ini adalah jantung permainan. Setiap level dimainkan di sini. Layout terdiri dari:

### AppBar
Lives (❤), score, timer, dan level identifier.

### Mission Brief (collapsible)
Narrative singkat, level objectives, recommended tools. Bisa di-collapse untuk memberi ruang terminal.

### Kill Chain Progress
Progress bar berdasarkan tahap attack:
- **M1:** RECON → ENUM → FLAG
- **M2:** RECON → ENUM → EXPLOIT → FLAG
- **M3:** RECON → ENUM → EXPLOIT → FOOTHOLD → PRIVESC → FLAG

Tahap selesai menyala (glow pulse), tahap aktif berkedip.

### Network Map (Topology)
Visualisasi node dan koneksi jaringan. Node yang sudah ditemukan menyala hijau, node belum discan gelap. Hint button tersedia di pojok.

### Terminal
Area utama interaksi. Pemain mengetik command, melihat output, dan mendapat suggestion bar di bawah. Setiap keystroke memutar SFX `typing.ogg` — satu ketikan, satu klik.

### Hint System
3 tingkat hint per level:
- **Hint 1** — arahan umum (gratis)
- **Hint 2** — petunjuk command spesifik (-100 score)
- **Hint 3** — solusi lengkap (-200 score total)

**Transisi:** → Mission Clear (setelah submit flag benar)

---

## Scene 7 — Mission Clear

![Mission Clear](images/mission_clear.svg)

Setelah setiap level selesai:

1. **Flag Captured** — animasi flag + SFX `flag_captured.ogg`
2. **Score Breakdown** — base + time bonus - hint penalty + no-hint bonus
3. **Star Rating** — ⭐ (0 hint) / ⭐⭐ (1 hint) / ⭐⭐⭐ (0 hint + cepat)
4. **Stats** — waktu, command count, hints used
5. **Learning Recap** — poin-poin pelajaran dari level
6. **CTA** — "NEXT LEVEL" atau "BACK TO MISSION"

**Transisi:** → Active Session (next level) atau → Mission Select

---

## Scene 8 — Mission 1: Network Recon

**Narasi pembuka:**
"Operasi dimulai dari nol. Tidak ada intel, tidak ada akses. Hanya terminal dan subnet yang menunggu untuk dipetakan."

**Tema:** Pemain baru masuk ke lab target. Tugas pertama adalah memetakan jaringan dan menemukan data yang terekspos — tanpa exploit berat. Recon yang rapi sudah cukup.

### M1 L1 — Host Discovery ⭐
- **Topology:** Kali Linux → Gateway Router → Corp Server
- **Kill Chain:** RECON → ENUM → FLAG
- **Alur:** `nmap 192.168.1.0/24` → `curl http://192.168.1.10` → `curl http://192.168.1.10/flag.txt`

### M1 L2 — Port Scan ⭐
- **Topology:** Kali Linux → Firewall → Workstation A + Workstation B
- **Kill Chain:** RECON → ENUM → FLAG
- **Alur:** `nmap 192.168.2.0/24` → `nmap -sV 192.168.2.20` → `curl http://192.168.2.20:8080/secret/flag.txt`

### M1 L3 — Service Fingerprint ⭐⭐
- **Topology:** Kali Linux → Core Router → Web Server + DB Server
- **Kill Chain:** RECON → ENUM → EXPLOIT → FLAG
- **Alur:** `nmap -A 172.16.0.10` → fingerprint Apache/2.4.49 → `curl http://172.16.0.10/flag.txt`

### M1 L4 — File Discovery ⭐⭐
- **Topology:** Kali Linux → File Server → Internal Share
- **Kill Chain:** RECON → ENUM → FLAG
- **Alur:** `nmap 192.168.10.50` → `curl http://192.168.10.50/backup/` → `curl http://192.168.10.50/backup/notes.txt` → `curl http://192.168.10.50/flag.txt`

### M1 L5 — Flag Extraction ⭐⭐⭐
- **Topology:** Kali Linux → Linux Server → Sensitive Files
- **Kill Chain:** RECON → ENUM → EXPLOIT → FLAG
- **Alur:** `nmap 192.168.20.100` → `curl http://192.168.20.100/export/` → `curl http://192.168.20.100/export/manifest.csv` → `curl http://192.168.20.100/flag.txt`

**Debrief M1:**
"Recon yang rapi adalah fondasi setiap operasi. Anda membuktikan bahwa informasi yang dikumpulkan dengan sabar sering lebih berharga daripada exploit yang dilakukan terburu-buru."

---

## Scene 9 — Mission 2: Web Exploitation

**Narasi pembuka:**
"Target Anda bukan lagi jaringan — melainkan aplikasi web yang menjalankan bisnis target. Setiap form, setiap parameter, adalah permukaan serang."

**Tema:** Fokus beralih ke aplikasi web. Pemain belajar menemukan kerentanan, memanfaatkan celah input, dan mengubah akses rendah menjadi kontrol penuh.

### M2 L1 — Endpoint Discovery ⭐⭐
- **Topology:** Kali Linux → Web Application → MySQL Database
- **Kill Chain:** RECON → ENUM → FLAG
- **Alur:** `curl http://192.168.50.10` → `curl http://192.168.50.10/recon/flag.txt`

### M2 L2 — SQL Injection ⭐⭐
- **Topology:** Kali Linux → Search Gateway → SQL Backend
- **Kill Chain:** RECON → ENUM → EXPLOIT → FLAG
- **Alur:** `curl http://192.168.50.10/search?q=test'` → `sqlmap -u http://192.168.50.10/search?q=test --dbs` → `sqlmap --dump`

### M2 L3 — Auth Bypass ⭐⭐⭐
- **Topology:** Kali Linux → Login Portal → Admin Panel
- **Kill Chain:** ENUM → EXPLOIT → FLAG
- **Alur:** `curl -X POST http://192.168.50.10/login -d "username=admin&password=' OR '1'='1"` → `curl http://192.168.50.10/admin/flag`

### M2 L4 — File Upload Abuse ⭐⭐⭐
- **Topology:** Kali Linux → Upload Server → Uploads Directory
- **Kill Chain:** ENUM → EXPLOIT → FOOTHOLD → FLAG
- **Alur:** `curl -F "file=@shell.php" http://192.168.50.10/upload` → `curl http://192.168.50.10/flag.txt`

### M2 L5 — Webshell Pivot ⭐⭐⭐⭐
- **Topology:** Kali Linux (Listener) → Production Server → Internal DB
- **Kill Chain:** RECON → EXPLOIT → FOOTHOLD → FLAG
- **Alur:** `curl http://192.168.50.10/uploads/shell.php?cmd=id` → `curl http://192.168.50.10/uploads/shell.php?cmd=bash` → `curl http://192.168.50.10/secret/flag.txt`

**Debrief M2:**
"Aplikasi web adalah permukaan serang terbesar di internet modern. Anda belajar bahwa setiap input adalah pintu masuk potensial, dan bahwa validasi yang lemah di satu titik bisa meruntuhkan seluruh sistem."

---

## Scene 10 — Mission 3: Privilege Escalation

**Narasi pembuka:**
"Foothold sudah aman. Tapi akses user biasa tidak cukup untuk menyelesaikan misi. Anda harus naik — menemukan celah privilege, memanfaatkan misconfiguration, dan merebut kontrol penuh."

**Tema:** Pemain sudah punya akses user via SSH. Tantangan sekarang adalah naik ke root. Enumerasi lokal, sudo misconfig, dan pivot antar jaringan internal.

### M3 L1 — Foothold Access ⭐⭐
- **Topology:** Kali Linux → Bastion Host
- **Kill Chain:** RECON → EXPLOIT → FLAG
- **Alur:** `nmap 192.168.100.10` → `ssh user@192.168.100.10` → `cat /home/user/flag.txt`

### M3 L2 — Enumeration Sweep ⭐⭐
- **Topology:** Kali Linux → Application Server
- **Kill Chain:** ENUM → FLAG
- **Alur:** `ssh user@192.168.100.20` → `whoami` + `id` → `cat /etc/passwd` → `cat /home/user/flag.txt`

### M3 L3 — Sudo Misconfig ⭐⭐⭐
- **Topology:** Kali Linux → Linux Server
- **Kill Chain:** ENUM → EXPLOIT → PRIVESC → FLAG
- **Alur:** `ssh user@192.168.100.30` → `sudo -l` (NOPASSWD: /usr/bin/find) → `sudo find . -exec /bin/sh \;` → `cat /root/flag.txt`

### M3 L4 — Service Pivot ⭐⭐⭐
- **Topology:** Kali Linux → Jump Host → Internal Service
- **Kill Chain:** RECON → PIVOT → FOOTHOLD → FLAG
- **Alur:** `nmap 192.168.100.40` → `ssh user@192.168.100.40` → `nmap 10.10.10.20` → `ssh user@10.10.10.20` → `cat /home/user/flag.txt`

### M3 L5 — Root Access ⭐⭐⭐⭐
- **Topology:** Kali Linux → Production Server → Root Shell
- **Kill Chain:** EXPLOIT → PRIVESC → FLAG
- **Alur:** `ssh operator@192.168.100.50` → `sudo -l` (find + vim) → `sudo find . -exec /bin/sh \;` → `cat /root/flag.txt`

**Debrief M3:**
"Root bukan tujuan — root adalah konsekuensi dari pemahaman. Anda membuktikan bahwa enumerasi yang sabar dan pemahaman konfigurasi sistem selalu mengalahkan brute force."

---

## Scene 11 — Endgame

![Endgame](images/endgame.svg)

Setelah ketiga mission selesai:

- Pemain mendapat gelar **"NULLBYTE Operator"**
- Semua achievements terbuka (28/28)
- Dictionary lengkap (108 entri)
- Profile menampilkan total stats dan rank

**Ini adalah akhir dari V1. Tidak ada layar kredit — hanya stats dan undangan untuk replay level demi bintang lebih tinggi.**
