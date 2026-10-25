import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:testapp3/components/reading_cat.dart';
import 'package:testapp3/create_account.dart';
import 'package:testapp3/util/constants.dart';

typedef PasswordResetSender = Future<void> Function(String email);

bool _looksLikeEmail(String value) {
  final email = value.trim();
  return email.contains('@') &&
      email.indexOf('@') > 0 &&
      email.lastIndexOf('.') > email.indexOf('@') + 1 &&
      email.lastIndexOf('.') < email.length - 1;
}

class LoginPage extends StatefulWidget {
  final PasswordResetSender? passwordResetSender;

  const LoginPage({super.key, this.passwordResetSender});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _signingIn = false;
  bool _obscurePassword = true;

  String _signInErrorMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => 'That email address does not look right.',
      'invalid-credential' ||
      'wrong-password' => 'The email or password is incorrect.',
      'user-not-found' => 'We could not find an account with that email.',
      'user-disabled' =>
        'This account has been disabled. Please contact support.',
      'too-many-requests' =>
        'Too many attempts. Please wait a moment and try again.',
      'network-request-failed' =>
        'Check your internet connection and try again.',
      _ => 'We could not sign you in. Please try again.',
    };
  }

  Future<void> signIn() async {
    if (_signingIn) return;
    setState(() => _signingIn = true);
    String email = emailController.text.trim();
    String password = passwordController.text;
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // The root auth listener replaces navigation for the signed-in user.
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_signInErrorMessage(e)),
            duration: const Duration(seconds: 2),
            backgroundColor: Constants.cocoa,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  Future<void> _showPasswordReset() async {
    FocusScope.of(context).unfocus();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Constants.cocoa.withValues(alpha: 0.32),
      builder:
          (context) => _PasswordResetSheet(
            initialEmail: emailController.text.trim(),
            sendPasswordResetEmail:
                widget.passwordResetSender ??
                (email) =>
                    FirebaseAuth.instance.sendPasswordResetEmail(email: email),
          ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Constants.butter, Color(0xFFE9EDE2)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  children: [
                    _buildWelcomePanel(),
                    const SizedBox(height: 16),
                    _buildSignInPanel(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomePanel() {
    return SizedBox(
      width: double.infinity,
      height: 208,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF2E4D5), Constants.surfaceAlt],
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Constants.outline, width: 1.2),
              ),
            ),
          ),
          const Positioned(
            left: 20,
            top: 24,
            right: 152,
            child: Text(
              'BOOKFANIA\nSIGN IN',
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                letterSpacing: 1.3,
                fontWeight: FontWeight.w800,
                color: Constants.mutedInk,
              ),
            ),
          ),
          const Positioned(
            left: 20,
            top: 72,
            right: 145,
            child: Text(
              'Your next\nchapter is waiting.',
              style: TextStyle(
                fontSize: 27,
                height: 1.08,
                fontWeight: FontWeight.w800,
                color: Constants.cocoa,
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.52),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Constants.border),
              ),
              child: const Text(
                'PICK UP WHERE YOU LEFT OFF',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 0.9,
                  fontWeight: FontWeight.w800,
                  color: Constants.ink,
                ),
              ),
            ),
          ),
          const Positioned(
            right: -4,
            bottom: -10,
            child: ReadingCat(
              size: 172,
              semanticLabel: 'Bookfania reading companion',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Constants.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Constants.outline, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Constants.cocoa.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome back',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Constants.ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sign in to return to your library, quizzes, and reading goals.',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Constants.mutedInk,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!_looksLikeEmail(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) {
                if (!_signingIn && _formKey.currentState!.validate()) {
                  signIn();
                }
              },
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _signingIn ? null : _showPasswordReset,
                icon: const Icon(Icons.key_rounded, size: 17),
                label: const Text('Forgot password?'),
                style: TextButton.styleFrom(
                  foregroundColor: Constants.cocoa,
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  padding: const EdgeInsets.fromLTRB(10, 8, 2, 8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed:
                  _signingIn
                      ? null
                      : () {
                        if (_formKey.currentState!.validate()) signIn();
                      },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                side: const BorderSide(color: Constants.outline, width: 1.2),
              ),
              child: Text(_signingIn ? 'Signing in…' : 'Sign in'),
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: Constants.border),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Createaccount()),
                );
              },
              child: const Text(
                'New to Bookfania? Create an account',
                style: TextStyle(
                  color: Constants.cocoa,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordResetSheet extends StatefulWidget {
  final String initialEmail;
  final PasswordResetSender sendPasswordResetEmail;

  const _PasswordResetSheet({
    required this.initialEmail,
    required this.sendPasswordResetEmail,
  });

  @override
  State<_PasswordResetSheet> createState() => _PasswordResetSheetState();
}

class _PasswordResetSheetState extends State<_PasswordResetSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _sending = false;
  bool _sent = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String _resetErrorMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => 'That email address does not look right.',
      'too-many-requests' =>
        'Too many requests were made. Please wait and try again.',
      'network-request-failed' =>
        'Check your internet connection and try again.',
      _ => 'We could not send the reset email. Please try again.',
    };
  }

  Future<void> _sendResetLink() async {
    if (_sending || !_formKey.currentState!.validate()) return;

    setState(() {
      _sending = true;
      _errorMessage = null;
    });

    try {
      await widget.sendPasswordResetEmail(_emailController.text.trim());
      if (mounted) setState(() => _sent = true);
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        if (error.code == 'user-not-found') {
          setState(() => _sent = true);
        } else {
          setState(() => _errorMessage = _resetErrorMessage(error));
        }
      }
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _errorMessage =
                  'We could not send the reset email. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 14,
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        decoration: BoxDecoration(
          color: Constants.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Constants.outline, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Constants.cocoa.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: _sent ? _buildSuccess(context) : _buildForm(context),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Constants.border,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHandle(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Constants.blush,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Constants.outline, width: 1.1),
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  color: Constants.cocoa,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reset your password',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: Constants.ink,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'We’ll email you a secure link so you can choose a new password.',
                      style: TextStyle(height: 1.4, color: Constants.mutedInk),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'The email may appear in your spam folder. If you don’t see it in your inbox, check there too.',
                      style: TextStyle(height: 1.4, color: Constants.mutedInk),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          TextFormField(
            controller: _emailController,
            autofocus: widget.initialEmail.isEmpty,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.send,
            autofillHints: const [AutofillHints.email],
            onFieldSubmitted: (_) => _sendResetLink(),
            decoration: const InputDecoration(
              labelText: 'Account email',
              hintText: 'reader@example.com',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!_looksLikeEmail(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Constants.blush.withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Constants.outline),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 20),
                  const SizedBox(width: 9),
                  Expanded(child: Text(_errorMessage!)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _sending ? null : _sendResetLink,
            icon:
                _sending
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.send_rounded),
            label: Text(_sending ? 'Sending…' : 'Send reset link'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: Constants.outline, width: 1.2),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _sending ? null : () => Navigator.pop(context),
            child: const Text('Back to sign in'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHandle(),
        Align(
          child: Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Constants.surfaceAlt,
              shape: BoxShape.circle,
              border: Border.all(color: Constants.outline, width: 1.2),
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              size: 31,
              color: Constants.cocoa,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Check your inbox',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Constants.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'If an account exists for ${_emailController.text.trim()}, you’ll receive a password reset link. The email may appear in your spam folder, so check there if you don’t see it in your inbox.',
          textAlign: TextAlign.center,
          style: const TextStyle(height: 1.45, color: Constants.mutedInk),
        ),
        const SizedBox(height: 22),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            side: const BorderSide(color: Constants.outline, width: 1.2),
          ),
          child: const Text('Return to sign in'),
        ),
      ],
    );
  }
}
