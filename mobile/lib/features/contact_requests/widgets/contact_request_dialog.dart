import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../providers/contact_request_provider.dart';

class ContactRequestDialog extends ConsumerStatefulWidget {
  final String reportId;
  final String petDisplayName;

  const ContactRequestDialog({
    super.key,
    required this.reportId,
    required this.petDisplayName,
  });

  @override
  ConsumerState<ContactRequestDialog> createState() => _ContactRequestDialogState();
}

class _ContactRequestDialogState extends ConsumerState<ContactRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _contactInfoController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _messageController.dispose();
    _contactInfoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final repo = ref.read(contactRequestRepositoryProvider);
      await repo.createContactRequest(
        reportId: widget.reportId,
        message: _messageController.text.trim(),
        senderContactInfo: _contactInfoController.text.trim().isNotEmpty
            ? _contactInfoController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact request sent! The owner will be notified.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.send_rounded, color: AppColors.primary, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Contact Regarding ${widget.petDisplayName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Protecting Pet Parents & Finders:\nYour private contact info is only shared after the recipient accepts your request.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _messageController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Message *',
                  hintText: 'Describe details, sightings, or questions...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a message';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _contactInfoController,
                decoration: InputDecoration(
                  labelText: 'Preferred Contact Method (Optional)',
                  hintText: 'e.g., Phone +1-555-0199 or WhatsApp',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppColors.surface,
                  helperText: 'Revealed to owner only upon acceptance',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Send Request'),
        ),
      ],
    );
  }
}
