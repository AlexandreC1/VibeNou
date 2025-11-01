import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';
import '../services/report_service.dart';
import '../utils/app_theme.dart';

class ReportDialog extends StatefulWidget {
  final UserModel reportedUser;
  final String reporterUserId;

  const ReportDialog({
    super.key,
    required this.reportedUser,
    required this.reporterUserId,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final ReportService _reportService = ReportService();
  final TextEditingController _descriptionController = TextEditingController();

  ReportReason? _selectedReason;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a reason'),
          backgroundColor: AppTheme.coral,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _reportService.submitReport(
        reporterId: widget.reporterUserId,
        reportedUserId: widget.reportedUser.uid,
        reason: _selectedReason!,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.reportSubmitted,
            ),
            backgroundColor: AppTheme.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: $e'),
            backgroundColor: AppTheme.coral,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(localizations.reportUser),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report ${widget.reportedUser.name}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              localizations.reportReason,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            _buildReasonOption(
              ReportReason.harassment,
              localizations.harassment,
              Icons.warning_outlined,
            ),
            _buildReasonOption(
              ReportReason.inappropriateContent,
              localizations.inappropriateContent,
              Icons.block_outlined,
            ),
            _buildReasonOption(
              ReportReason.spam,
              localizations.spam,
              Icons.report_outlined,
            ),
            _buildReasonOption(
              ReportReason.fakeProfile,
              localizations.fakeProfile,
              Icons.person_off_outlined,
            ),
            _buildReasonOption(
              ReportReason.other,
              localizations.other,
              Icons.more_horiz,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Additional details (optional)',
                hintText: 'Describe what happened...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(localizations.cancel),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.coral,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(localizations.submit),
        ),
      ],
    );
  }

  Widget _buildReasonOption(ReportReason reason, String label, IconData icon) {
    final isSelected = _selectedReason == reason;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedReason = reason;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryBlue.withOpacity(0.1)
                : Colors.transparent,
            border: Border.all(
              color: isSelected ? AppTheme.primaryBlue : AppTheme.borderColor,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
