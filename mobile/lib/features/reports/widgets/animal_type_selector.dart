import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

class AnimalTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onSelected;

  const AnimalTypeSelector({
    super.key,
    required this.selectedType,
    required this.onSelected,
  });

  static const List<String> types = ['Dog', 'Cat', 'Bird', 'Other'];

  IconData _iconForType(String type) {
    switch (type) {
      case 'Dog':
        return Icons.pets;
      case 'Cat':
        return Icons.cruelty_free;
      case 'Bird':
        return Icons.flutter_dash;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Animal Type *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: types.map((type) {
            final isSelected = selectedType.toLowerCase() == type.toLowerCase();
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _iconForType(type),
                        size: 20,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ],
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
                    if (selected) {
                      onSelected(type);
                    }
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

