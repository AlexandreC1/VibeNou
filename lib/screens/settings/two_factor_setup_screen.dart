import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/two_factor_service.dart';
import '../../widgets/qr_code_widget.dart';
import '../../utils/app_logger.dart';

class TwoFactorSetupScreen extends StatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  State<TwoFactorSetupScreen> createState() => _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends State<TwoFactorSetupScreen> {
  final TwoFactorService _twoFactorService = TwoFactorService();
  final TextEditingController _verificationController = TextEditingController();

  String? _secret;
  String? _qrCodeUrl;
  List<String>? _recoveryCodes;
  final bool _isLoading = false;
  bool _isVerifying = false;
  bool _setupComplete = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _generateSecret();
  }

  void _generateSecret() {
    setState(() {
      _secret = _twoFactorService.generateSecret();
      _qrCodeUrl = _twoFactorService.getQRCodeUrl(
        'user@vibenou.com', // Replace with actual user email
        _secret!,
      );
      _recoveryCodes = _twoFactorService.generateRecoveryCodes();
    });
  }

  Future<void> _verifyAndEnable() async {
    if (_verificationController.text.length != 6) {
      _showError('Please enter a 6-digit code');
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      // Verify the code
      final isValid = _twoFactorService.verifyCode(
        _secret!,
        _verificationController.text,
      );

      if (!isValid) {
        _showError('Invalid code. Please try again.');
        setState(() {
          _isVerifying = false;
        });
        return;
      }

      // Enable 2FA
      await _twoFactorService.enableTwoFactor(_secret!, _recoveryCodes!);

      setState(() {
        _setupComplete = true;
        _currentStep = 2;
        _isVerifying = false;
      });

      AppLogger.info('2FA enabled successfully');
    } catch (e) {
      _showError('Failed to enable 2FA: ${e.toString()}');
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

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up 2FA'),
        leading: _setupComplete
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              currentStep: _currentStep,
              onStepContinue: _currentStep < 2 ? _nextStep : null,
              onStepCancel: _currentStep > 0 && !_setupComplete ? _previousStep : null,
              controlsBuilder: (context, details) {
                if (_setupComplete) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Done'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  );
                }
                return Row(
                  children: [
                    if (_currentStep < 2)
                      ElevatedButton(
                        onPressed: details.onStepContinue,
                        child: const Text('Next'),
                      ),
                    if (_currentStep > 0 && !_setupComplete) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Back'),
                      ),
                    ],
                  ],
                );
              },
              steps: [
                Step(
                  title: const Text('Scan QR Code'),
                  content: _buildQRCodeStep(),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: const Text('Verify Code'),
                  content: _buildVerifyStep(),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: const Text('Save Recovery Codes'),
                  content: _buildRecoveryCodesStep(),
                  isActive: _currentStep >= 2,
                  state: _setupComplete ? StepState.complete : StepState.indexed,
                ),
              ],
            ),
    );
  }

  Widget _buildQRCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1. Install an authenticator app:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('• Google Authenticator'),
        const Text('• Authy'),
        const Text('• Microsoft Authenticator'),
        const SizedBox(height: 16),
        const Text(
          '2. Scan this QR code:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Center(
          child: QRCodeWidget(
            data: _qrCodeUrl ?? '',
            size: 200,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Or enter this code manually:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  _secret ?? '',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () => _copyToClipboard(_secret ?? ''),
                tooltip: 'Copy to clipboard',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildVerifyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter the 6-digit code from your authenticator app:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _verificationController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: 'Verification Code',
            hintText: '000000',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isVerifying ? null : _verifyAndEnable,
            child: _isVerifying
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Verify and Enable 2FA'),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRecoveryCodesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange.shade700),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Save these codes in a safe place! You\'ll need them if you lose access to your authenticator app.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Recovery Codes:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._recoveryCodes!.map(
                (code) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _copyToClipboard(_recoveryCodes!.join('\n')),
                icon: const Icon(Icons.copy),
                label: const Text('Copy All'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _downloadRecoveryCodes,
                icon: const Icon(Icons.download),
                label: const Text('Download'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Important:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('• Each code can only be used once'),
        const Text('• Store them securely (password manager recommended)'),
        const Text('• Don\'t share them with anyone'),
        const SizedBox(height: 24),
      ],
    );
  }

  void _nextStep() {
    if (_currentStep == 0) {
      setState(() {
        _currentStep = 1;
      });
    } else if (_currentStep == 1) {
      _verifyAndEnable();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _downloadRecoveryCodes() {
    // In a real app, this would save to file
    _copyToClipboard(_recoveryCodes!.join('\n'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recovery codes copied. Save them to a secure location.'),
      ),
    );
  }

  @override
  void dispose() {
    _verificationController.dispose();
    super.dispose();
  }
}
