import 'package:flutter/material.dart';
import '../services/account_lockout_service.dart';

/// Widget to display account lockout messages
class LockoutMessageWidget extends StatelessWidget {
  final LockoutStatus lockoutStatus;

  const LockoutMessageWidget({
    super.key,
    required this.lockoutStatus,
  });

  @override
  Widget build(BuildContext context) {
    final message = lockoutStatus.getMessage();

    if (message.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: lockoutStatus.isLocked
            ? Colors.red.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: lockoutStatus.isLocked
              ? Colors.red
              : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            lockoutStatus.isLocked
                ? Icons.lock_outline
                : Icons.warning_amber_outlined,
            color: lockoutStatus.isLocked
                ? Colors.red
                : Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: lockoutStatus.isLocked
                    ? Colors.red.shade700
                    : Colors.orange.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog to show when account is locked
class AccountLockedDialog extends StatelessWidget {
  final LockoutStatus lockoutStatus;

  const AccountLockedDialog({
    super.key,
    required this.lockoutStatus,
  });

  @override
  Widget build(BuildContext context) {
    final duration = lockoutStatus.lockedUntil?.difference(DateTime.now());
    final minutes = duration?.inMinutes ?? 0;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.red, size: 28),
          SizedBox(width: 12),
          Text('Account Locked'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your account has been temporarily locked due to too many failed login attempts.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    minutes > 0
                        ? 'Try again in $minutes minute${minutes != 1 ? 's' : ''}'
                        : 'You can try again shortly',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Security Tips:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          _buildTip('• Double-check your email and password'),
          _buildTip('• Make sure Caps Lock is off'),
          _buildTip('• Use the "Forgot Password?" option if needed'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        tip,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  /// Show the account locked dialog
  static Future<void> show(BuildContext context, LockoutStatus lockoutStatus) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AccountLockedDialog(lockoutStatus: lockoutStatus),
    );
  }
}
