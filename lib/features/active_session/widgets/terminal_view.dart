import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nullbyte/core/constants/app_constants.dart';
import 'package:nullbyte/core/theme/app_theme.dart';
import 'package:nullbyte/features/active_session/domain/command_parser.dart';
import 'package:nullbyte/features/active_session/domain/command_registry.dart';
import 'package:nullbyte/features/active_session/domain/commands/commands_registry_factory.dart';
import 'package:nullbyte/features/active_session/domain/terminal_command.dart';
import 'package:nullbyte/features/active_session/providers/game_session_provider.dart';
import 'package:nullbyte/features/active_session/widgets/command_suggestions.dart';
import 'package:nullbyte/shared/providers/audio_manager.dart';

const _kClearSentinel = '__CLEAR__';

/// Satu entry di buffer terminal.
/// Bisa berupa baris output biasa atau baris input yang sudah disubmit.
class _TerminalLine {
  final String text;
  final TerminalOutputType type;

  /// Jika ini adalah baris input yang sudah disubmit, simpan prompt-nya.
  final String? prompt;

  const _TerminalLine({required this.text, required this.type, this.prompt});
}

/// Terminal view bergaya Linux.
/// Prompt aktif tampil inline dan output mengalir ke atas.
class TerminalView extends ConsumerStatefulWidget {
  const TerminalView({super.key});

  @override
  ConsumerState<TerminalView> createState() => _TerminalViewState();
}

class _TerminalViewState extends ConsumerState<TerminalView> {
  late final ScrollController _scrollController;
  late final TextEditingController _inputController;
  late final FocusNode _focusNode;
  late final CommandRegistry _registry;
  static const CommandParser _parser = CommandParser();

  final List<_TerminalLine> _lines = [];
  // ValueNotifier avoids full setState() rebuilds on every keystroke.
  // Only the active input line listens to this, so the ListView,
  // suggestions bar, and cursor are NOT rebuilt on each character.
  final ValueNotifier<String> _currentInputNotifier = ValueNotifier('');
  bool _isExecuting = false;

  List<String> _history = [];
  int _historyIndex = -1;

  // Track previous input length to detect character additions vs deletions.
  int _prevInputLength = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _inputController = TextEditingController();
    _focusNode = FocusNode();
    _registry = createDefaultRegistry();

    _seedWelcomeLines();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      // BUG-16 FIX: restore command history dari provider setelah frame pertama
      // agar navigasi history (↑/↓) tetap berfungsi setelah app resume/restore.
      final savedHistory = ref.read(gameSessionProvider).commandHistory;
      if (savedHistory.isNotEmpty) {
        _history = List.from(savedHistory);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    _focusNode.dispose();
    _currentInputNotifier.dispose();
    super.dispose();
  }

  String _buildPrompt() {
    final ctx = ref.read(levelContextProvider);
    final isRoot = ctx.hasRootPrivilege;
    final user = ctx.currentUser;
    final host = ctx.currentHost;
    final dir = ctx.currentDirectory.isEmpty ? '/' : ctx.currentDirectory;
    final displayDir = dir == '/home/$user' ? '~' : dir;
    final symbol = isRoot ? '#' : r'$';
    return '$user@$host:$displayDir$symbol';
  }

