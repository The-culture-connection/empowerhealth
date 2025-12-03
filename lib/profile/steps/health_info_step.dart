import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_creation_provider.dart';
import '../../cors/ui_theme.dart';

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
            const Text(
              'Your health information helps us provide personalized care and resources.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: AppTheme.spacingXL),

            // Pregnancy Stage
            DropdownButtonFormField<String>(
              value: provider.pregnancyStage,
              decoration: const InputDecoration(
                labelText: 'Pregnancy Stage',
                hintText: 'Select your stage',
                prefixIcon: Icon(Icons.pregnant_woman),
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
            const SizedBox(height: AppTheme.spacingXL),

            // Chronic Conditions
            _buildSectionHeader('Chronic Conditions'),
            const SizedBox(height: AppTheme.spacingS),
            const Text(
              'e.g., hypertension, diabetes, asthma',
              style: TextStyle(fontSize: 14, color: Colors.black54),
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
            const SizedBox(height: AppTheme.spacingS),
            const Text(
              'List all medications you are currently taking',
              style: TextStyle(fontSize: 14, color: Colors.black54),
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
            const SizedBox(height: AppTheme.spacingS),
            const Text(
              'List any known allergies',
              style: TextStyle(fontSize: 14, color: Colors.black54),
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
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.brandPurple,
        fontFamily: 'Primary',
      ),
    );
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacingM),
          ...items.asMap().entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.brandWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => onRemove(entry.key),
                    color: Colors.red,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
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






