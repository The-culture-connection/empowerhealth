import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/provider.dart';
import '../services/provider_repository.dart';
import '../services/firebase_functions_service.dart';
import '../constants/provider_types.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';

class AddProviderScreen extends StatefulWidget {
  final bool isMamaApproved;
  
  const AddProviderScreen({
    super.key,
    this.isMamaApproved = false,
  });

  @override
  State<AddProviderScreen> createState() => _AddProviderScreenState();
}

class _AddProviderScreenState extends State<AddProviderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = ProviderRepository();
  final _functionsService = FirebaseFunctionsService();
  
  final _nameController = TextEditingController();
  final _providerTypeController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedProviderType = '';
  String _selectedSpecialty = '';
  bool _isSubmitting = false;
  bool _submitted = false;

  final List<String> _providerTypes = ProviderTypes.getAllTypes()
      .map((t) => t['name']!)
      .toList();

  final List<String> _specialties = Specialties.specialties;

  @override
  void initState() {
    super.initState();
    // Add listeners to text controllers to update button state
    _nameController.addListener(_updateSubmitState);
    _addressController.addListener(_updateSubmitState);
    _cityController.addListener(_updateSubmitState);
    _zipController.addListener(_updateSubmitState);
  }

  void _updateSubmitState() {
    setState(() {
      // Trigger rebuild to update button state
    });
  }

  @override
  void dispose() {
    _nameController.removeListener(_updateSubmitState);
    _addressController.removeListener(_updateSubmitState);
    _cityController.removeListener(_updateSubmitState);
    _zipController.removeListener(_updateSubmitState);
    _nameController.dispose();
    _providerTypeController.dispose();
    _specialtyController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final canSubmit = _nameController.text.trim().isNotEmpty &&
        _selectedProviderType.isNotEmpty &&
        _selectedSpecialty.isNotEmpty &&
        _addressController.text.trim().isNotEmpty &&
        _cityController.text.trim().isNotEmpty &&
        _zipController.text.trim().length == 5;
    
    // Debug print to help diagnose why button might be disabled
    if (!canSubmit) {
      print('🔍 [AddProvider] Submit disabled - name: ${_nameController.text.trim().isNotEmpty}, type: ${_selectedProviderType.isNotEmpty}, specialty: ${_selectedSpecialty.isNotEmpty}, address: ${_addressController.text.trim().isNotEmpty}, city: ${_cityController.text.trim().isNotEmpty}, zip: ${_zipController.text.trim().length == 5}');
    }
    
    return canSubmit;
  }

  Future<void> _handleSubmit() async {
    if (!_canSubmit || !_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get provider type ID
      final providerTypeId = ProviderTypes.getTypeId(_selectedProviderType);
      
      final provider = Provider(
        name: _nameController.text,
        providerTypes: providerTypeId != null ? [providerTypeId] : [],
        specialties: [_selectedSpecialty],
        locations: [
          ProviderLocation(
            address: _addressController.text,
            city: _cityController.text,
            state: 'OH',
            zip: _zipController.text,
            phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
          ),
        ],
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        website: _websiteController.text.isNotEmpty ? _websiteController.text : null,
        source: widget.isMamaApproved ? 'admin_mama_approved' : 'user_submission',
        mamaApproved: widget.isMamaApproved,
      );

      // If Mama Approved, use Firebase function; otherwise use repository
      if (widget.isMamaApproved) {
        await _functionsService.addProvider(
          name: _nameController.text,
          specialty: _selectedSpecialty,
          providerTypes: providerTypeId != null ? [providerTypeId] : [],
          specialties: [_selectedSpecialty],
          locations: [
            {
              'address': _addressController.text,
              'city': _cityController.text,
              'state': 'OH',
              'zip': _zipController.text,
              'phone': _phoneController.text.isNotEmpty ? _phoneController.text : null,
            },
          ],
          phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
          email: _emailController.text.isNotEmpty ? _emailController.text : null,
          website: _websiteController.text.isNotEmpty ? _websiteController.text : null,
          mamaApproved: true,
        );
      } else {
        // Get current user ID
        final userId = FirebaseAuth.instance.currentUser?.uid;
        await _repository.submitProvider(
          provider,
          userId: userId,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );
      }

      setState(() {
        _submitted = true;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting provider: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _buildSuccessScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.ground,
      body: SafeArea(
          child: Column(
            children: [
              // Header
              HearthPushedHeader(
                backLabel: 'Cancel',
                onBack: () => Navigator.pop(context),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                actions: [
                  ElevatedButton(
                    onPressed: _canSubmit && !_isSubmitting ? _handleSubmit : null,
                    // Compact header button; the theme supplies colours and the stadium shape.
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.onPurple),
                            ),
                          )
                        : const Text('Submit'),
                  ),
                ],
              ),

              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Intro
                        HearthFeatureCard(
                          tone: HearthTone.purple,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add a Provider',
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(color: AppTheme.onPurple),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Can\'t find your provider? Help other mothers by adding them to our community directory. We\'ll review and publish soon.',
                                style: hearthCardBodyStyle.copyWith(
                                  color: AppTheme.onPurpleSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Info Notice
                        HearthNote(
                          icon: Icons.info_outline,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Before you add:',
                                style: hearthCardBodyStyle.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Search carefully to avoid duplicates. Our team will verify the information before publishing.',
                                style: hearthCardBodyStyle,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'All submissions go through a moderation process to ensure accuracy and safety.',
                                style: hearthCardBodyStyle,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Basic Information
                        _buildSection(
                          title: 'Basic Information',
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: _nameController,
                                label: 'Provider Name',
                                required: true,
                                hintText: 'Dr. Jane Smith or Smith Family Practice',
                              ),
                              const SizedBox(height: 16),
                              _buildDropdown(
                                label: 'Provider Type',
                                required: true,
                                value: _selectedProviderType,
                                items: _providerTypes,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedProviderType = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildDropdown(
                                label: 'Specialty',
                                required: true,
                                value: _selectedSpecialty,
                                items: _specialties,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSpecialty = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Location
                        _buildSection(
                          title: 'Location',
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: _addressController,
                                label: 'Street Address',
                                required: true,
                                hintText: '123 Main Street',
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _cityController,
                                      label: 'City',
                                      required: true,
                                      hintText: 'Cleveland',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildTextField(
                                      controller: TextEditingController(text: 'Ohio'),
                                      label: 'State',
                                      enabled: false,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _zipController,
                                label: 'ZIP Code',
                                required: true,
                                maxLength: 5,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                hintText: '44115',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Contact Information (Optional)
                        _buildSection(
                          title: 'Contact Information (Optional)',
                          child: Column(
                            children: [
                              const Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  'Help others contact this provider',
                                  style: hearthCaptionStyle,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _phoneController,
                                label: 'Phone Number',
                                keyboardType: TextInputType.phone,
                                hintText: '(216) 555-0100',
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _emailController,
                                label: 'Email',
                                keyboardType: TextInputType.emailAddress,
                                hintText: 'office@provider.com',
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _websiteController,
                                label: 'Website',
                                keyboardType: TextInputType.url,
                                hintText: 'www.provider.com',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Additional Notes
                        _buildSection(
                          title: 'Additional Notes (Optional)',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Share anything that might be helpful for other mothers',
                                style: hearthCaptionStyle,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _notesController,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  hintText: 'Example: Accepts Medicaid, Spanish-speaking staff, evening appointments available...',
                                  contentPadding: EdgeInsets.all(16),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Moderation Notice
                        HearthFeatureCard(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Moderation process: All provider submissions are reviewed by our team to ensure accuracy and prevent spam. This usually takes 1-2 business days.',
                            style: hearthCardBodyStyle.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppTheme.ink,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Submit Button
                        HearthButton.primary(
                          label: 'Submit for Review',
                          onPressed: _canSubmit && !_isSubmitting ? _handleSubmit : null,
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: AppTheme.ground,
      body: SafeArea(
          child: Column(
            children: [
              HearthPushedHeader(
                backLabel: 'Back to search',
                onBack: () => Navigator.pop(context),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const HearthIconChip(
                              Icons.check,
                              size: 64,
                              iconSize: 32,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Thank you!',
                              style: Theme.of(context).textTheme.displaySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'We\'ve received your provider submission. Our team will review the information and publish it to help other mothers in the community.',
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            HearthCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'What happens next?',
                                    style: hearthCardTitleStyle,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildNextStepItem('Our team reviews the information (usually 1-2 business days)'),
                                  _buildNextStepItem('We may verify details with the provider'),
                                  _buildNextStepItem('Once approved, the provider appears in search results'),
                                  _buildNextStepItem('You\'ll receive a notification when it\'s published'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            HearthButton.primary(
                              label: 'Back to search',
                              expand: false,
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(height: 12),
                            HearthButton.text(
                              label: 'Add another provider',
                              onPressed: () {
                                setState(() {
                                  _submitted = false;
                                  _nameController.clear();
                                  _providerTypeController.clear();
                                  _specialtyController.clear();
                                  _addressController.clear();
                                  _cityController.clear();
                                  _zipController.clear();
                                  _phoneController.clear();
                                  _emailController.clear();
                                  _websiteController.clear();
                                  _notesController.clear();
                                  _selectedProviderType = '';
                                  _selectedSpecialty = '';
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
      ),
    );
  }

  Widget _buildNextStepItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              '• ',
              style: hearthCardBodyStyle.copyWith(
                fontSize: 15,
                height: 22 / 15,
                color: AppTheme.brandPurple,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: hearthCardBodyStyle.copyWith(fontSize: 15, height: 22 / 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return HearthCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  /// Field label with the purple required marker.
  Widget _buildFieldLabel(String label, bool required) {
    return Text.rich(
      TextSpan(
        text: label,
        children: [
          if (required)
            const TextSpan(
              text: ' ',
              children: [
                TextSpan(
                  text: '*',
                  style: TextStyle(color: AppTheme.brandPurple),
                ),
              ],
            ),
        ],
      ),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.ink),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? hintText,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, required),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLength: maxLength,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: enabled ? null : const TextStyle(color: AppTheme.textMuted),
          decoration: InputDecoration(
            hintText: hintText,
            // The fixed State field sits on the warm tint so it reads as locked.
            fillColor: enabled ? null : AppTheme.tintWarm,
            counterText: '',
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
    bool required = false,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, required),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value.isEmpty ? null : value,
          isExpanded: true, // Prevents overflow
          icon: const Icon(Icons.expand_more, color: AppTheme.brandPurple),
          borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
          dropdownColor: AppTheme.surface,
          decoration: InputDecoration(
            hintText: hint ?? 'Select $label',
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ],
    );
  }
}
