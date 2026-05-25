import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nullbyte/core/constants/app_constants.dart';
import 'package:nullbyte/core/constants/hive_boxes.dart';
import 'package:nullbyte/shared/widgets/scanline_overlay.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController _terminalController = TextEditingController();
  String _terminalOutput = '';
  bool _step1Unlocked = false;

  int? _tappedNode;
  bool _step2Unlocked = false;

  int? _selectedFlowStep;
  bool _step3Unlocked = false;

  @override
  void dispose() {
    _pageController.dispose();
    _terminalController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final box = await Hive.openBox<dynamic>(HiveBoxes.settings);
    await box.put('onboardingCompleted', true);
    if (mounted) context.go('/mission');
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  bool get _currentStepUnlocked {
    switch (_currentPage) {
      case 0:
        return _step1Unlocked;
      case 1:
        return _step2Unlocked;
      case 2:
        return _step3Unlocked;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScanlineOverlay(
      child: Scaffold(
        backgroundColor: AppConstants.colorSurface,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildProgressIndicator(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _buildStep1Terminal(),
                    _buildStep2NetworkMap(),
                    _buildStep3MissionFlow(),
                  ],
                ),
              ),
              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'MISSION INTRO',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 12,
              color: AppConstants.colorOnSurfaceVariant,
              letterSpacing: 0.15,
            ),
          ),
          TextButton(
            onPressed: _completeOnboarding,
            style: TextButton.styleFrom(
              foregroundColor: AppConstants.colorOnSurfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'SKIP',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 12,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = i <= _currentPage;
          return Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
              color: isActive
                  ? AppConstants.colorPrimary
                  : AppConstants.colorOutlineVariant,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomButton() {
    final isLast = _currentPage == 2;
    final label = isLast ? 'MULAI MISI' : 'LANJUT';
    final enabled = _currentStepUnlocked;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: enabled ? _nextPage : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: enabled
                ? AppConstants.colorPrimary
                : AppConstants.colorOutlineVariant,
            foregroundColor: enabled
                ? AppConstants.colorSurface
                : AppConstants.colorOnSurfaceVariant,
            shape: const RoundedRectangleBorder(),
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: 0,
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1Terminal() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildStepHeader(
            title: 'TERMINAL FIRST',
            description:
                "Terminal adalah pusat permainan NULLBYTE. Coba ketik 'help' untuk melihat command yang tersedia, lalu biasakan memulai dari command discovery.",
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppConstants.colorSurfaceLowest,
                border: Border.all(color: AppConstants.colorOutlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NULLBYTE Terminal v1.0',
                            style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 12,
                              color: AppConstants.colorOnSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (_terminalOutput.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              '> help',
                              style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 12,
                                color: AppConstants.colorPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _terminalOutput,
                              style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 12,
                                color: AppConstants.colorOnSurface,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1, color: AppConstants.colorOutlineVariant),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          r'$',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 14,
                            color: AppConstants.colorPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _terminalController,
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 13,
                            color: AppConstants.colorOnSurface,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintText: 'ketik perintah...',
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onSubmitted: _handleTerminalInput,
                          textInputAction: TextInputAction.send,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (!_step1Unlocked)
            Text(
              'Ketik "help" dan tekan Enter untuk melanjutkan',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 10,
                color: AppConstants.colorOnSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  void _handleTerminalInput(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed == 'help') {
      setState(() {
        _terminalOutput =
            'Available commands: nmap, ping, ssh, ls, cat, whoami, id, curl, hydra, sqlmap\n\n[tip] Untuk mission awal, mulai dari command discovery seperti nmap atau ping.';
        _step1Unlocked = true;
        _terminalController.clear();
      });
    } else if (trimmed.isNotEmpty) {
      setState(() => _terminalController.clear());
    }
  }

  static const _nodes = [
    _NodeData(label: 'ROUTER', ip: '192.168.1.1', type: 'Gateway Router'),
    _NodeData(label: 'SERVER', ip: '192.168.1.10', type: 'Web Server'),
    _NodeData(label: 'HOST', ip: '192.168.1.20', type: 'Linux Workstation'),
  ];

  Widget _buildStep2NetworkMap() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildStepHeader(
            title: 'READ THE TARGET',
            description:
                'NetMap membantu Anda membaca konteks target. Lihat node yang ada, lalu tentukan host mana yang paling layak diperiksa lewat terminal.',
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppConstants.colorSurfaceLowest,
                border: Border.all(color: AppConstants.colorOutlineVariant),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          _nodes.length,
                          _buildNetworkNode,
                        ),
                      ),
                    ),
                  ),
                  if (_tappedNode != null) ...[
                    Divider(height: 1, color: AppConstants.colorOutlineVariant),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: AppConstants.colorSurfaceContainer,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nodes[_tappedNode!].label,
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.colorPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'IP: ${_nodes[_tappedNode!].ip}',
                            style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 11,
                              color: AppConstants.colorOnSurface,
                            ),
                          ),
                          Text(
                            'Type: ${_nodes[_tappedNode!].type}',
                            style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 11,
                              color: AppConstants.colorOnSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (!_step2Unlocked)
            Text(
              'Ketuk salah satu node untuk melanjutkan',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 10,
                color: AppConstants.colorOnSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNetworkNode(int index) {
    final node = _nodes[index];
    final isSelected = _tappedNode == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _tappedNode = index;
          _step2Unlocked = true;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? AppConstants.colorPrimary.withValues(alpha: 0.15)
                  : AppConstants.colorSurfaceHigh,
              border: Border.all(
                color: isSelected
                    ? AppConstants.colorPrimary
                    : AppConstants.colorOutlineVariant,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                node.label[0],
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppConstants.colorPrimary
                      : AppConstants.colorOnSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            node.label,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 9,
              color: isSelected
                  ? AppConstants.colorPrimary
                  : AppConstants.colorOnSurfaceVariant,
              letterSpacing: 0.05,
            ),
          ),
        ],
      ),
    );
  }

  static const _flowSteps = [
    _FlowStepData(
      name: 'SELECT MISSION',
      category: 'FLOW',
      description:
          'Masuk dari mission select lalu pilih operasi yang sedang terbuka. Progression v1 berjalan lurus: selesaikan challenge yang ada sebelum membuka level berikutnya.',
    ),
    _FlowStepData(
      name: 'RUN COMMANDS',
      category: 'FLOW',
      description:
          'Gunakan terminal untuk discovery, enumerasi, dan ekstraksi data. Objective adalah kompas utama Anda, sedangkan hint dipakai hanya saat benar-benar mentok.',
    ),
    _FlowStepData(
      name: 'SUBMIT FLAG',
      category: 'FLOW',
      description:
          'Setelah flag ditemukan, submit untuk mengunci hasil level. Inilah yang menentukan score, stars, dan unlock progression.',
    ),
  ];

  Widget _buildStep3MissionFlow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildStepHeader(
            title: 'CORE LOOP',
            description:
                'NULLBYTE v1 berfokus pada satu loop sederhana: pilih mission, jalankan terminal challenge, ambil flag, lalu lanjut ke level berikutnya.',
          ),
          const SizedBox(height: 16),
          ...List.generate(_flowSteps.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildFlowCard(i),
            );
          }),
          if (_selectedFlowStep != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.colorSurfaceContainer,
                border: Border.all(color: AppConstants.colorPrimary),
              ),
              child: Text(
                _flowSteps[_selectedFlowStep!].description,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 12,
                  color: AppConstants.colorOnSurface,
                  height: 1.5,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (!_step3Unlocked)
            Text(
              'Ketuk salah satu langkah untuk melanjutkan',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 10,
                color: AppConstants.colorOnSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFlowCard(int index) {
    final step = _flowSteps[index];
    final isSelected = _selectedFlowStep == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFlowStep = index;
          _step3Unlocked = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.colorPrimary.withValues(alpha: 0.08)
              : AppConstants.colorSurfaceLow,
          border: Border.all(
            color: isSelected
                ? AppConstants.colorPrimary
                : AppConstants.colorOutlineVariant,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              color: AppConstants.colorSurfaceHigh,
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppConstants.colorPrimary
                        : AppConstants.colorOnSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.name,
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppConstants.colorPrimary
                          : AppConstants.colorOnSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.category,
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 10,
                      color: AppConstants.colorSecondary,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              color: isSelected
                  ? AppConstants.colorPrimary
                  : AppConstants.colorOutlineVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepHeader({
    required String title,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppConstants.colorPrimary,
            letterSpacing: 0.05,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 13,
            color: AppConstants.colorOnSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _NodeData {
  final String label;
  final String ip;
  final String type;

  const _NodeData({required this.label, required this.ip, required this.type});
}

class _FlowStepData {
  final String name;
  final String category;
  final String description;

  const _FlowStepData({
    required this.name,
    required this.category,
    required this.description,
  });
}
