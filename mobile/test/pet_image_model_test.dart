import 'package:flutter_test/flutter_test.dart';
import 'package:pawfinder/core/constants/api_constants.dart';
import 'package:pawfinder/features/reports/models/pet_image_model.dart';

void main() {
  group('PetImageModel.resolveUrl', () {
    final apiUri = Uri.parse(ApiConstants.baseUrl);
    final backendPath = apiUri.path.replaceFirst(RegExp(r'/api/?$'), '');
    final backendUri = apiUri.replace(path: backendPath);

    test('resolves a backend-relative image path against the API host', () {
      expect(
        PetImageModel.resolveUrl('/static/uploads/pet.jpg'),
        backendUri.resolve('/static/uploads/pet.jpg').toString(),
      );
    });

    test('rewrites a local backend URL to the configured API host', () {
      expect(
        PetImageModel.resolveUrl('http://localhost:8000/static/uploads/pet.jpg'),
        backendUri
            .replace(
              scheme: 'http',
              host: apiUri.host,
              port: apiUri.hasPort ? apiUri.port : null,
            )
            .replace(path: '/static/uploads/pet.jpg')
            .toString(),
      );
    });

    test('preserves public storage URLs', () {
      const url = 'https://project.supabase.co/storage/v1/object/public/pet-images/pet.jpg';
      expect(PetImageModel.resolveUrl(url), url);
    });
  });
}
