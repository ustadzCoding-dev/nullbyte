import 'package:flutter/material.dart';
import 'package:nullbyte/core/theme/app_theme.dart';

class TourStep {
  final String title;
  final String description;
  final IconData icon;

  const TourStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class TourGuide extends StatefulWidget {
  final List<TourStep> steps;
  final VoidCallback onFinished;

  const TourGuide({super.key, required this.steps, required this.onFinished});

  static Future<void> show(BuildContext context, List<TourStep> steps) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => TourGuide(
        steps: steps,
        onFinished: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<TourGuide> createState() => _TourGuideState();
}

class _TourGuideState extends State<TourGuide>
    with SingleTickerProviderStateMixin {
  int _current = 0;
  late AnimationController _anim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _next() async {
    await _anim.reverse();
    if (_current < widget.steps.length - 1) {
      setState(() => _current++);
      _anim.forward();
    } else {
      widget.onFinished();
    }
  }

  void _skip() => widget.onFinished();

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_current];
    final isLast = _current == widget.steps.length - 1;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            border: Border.all(color: AppTheme.primaryContainer, width: 1.5),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${_current + 1}/${widget.steps.length}',
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 10,
                      color: AppTheme.onSurfaceVariant,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _skip,
                    child: const Text(
                      'SKIP',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 10,
                        color: AppTheme.outlineVariant,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppTheme.primaryContainer,
                    width: 1,
                  ),
                ),
                child: Icon(
                  step.icon,
                  color: AppTheme.primaryContainer,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                step.title,
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppTheme.primaryContainer,
                  letterSpacing: 0.05,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                step.description,
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 13,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: List.generate(
                  widget.steps.length,
                  (i) => Container(
                    width: i == _current ? 16 : 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 4),
                    color: i == _current
                        ? AppTheme.primaryContainer
                        : AppTheme.outlineVariant,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryContainer,
                    foregroundColor: AppTheme.onPrimary,
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: Text(
                    isLast ? 'MULAI MISI' : 'LANJUT',
                    style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const List<TourStep> activeSessionTour = [
  TourStep(
    title: 'NETWORK MAP',
    icon: Icons.hub,
    description:
        'Area atas menampilkan peta target yang sedang Anda investigasi.\n\n'
        '- Node redup: belum benar-benar relevan atau belum Anda pahami\n'
        '- Node terang: sudah terpetakan atau lebih penting untuk objective saat ini\n\n'
        'Gunakan map sebagai konteks visual, lalu lakukan validasi lewat terminal.',
  ),
  TourStep(
    title: 'TERMINAL',
    icon: Icons.terminal,
    description:
        'Area bawah adalah pusat gameplay utama.\n\n'
        'Mulai dengan "help" jika lupa command yang tersedia. Untuk mission recon awal, pola pikir paling aman biasanya:\n'
        'discover -> inspect service -> read exposed artifact.',
  ),
  TourStep(
    title: 'OBJECTIVE FLOW',
    icon: Icons.flag_circle,
    description:
        'Jangan cari jawaban langsung. Gunakan objective panel untuk menentukan apa yang harus dibuktikan lebih dulu.\n\n'
        'Selesaikan satu objective, baca feedback terminal, lalu lanjut ke objective berikutnya.',
  ),
  TourStep(
    title: 'SUBMIT FLAG',
    icon: Icons.flag,
    description:
        'Setelah flag ditemukan, tap ikon flag di kanan atas.\n\n'
        'Format flag selalu seperti:\n'
        'nullbyte{...}\n\n'
        'Jika file flag belum bisa dibaca, berarti ada langkah reconnaissance atau akses yang belum selesai.',
  ),
  TourStep(
    title: 'HINT SYSTEM',
    icon: Icons.lightbulb,
    description:
        'Jika mentok, gunakan tombol hint di kanan bawah map.\n\n'
        'Hint dibuka bertahap:\n'
        '- hint 1: arah konseptual\n'
        '- hint 2: arah tool atau target\n'
        '- hint 3: langkah yang lebih dekat ke solusi\n\n'
        'Gunakan hint untuk memahami alur, bukan sekadar menyalin command.',
  ),
];

const List<TourStep> missionSelectTour = [
  TourStep(
    title: 'MISSION SELECT',
    icon: Icons.assignment,
    description:
        'Pilih misi yang sedang terbuka lalu lanjutkan challenge secara berurutan.\n\n'
        'Mission 1 membangun fondasi reconnaissance, Mission 2 masuk ke web exploitation, dan Mission 3 menutup dengan privilege escalation.',
  ),
  TourStep(
    title: 'PROGRESSION',
    icon: Icons.star,
    description:
        'Setiap level memberi score dan rating bintang.\n\n'
        'Progression utamanya bukan koleksi fitur samping, tetapi ritme:\n'
        'pilih mission -> jalankan terminal challenge -> ambil flag -> unlock level berikutnya.',
  ),
];
