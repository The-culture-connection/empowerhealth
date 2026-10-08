import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/profile_creation_provider.dart';
import '../../cors/ui_theme.dart';
import '../../design_system/hearth.dart';

class BasicInfoStep extends StatefulWidget {
  const BasicInfoStep({super.key});

  @override
  State<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends State<BasicInfoStep> {
  final _formKey = GlobalKey<FormState>();
  final _zipCodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _childAgeMonthsController = TextEditingController();
  final _formRecruitmentKey = GlobalKey<FormFieldState<String>>();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ProfileCreationProvider>(context, listen: false);
    _zipCodeController.text = provider.zipCode;
    _cityController.text = provider.city;
    _stateController.text = provider.state;
    _childAgeMonthsController.text = provider.childAgeMonths?.toString() ?? '';
  }

  @override
  void dispose() {
    _zipCodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _childAgeMonthsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileCreationProvider>(
      builder: (context, provider, child) {
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Let\'s start with some basic information about you.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppTheme.spacingXL),

              _buildSectionHeader('Research study (optional)'),
              const SizedBox(height: AppTheme.spacingM),
              HearthCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                // Not .adaptive: the Cupertino switch ignores the Hearth switch colours.
                child: SwitchListTile(
                  value: provider.enrollInResearchStudy,
                  onChanged: provider.updateEnrollInResearchStudy,
                  title: const Text(
                    'Join the EmpowerHealth Watch research study',
                    style: hearthCardTitleStyle,
                  ),
                  subtitle: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'If you turn this on, after saving your profile you will complete a short '
                      'research enrollment (study ID and baseline survey). Your name and email are '
                      'not stored in the research dataset.',
                      style: hearthCardBodyStyle,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),

              // Recruitment source
              _buildSectionHeader('How did you hear about EmpowerHealth Watch?'),
              const SizedBox(height: AppTheme.spacingM),
              _buildFieldLabel('Select an option'),
              DropdownButtonFormField<String>(
                isExpanded: true,
                isDense: false,
                itemHeight: null,
                key: _formRecruitmentKey,
                value: provider.recruitmentSource,
                icon: _dropdownIcon,
                dropdownColor: AppTheme.surface,
                borderRadius: hearthCardRadius,
                decoration: const InputDecoration(
                  helperText: 'This helps us understand how people find the app',
                  helperMaxLines: 3,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'doula',
                    child: Text('Doula'),
                  ),
                  DropdownMenuItem(
                    value: 'chw',
                    child: Text('Community Health Worker (CHW)'),
                  ),
                  DropdownMenuItem(
                    value: 'home_visitor',
                    child: Text('Home Visitor'),
                  ),
                  DropdownMenuItem(
                    value: 'cbo',
                    child: Text('Community-based organization (CBO)'),
                  ),
                  DropdownMenuItem(
                    value: 'social_media',
                    child: Text('Social Media'),
                  ),
                  DropdownMenuItem(
                    value: 'event',
                    child: Text('Event'),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text('Other'),
                  ),
                ],
                onChanged: (value) {
                  provider.updateBasicInfo(recruitmentSource: value);
                },
              ),
              const SizedBox(height: AppTheme.spacingXL),

              // Username
              _buildFieldLabel('Username'),
              TextFormField(
                initialValue: provider.username,
                decoration: const InputDecoration(
                  hintText: 'Choose a username',
                  prefixIcon: Icon(Icons.person_outline, color: AppTheme.brandPurple),
                  helperText: 'This will be displayed in the community and reviews',
                  helperMaxLines: 3,
                  errorMaxLines: 3,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  if (value.length < 3) {
                    return 'Username must be at least 3 characters';
                  }
                  if (value.length > 20) {
                    return 'Username must be 20 characters or less';
                  }
                  // Check for valid characters (alphanumeric, underscore, hyphen)
                  if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
                    return 'Username can only contain letters, numbers, underscores, and hyphens';
                  }
                  return null;
                },
                onChanged: (value) {
                  provider.updateBasicInfo(username: value.trim());
                },
              ),
              const SizedBox(height: AppTheme.spacingXL),

              // Age
              _buildFieldLabel('Age'),
              TextFormField(
                initialValue: provider.age.toString(),
                decoration: const InputDecoration(
                  hintText: 'Enter your age',
                  prefixIcon: Icon(Icons.cake_outlined, color: AppTheme.brandPurple),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your age';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 13 || age > 100) {
                    return 'Please enter a valid age';
                  }
                  return null;
                },
                onChanged: (value) {
                  final age = int.tryParse(value);
                  if (age != null) {
                    provider.updateBasicInfo(age: age);
                  }
                },
              ),
              const SizedBox(height: AppTheme.spacingXL),

              // Pregnancy Status - Single Select
              _buildSectionHeader('Pregnancy Status'),
              const SizedBox(height: AppTheme.spacingM),

              HearthOptionRow(
                label: 'I am currently pregnant',
                selected: provider.isPregnant,
                onTap: () {
                  provider.updateBasicInfo(isPregnant: true, isPostpartum: false);
                },
              ),

