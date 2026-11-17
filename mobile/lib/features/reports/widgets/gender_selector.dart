import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

class GenderSelector extends StatelessWidget {
  final String? selectedGender;
  final ValueChanged<String?> onSelected;

  const GenderSelector({
    super.key,
    required this.selectedGender,
    required this.onSelected,
  });

  static const List<String> genders = ['Male', 'Female', 'Unknown'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: genders.map((gender) {
            final isSelected = selectedGender?.toLowerCase() == gender.toLowerCase();
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Center(
                    child: Text(
                      gender,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  onSelected: (selected) {
                    onSelected(selected ? gender : null);
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

