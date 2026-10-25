import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'extras.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoggingIn = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showComingSoon(String provider) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('$provider sign-in is coming soon.'),
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      backgroundColor: const Color(0xFF081426),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF071426), Color(0xFF0C2D55), Color(0xFF1769D2)],
            stops: [0, .58, 1],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -95,
              right: -65,
              child: _GlowOrb(size: 260, color: Color(0x3367C7E8)),
            ),
            const Positioned(
              bottom: -120,
              left: -90,
              child: _GlowOrb(size: 300, color: Color(0x294B8FF7)),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    keyboardOpen ? 12 : 26,
                    20,
                    keyboardOpen ? 12 : 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      children: [
                        if (!keyboardOpen) ...[
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x55000000),
                                  blurRadius: 28,
                                  offset: Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/mascot/kalasagicon-transparent.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'KALASAG',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 29,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Be informed. Be prepared. Stay safe.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFFBED7F3)),
                          ),
                          const SizedBox(height: 22),
                        ] else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/mascot/kalasagicon-transparent.png',
                                width: 38,
                                height: 38,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'KALASAG',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        Container(
                          padding: EdgeInsets.fromLTRB(
                            24,
                            keyboardOpen ? 18 : 26,
                            24,
                            keyboardOpen ? 18 : 22,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xF2162946),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: const Color(0x337EC8FF)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x59030B17),
                                blurRadius: 42,
                                offset: Offset(0, 20),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (!keyboardOpen) ...[
                                  const Text(
                                    'Welcome back',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 23,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Sign in to continue to your safety dashboard.',
                                    style: TextStyle(color: Color(0xFFADC5DF)),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                TextFormField(
                                  controller: _emailController,
                                  style: const TextStyle(
                                    color: Color(0xFF152A45),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  cursorColor: const Color(0xFF1769D2),
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
                                  style: const TextStyle(
                                    color: Color(0xFF152A45),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  cursorColor: const Color(0xFF1769D2),
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
                                const SizedBox(height: 18),
                                SizedBox(
                                  height: 52,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF1769D2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: _isLoggingIn ? null : _login,
                                    child: _isLoggingIn
                                        ? const SizedBox.square(
                                            dimension: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'Sign in',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: Color(0xFF405672),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Text(
                                          'or continue with',
                                          style: TextStyle(
                                            color: Color(0xFF91A8C2),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: Color(0xFF405672),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _SocialButton(
                                        label: 'Google',
                                        icon: FontAwesomeIcons.google,
                                        iconColor: const Color(0xFF4285F4),
                                        onPressed: () =>
                                            _showComingSoon('Google'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _SocialButton(
                                        label: 'Facebook',
                                        icon: FontAwesomeIcons.facebookF,
                                        iconColor: const Color(0xFF1877F2),
                                        onPressed: () =>
                                            _showComingSoon('Facebook'),
                                      ),
                                    ),
                                  ],
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
        hintStyle: const TextStyle(
          color: Color(0xFF8492A6),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF50647E), size: 22),
        prefixIconConstraints: const BoxConstraints(minWidth: 52),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 17,
          horizontal: 16,
        ),
        filled: true,
        fillColor: const Color(0xFFF4F7FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE3EAF3)),
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
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF203855),
        side: const BorderSide(color: Color(0xFF3A5472)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      onPressed: onPressed,
      icon: FaIcon(icon, color: iconColor, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    ),
  );
}
