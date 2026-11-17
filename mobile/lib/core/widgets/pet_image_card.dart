import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../../features/reports/models/pet_image_model.dart';

class PetImageCard extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;
  final Widget? overlay;

  const PetImageCard({
    super.key,
    this.imageUrl,
    this.width = double.infinity,
    this.height = 180,
    this.borderRadius = 16,
    this.fit = BoxFit.cover,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        children: [
          Container(
            width: width,
            height: height,
            color: AppColors.surfaceVariant,
            child: (imageUrl != null && imageUrl!.isNotEmpty)
                ? Image.network(
                    PetImageModel.resolveUrl(imageUrl!),
                    width: width,
                    height: height,
                    fit: fit,
                    errorBuilder: (context, error, stackTrace) => _placeholder(),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      );
                    },
                  )
                : _placeholder(),
          ),
          // ignore: use_null_aware_elements
          if (overlay != null) overlay!,
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.pets, size: 40, color: AppColors.textMuted),
          SizedBox(height: 6),
          Text(
            'PawFinder',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

