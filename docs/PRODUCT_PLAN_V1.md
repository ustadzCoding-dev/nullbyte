# NULLBYTE Product Plan V1

## 1. Product Positioning

**One-line vision**

NULLBYTE adalah game single-player terminal CTF untuk pemula total yang ingin merasakan fantasy menjadi hacker sambil belajar alur berpikir dasar cybersecurity tanpa kewalahan.

**Category**

- Game edukasi ringan
- Story-driven beginner CTF
- Terminal-first puzzle progression

**What NULLBYTE is**

- Pengalaman onboarding ke dunia CTF
- Game dengan mission terstruktur dan level pendek
- Produk yang mengajarkan pola pikir, bukan hafalan teori
- Game lokal/offline-first dengan progression yang jelas

**What NULLBYTE is not**

- Bukan MMO hacking sandbox
- Bukan simulator jaringan ultra-realistis
- Bukan platform training enterprise
- Bukan course cybersecurity lengkap
- Bukan game yang bergantung pada leaderboard online

## 2. Target Player

**Primary target**

- Pemain usia 16-30
- Penasaran dengan hacking, CTF, Linux, atau command line
- Pernah lihat Hacknet, TryHackMe, HTB, atau konten cyber di YouTube
- Tertarik suasana terminal cyberpunk, tapi belum siap masuk ke platform belajar yang berat

**Player problems**

- Ingin mulai belajar, tapi takut terlalu teknis
- Ingin merasa progres cepat, bukan membaca materi panjang
- Ingin sensasi "meretas", tapi tetap diarahkan
- Sering bingung harus mulai dari command apa

**Why they will choose NULLBYTE**

- Lebih game daripada platform belajar
- Lebih jelas dan ramah daripada sandbox hacking sim
- Lebih ringan, cepat, dan fokus untuk sesi main pendek

## 3. Product Pillars

### 1. Learn By Doing

Setiap level harus mengajarkan satu pola pikir inti:

- discover
- enumerate
- exploit
- extract
- escalate

Pemain belajar lewat aksi, bukan penjelasan panjang.

### 2. Guided Tension

Pemain harus merasa sedang "meretas", tetapi tidak boleh tersesat terlalu lama.

Prinsip:

- objective jelas
- feedback cepat
- hint bertingkat
- output terminal informatif

### 3. Short Session Mastery

Satu level idealnya selesai dalam 10-20 menit.

Prinsip:

- satu tujuan utama per level
- kill chain pendek
- reward cepat
- retry cepat

### 4. Real Command, Safe Context

Command harus terasa nyata, tetapi sistem tetap disederhanakan agar ramah pemula.

Prinsip:

- gunakan command yang familiar secara dunia nyata
- kurangi noise sintaks yang tidak penting untuk beginner
- tekankan reasoning, bukan realism ekstrem

## 4. Core Loop V1

Loop utama NULLBYTE v1:

1. Pilih mission
2. Baca briefing singkat
3. Jalankan command untuk menemukan jalur solusi
4. Selesaikan objective
5. Submit atau temukan flag
6. Dapat score dan star
7. Unlock level berikutnya

**Rule penting**

- Semua layar, fitur, dan sistem harus mendukung loop ini
- Jika fitur tidak memperkuat loop ini, fitur harus ditunda

## 5. V1 Scope

**Must have**

- 3 mission utama
- 4-5 level per mission
- terminal command gameplay
- mission select
- objective tracking
- hint bertingkat
- score dan star
- unlock progression
- save local
- result screen dan debrief singkat

**Nice to have**

- audio polish
- onboarding yang lebih halus
- mini glossary/dictionary untuk istilah cyber
- achievement sederhana

**Not for V1**

- leaderboard online
- inventory kompleks
- skill tree aktif
- PvP atau multiplayer
- remote sync sebagai fitur utama
- open sandbox mode
- scripting bebas
- ekonomi item

## 6. Product Identity

NULLBYTE harus punya identitas berikut:

- cyberpunk training sim
- clean terminal fantasy
- beginner-safe CTF journey
- stylish, tajam, dan fokus

**Tone**

- tegang tapi tidak menakutkan
- cerdas tapi tidak sok teknis
- futuristik tapi tetap mudah dipahami

## 7. Design Rules

Setiap keputusan fitur harus lolos 5 pertanyaan ini:

