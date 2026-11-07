import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Result returned on a successful Cloudinary upload.
class CloudinaryUploadResult {
  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
  });

  final String secureUrl;
  final String publicId;
}

/// Typed failures from the upload service.
class CloudinaryUploadException implements Exception {
  const CloudinaryUploadException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Handles unsigned image uploads to Cloudinary.
///
/// Configuration is supplied via compile-time `--dart-define` flags:
///   CLOUDINARY_CLOUD_NAME
///   CLOUDINARY_UPLOAD_PRESET
///
/// No Cloudinary API secret is included in the application.
class CloudinaryService {
  CloudinaryService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _cloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  static const String _uploadPreset = String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');

  static const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const Set<String> _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

  /// Whether the required Cloudinary configuration values are present.
  static bool get isConfigured =>
      _cloudName.isNotEmpty && _uploadPreset.isNotEmpty;

  /// Validates [file] against size and format requirements without uploading.
  ///
  /// Throws [CloudinaryUploadException] if validation fails.
  static void validateFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    if (!_allowedExtensions.contains(extension)) {
      throw const CloudinaryUploadException(
        'Unsupported image format. Please select a JPG, JPEG, PNG, or WebP file.',
      );
    }

    final sizeBytes = file.lengthSync();
    if (sizeBytes > _maxFileSizeBytes) {
      final sizeMb = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
      throw CloudinaryUploadException(
        'The selected image is ${sizeMb}MB. Please choose an image smaller than 5MB.',
      );
    }
  }

  /// Uploads [file] to Cloudinary using the unsigned upload preset.
  ///
  /// Returns a [CloudinaryUploadResult] on success.
  /// Throws [CloudinaryUploadException] on configuration, validation, or
  /// network errors.
  Future<CloudinaryUploadResult> uploadImage(File file) async {
    if (!isConfigured) {
      throw const CloudinaryUploadException(
        'Cloudinary is not configured. Run the app with --dart-define=CLOUDINARY_CLOUD_NAME=... --dart-define=CLOUDINARY_UPLOAD_PRESET=...',
      );
    }

    validateFile(file);

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final publicId =
        'campuscare_${DateTime.now().millisecondsSinceEpoch}_${file.path.split(Platform.pathSeparator).last.split('.').first}';

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['public_id'] = publicId
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    try {
      final streamedResponse = await _client
          .send(request)
          .timeout(const Duration(seconds: 60));

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body =
            jsonDecode(response.body) as Map<String, dynamic>;

        final secureUrl = body['secure_url'] as String?;
        final returnedPublicId = body['public_id'] as String?;

        if (secureUrl == null || secureUrl.isEmpty) {
          throw const CloudinaryUploadException(
            'Upload succeeded but the response did not include a URL. Please try again.',
          );
        }

        return CloudinaryUploadResult(
          secureUrl: secureUrl,
          publicId: returnedPublicId ?? publicId,
        );
      }

      // Parse Cloudinary error body when possible
      String errorMessage = 'Image upload failed (HTTP ${response.statusCode}).';
      try {
        final errorBody =
            jsonDecode(response.body) as Map<String, dynamic>;
        final cloudinaryError =
            errorBody['error'] as Map<String, dynamic>?;
        if (cloudinaryError != null && cloudinaryError['message'] is String) {
          errorMessage =
              'Upload failed: ${cloudinaryError['message']}';
        }
      } catch (_) {
        // Keep the generic message if the body cannot be parsed
      }

      throw CloudinaryUploadException(errorMessage);
    } on CloudinaryUploadException {
      rethrow;
    } on SocketException {
      throw const CloudinaryUploadException(
        'Network error: Could not reach Cloudinary. Please check your internet connection.',
      );
    } on http.ClientException catch (e) {
      throw CloudinaryUploadException('Upload failed: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw const CloudinaryUploadException(
          'Upload timed out. The image may be too large or your connection too slow.',
        );
      }
      throw const CloudinaryUploadException(
        'An unexpected error occurred during image upload. Please try again.',
      );
    }
  }
}

