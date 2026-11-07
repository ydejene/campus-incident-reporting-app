import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_incident_reporting_app/features/incidents/data/services/cloudinary_service.dart';

/// Unit tests for CloudinaryService validation logic.
///
/// These tests do not make network requests. Upload integration is not
/// tested here because it requires live Cloudinary credentials.
void main() {
  group('CloudinaryService – static configuration', () {
    test('isConfigured returns false when dart-define values are absent', () {
      // In the test environment --dart-define values are not passed, so the
      // compile-time constants remain empty strings.
      expect(CloudinaryService.isConfigured, isFalse);
    });
  });

  group('CloudinaryService – file validation', () {
    Directory? tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cc_test_');
    });

    tearDown(() async {
      await tempDir?.delete(recursive: true);
    });

    File createFile(String name, int sizeBytes) {
      final file = File('${tempDir!.path}/$name');
      // Write a minimal JPEG-like header so the extension check passes via path
      file.writeAsBytesSync(List.filled(sizeBytes, 0));
      return file;
    }

    test('accepts supported formats: jpg, jpeg, png, webp', () {
      for (final ext in ['jpg', 'jpeg', 'png', 'webp']) {
        final file = createFile('image.$ext', 100);
        // Should not throw
        expect(() => CloudinaryService.validateFile(file), returnsNormally);
      }
    });

    test('rejects unsupported formats: gif, bmp, tiff, pdf', () {
      for (final ext in ['gif', 'bmp', 'tiff', 'pdf']) {
        final file = createFile('image.$ext', 100);
        expect(
          () => CloudinaryService.validateFile(file),
          throwsA(isA<CloudinaryUploadException>()),
        );
      }
    });

    test('rejects files larger than 5 MB', () {
      final oversized = createFile('large.jpg', 5 * 1024 * 1024 + 1);
      expect(
        () => CloudinaryService.validateFile(oversized),
        throwsA(isA<CloudinaryUploadException>()),
      );
    });

    test('accepts files exactly at 5 MB boundary', () {
      final atLimit = createFile('limit.png', 5 * 1024 * 1024);
      // Should not throw
      expect(() => CloudinaryService.validateFile(atLimit), returnsNormally);
    });

    test('CloudinaryUploadException carries a human-readable message', () {
      final file = createFile('image.gif', 100);
      try {
        CloudinaryService.validateFile(file);
        fail('Expected CloudinaryUploadException');
      } on CloudinaryUploadException catch (e) {
        expect(e.message, isNotEmpty);
        expect(e.toString(), equals(e.message));
      }
    });
  });
}

