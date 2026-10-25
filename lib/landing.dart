import 'package:flutter/material.dart';
import 'package:testapp3/create_account.dart';
import 'package:testapp3/components/reading_cat.dart';
import 'package:testapp3/login_page.dart';
import 'package:testapp3/util/constants.dart';
import 'package:testapp3/util/google_services.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _googleLoading = false;
  bool _showAuthOptions = false;

  Future<void> _continueWithGoogle() async {
    if (_googleLoading) return;

    setState(() {
      _googleLoading = true;
    });

    final result = await GoogleServices.signInWithGoogle();
    if (!mounted) return;

    setState(() {
      _googleLoading = false;
    });

    if (result.succeeded || result.errorMessage == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.errorMessage!),
        backgroundColor: Constants.ink,
      ),
    );
  }

  void _openEmailLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.background,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Constants.butter, Constants.surfaceAlt],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child:
                      _showAuthOptions ? _buildAuthCard() : _buildWelcomeCard(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      key: const ValueKey('welcome-card'),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        color: Constants.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Constants.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildReadingNookHero(),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Constants.surfaceAlt,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'YOUR COZY READING CORNER',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w800,
                color: Constants.ink,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Welcome to Bookfania',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.w800,
              color: Constants.ink,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Find your next favorite book, grow gentle reading habits, and keep every chapter close.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              color: Constants.mutedInk,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _showAuthOptions = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.cocoa,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingNookHero() {
    return SizedBox(
      height: 248,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF8E8D7), Color(0xFFE3EBD9)],
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Constants.border),
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 18,
            top: 24,
            child: Icon(
              Icons.auto_stories_rounded,
              size: 34,
              color: Constants.cocoa.withValues(alpha: 0.35),
            ),
          ),
          const Positioned(
            left: 22,
            top: 38,
            right: 155,
            child: Text(
              'Meet your\nreading buddy.',
              style: TextStyle(
                fontFamily: 'Redressed',
                fontSize: 32,
                height: 1.02,
                color: Constants.cocoa,
              ),
            ),
          ),
          const Positioned(
            left: 22,
            bottom: 28,
            right: 166,
            child: Text(
              'A quiet place for every page you love.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: Constants.mutedInk,
              ),
            ),
          ),
          const Positioned(
            right: -6,
            bottom: -12,
            child: ReadingCat(
              size: 235,
              alignment: Alignment.bottomCenter,
              semanticLabel: 'A white cat reading a book',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthCard() {
    return Container(
      key: const ValueKey('auth-card'),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: Constants.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Constants.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _showAuthOptions = false;
                  });
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Constants.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Constants.ink,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Log in or sign up',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Constants.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Use your email or Google to continue with Bookfania.',
            style: TextStyle(
              fontSize: 16,
              color: Constants.mutedInk,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          _AuthMethodButton(
            label:
                _googleLoading
                    ? 'Connecting to Google...'
                    : 'Continue with Google',
            leading: _AuthMark.google(),
            onTap: _continueWithGoogle,
          ),
          const SizedBox(height: 14),
          _AuthMethodButton(
            label: 'Continue with email',
            leading: _AuthMark.email(),
            onTap: _openEmailLogin,
          ),
          const SizedBox(height: 18),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Createaccount()),
                );
              },
              child: const Text(
                'Need a new account? Create one with email.',
                style: TextStyle(
                  color: Constants.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthMethodButton extends StatelessWidget {
  final String label;
  final Widget leading;
  final VoidCallback onTap;

  const _AuthMethodButton({
    required this.label,
    required this.leading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Constants.border),
          ),
          child: Row(
            children: [
              SizedBox(width: 38, child: Center(child: leading)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Constants.ink,
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

class _AuthMark extends StatelessWidget {
  final Widget child;

  const _AuthMark._(this.child);

  factory _AuthMark.google() {
    return const _AuthMark._(
      Text(
        'G',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: Color(0xFF4285F4),
        ),
      ),
    );
  }

  factory _AuthMark.email() {
    return const _AuthMark._(
      Icon(Icons.mail_outline_rounded, color: Constants.ink, size: 27),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Constants.border),
      ),
      child: child,
    );
  }
}
