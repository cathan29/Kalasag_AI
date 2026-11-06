import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth/google_auth_service.dart';
import 'extras.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.googleSignIn,
    this.navigateAfterGoogleSignIn = true,
    this.createAccount,
    this.continueAsGuest,
  });

  final Future<void> Function()? googleSignIn;
  final bool navigateAfterGoogleSignIn;
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
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
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
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final heroHeight = (MediaQuery.sizeOf(context).height * .27).clamp(
      220.0,
      236.0,
    );
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
              child: SingleChildScrollView(
                padding: EdgeInsets.only(top: keyboardOpen ? 12 : 22),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      children: [
                        if (!keyboardOpen)
                          SizedBox(
                            height: heroHeight,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Be prepared.',
                                          style: TextStyle(
                                            color: scheme.onSecondary,
                                            fontSize: 30,
                                            fontWeight: FontWeight.w800,
                                            height: 1.05,
                                          ),
                                        ),
                                        Text(
                                          'Stay safe.',
                                          style: TextStyle(
                                            color: scheme.onSecondary
                                                .withValues(alpha: .72),
                                            fontSize: 30,
                                            fontWeight: FontWeight.w800,
                                            height: 1.05,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
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
                                  Image.asset(
                                    'assets/mascot/kalasag-ready-transparent.png',
                                    width: 168,
                                    height: 190,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/mascot/kalasagicon-transparent.png',
                                  width: 36,
                                  height: 36,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'KALASAG',
                                  style: TextStyle(
                                    color: scheme.onSecondary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(
                            24,
                            keyboardOpen ? 20 : 26,
                            24,
                            keyboardOpen ? 18 : 24,
                          ),
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
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _isCreateMode
                                      ? 'Create your account'
                                      : 'Welcome back',
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
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                  ),
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
                                    if (!email.contains('@') ||
                                        !email.contains('.')) {
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
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) {
                                    if (!_isLoggingIn) _login();
                                  },
                                  decoration:
                                      _inputDecoration(
                                        'Password',
                                        Icons.lock_outline,
                                      ).copyWith(
                                        suffixIcon: IconButton(
                                          tooltip: _obscurePassword
                                              ? 'Show password'
                                              : 'Hide password',
                                          onPressed: () => setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          ),
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
                                                  : Icons
                                                        .visibility_off_outlined,
                                            ),
                                          ),
                                        ),
                                    validator: (value) {
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
                                        _isLoggingIn ||
                                            _isCreatingAccount ||
                                            _isContinuingAsGuest
                                        ? null
                                        : (_isCreateMode
                                              ? _createAccount
                                              : _login),
                                    child:
                                        _isLoggingIn ||
                                            _isCreatingAccount ||
                                            _isContinuingAsGuest
                                        ? SizedBox.square(
                                            dimension: 20,
                                            child: CircularProgressIndicator(
                                              color: scheme.onPrimary,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            _isCreateMode
                                                ? 'Create account'
                                                : 'Sign in',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: scheme.outlineVariant,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Text(
                                          'or continue with',
                                          style: TextStyle(
                                            color: scheme.onSurfaceVariant,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: scheme.outlineVariant,
                                        ),
                                      ),
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
                                        icon: FontAwesomeIcons.google,
                                        iconColor: const Color(0xFF4285F4),
                                        onPressed: _isSigningInWithGoogle
                                            ? null
                                            : _signInWithGoogle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _SocialButton(
                                        label: 'Facebook · Coming soon',
                                        icon: FontAwesomeIcons.facebookF,
                                        iconColor: const Color(0xFF1877F2),
                                        onPressed: null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: TextButton(
                                    onPressed:
                                        _isLoggingIn ||
                                            _isCreatingAccount ||
                                            _isContinuingAsGuest
                                        ? null
                                        : () => setState(
                                            () =>
                                                _isCreateMode = !_isCreateMode,
                                          ),
                                    child: Text(
                                      _isCreateMode
                                          ? 'Already have an account? Sign in'
                                          : 'New here? Create an account',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                OutlinedButton.icon(
                                  onPressed:
                                      _isLoggingIn ||
                                          _isCreatingAccount ||
                                          _isContinuingAsGuest
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
                                  label: const Text('Continue as Guest'),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Demo: use any valid email and 6+ character password.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF8FA7C1),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
    required this.iconColor,
    required this.onPressed,
  });

  final String label;
  final FaIconData icon;
  final Color iconColor;
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
        ),
        onPressed: onPressed,
        icon: FaIcon(icon, color: iconColor, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