  void _addLine(String text, TerminalOutputType type, {String? prompt}) {
    setState(
      () => _lines.add(_TerminalLine(text: text, type: type, prompt: prompt)),
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _seedWelcomeLines() {
    final levelId = ref.read(levelContextProvider).levelId;

    _addLine(
      'NULLBYTE Terminal v1.0 - ketik "help" untuk bantuan',
      TerminalOutputType.info,
    );

    switch (levelId) {
      case 'm1_l1':
        _addLine(
          '[tip] Mission 1 dimulai dari discovery. Cari host aktif dulu sebelum mencoba akses web.',
          TerminalOutputType.info,
        );
      case 'm1_l2':
        _addLine(
          '[tip] Setelah host terlihat, fokus ke port yang tidak biasa atau service web alternatif.',
          TerminalOutputType.info,
        );
      case 'm1_l3':
        _addLine(
          '[tip] Port terbuka belum cukup. Cari tahu versi service sebelum menentukan langkah berikutnya.',
          TerminalOutputType.info,
        );
      case 'm1_l4':
        _addLine(
          '[tip] Pikirkan enumerasi konten. Direktori backup atau note internal sering jadi petunjuk tercepat.',
          TerminalOutputType.info,
        );
      case 'm1_l5':
        _addLine(
          '[tip] Tujuan level ini adalah ekstraksi data. Pilih service yang paling relevan lalu baca artefaknya.',
          TerminalOutputType.info,
        );
      case 'm2_l1':
        _addLine(
          '[tip] Mission 2 dimulai dari pemetaan aplikasi. Baca halaman utama dulu, lalu catat endpoint dan parameter yang terlihat menarik.',
          TerminalOutputType.info,
        );
      case 'm2_l2':
        _addLine(
          '[tip] Sebelum memakai automation, cari bukti kecil bahwa input user benar-benar memengaruhi query backend.',
          TerminalOutputType.info,
        );
      case 'm2_l3':
        _addLine(
          '[tip] Login form adalah logic target. Perhatikan bagaimana username dan password kemungkinan digabung dalam query autentikasi.',
          TerminalOutputType.info,
        );
      case 'm2_l4':
        _addLine(
          '[tip] Fokus level ini ada pada validasi upload. Pikirkan bagaimana request file bisa lolos walau kontennya berbahaya.',
          TerminalOutputType.info,
        );
      case 'm2_l5':
        _addLine(
          '[tip] Webshell hanyalah foothold. Tujuan Anda sekarang adalah mengubahnya menjadi jalur operasi yang lebih stabil.',
          TerminalOutputType.info,
        );
      case 'm3_l1':
        _addLine(
          '[tip] Mission 3 dimulai dari foothold. Gunakan SSH untuk mendapatkan akses ke target, lalu enumerasi sistem.',
          TerminalOutputType.info,
        );
      case 'm3_l2':
        _addLine(
          '[tip] Setelah foothold aktif, enumerasi lokal adalah kunci. Cek file sistem, log, dan jejak privilege.',
          TerminalOutputType.info,
        );
      case 'm3_l3':
        _addLine(
          '[tip] Cek sudo permission — misconfiguration sering menjadi jalur tercepat ke root.',
          TerminalOutputType.info,
        );
      case 'm3_l4':
        _addLine(
          '[tip] Satu foothold jarang cukup. Gunakan host yang dikuasai sebagai pivot untuk menjangkau jaringan internal.',
          TerminalOutputType.info,
        );
      case 'm3_l5':
        _addLine(
          '[tip] Level ini menyatukan seluruh kill chain: foothold, enumerasi, escalation, dan objective capture.',
          TerminalOutputType.info,
        );
      default:
        _addLine('', TerminalOutputType.info);
        return;
    }

    _addLine('', TerminalOutputType.info);
  }

  Future<void> _handleSubmit(String input) async {
    final trimmed = input.trim();
    _inputController.clear();
    _currentInputNotifier.value = '';
    _prevInputLength = 0;

    if (trimmed.isEmpty) {
      _addLine('', TerminalOutputType.input, prompt: _buildPrompt());
      return;
    }

    final submittedPrompt = _buildPrompt();
    _addLine(trimmed, TerminalOutputType.input, prompt: submittedPrompt);

    ref.read(gameSessionProvider.notifier).recordCommand(trimmed);
    _history = List.from(ref.read(gameSessionProvider).commandHistory);
    _historyIndex = -1;

    setState(() => _isExecuting = true);

    final parsed = _parser.parse(trimmed);
    if (parsed.isEmpty) {
      setState(() => _isExecuting = false);
      return;
    }

    final command = _registry.lookup(parsed.name);
    if (command == null) {
      _addLine(_registry.notFound(parsed.name).text, TerminalOutputType.error);
      setState(() => _isExecuting = false);
      return;
    }

    final levelContext = ref.read(levelContextProvider);
    final objectivesBefore = levelContext.completedObjectives.length;
    final result = await command.execute(parsed.args, levelContext);

    setState(() => _isExecuting = false);

    if (levelContext.completedObjectives.length > objectivesBefore) {
      ref.read(audioManagerProvider).playSfx(AppConstants.sfxAchievementUnlock);
    }

    if (result.text == _kClearSentinel) {
      setState(() => _lines.clear());
      return;
    }

    for (final line in result.text.split('\n')) {
      final lineType = line.startsWith('[tip]')
          ? TerminalOutputType.info
          : result.type;
      _addLine(line, lineType);
    }
  }

  void _navigateHistoryPrev() {
    if (_history.isEmpty) return;
    if (_historyIndex == -1) {
      _historyIndex = _history.length - 1;
    } else if (_historyIndex > 0) {
      _historyIndex--;
    }
    final text = _history[_historyIndex];
    _inputController.text = text;
    _inputController.selection = TextSelection.collapsed(offset: text.length);
    _currentInputNotifier.value = text;
    _prevInputLength = text.length;
  }

  void _navigateHistoryNext() {
    if (_history.isEmpty || _historyIndex == -1) return;
    if (_historyIndex < _history.length - 1) {
      _historyIndex++;
      final text = _history[_historyIndex];
      _inputController.text = text;
      _inputController.selection = TextSelection.collapsed(offset: text.length);
      _currentInputNotifier.value = text;
      _prevInputLength = text.length;
    } else {
      _historyIndex = -1;
      _inputController.text = '';
      _currentInputNotifier.value = '';
      _prevInputLength = 0;
    }
  }

  void _handleSuggestionTap(String suggestion) {
    _inputController.text = suggestion;
    _inputController.selection = TextSelection.collapsed(
      offset: suggestion.length,
    );
    _currentInputNotifier.value = suggestion;
    _prevInputLength = suggestion.length;
    _focusNode.requestFocus();
  }

  void _requestTerminalFocus() {
    // Brief delay to allow gesture arena selection handlers to settle
    // and prevent SelectionArea from clearing focus immediately.
    Future.delayed(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      _focusNode.requestFocus();
      SystemChannels.textInput.invokeMethod('TextInput.show');
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(levelContextProvider);

    return GestureDetector(
      onTap: _requestTerminalFocus,
      behavior: HitTestBehavior.translucent,
      child: Container(
        color: AppTheme.surfaceContainerLowest,
        child: Column(
          children: [
            Expanded(
              child: SelectionArea(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                  itemCount: _lines.length + 1,
                  itemBuilder: (context, index) {
                    if (index < _lines.length) {
                      return _buildLine(_lines[index]);
                    }
                    return _buildActiveInputLine();
                  },
                ),
              ),
            ),
            ValueListenableBuilder<String>(
              valueListenable: _currentInputNotifier,
              builder: (context, input, _) => CommandSuggestions(
                registry: _registry,
                currentInput: input,
                onSuggestionTap: _handleSuggestionTap,
                onHistoryPrev: _navigateHistoryPrev,
                onHistoryNext: _navigateHistoryNext,
              ),
            ),
            _buildHiddenInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildLine(_TerminalLine line) {
    Widget content;
    if (line.type == TerminalOutputType.input && line.prompt != null) {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${line.prompt} ',
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 12,
                  color: AppTheme.primaryContainer,
                  height: 1.5,
                ),
              ),
              TextSpan(
                text: line.text,
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 12,
                  color: AppTheme.onSurface,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final color = _colorFor(line.type);
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Text(
          line.text,
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 12,
            color: color,
            height: 1.5,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _requestTerminalFocus,
      behavior: HitTestBehavior.translucent,
      child: content,
    );
  }

  Widget _buildActiveInputLine() {
    final prompt = _buildPrompt();
    // ValueListenableBuilder ensures ONLY this line rebuilds on keystroke,
    // not the entire ListView / suggestions / cursor.
    return ValueListenableBuilder<String>(
      valueListenable: _currentInputNotifier,
      builder: (context, currentInput, _) {
        return GestureDetector(
          onTap: _requestTerminalFocus,
          behavior: HitTestBehavior.translucent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '$prompt ',
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 12,
                    color: AppTheme.primaryContainer,
                    height: 1.5,
                  ),
                ),
                if (_isExecuting)
                  const Text(
                    '...',
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  )
                else ...[
                  Text(
                    currentInput,
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 12,
                      color: AppTheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                  _BlinkingCursor(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHiddenInput() {
    // Nearly-invisible TextField: opacity 0.01 so the system recognizes
    // it as a focusable input and shows the keyboard reliably.
    // SizedBox(height: 0) can cause keyboard not to appear on some devices.
    return Opacity(
      opacity: 0.01,
      child: SizedBox(
        height: 1,
        child: TextField(
          controller: _inputController,
          focusNode: _focusNode,
          onSubmitted: (value) {
            _handleSubmit(value);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _focusNode.requestFocus();
            });
          },
          onChanged: (value) {
            // Only play keypress sound when characters are ADDED (not on delete).
            // playSfxCut stops previous keypress sound before playing new one
            // → satu ketikan = satu klik, bunyi sebelumnya dipotong.
            final newLen = value.length;
            if (newLen > _prevInputLength) {
              ref
                  .read(audioManagerProvider)
                  .playSfxCut(AppConstants.sfxKeypress);
            }
            _prevInputLength = newLen;
            _currentInputNotifier.value = value;
          },
          style: const TextStyle(fontSize: 1, color: Colors.transparent),
          cursorColor: Colors.transparent,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.send,
          keyboardType: TextInputType.text,
        ),
      ),
    );
  }

  Color _colorFor(TerminalOutputType type) {
    return switch (type) {
      TerminalOutputType.input => AppTheme.primaryContainer,
      TerminalOutputType.output => AppTheme.onSurface,
      TerminalOutputType.error => AppTheme.error,
      TerminalOutputType.info => AppTheme.onSurfaceVariant,
      TerminalOutputType.success => AppTheme.primaryContainer,
    };
  }
}

class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Opacity(
        opacity: _controller.value > 0.5 ? 1.0 : 0.0,
        child: Container(
          width: 8,
          height: 14,
          color: AppTheme.primaryContainer,
        ),
      ),
    );
  }
}
