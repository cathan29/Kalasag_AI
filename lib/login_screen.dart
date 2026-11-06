import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth/google_auth_service.dart';
import 'extras.dart';

/// Shared reusable authentication scaffold and layout.
///
/// Keeps top branding, mascot placement, and dark navy container position
/// completely identical between Sign In and Sign Up states.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final heroStart = Color.alphaBlend(
      scheme.primary.withValues(alpha: .18),
      scheme.secondary,
    );
    final heroEnd = Color.alphaBlend(
      scheme.primary.withValues(alpha: .38),
      scheme.secondary,
    );

    return Scaffold(
      backgroundColor: scheme.surface,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [heroStart, heroEnd],
          ),
        ),
        child: Stack(
          children: [
            // Upper decorative ambient lighting orbs
            Positioned(
              top: -90,
              right: -60,
              child: _GlowOrb(
                size: 230,
                color: scheme.onPrimary.withValues(alpha: .10),
              ),
            ),
            Positioned(
              top: 120,
              left: -80,
              child: _GlowOrb(
                size: 190,
                color: scheme.onPrimary.withValues(alpha: .08),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenHeight = MediaQuery.sizeOf(context).height;
                  final idealHeaderHeight = (screenHeight * 0.28).clamp(
                    180.0,
                    220.0,
                  );
                  // Preserve fixed master header height while ensuring panel has
                  // sufficient room if an on-screen keyboard is open.
                  final heroHeight = (constraints.maxHeight - 200.0).clamp(
                    100.0,
                    idealHeaderHeight,
                  );

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Stationary Header Section
                          SizedBox(
                            height: heroHeight,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Be prepared.',
                                            style: TextStyle(
                                              color: scheme.onSecondary,
                                              fontSize: 28,
                                              fontWeight: FontWeight.w800,
                                              height: 1.05,
                                            ),
                                          ),
                                          Text(
                                            'Stay safe.',
                                            style: TextStyle(
                                              color: scheme.onSecondary
                                                  .withValues(alpha: .72),
                                              fontSize: 28,
                                              fontWeight: FontWeight.w800,
                                              height: 1.05,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Your trusted disaster readiness companion.',
                                            style: TextStyle(
                                              color: scheme.onSecondary
                                                  .withValues(alpha: .82),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Stack(
                                      alignment: Alignment.bottomCenter,
                                      children: [
                                        // Soft contact shadow at base of mascot
                                        Positioned(
                                          bottom: 0,
                                          child: Container(
                                            width: 130,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  const BorderRadius.all(
                                                    Radius.elliptical(130, 10),
                                                  ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.22),
                                                  blurRadius: 8,
                                                  spreadRadius: 1,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Image.asset(
                                          'assets/mascot/kalasag-ready-transparent.png',
                                          width: 160,
                                          height: 185,
                                          fit: BoxFit.contain,
                                          alignment: Alignment.bottomCenter,
                                          filterQuality: FilterQuality.high,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Stationary Dark Navy Panel
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: scheme.surface,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(30),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: .18),
                                    blurRadius: 24,
                                    offset: const Offset(0, -6),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(30),
                                ),
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    24,
                                    24,
                                    24,
                                  ),
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  child: form,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.googleSignIn,
    this.navigateAfterGoogleSignIn = true,
    this.navigateAfterGuestSignIn = true,
    this.createAccount,
    this.continueAsGuest,
  });

  final Future<void> Function()? googleSignIn;
  final bool navigateAfterGoogleSignIn;
  final bool navigateAfterGuestSignIn;
  final Future<void> Function(String email, String password)? createAccount;
  final Future<void> Function()? continueAsGuest;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isCreatingAccount = false;
  bool _isContinuingAsGuest = false;
  bool _isCreateMode = false;
  bool _isLoggingIn = false;
  bool _isSigningInWithGoogle = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
      );
  }

  Future<void> _signInWithGoogle() async {
    if (_isSigningInWithGoogle) return;
    setState(() => _isSigningInWithGoogle = true);
    try {
      await (widget.googleSignIn ?? GoogleAuthService().signIn)();
      if (!mounted) return;
      if (widget.navigateAfterGoogleSignIn) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
      }
    } on GoogleSignInException catch (error) {
      if (!mounted) return;
      if (error.code == GoogleSignInExceptionCode.canceled) {
        _showMessage('Google sign-in was cancelled.');
      } else {
        _showMessage('Google sign-in failed. Please try again.');
      }
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        'Google sign-in is not configured yet. Add the Firebase app configuration and try again.',
      );
    } finally {
      if (mounted) setState(() => _isSigningInWithGoogle = false);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoggingIn = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isCreatingAccount = true);
    try {
      await (widget.createAccount ??
          (email, password) async {
            final credential = await FirebaseAuth.instance
                .createUserWithEmailAndPassword(
                  email: email,
                  password: password,
                );
            await credential.user?.sendEmailVerification();
          })(_emailController.text.trim(), _passwordController.text);
      if (!mounted) return;
      _showMessage(
        'Account created. Check your email and tap the verification link.',
      );
      setState(() => _isCreateMode = false);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      final message = switch (error.code) {
        'email-already-in-use' => 'This email is already registered.',
        'invalid-email' => 'Enter a valid email address.',
        'weak-password' => 'Use a stronger password.',
        'network-request-failed' => 'Network unavailable. Please try again.',
        _ => 'Could not create your account. Please try again.',
      };
      _showMessage(message);
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        'Sign-up is not configured yet. Add the Firebase app configuration and try again.',
      );
    } finally {
      if (mounted) setState(() => _isCreatingAccount = false);
    }
  }

  Future<void> _continueAsGuest() async {
    if (_isContinuingAsGuest) return;
    setState(() => _isContinuingAsGuest = true);
    try {
      await (widget.continueAsGuest ??
          () => FirebaseAuth.instance.signInAnonymously())();
      if (!mounted) return;
      if (widget.navigateAfterGuestSignIn) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _showMessage(
        error.code == 'network-request-failed'
            ? 'Network unavailable. Guest access could not start.'
            : 'Guest access is unavailable right now. Please try again.',
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        'Guest access is not configured yet. Add the Firebase app configuration and try again.',
      );
    } finally {
      if (mounted) setState(() => _isContinuingAsGuest = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AuthLayout(
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isCreateMode ? 'Create your account' : 'Welcome back',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _isCreateMode
                  ? 'Stay informed, prepared, and safe with KALASAG.'
                  : 'Sign in to continue to your safety dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              style: TextStyle(color: scheme.onSurface),
              cursorColor: scheme.primary,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration(
                'Email address',
                Icons.email_outlined,
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) {
                  return 'Enter your email address.';
                }
                if (!email.contains('@') || !email.contains('.')) {
                  return 'Enter a valid email address.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              style: TextStyle(color: scheme.onSurface),
              cursorColor: scheme.primary,
              obscureText: _obscurePassword,
              textInputAction: _isCreateMode
                  ? TextInputAction.next
                  : TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!_isCreateMode && !_isLoggingIn) {
                  _login();
                }
              },
              decoration: _inputDecoration('Password', Icons.lock_outline)
                  .copyWith(
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Show password'
                          : 'Hide password',
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
              validator: (value) {
                if ((value ?? '').isEmpty) {
                  return 'Enter your password.';
                }
                if (value!.length < 6) {
                  return 'Password must have at least 6 characters.';
                }
                return null;
              },
            ),
            if (_isCreateMode) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmPasswordController,
                style: TextStyle(color: scheme.onSurface),
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (!_isCreatingAccount) {
                    _createAccount();
                  }
                },
                decoration:
                    _inputDecoration(
                      'Confirm password',
                      Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        tooltip: _obscureConfirmPassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                validator: (value) {
                  if ((value ?? '').isEmpty) {
                    return 'Confirm your password.';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match.';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed:
                    _isLoggingIn || _isCreatingAccount || _isContinuingAsGuest
                    ? null
                    : (_isCreateMode ? _createAccount : _login),
                child:
                    _isLoggingIn || _isCreatingAccount || _isContinuingAsGuest
                    ? SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          color: scheme.onPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isCreateMode ? 'Create account' : 'Sign in',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            if (!_isCreateMode) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: scheme.outlineVariant)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or continue with',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: scheme.outlineVariant)),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _SocialButton(
                      label: _isSigningInWithGoogle
                          ? 'Signing in...'
                          : 'Google',
                      icon: const _GoogleMark(),
                      onPressed: _isSigningInWithGoogle
                          ? null
                          : _signInWithGoogle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SocialButton(
                      label: 'Facebook · Coming soon',
                      icon: const FaIcon(
                        FontAwesomeIcons.facebookF,
                        color: Color(0xFF1877F2),
                        size: 18,
                      ),
                      onPressed: null,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Center(
              child: TextButton(
                onPressed:
                    _isLoggingIn || _isCreatingAccount || _isContinuingAsGuest
                    ? null
                    : () {
                        _formKey.currentState?.reset();
                        setState(() => _isCreateMode = !_isCreateMode);
                      },
                child: Text(
                  _isCreateMode
                      ? 'Already have an account? Sign in'
                      : 'New here? Create an account',
                ),
              ),
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: BorderSide(color: scheme.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed:
                  _isLoggingIn || _isCreatingAccount || _isContinuingAsGuest
                  ? null
                  : _continueAsGuest,
              icon: _isContinuingAsGuest
                  ? SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    )
                  : const Icon(Icons.person_outline),
              label: const Text(
                'Continue as Guest',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) =>
      InputDecoration(
        hintText: label,
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 22,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 52),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 17,
          horizontal: 16,
        ),
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: .55),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      );
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final Widget icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: onPressed == null
              ? scheme.onSurfaceVariant
              : scheme.onSurface,
          backgroundColor: onPressed == null
              ? scheme.surfaceContainerHighest.withValues(alpha: .35)
              : scheme.surfaceContainerHighest,
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        onPressed: onPressed,
        icon: icon,
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 20,
    child: CustomPaint(painter: _GoogleLogoPainter()),
  );
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Blue (#4285F4)
    paint.color = const Color(0xFF4285F4);
    final bluePath = Path()
      ..moveTo(22.56, 12.25)
      ..cubicTo(22.56, 11.47, 22.49, 10.72, 22.36, 10.0)
      ..lineTo(12.0, 10.0)
      ..lineTo(12.0, 14.26)
      ..lineTo(17.92, 14.26)
      ..cubicTo(17.66, 15.63, 16.88, 16.79, 15.71, 17.57)
      ..lineTo(15.71, 20.34)
      ..lineTo(19.28, 20.34)
      ..cubicTo(21.36, 18.42, 22.56, 15.6, 22.56, 12.25)
      ..close();
    canvas.drawPath(bluePath, paint);

    // Green (#34A853)
    paint.color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(12.0, 23.0)
      ..cubicTo(14.97, 23.0, 17.46, 22.02, 19.28, 20.34)
      ..lineTo(15.71, 17.57)
      ..cubicTo(14.73, 18.23, 13.48, 18.63, 12.0, 18.63)
      ..cubicTo(9.14, 18.63, 6.71, 16.7, 5.84, 14.1)
      ..lineTo(2.18, 14.1)
      ..lineTo(2.18, 16.94)
      ..cubicTo(3.99, 20.53, 7.7, 23.0, 12.0, 23.0)
      ..close();
    canvas.drawPath(greenPath, paint);

    // Yellow (#FBBC05)
    paint.color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..moveTo(5.84, 14.1)
      ..cubicTo(5.62, 13.44, 5.49, 12.74, 5.49, 12.0)
      ..cubicTo(5.49, 11.26, 5.62, 10.56, 5.84, 9.9)
      ..lineTo(5.84, 7.06)
      ..lineTo(2.18, 7.06)
      ..cubicTo(1.43, 8.55, 1.0, 10.22, 1.0, 12.0)
      ..cubicTo(1.0, 13.78, 1.43, 15.45, 2.18, 16.94)
      ..lineTo(5.84, 14.1)
      ..close();
    canvas.drawPath(yellowPath, paint);

    // Red (#EA4335)
    paint.color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(12.0, 5.38)
      ..cubicTo(13.62, 5.38, 15.06, 5.94, 16.21, 7.02)
      ..lineTo(19.36, 3.87)
      ..cubicTo(17.45, 2.09, 14.97, 1.0, 12.0, 1.0)
      ..cubicTo(7.7, 1.0, 3.99, 3.47, 2.18, 7.06)
      ..lineTo(5.84, 9.9)
      ..cubicTo(6.71, 7.3, 9.14, 5.38, 12.0, 5.38)
      ..close();
    canvas.drawPath(redPath, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