1. Apakah ini membantu pemain pemula masuk ke terminal gameplay lebih cepat?
2. Apakah ini membuat mission loop lebih jelas?
3. Apakah ini memperkuat rasa menjadi hacker?
4. Apakah ini bisa dipahami tanpa tutorial panjang?
5. Apakah ini realistis untuk scope indie kecil?

Jika jawaban "tidak" pada 3 atau lebih pertanyaan, fitur ditunda.

## 8. Current Strategic Decision

Berdasarkan kondisi proyek saat ini, arah terbaik untuk NULLBYTE adalah:

**Beginner-first, mission-based, offline-first, terminal-centered.**

Konsekuensinya:

- jangan kejar fitur besar yang memecah fokus
- polish mission yang sudah ada sebelum menambah sistem baru
- jadikan Mission 1 sebagai vertical slice kualitas
- pakai konten level sebagai jantung produk, bukan meta system

## 9. 30-Day Roadmap

### Week 1: Lock The Vision

Goal:

- semua keputusan produk kembali ke satu arah yang sama

Deliverables:

- finalisasi product vision
- tentukan fitur v1 vs tunda
- audit semua screen yang tidak mendukung core loop
- rapikan wording dan UX supaya lebih beginner-friendly

Definition of done:

- ada satu dokumen visi produk
- semua pekerjaan berikutnya mengacu ke dokumen ini

### Week 2: Polish Mission 1

Goal:

- Mission 1 jadi contoh kualitas final

Deliverables:

- briefing level lebih jelas
- hint bertingkat lebih rapi
- kurangi spoiler langsung di UI
- perjelas feedback command sukses/gagal
- perbaiki pacing reward, star, dan result screen

Definition of done:

- pemain baru bisa menyelesaikan Mission 1 tanpa dibimbing developer

### Week 3: Standardize Mission 2-3

Goal:

- Mission 2 dan 3 mengikuti standar pengalaman yang sama

Deliverables:

- samakan pola objective
- samakan kualitas hint
- samakan clarity output terminal
- cek keseimbangan difficulty antar level

Definition of done:

- semua mission terasa satu produk yang konsisten

### Week 4: Stabilize And Package

Goal:

- siapkan build yang stabil untuk playtest tertutup

Deliverables:

- bugfix progression
- bugfix save/resume
- clean up UI copy
- test flow dari awal sampai akhir
- siapkan checklist rilis internal

Definition of done:

- build bisa dimainkan dari awal sampai akhir tanpa blocker mayor

## 10. Prioritized Backlog

### P0 - Kerjakan Sekarang

- kunci product vision
- polish Mission 1 sebagai vertical slice
- rapikan hint system
- pastikan objective dan terminal feedback jelas
- validasi flow unlock, save, score, dan result

### P1 - Setelah Core Loop Stabil

- upgrade onboarding
- achievement polish
- glossary/dictionary yang benar-benar berguna
- penyesuaian difficulty curve

### P2 - Tunda

- skill tree aktif
- inventory aktif
- leaderboard online
- cloud sync
- sandbox mode

## 11. Success Criteria For V1

V1 dianggap berhasil jika:

- pemain baru paham apa yang harus dilakukan dalam 2 menit pertama
- pemain bisa menyelesaikan mission pertama tanpa frustrasi besar
- pemain merasa "aku paham alurnya" setelah beberapa level
- progression terasa nyata dan memotivasi
- pengalaman dari awal sampai akhir terasa fokus, bukan campur aduk

## 12. Risks To Avoid

- scope creep dari fitur keren tapi tidak penting
- terlalu cepat mengejar realism
- terlalu banyak command tanpa onboarding yang cukup
- UI memberi spoiler penuh sehingga challenge hilang
- terlalu banyak sistem meta yang menutupi gameplay inti

## 13. Immediate Next Actions

Urutan kerja terbaik dari titik sekarang:

1. Jadikan dokumen ini sumber kebenaran v1
2. Audit layar dan sistem yang tidak mendukung core loop
3. Polish Mission 1 sampai layak jadi acuan kualitas
4. Baru lanjut menyamakan Mission 2 dan 3

## 14. Product Mantra

Saat bingung menentukan fitur, kembali ke kalimat ini:

**NULLBYTE harus membuat pemain pemula merasa pintar, tegang, dan terus maju lewat terminal challenge yang jelas.**