              if (provider.isPregnant) ...[
                const SizedBox(height: AppTheme.spacingS),
                _buildDateField(
                  label: 'Due Date',
                  value: provider.dueDate != null
                      ? DateFormat('MMMM d, yyyy').format(provider.dueDate!)
                      : 'Tap to select',
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: provider.dueDate ?? DateTime.now().add(const Duration(days: 180)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      provider.updateBasicInfo(dueDate: date);
                    }
                  },
                ),
                if (provider.dueDate != null) ...[
                  const SizedBox(height: AppTheme.spacingS),
                  HearthNote(
                    tone: HearthNoteTone.lavender,
                    child: Text(
                      'Current Trimester: ${_calculateTrimester(provider.dueDate)}',
                      style: const TextStyle(
                        fontFamily: AppTheme.sansFamily,
                        fontSize: 15,
                        height: 22 / 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: AppTheme.spacingS),

              HearthOptionRow(
                label: 'I am postpartum',
                selected: !provider.isPregnant && provider.isPostpartum,
                onTap: () {
                  provider.updateBasicInfo(isPregnant: false, isPostpartum: true);
                },
              ),

              if (provider.isPostpartum) ...[
                const SizedBox(height: AppTheme.spacingS),
                _buildDateField(
                  label: 'Delivery Date',
                  value: provider.deliveryDate != null
                      ? DateFormat('MMMM d, yyyy').format(provider.deliveryDate!)
                      : 'Tap to select',
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: provider.deliveryDate ?? DateTime.now().subtract(const Duration(days: 30)),
                      firstDate: DateTime.now().subtract(const Duration(days: 730)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      provider.updateBasicInfo(deliveryDate: date);
                    }
                  },
                ),
                if (provider.deliveryDate != null) ...[
                  const SizedBox(height: AppTheme.spacingL),
                  _buildFieldLabel('Child\'s Age (in months)'),
                  TextFormField(
                    controller: _childAgeMonthsController,
                    decoration: const InputDecoration(
                      hintText: 'Auto-calculated from delivery date',
                      prefixIcon: Icon(Icons.child_care, color: AppTheme.brandPurple),
                    ),
                    keyboardType: TextInputType.number,
                    readOnly: true,
                  ),
                ],
              ],

              const SizedBox(height: AppTheme.spacingXL),

              // Zip Code
              _buildFieldLabel('Zip Code'),
              TextFormField(
                controller: _zipCodeController,
                decoration: const InputDecoration(
                  hintText: 'Enter your zip code',
                  prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.brandPurple),
                  errorMaxLines: 2,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your zip code';
                  }
                  if (value.length != 5) {
                    return 'Please enter a valid 5-digit zip code';
                  }
                  return null;
                },
                onChanged: (value) {
                  provider.updateBasicInfo(zipCode: value);
                },
              ),
              const SizedBox(height: AppTheme.spacingXL),

              // City
              _buildFieldLabel('City'),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  hintText: 'Enter your city',
                  prefixIcon: Icon(Icons.location_city_outlined, color: AppTheme.brandPurple),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your city';
                  }
                  return null;
                },
                onChanged: (value) {
                  provider.updateBasicInfo(city: value);
                },
              ),
              const SizedBox(height: AppTheme.spacingXL),

              // State
              _buildFieldLabel('State'),
              TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(
                  hintText: 'Enter your state (e.g., OH)',
                  prefixIcon: Icon(Icons.map_outlined, color: AppTheme.brandPurple),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your state';
                  }
                  return null;
                },
                onChanged: (value) {
                  provider.updateBasicInfo(state: value.toUpperCase());
                },
              ),
              const SizedBox(height: AppTheme.spacingXL),

              // Insurance Type
              _buildFieldLabel('Insurance Type'),
              DropdownButtonFormField<String>(
                isExpanded: true,
                isDense: false,
                itemHeight: null,
                value: provider.insuranceType.isEmpty ? null : provider.insuranceType,
                icon: _dropdownIcon,
                dropdownColor: AppTheme.surface,
                borderRadius: hearthCardRadius,
                decoration: const InputDecoration(
                  hintText: 'Select your insurance type',
                  prefixIcon: Icon(Icons.medical_services_outlined, color: AppTheme.brandPurple),
                  errorMaxLines: 2,
                ),
                items: const [
                  DropdownMenuItem(value: 'Private', child: Text('Private Insurance')),
                  DropdownMenuItem(value: 'Medicaid', child: Text('Medicaid')),
                  DropdownMenuItem(value: 'Medicare', child: Text('Medicare')),
                  DropdownMenuItem(value: 'Uninsured', child: Text('Uninsured')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your insurance type';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value != null) {
                    provider.updateBasicInfo(insuranceType: value);
                  }
                },
              ),
              const SizedBox(height: AppTheme.spacingXXL),
            ],
          ),
        );
      },
    );
  }

  static const Widget _dropdownIcon = Icon(Icons.expand_more, color: AppTheme.brandPurple);

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  // Labels sit above the field, as in the Hearth forms.
  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.ink),
      ),
    );
  }

  // Tappable date row drawn like a field: label, value, calendar icon.
  Widget _buildDateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return HearthCard(
      onTap: onTap,
      radius: BorderRadius.circular(AppTheme.fieldRadius),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.ink),
                ),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          const Icon(Icons.calendar_today_outlined, size: 22, color: AppTheme.brandPurple),
        ],
      ),
    );
  }

  String _calculateTrimester(DateTime? dueDate) {
    if (dueDate == null) return 'First';

    final now = DateTime.now();
    final daysUntilDue = dueDate.difference(now).inDays;
    final weeksPregnant = 40 - (daysUntilDue / 7).floor();

    if (weeksPregnant <= 0) return 'First';
    if (weeksPregnant <= 13) return 'First';
    if (weeksPregnant <= 27) return 'Second';
    return 'Third';
  }
}
