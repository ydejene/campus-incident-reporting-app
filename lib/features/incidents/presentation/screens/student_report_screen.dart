import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../../application/incident_submission_controller.dart';
import '../../data/services/cloudinary_service.dart';
import '../../domain/models/incident_category.dart';

class StudentReportScreen extends ConsumerStatefulWidget {
  const StudentReportScreen({super.key});

  @override
  ConsumerState<StudentReportScreen> createState() =>
      _StudentReportScreenState();
}

class _StudentReportScreenState extends ConsumerState<StudentReportScreen> {
  final _formKey = GlobalKey<FormState>();

  final _descriptionController = TextEditingController();
  final _buildingController = TextEditingController();
  final _blockController = TextEditingController();
  final _specificAreaController = TextEditingController();

  IncidentCategory? _selectedCategory;
  File? _selectedImage;
  String? _imageError;

  @override
  void dispose() {
    _descriptionController.dispose();
    _buildingController.dispose();
    _blockController.dispose();
    _specificAreaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _imageError = null);

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (picked == null) return;

    final file = File(picked.path);

    try {
      CloudinaryService.validateFile(file);
      setState(() => _selectedImage = file);
    } on CloudinaryUploadException catch (e) {
      setState(() => _imageError = e.message);
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageError = null;
    });
  }

  Future<void> _submit() async {
    // Validate the form – preserves values on failure
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) return;

    if (_selectedCategory == null) {
      // Category validation is handled inline; show a snackbar as a fallback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an incident category.')),
      );
      return;
    }

    final success = await ref
        .read(incidentSubmissionControllerProvider.notifier)
        .submitIncident(
          category: _selectedCategory!,
          description: _descriptionController.text,
          building: _buildingController.text,
          block: _blockController.text,
          specificArea: _specificAreaController.text,
          imageFile: _selectedImage,
        );

    if (success && mounted) {
      _showSuccessAndReset();
    }
  }

  void _showSuccessAndReset() {
    _formKey.currentState?.reset();
    _descriptionController.clear();
    _buildingController.clear();
    _blockController.clear();
    _specificAreaController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedImage = null;
      _imageError = null;
    });

    ref.read(incidentSubmissionControllerProvider.notifier).reset();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Incident reported successfully. Campus staff will review it shortly.',
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'My Reports',
          textColor: Colors.white,
          onPressed: () => context.go('/student/my-reports'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final submissionState = ref.watch(incidentSubmissionControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final isSubmitting = submissionState.isLoading;

    // Show persistent error from the controller
    ref.listen<IncidentSubmissionState>(
      incidentSubmissionControllerProvider,
      (previous, next) {
        if (next.status == IncidentSubmissionStatus.error &&
            next.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(next.errorMessage!)),
                ],
              ),
              backgroundColor: AppColors.accent,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 6),
            ),
          );
          ref.read(incidentSubmissionControllerProvider.notifier).reset();
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const BrandLogo(
          variant: LogoVariant.fullHorizontal,
          height: 28,
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              // Page heading
              Text('Report an Issue', style: textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                'Describe the campus issue you observed. Your report will be reviewed by authorized staff.',
                style: textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),

              // ── Category ────────────────────────────────────────────
              _SectionLabel(label: 'Category', isRequired: true),
              const SizedBox(height: 8),
              _CategorySelector(
                selected: _selectedCategory,
                enabled: !isSubmitting,
                onSelected: (cat) =>
                    setState(() => _selectedCategory = cat),
              ),
              const SizedBox(height: 20),

              // ── Description ─────────────────────────────────────────
              _SectionLabel(label: 'Description', isRequired: true),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                enabled: !isSubmitting,
                maxLines: 5,
                maxLength: 1000,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(1000),
                ],
                decoration: const InputDecoration(
                  hintText:
                      'Describe what you observed — be specific about the issue, its severity, and any relevant context.',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return 'Description is required.';
                  }
                  if (trimmed.length < 10) {
                    return 'Please provide at least 10 characters of description.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Location ─────────────────────────────────────────────
              _SectionLabel(label: 'Location', isRequired: true),
              const SizedBox(height: 4),
              Text(
                'Specify where on campus the issue was observed.',
                style: textTheme.bodySmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _buildingController,
                enabled: !isSubmitting,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Building name',
                  prefixIcon: Icon(Icons.apartment_outlined,
                      size: 20, color: AppColors.textMuted),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Building name is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _blockController,
                enabled: !isSubmitting,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'Block / Wing (optional)',
                  prefixIcon: Icon(Icons.grid_view_outlined,
                      size: 20, color: AppColors.textMuted),
                ),
                // Block is optional per the existing model and project spec
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _specificAreaController,
                enabled: !isSubmitting,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Specific area — e.g., "2nd floor restroom"',
                  prefixIcon: Icon(Icons.place_outlined,
                      size: 20, color: AppColors.textMuted),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Specific area is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Photo Attachment ─────────────────────────────────────
              _SectionLabel(label: 'Photo (Optional)'),
              const SizedBox(height: 8),
              _ImageAttachmentArea(
                imageFile: _selectedImage,
                imageError: _imageError,
                isUploading:
                    submissionState.status == IncidentSubmissionStatus.uploading,
                enabled: !isSubmitting,
                onPickImage: _pickImage,
                onRemoveImage: _removeImage,
              ),

              if (!CloudinaryService.isConfigured) ...[
                const SizedBox(height: 8),
                _ConfigWarning(
                  message:
                      'Cloudinary is not configured. Submitting without an image will work, but photo attachments require the app to be run with --dart-define=CLOUDINARY_CLOUD_NAME=... --dart-define=CLOUDINARY_UPLOAD_PRESET=...',
                ),
              ],

              const SizedBox(height: 20),

              // ── Privacy note ─────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_outline,
                      size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your identity is kept private. Your email and name are stored separately and are not visible in campus-wide incident listings.',
                      style: textTheme.bodySmall
                          ?.copyWith(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Submit button ─────────────────────────────────────────
              _SubmitButton(
                submissionState: submissionState,
                onPressed: isSubmitting ? null : _submit,
              ),
              const SizedBox(height: 20),
              Text(
                'CampusCare • ${AppStrings.appTagline}',
                style: textTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.isRequired = false});

  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 3),
          const Text(
            '*',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.selected,
    required this.onSelected,
    required this.enabled,
  });

  final IncidentCategory? selected;
  final ValueChanged<IncidentCategory> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: IncidentCategory.values.map((cat) {
        final isSelected = selected == cat;
        return Semantics(
          label: '${cat.label} category${isSelected ? ", selected" : ""}',
          button: true,
          child: FilterChip(
            label: Text(cat.label),
            selected: isSelected,
            onSelected: enabled ? (_) => onSelected(cat) : null,
            selectedColor: AppColors.primary.withValues(alpha: 0.15),
            checkmarkColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13,
            ),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ImageAttachmentArea extends StatelessWidget {
  const _ImageAttachmentArea({
    required this.imageFile,
    required this.imageError,
    required this.isUploading,
    required this.enabled,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  final File? imageFile;
  final String? imageError;
  final bool isUploading;
  final bool enabled;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (isUploading) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
          color: AppColors.background,
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Uploading image…',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (imageFile != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  imageFile!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  semanticLabel: 'Selected incident photo',
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Semantics(
                  label: 'Remove selected photo',
                  button: true,
                  child: GestureDetector(
                    onTap: enabled ? onRemoveImage : null,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tap the × to remove the photo.',
            style: textTheme.bodySmall
                ?.copyWith(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      );
    }

    return Column(
      children: [
        InkWell(
          onTap: enabled ? onPickImage : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(
                color: imageError != null
                    ? AppColors.accent
                    : AppColors.border,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(10),
              color: AppColors.background,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  color: imageError != null
                      ? AppColors.accent
                      : AppColors.textMuted,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attach a photo',
                      style: textTheme.bodyMedium?.copyWith(
                        color: imageError != null
                            ? AppColors.accent
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'JPG, PNG or WebP · Max 5 MB',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (imageError != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline,
                  size: 14, color: AppColors.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  imageError!,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.accent,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ConfigWarning extends StatelessWidget {
  const _ConfigWarning({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.statusSubmittedBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.statusSubmittedText.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_outlined,
              size: 16, color: AppColors.statusSubmittedText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.statusSubmittedText,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.submissionState,
    required this.onPressed,
  });

  final IncidentSubmissionState submissionState;
  final VoidCallback? onPressed;

  String get _label {
    return switch (submissionState.status) {
      IncidentSubmissionStatus.uploading => 'Uploading image…',
      IncidentSubmissionStatus.submitting => 'Submitting…',
      _ => 'Submit Report',
    };
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: submissionState.isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.send_outlined, size: 18),
      label: Text(_label),
    );
  }
}
