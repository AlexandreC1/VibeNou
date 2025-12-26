import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/email_verification_service.dart';
import '../../utils/app_logger.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final EmailVerificationService _verificationService =
      EmailVerificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isChecking = false;
  bool _canResend = true;
  int _resendCooldown = 0;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _sendInitialVerificationEmail();
    _startListeningForVerification();
  }

  /// Send verification email when screen first loads
  Future<void> _sendInitialVerificationEmail() async {
    try {
      await _verificationService.sendVerificationEmail();
      setState(() {
        _statusMessage = 'Verification email sent!';
      });
    } catch (e) {
      AppLogger.error('Failed to send initial verification email', e);
      setState(() {
        _statusMessage = 'Failed to send email. Please try again.';
      });
    }
  }

  /// Listen for email verification in real-time
  void _startListeningForVerification() {
    _verificationService
        .waitForVerification(timeout: const Duration(minutes: 10))
        .listen(
      (isVerified) {
        if (isVerified && mounted) {
          // Email verified! Navigate to main screen
          Navigator.of(context).pushReplacementNamed('/main');
        }
      },
      onError: (error) {
        AppLogger.error('Error waiting for verification', error);
      },
    );
  }

  /// Manually check verification status
  Future<void> _checkVerification() async {
    setState(() {
      _isChecking = true;
      _statusMessage = 'Checking verification status...';
    });

    try {
      final isVerified = await _verificationService.isEmailVerified();

      if (isVerified && mounted) {
        setState(() {
          _statusMessage = 'Email verified successfully!';
        });

        // Navigate to main screen
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/main');
        }
      } else {
        setState(() {
          _statusMessage = 'Email not verified yet. Please check your inbox.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to check verification status.';
      });
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  /// Resend verification email with cooldown
  Future<void> _resendEmail() async {
    if (!_canResend) return;

    setState(() {
      _canResend = false;
      _resendCooldown = 60;
      _statusMessage = 'Sending verification email...';
    });

    try {
      await _verificationService.sendVerificationEmail();

      setState(() {
        _statusMessage = 'Verification email sent! Check your inbox.';
      });

      // Start cooldown timer
      _startCooldownTimer();
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to send email. Please try again.';
        _canResend = true;
      });
    }
  }

  /// Countdown timer for resend cooldown
  void _startCooldownTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendCooldown > 0) {
        setState(() {
          _resendCooldown--;
        });
        _startCooldownTimer();
      } else if (mounted) {
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  /// Sign out and return to login
  Future<void> _signOut() async {
    try {
      await _verificationService.signOutAndRetry();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign out: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final email = user?.email ?? 'your email';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Email icon
              Icon(
                Icons.email_outlined,
                size: 100,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Verify Your Email',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'We sent a verification link to:',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Email address
              Text(
                email,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Steps:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _buildInstructionItem('1. Check your email inbox'),
                    _buildInstructionItem('2. Click the verification link'),
                    _buildInstructionItem('3. Return to this app'),
                    _buildInstructionItem(
                        '4. Tap "I\'ve Verified" button below'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Status message
              if (_statusMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(color: Colors.green.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Check verification button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isChecking ? null : _checkVerification,
                  icon: _isChecking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                      _isChecking ? 'Checking...' : 'I\'ve Verified My Email'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Resend email button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _canResend ? _resendEmail : null,
                  icon: const Icon(Icons.send),
                  label: Text(
                    _canResend
                        ? 'Resend Verification Email'
                        : 'Resend in ${_resendCooldown}s',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Help text
              Text(
                'Didn\'t receive the email?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Check your spam folder or use a different email address.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Sign out button
              TextButton(
                onPressed: _signOut,
                child: const Text('Use Different Email Address'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
