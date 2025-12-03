import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/profile_creation_provider.dart';
import '../../cors/ui_theme.dart';

class BasicInfoStep extends StatefulWidget {
  const BasicInfoStep({super.key});

  @override
  State<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends State<BasicInfoStep> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _zipCodeController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ProfileCreationProvider>(context, listen: false);
    _nameController.text = provider.name;
    _zipCodeController.text = provider.zipCode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _zipCodeController.dispose();
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
              const Text(
                'Let\'s start with some basic information about you.',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: AppTheme.spacingXL),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
                onChanged: (value) {
                  provider.updateBasicInfo(name: value);
                },
              ),
              const SizedBox(height: AppTheme.spacingL),

              // Age
              TextFormField(
                initialValue: provider.age.toString(),
                decoration: const InputDecoration(
                  labelText: 'Age',
                  hintText: 'Enter your age',
                  prefixIcon: Icon(Icons.cake_outlined),
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

              // Pregnancy Status
              _buildSectionHeader('Pregnancy Status'),
              const SizedBox(height: AppTheme.spacingM),
              
              CheckboxListTile(
                title: const Text('I am currently pregnant'),
                value: provider.isPregnant,
                activeColor: AppTheme.brandPurple,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  provider.updateBasicInfo(isPregnant: value ?? false);
                  if (value == false) {
                    provider.updateBasicInfo(dueDate: null);
                  }
                },
              ),

              if (provider.isPregnant) ...[
                const SizedBox(height: AppTheme.spacingM),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Due Date'),
                  subtitle: Text(
                    provider.dueDate != null
                        ? DateFormat('MMMM d, yyyy').format(provider.dueDate!)
                        : 'Tap to select',
                  ),
                  trailing: const Icon(Icons.calendar_today),
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
              ],

              const SizedBox(height: AppTheme.spacingM),
              
              CheckboxListTile(
                title: const Text('I am postpartum'),
                value: provider.isPostpartum,
                activeColor: AppTheme.brandPurple,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  provider.updateBasicInfo(isPostpartum: value ?? false);
                  if (value == false) {
                    provider.updateBasicInfo(childAgeMonths: null);
                  }
                },
              ),

              if (provider.isPostpartum) ...[
                const SizedBox(height: AppTheme.spacingM),
                TextFormField(
                  initialValue: provider.childAgeMonths?.toString() ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Child\'s Age (in months)',
                    hintText: 'Enter age in months',
                    prefixIcon: Icon(Icons.child_care),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final age = int.tryParse(value);
                    if (age != null && age >= 0) {
                      provider.updateBasicInfo(childAgeMonths: age);
                    }
                  },
                ),
              ],

              const SizedBox(height: AppTheme.spacingXL),

              // Zip Code
              TextFormField(
                controller: _zipCodeController,
                decoration: const InputDecoration(
                  labelText: 'Zip Code',
                  hintText: 'Enter your zip code',
                  prefixIcon: Icon(Icons.location_on_outlined),
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
              const SizedBox(height: AppTheme.spacingL),

              // Insurance Type
              DropdownButtonFormField<String>(
                value: provider.insuranceType.isEmpty ? null : provider.insuranceType,
                decoration: const InputDecoration(
                  labelText: 'Insurance Type',
                  hintText: 'Select your insurance type',
                  prefixIcon: Icon(Icons.medical_services_outlined),
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
}






