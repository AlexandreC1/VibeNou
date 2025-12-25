import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/two_factor_service.dart';
import '../../utils/app_logger.dart';

class TwoFactorVerifyScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onSuccess;

  const TwoFactorVerifyScreen({
    Key? key,
    required this.userId,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<TwoFactorVerifyScreen> createState() => _TwoFactorVerifyScreenState();
}

class _TwoFactorVerifyScreenState extends State<TwoFactorVerifyScreen> {
  final TwoFactorService _twoFactorService = TwoFactorService();
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();

  bool _isVerifying = false;
  bool _useRecoveryCode = false;
  int _attemptsRemaining = 3;

  @override
  void initState() {
    super.initState();
    // Auto-focus on code input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _codeFocusNode.requestFocus();
    });
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      _showError('Please enter a code');
      return;
    }

    if (!_useRecoveryCode && code.length != 6) {
      _showError('Code must be 6 digits');
      return;
    }

    if (_useRecoveryCode && code.length != 8) {
      _showError('Recovery code must be 8 digits');
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final isValid = await _twoFactorService.verifyTwoFactorLogin(
        widget.userId,
        code,
      );

      if (isValid) {
        AppLogger.info('2FA verification successful');
        widget.onSuccess();
      } else {
        setState(() {
          _attemptsRemaining--;
          _isVerifying = false;
        });

        if (_attemptsRemaining <= 0) {
          _showError('Too many failed attempts. Please try again later.');
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          _showError(
            'Invalid code. $_attemptsRemaining ${_attemptsRemaining == 1 ? "attempt" : "attempts"} remaining.',
          );
          _codeController.clear();
          _codeFocusNode.requestFocus();
        }
      }
    } catch (e) {
      _showError('Verification failed: ${e.toString()}');
      setState(() {
        _isVerifying = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _toggleRecoveryCode() {
    setState(() {
      _useRecoveryCode = !_useRecoveryCode;
      _codeController.clear();
      _codeFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Icon(
                _useRecoveryCode ? Icons.vpn_key : Icons.phone_android,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                _useRecoveryCode
                    ? 'Enter Recovery Code'
                    : 'Enter Verification Code',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                _useRecoveryCode
                    ? 'Enter one of your 8-digit recovery codes'
                    : 'Enter the 6-digit code from your authenticator app',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Code input
              TextField(
                controller: _codeController,
                focusNode: _codeFocusNode,
                keyboardType: TextInputType.number,
                maxLength: _useRecoveryCode ? 8 : 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: _useRecoveryCode ? '00000000' : '000000',
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onSubmitted: (_) => _verifyCode(),
              ),
              const SizedBox(height: 24),

              // Verify button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Verify'),
                ),
              ),
              const SizedBox(height: 16),

              // Toggle recovery code
              TextButton.icon(
                onPressed: _toggleRecoveryCode,
                icon: Icon(
                  _useRecoveryCode ? Icons.phone_android : Icons.vpn_key,
                ),
                label: Text(
                  _useRecoveryCode
                      ? 'Use Authenticator Code Instead'
                      : 'Use Recovery Code Instead',
                ),
              ),
              const SizedBox(height: 32),

              // Help text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Need Help?',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_useRecoveryCode) ...[
                      const Text(
                        '• Recovery codes are 8 digits long',
                      ),
                      const Text(
                        '• Each code can only be used once',
                      ),
                      const Text(
                        '• Find them in your saved recovery codes',
                      ),
                    ] else ...[
                      const Text(
                        '• Open your authenticator app',
                      ),
                      const Text(
                        '• Find the VibeNou entry',
                      ),
                      const Text(
                        '• Enter the 6-digit code shown',
                      ),
                      const Text(
                        '• Codes refresh every 30 seconds',
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),

              // Attempts remaining
              if (_attemptsRemaining < 3)
                Text(
                  '$_attemptsRemaining ${_attemptsRemaining == 1 ? "attempt" : "attempts"} remaining',
                  style: TextStyle(
                    color: _attemptsRemaining == 1 ? Colors.red : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }
}
