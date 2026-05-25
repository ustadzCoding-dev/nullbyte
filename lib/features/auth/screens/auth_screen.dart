import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nullbyte/core/router/app_router.dart';
import 'package:nullbyte/core/theme/app_theme.dart';
import 'package:nullbyte/features/auth/data/auth_provider.dart';
import 'package:nullbyte/features/auth/data/auth_repository.dart';
import 'package:nullbyte/shared/widgets/scanline_overlay.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _isRegisterMode = false;
  final List<String> _allBootLogs = [
    '[SYSTEM] ESTABLISHING SECURE TUNNEL... DONE',
    '[SYSTEM] ENCRYPTING PACKETS... AES-256 ACTIVE',
    '[SYSTEM] LOCAL PROGRESSION STORAGE... READY',
    '[SYSTEM] WAITING FOR OPERATOR INPUT_',
  ];
  final List<String> _visibleLogs = [];

  @override
  void initState() {
    super.initState();
    _startBootSequence();
  }

  void _startBootSequence() async {
    for (final log in _allBootLogs) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      setState(() {
        _visibleLogs.add(log);
      });
    }
  }
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _visibleLogs.add(_isRegisterMode 
          ? '[AUTH] CREATING NEW NODE IDENTIFIER...' 
          : '[AUTH] INITIATING SECURE INFILTRATION...');
      _errorMessage = null;
    });
    try {
      final notifier = ref.read(authNotifierProvider.notifier);
      final currentUser = ref.read(currentUserProvider);
      final isGuestUpgrade = _isRegisterMode && (currentUser?.isGuest ?? false);
      if (_isRegisterMode) {
        await notifier.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          _usernameController.text.trim(),
        );
        if (mounted) {
          setState(() {
            _visibleLogs.add('[AUTH] NODE INITIALIZED SUCCESSFULLY');
            _visibleLogs.add('[AUTH] ALLOCATING ASSETS & SECURE TUNNELS... DONE');
          });
          await Future.delayed(const Duration(milliseconds: 400));
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isGuestUpgrade
                    ? '[OK] GUEST SESSION BERHASIL DI-UPGRADE. PROGRESS LOKAL TETAP AMAN'
                    : '[OK] REGISTRASI BERHASIL. NODE AKTIF DAN SIAP MASUK MISI',
              ),
            ),
          );
          AppRouter.disclaimerNotifier.setAccepted(true);
          context.go('/mission');
        }
      } else {
        await notifier.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (mounted) {
          setState(() {
            _visibleLogs.add('[AUTH] SIGNATURE MATCHED');
            _visibleLogs.add('[AUTH] ACCESS GRANTED. LINKING CORE...');
          });
          await Future.delayed(const Duration(milliseconds: 400));
          if (!mounted) return;
          AppRouter.disclaimerNotifier.setAccepted(true);
          context.go('/mission');
        }
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _visibleLogs.add('[ERROR] AUTHORIZATION REJECTED BY HOST');
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'SYSTEM_ERROR: ${e.toString()}';
        _visibleLogs.add('[ERROR] FATAL PROTOCOL COLLISION');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGuest() async {
    setState(() {
      _isLoading = true;
      _visibleLogs.add('[AUTH] ALLOCATING TEMPORARY GUEST VECTOR...');
      _errorMessage = null;
    });
    try {
      await ref.read(authNotifierProvider.notifier).signInAsGuest();
      if (mounted) {
        setState(() {
          _visibleLogs.add('[AUTH] VECTOR ROUTED');
          _visibleLogs.add('[AUTH] GUEST TUNNEL SECURED. ENTERING SATELLITE...');
        });
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        AppRouter.disclaimerNotifier.setAccepted(true);
        context.go('/mission');
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _visibleLogs.add('[ERROR] GUEST INITIALIZATION ABORTED');
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'SYSTEM_ERROR: ${e.toString()}';
        _visibleLogs.add('[ERROR] GUEST STACK OVERFLOW');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isGuestUpgrade = _isRegisterMode && (currentUser?.isGuest ?? false);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: ScanlineOverlay(
        child: Stack(
          children: [
            // Grid background
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),
            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 48),
                        _buildFormContainer(isGuestUpgrade: isGuestUpgrade),
                        const SizedBox(height: 32),
                        _buildTerminalLogs(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 48, height: 2, color: AppTheme.primaryContainer),
            const SizedBox(width: 12),
            Text(
              _isRegisterMode
                  ? 'PROVISION_PROTOCOL_V1.0.0'
                  : 'AUTHENTICATION_PROTOCOL_V1.0.0',
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 10,
                color: AppTheme.primaryContainer,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: _isRegisterMode ? 'NODE\n' : 'NULL\n',
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.w900,
                  fontSize: 48,
                  color: AppTheme.onSurface,
                  height: 1.0,
                  letterSpacing: -1,
                ),
              ),
              TextSpan(
                text: _isRegisterMode ? 'REGISTRATION' : 'BYTE',
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.w900,
                  fontSize: 48,
                  color: AppTheme.primaryContainer,
                  height: 1.0,
                  letterSpacing: -1,
                  shadows: [Shadow(color: Color(0x4D00FF41), blurRadius: 10)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormContainer({required bool isGuestUpgrade}) {
    return Container(
      color: AppTheme.surfaceContainerLow,
      child: Stack(
        children: [
          // Left warning stripe
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: Opacity(
              opacity: 0.5,
              child: CustomPaint(painter: _WarnStripePainter()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isGuestUpgrade) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: AppTheme.surfaceContainerHigh,
                    child: const Text(
                      '[INFO] Anda sedang meng-upgrade guest session menjadi akun terdaftar. Progress lokal, score, stars, dan unlock level akan tetap dipertahankan.',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 10,
                        color: AppTheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                // Username field (register mode only)
                if (_isRegisterMode) ...[
                  _buildFieldLabel('NODE_IDENTIFIER'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _usernameController,
                    placeholder: 'USERNAME',
                  ),
                  const SizedBox(height: 24),
                ],
                // Email field
                _buildFieldLabel('USER_IDENTIFIER'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _emailController,
                  placeholder: 'EMAIL_ADDRESS',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                // Password field
                _buildFieldLabel('ACCESS_KEY'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _passwordController,
                  placeholder: '••••••••',
                  obscureText: true,
                ),
                const SizedBox(height: 32),
                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    color: AppTheme.errorContainer,
                    child: Text(
                      '[ERROR] ${_errorMessage!.toUpperCase()}',
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 10,
                        color: AppTheme.onErrorContainer,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Execute login / register button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryContainer,
                      foregroundColor: AppTheme.onPrimary,
                      disabledBackgroundColor: AppTheme.primaryContainer
                          .withValues(alpha: 0.4),
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.onPrimary,
                            ),
                          )
                        : Text(
                            _isRegisterMode
                                ? (isGuestUpgrade
                                      ? 'UPGRADE_GUEST_NODE'
                                      : 'INITIALIZE_NEW_NODE')
                                : 'EXECUTE_LOGIN',
                            style: const TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                // Guest session button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _handleGuest,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.onSurface,
                      side: const BorderSide(
                        color: AppTheme.outlineVariant,
                        width: 1,
                      ),
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'INITIALIZE_GUEST_SESSION',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 10,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Bottom links
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '[INFO] RESET KREDENSIAL BELUM DIAKTIFKAN DI V1. GUNAKAN SESI GUEST ATAU LOGIN YANG SUDAH ADA.',
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        '> FORGOT_CREDENTIALS',
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 10,
                          color: AppTheme.outline,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isRegisterMode = !_isRegisterMode;
                          _errorMessage = null;
                        });
                      },
                      child: Text(
                        _isRegisterMode
                            ? '> BACK_TO_LOGIN'
                            : '> REGISTER_NEW_NODE',
                        style: const TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 10,
                          color: AppTheme.outline,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'SpaceMono',
        fontSize: 10,
        color: AppTheme.primaryContainer,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      color: AppTheme.surfaceContainerLowest,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 14,
          color: AppTheme.primaryContainer,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppTheme.surfaceContainerLowest,
          hintText: placeholder,
          hintStyle: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 12,
            color: AppTheme.outlineVariant,
            letterSpacing: 1,
          ),
          prefixText: '> ',
          prefixStyle: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 14,
            color: AppTheme.primaryContainer,
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.outlineVariant, width: 2),
            borderRadius: BorderRadius.zero,
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.primaryContainer, width: 2),
            borderRadius: BorderRadius.zero,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildTerminalLogs() {
    const logStyle = TextStyle(
      fontFamily: 'JetBrainsMono',
      fontSize: 10,
      color: AppTheme.outlineVariant,
      letterSpacing: 0.5,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _visibleLogs
          .map((log) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(log, style: logStyle),
              ))
          .toList(),
    );
  }
}

/// Grid background painter — neon green dots/lines setiap 40px.
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          const Color(0x0D00FF41) // ~5% opacity neon green
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

/// Warning stripe painter — diagonal amber/black stripes.
class _WarnStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintAmber = Paint()
      ..color = AppTheme.secondaryContainer
      ..style = PaintingStyle.fill;
    final paintDark = Paint()
      ..color = AppTheme.surface
      ..style = PaintingStyle.fill;

    const stripeWidth = 10.0;
    final totalStripes = (size.height / stripeWidth).ceil() + 2;
    for (int i = 0; i < totalStripes; i++) {
      final y = i * stripeWidth;
      final paint = i.isEven ? paintAmber : paintDark;
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, stripeWidth), paint);
    }
  }

  @override
  bool shouldRepaint(_WarnStripePainter oldDelegate) => false;
}
