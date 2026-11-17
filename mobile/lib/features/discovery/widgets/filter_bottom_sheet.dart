import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../providers/discovery_provider.dart';

class FilterBottomSheet extends StatefulWidget {
  final DiscoveryFilterState initialFilters;
  final ValueChanged<DiscoveryFilterState> onApply;

  const FilterBottomSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required DiscoveryFilterState initialFilters,
    required ValueChanged<DiscoveryFilterState> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => FilterBottomSheet(
        initialFilters: initialFilters,
        onApply: onApply,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String? _reportType;
  late String? _animalType;
  late TextEditingController _breedController;
  late TextEditingController _colorController;
  late String _sortBy;
  late String _sortOrder;

  final List<String> _animalTypes = ['Dog', 'Cat', 'Bird', 'Rabbit', 'Other'];

  @override
  void initState() {
    super.initState();
    _reportType = widget.initialFilters.reportType;
    _animalType = widget.initialFilters.animalType;
    _breedController = TextEditingController(text: widget.initialFilters.breed ?? '');
    _colorController = TextEditingController(text: widget.initialFilters.color ?? '');
    _sortBy = widget.initialFilters.sortBy;
    _sortOrder = widget.initialFilters.sortOrder;
  }

  @override
  void dispose() {
    _breedController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _clearAll() {
    setState(() {
      _reportType = null;
      _animalType = null;
      _breedController.clear();
      _colorController.clear();
      _sortBy = 'created_at';
      _sortOrder = 'desc';
    });
  }

  void _apply() {
    final updated = widget.initialFilters.copyWith(
      reportType: _reportType,
      clearReportType: _reportType == null,
      animalType: _animalType,
      clearAnimalType: _animalType == null,
      breed: _breedController.text.trim(),
      clearBreed: _breedController.text.trim().isEmpty,
      color: _colorController.text.trim(),
      clearColor: _colorController.text.trim().isEmpty,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
    );
    widget.onApply(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters & Sorting',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: _clearAll,
                  child: const Text('Reset All', style: TextStyle(color: AppColors.secondary)),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),
            // Report Type Selection
            const Text(
              'Report Type',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildChoiceChip('All', _reportType == null, () {
                  setState(() => _reportType = null);
                }),
                const SizedBox(width: 8),
                _buildChoiceChip('Lost Only', _reportType == 'LOST', () {
                  setState(() => _reportType = 'LOST');
                }),
                const SizedBox(width: 8),
                _buildChoiceChip('Found Only', _reportType == 'FOUND', () {
                  setState(() => _reportType = 'FOUND');
                }),
              ],
            ),
            const SizedBox(height: 20),
            // Animal Type Selection
            const Text(
              'Animal Type',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChoiceChip('Any', _animalType == null, () {
                  setState(() => _animalType = null);
                }),
                ..._animalTypes.map((type) => _buildChoiceChip(
                      type,
                      _animalType == type,
                      () => setState(() => _animalType = type),
                    )),
              ],
            ),
            const SizedBox(height: 20),
            // Breed input
            const Text(
              'Breed',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _breedController,
              decoration: InputDecoration(
                hintText: 'e.g. Golden Retriever, Siamese',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            // Color input
            const Text(
              'Color',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _colorController,
              decoration: InputDecoration(
                hintText: 'e.g. Golden, Brown, Black & White',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            // Sort Options
            const Text(
              'Sort By',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _sortBy,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'created_at', child: Text('Date Listed')),
                      DropdownMenuItem(value: 'event_datetime', child: Text('Event Date')),
                      DropdownMenuItem(value: 'reward', child: Text('Reward Amount')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _sortBy = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.outlined(
                  icon: Icon(_sortOrder == 'desc' ? Icons.arrow_downward : Icons.arrow_upward),
                  tooltip: _sortOrder == 'desc' ? 'Descending' : 'Ascending',
                  onPressed: () {
                    setState(() {
                      _sortOrder = _sortOrder == 'desc' ? 'asc' : 'desc';
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 28),
            // Apply Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

