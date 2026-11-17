import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/error_display.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/report_provider.dart';
import '../widgets/animal_type_selector.dart';
import '../widgets/gender_selector.dart';
import '../widgets/location_picker_input.dart';
import '../widgets/multi_image_picker_widget.dart';

class CreateReportScreen extends ConsumerStatefulWidget {
  final bool isLost;

  const CreateReportScreen({
    super.key,
    required this.isLost,
  });

  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _petNameController = TextEditingController();
  final _breedController = TextEditingController();
  final _colorController = TextEditingController();
  final _ageController = TextEditingController();
  final _featuresController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rewardController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  // State
  String _selectedAnimalType = 'Dog';
  String? _selectedGender;
  DateTime _eventDatetime = DateTime.now();
  List<XFile> _selectedImages = [];

  @override
  void dispose() {
    _petNameController.dispose();
    _breedController.dispose();
    _colorController.dispose();
    _ageController.dispose();
    _featuresController.dispose();
    _descriptionController.dispose();
    _rewardController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _eventDatetime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_eventDatetime),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _eventDatetime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final reportData = <String, dynamic>{
      'report_type': widget.isLost ? 'LOST' : 'FOUND',
      'animal_type': _selectedAnimalType,
      'color': _colorController.text.trim(),
      'distinguishing_features': _featuresController.text.trim(),
      'description': _descriptionController.text.trim(),
      'latitude': double.parse(_latitudeController.text.trim()),
      'longitude': double.parse(_longitudeController.text.trim()),
      'location_label': _addressController.text.trim(),
      'event_datetime': _eventDatetime.toUtc().toIso8601String(),
    };

    if (widget.isLost && _petNameController.text.trim().isNotEmpty) {
      reportData['pet_name'] = _petNameController.text.trim();
    }
    if (_breedController.text.trim().isNotEmpty) {
      reportData['breed'] = _breedController.text.trim();
    }
    if (_ageController.text.trim().isNotEmpty) {
      reportData['approximate_age'] = _ageController.text.trim();
    }
    if (_selectedGender != null) {
      reportData['gender'] = _selectedGender;
    }
    if (widget.isLost && _rewardController.text.trim().isNotEmpty) {
      final rewardVal = double.tryParse(_rewardController.text.trim());
      if (rewardVal != null && rewardVal > 0) {
        reportData['reward'] = rewardVal;
      }
    }

    final success = await ref.read(reportSubmissionProvider.notifier).submitReport(
          reportData: reportData,
          images: _selectedImages,
        );

    if (success && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Report Created'),
            ],
          ),
          content: Text(
            widget.isLost
                ? 'Your missing pet report has been published to the PawFinder community. We will alert you if any potential matches are found!'
                : 'Thank you for reporting this found animal! We are actively checking for matching missing-pet alerts.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(); // Back to main shell
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final submissionState = ref.watch(reportSubmissionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isLost ? 'Report Lost Pet' : 'Report Found Animal'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Error Display if submission failed
                if (submissionState.hasError) ...[
                  ErrorDisplay(
                    message: submissionState.errorMessage ?? 'Submission failed.',
                  ),
                  const SizedBox(height: 16),
                ],

                // Photos Section
                MultiImagePickerWidget(
                  images: _selectedImages,
                  onImagesChanged: (updated) {
                    setState(() {
                      _selectedImages = updated;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Animal Type
                AnimalTypeSelector(
                  selectedType: _selectedAnimalType,
                  onSelected: (type) {
                    setState(() {
                      _selectedAnimalType = type;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Pet Name (for Lost report)
                if (widget.isLost) ...[
                  CustomTextField(
                    controller: _petNameController,
                    label: 'Pet Name *',
                    hint: 'e.g. Milo, Bella',
                    prefixIcon: Icons.badge_outlined,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Pet name is required for lost reports.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Breed
                CustomTextField(
                  controller: _breedController,
                  label: widget.isLost ? 'Breed' : 'Approximate Breed',
                  hint: 'e.g. Golden Retriever, Tabby, Mix',
                  prefixIcon: Icons.pets_outlined,
                ),
                const SizedBox(height: 16),

                // Primary Color
                CustomTextField(
                  controller: _colorController,
                  label: 'Color(s) *',
                  hint: 'e.g. Black with white chest',
                  prefixIcon: Icons.palette_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Pet color is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Gender
                GenderSelector(
                  selectedGender: _selectedGender,
                  onSelected: (gender) {
                    setState(() {
                      _selectedGender = gender;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Approximate Age
                CustomTextField(
                  controller: _ageController,
                  label: 'Approximate Age',
                  hint: 'e.g. 2 years, Puppy, Senior',
                  prefixIcon: Icons.cake_outlined,
                ),
                const SizedBox(height: 16),

                // Distinguishing Features
                CustomTextField(
                  controller: _featuresController,
                  label: 'Distinguishing Features *',
                  hint: 'e.g. Floppy left ear, red collar, blue bandana',
                  prefixIcon: Icons.fingerprint,
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please describe any distinguishing marks or features.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                CustomTextField(
                  controller: _descriptionController,
                  label: 'Description & Observations *',
                  hint: 'Provide details about how the pet was lost or found...',
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Description is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date & Time Picker Tile
                InkWell(
                  onTap: _selectDateTime,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.isLost ? 'Date & Time Last Seen' : 'Date & Time Found',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('MMM dd, yyyy - hh:mm a').format(_eventDatetime),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.edit_calendar, size: 18, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Optional Reward (for lost reports only)
                if (widget.isLost) ...[
                  CustomTextField(
                    controller: _rewardController,
                    label: 'Reward Amount (Optional)',
                    hint: 'e.g. 100.00',
                    prefixIcon: Icons.attach_money,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        final val = double.tryParse(value.trim());
                        if (val == null || val < 0) {
                          return 'Reward must be a positive number.';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Location Picker
                LocationPickerInput(
                  addressController: _addressController,
                  latitudeController: _latitudeController,
                  longitudeController: _longitudeController,
                ),
                const SizedBox(height: 32),

                // Submit Button
                PrimaryButton(
                  text: widget.isLost ? 'Submit Lost Pet Report' : 'Submit Found Pet Report',
                  isLoading: submissionState.isSubmitting,
                  onPressed: _handleSubmit,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

