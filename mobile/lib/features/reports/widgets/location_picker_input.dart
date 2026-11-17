import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/custom_text_field.dart';

class LocationPickerInput extends StatelessWidget {
  final TextEditingController addressController;
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;

  const LocationPickerInput({
    super.key,
    required this.addressController,
    required this.latitudeController,
    required this.longitudeController,
  });

  void _autofillSampleGps(BuildContext context) {
    // Default simulated device GPS coordinate (San Francisco downtown landmark)
    latitudeController.text = '37.7749';
    longitudeController.text = '-122.4194';
    if (addressController.text.trim().isEmpty) {
      addressController.text = 'Market Street & 4th, San Francisco, CA';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Acquired GPS coordinates')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Location Details *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: () => _autofillSampleGps(context),
              icon: const Icon(Icons.my_location, size: 16),
              label: const Text('Use Current GPS'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        CustomTextField(
          controller: addressController,
          label: 'Location Label / Street Address',
          hint: 'e.g. Central Park near the fountain',
          prefixIcon: Icons.location_on_outlined,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Location description is required.';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: latitudeController,
                label: 'Latitude',
                hint: 'e.g. 37.7749',
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null || parsed < -90 || parsed > 90) {
                    return '-90 to 90';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: longitudeController,
                label: 'Longitude',
                hint: 'e.g. -122.4194',
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null || parsed < -180 || parsed > 180) {
                    return '-180 to 180';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

