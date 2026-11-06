import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/brand_logo.dart';
import '../../../shared/widgets/status_badge.dart';

class InitialShellScreen extends StatelessWidget {
  const InitialShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const BrandLogo(
                    variant: LogoVariant.markOnly,
                    height: 84,
                  ),
                  const SizedBox(height: 16),
                  const BrandLogo(
                    variant: LogoVariant.fullHorizontal,
                    height: 38,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.appTagline,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Design System & Status Tokens',
                                style: textTheme.titleSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Status lifecycles with WCAG-compliant contrast surfaces and readable text labels:',
                            style: textTheme.bodySmall,
                          ),
                          const SizedBox(height: 14),
                          const Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              StatusBadge(status: IncidentStatus.submitted),
                              StatusBadge(status: IncidentStatus.underReview),
                              StatusBadge(status: IncidentStatus.inProgress),
                              StatusBadge(status: IncidentStatus.resolved),
                              StatusBadge(status: IncidentStatus.rejected),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Foundation Initialized'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'CampusCare Mobile Platform • Stage 1',
                    style: textTheme.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

