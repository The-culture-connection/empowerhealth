import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_creation_provider.dart';
import '../../cors/ui_theme.dart';
import '../../design_system/hearth.dart';

class HealthInfoStep extends StatefulWidget {
  const HealthInfoStep({super.key});

  @override
  State<HealthInfoStep> createState() => _HealthInfoStepState();
}

class _HealthInfoStepState extends State<HealthInfoStep> {
  final _conditionController = TextEditingController();
  final _medicationController = TextEditingController();
  final _allergyController = TextEditingController();

  @override
  void dispose() {
    _conditionController.dispose();
    _medicationController.dispose();
    _allergyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileCreationProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your health information helps us provide personalized care and resources.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppTheme.spacingXL),

            // Pregnancy Stage - Auto-calculated if pregnant, otherwise allow selection
            if (provider.isPregnant && provider.dueDate != null) ...[
              // Show calculated trimester as read-only
              HearthNote(
                tone: HearthNoteTone.lavender,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pregnancy Stage (Auto-calculated)',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _calculateTrimester(provider.dueDate),
                      style: hearthCardTitleStyle,
                    ),
                  ],
                ),
              ),
              // Auto-update provider with calculated trimester
              Builder(
                builder: (context) {
                  final calculatedStage = _calculateTrimester(provider.dueDate);
                  if (provider.pregnancyStage != calculatedStage) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      provider.updateHealthInfo(pregnancyStage: calculatedStage);
                    });
                  }
                  return const SizedBox.shrink();
                },
              ),
            ] else ...[
              // Allow manual selection for postpartum or if not pregnant
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
                child: Text(
                  'Pregnancy Stage',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.ink),
                ),
              ),
              DropdownButtonFormField<String>(
                isExpanded: true,
                isDense: false,
                itemHeight: null,
                value: provider.pregnancyStage,
                icon: const Icon(Icons.expand_more, color: AppTheme.brandPurple),
                dropdownColor: AppTheme.surface,
                borderRadius: hearthCardRadius,
                decoration: const InputDecoration(
                  hintText: 'Select your stage',
                  prefixIcon: Icon(Icons.pregnant_woman, color: AppTheme.brandPurple),
                ),
                items: const [
                  DropdownMenuItem(value: 'First Trimester', child: Text('First Trimester (1-12 weeks)')),
                  DropdownMenuItem(value: 'Second Trimester', child: Text('Second Trimester (13-26 weeks)')),
                  DropdownMenuItem(value: 'Third Trimester', child: Text('Third Trimester (27-40 weeks)')),
                  DropdownMenuItem(value: '0-6 weeks postpartum', child: Text('0-6 weeks postpartum')),
                  DropdownMenuItem(value: '6-12 weeks postpartum', child: Text('6-12 weeks postpartum')),
                  DropdownMenuItem(value: '3-6 months postpartum', child: Text('3-6 months postpartum')),
                  DropdownMenuItem(value: '6-12 months postpartum', child: Text('6-12 months postpartum')),
                  DropdownMenuItem(value: '12+ months postpartum', child: Text('12+ months postpartum')),
                ],
                onChanged: (value) {
                  provider.updateHealthInfo(pregnancyStage: value);
                },
              ),
            ],
            const SizedBox(height: AppTheme.spacingXL),

            // Chronic Conditions
            _buildSectionHeader('Chronic Conditions'),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              'e.g., hypertension, diabetes, asthma',
              style: _captionStyle(context),
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            _buildListInput(
              controller: _conditionController,
              items: provider.chronicConditions,
              onAdd: () {
                if (_conditionController.text.isNotEmpty) {
                  final updated = List<String>.from(provider.chronicConditions)
                    ..add(_conditionController.text);
                  provider.updateHealthInfo(chronicConditions: updated);
                  _conditionController.clear();
                }
              },
              onRemove: (index) {
                final updated = List<String>.from(provider.chronicConditions)
                  ..removeAt(index);
                provider.updateHealthInfo(chronicConditions: updated);
              },
              hintText: 'Add a condition',
            ),
            const SizedBox(height: AppTheme.spacingXL),

            // Medications
            _buildSectionHeader('Current Medications'),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              'List all medications you are currently taking',
              style: _captionStyle(context),
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            _buildListInput(
              controller: _medicationController,
              items: provider.medications,
              onAdd: () {
                if (_medicationController.text.isNotEmpty) {
                  final updated = List<String>.from(provider.medications)
                    ..add(_medicationController.text);
                  provider.updateHealthInfo(medications: updated);
                  _medicationController.clear();
                }
              },
              onRemove: (index) {
                final updated = List<String>.from(provider.medications)
                  ..removeAt(index);
                provider.updateHealthInfo(medications: updated);
              },
              hintText: 'Add a medication',
            ),
            const SizedBox(height: AppTheme.spacingXL),

            // Allergies
            _buildSectionHeader('Allergies'),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              'List any known allergies',
              style: _captionStyle(context),
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            _buildListInput(
              controller: _allergyController,
              items: provider.allergies,
              onAdd: () {
                if (_allergyController.text.isNotEmpty) {
                  final updated = List<String>.from(provider.allergies)
                    ..add(_allergyController.text);
                  provider.updateHealthInfo(allergies: updated);
                  _allergyController.clear();
                }
              },
              onRemove: (index) {
                final updated = List<String>.from(provider.allergies)
                  ..removeAt(index);
                provider.updateHealthInfo(allergies: updated);
              },
              hintText: 'Add an allergy',
            ),
            const SizedBox(height: AppTheme.spacingXXL),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  TextStyle? _captionStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted);

  String _calculateTrimester(DateTime? dueDate) {
    if (dueDate == null) return 'First Trimester';
    
    final now = DateTime.now();
    final daysUntilDue = dueDate.difference(now).inDays;
    final weeksPregnant = 40 - (daysUntilDue / 7).floor();
    
    if (weeksPregnant <= 0) return 'First Trimester';
    if (weeksPregnant <= 13) return 'First Trimester';
    if (weeksPregnant <= 27) return 'Second Trimester';
    return 'Third Trimester';
  }

  Widget _buildListInput({
    required TextEditingController controller,
    required List<String> items,
    required VoidCallback onAdd,
    required Function(int) onRemove,
    required String hintText,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hintText,
                ),
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 10),
            HearthButton.primary(
              label: 'Add',
              onPressed: onAdd,
              expand: false,
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacingM),
          ...items.asMap().entries.map((entry) {
            return HearthCard(
              margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
              radius: BorderRadius.circular(AppTheme.fieldRadius),
              padding: const EdgeInsets.fromLTRB(16, 3, 4, 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        fontFamily: AppTheme.sansFamily,
                        fontSize: 15,
                        height: 22 / 15,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => onRemove(entry.key),
                    color: AppTheme.ink,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}






