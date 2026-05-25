import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nullbyte/core/router/app_router.dart';
import 'package:nullbyte/core/theme/app_theme.dart';
import 'package:nullbyte/features/save/providers/hive_repository_provider.dart';
import 'package:nullbyte/shared/widgets/scanline_overlay.dart';

const _disclaimerKey = 'disclaimerAccepted';

const _paragraphs = [
  'Game ini dibuat semata-mata untuk tujuan edukasi. Seluruh konten, skenario, dan teknik yang disajikan dirancang untuk membantu pengguna memahami konsep keamanan siber secara teoritis dan praktis dalam lingkungan yang aman dan terkontrol.',
  'Teknik-teknik yang diajarkan dalam game ini hanya boleh dipraktikkan pada sistem yang Anda miliki sendiri, atau pada sistem milik pihak lain yang telah memberikan izin eksplisit secara tertulis. Selalu pastikan Anda memiliki otorisasi yang sah sebelum melakukan pengujian keamanan apa pun.',
  'Penggunaan teknik-teknik ini pada sistem, jaringan, atau perangkat tanpa izin dari pemiliknya adalah tindakan ilegal. Pelanggaran ini dapat dikenakan sanksi hukum pidana maupun perdata sesuai dengan undang-undang yang berlaku di yurisdiksi Anda, termasuk namun tidak terbatas pada UU ITE di Indonesia.',
  'Developer, publisher, dan seluruh pihak yang terlibat dalam pembuatan game ini tidak bertanggung jawab atas segala bentuk penyalahgunaan informasi, teknik, atau pengetahuan yang diperoleh dari game ini. Risiko dan tanggung jawab sepenuhnya berada pada pengguna.',
  'Dengan menekan tombol "SAYA SETUJU & LANJUTKAN", Anda menyatakan bahwa Anda telah membaca, memahami, dan menyetujui seluruh ketentuan di atas. Anda berkomitmen untuk menggunakan pengetahuan yang diperoleh dari game ini secara etis, bertanggung jawab, dan sesuai dengan hukum yang berlaku.',
];

class DisclaimerScreen extends ConsumerStatefulWidget {
  const DisclaimerScreen({super.key});

  @override
  ConsumerState<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends ConsumerState<DisclaimerScreen> {
  final _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_hasScrolledToBottom) return;
    final pos = _scrollController.position;
    // Threshold 32px dari bawah
    if (pos.pixels >= pos.maxScrollExtent - 32) {
      setState(() => _hasScrolledToBottom = true);
    }
  }

  Future<void> _onAgree() async {
    final repo = ref.read(hiveRepositoryProvider);
    await repo.saveSettings(_disclaimerKey, true);
    AppRouter.disclaimerNotifier.setAccepted(true);
    if (mounted) context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerHigh,
        title: const Text(
          'ETHICAL_HACKING_PROTOCOL',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppTheme.onSurface,
            letterSpacing: 0.05,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: ScanlineOverlay(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    ..._buildParagraphs(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          color: AppTheme.secondaryContainer,
          size: 32,
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'DISCLAIMER & ETIKA HACKING',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppTheme.primaryContainer,
              letterSpacing: 0.05,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildParagraphs() {
    final widgets = <Widget>[];
    for (int i = 0; i < _paragraphs.length; i++) {
      widgets.add(
        Text(
          _paragraphs[i],
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 13,
            color: AppTheme.onSurfaceVariant,
            height: 1.6,
          ),
        ),
      );
      if (i < _paragraphs.length - 1) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(
              color: AppTheme.primaryContainer,
              thickness: 0.5,
              height: 1,
            ),
          ),
        );
      }
    }
    return widgets;
  }

  Widget _buildBottomSection() {
    return Container(
      color: AppTheme.surfaceContainerHigh,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_hasScrolledToBottom) ...[
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.keyboard_arrow_down,
                  color: AppTheme.secondaryContainer,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'SCROLL KE BAWAH UNTUK MELANJUTKAN',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 10,
                    color: AppTheme.secondaryContainer,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Opacity(
            opacity: _hasScrolledToBottom ? 1.0 : 0.4,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _hasScrolledToBottom ? _onAgree : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryContainer,
                  foregroundColor: AppTheme.onPrimary,
                  disabledBackgroundColor: AppTheme.primaryContainer,
                  disabledForegroundColor: AppTheme.onPrimary,
                  shape: const RoundedRectangleBorder(),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'SAYA SETUJU & LANJUTKAN',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.08,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
