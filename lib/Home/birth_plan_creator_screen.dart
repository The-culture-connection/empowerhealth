import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai_service.dart';
import '../cors/ui_theme.dart';

class BirthPlanCreatorScreen extends StatefulWidget {
  const BirthPlanCreatorScreen({super.key});

  @override
  State<BirthPlanCreatorScreen> createState() => _BirthPlanCreatorScreenState();
}

class _BirthPlanCreatorScreenState extends State<BirthPlanCreatorScreen> {
  final AIService _aiService = AIService();
  final TextEditingController _medicalHistoryController = TextEditingController();
  final TextEditingController _concernsController = TextEditingController();
  final TextEditingController _supportPeopleController = TextEditingController();

  bool _isGenerating = false;
  String? _generatedPlan;

  // Preferences
  String _laborPreference = 'move_freely';
  String _painManagement = 'open_to_options';
  String _deliveryPosition = 'flexible';
  bool _skinToSkin = true;
  bool _delayedCordClamping = true;
  bool _breastfeedingImmediately = true;

  @override
  void dispose() {
    _medicalHistoryController.dispose();
    _concernsController.dispose();
    _supportPeopleController.dispose();
    super.dispose();
  }

  Future<void> _generateBirthPlan() async {
    setState(() => _isGenerating = true);

    try {
      final preferences = {
        'labor': _getLaborPreferenceText(),
        'painManagement': _getPainManagementText(),
        'delivery': _getDeliveryPositionText(),
        'afterBirth': _getAfterBirthPreferences(),
        'specialRequests': 'Please explain all procedures before they happen.',
      };

      final result = await _aiService.generateBirthPlan(
        preferences: preferences,
        medicalHistory: _medicalHistoryController.text.trim().isNotEmpty
            ? _medicalHistoryController.text
            : null,
        concerns: _concernsController.text.trim().isNotEmpty
            ? _concernsController.text
            : null,
        supportPeople: _supportPeopleController.text.trim().isNotEmpty
            ? _supportPeopleController.text
            : null,
      );

      setState(() {
        _generatedPlan = result['birthPlan'];
        _isGenerating = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String _getLaborPreferenceText() {
    switch (_laborPreference) {
      case 'move_freely':
        return 'I want to move around freely during labor and try different positions.';
      case 'stay_in_bed':
        return 'I prefer to stay in bed during labor.';
      case 'water_therapy':
        return 'I\'d like to use water therapy (shower or tub) during labor.';
      default:
        return 'I\'m flexible about my labor preferences.';
    }
  }

  String _getPainManagementText() {
    switch (_painManagement) {
      case 'epidural':
        return 'I plan to use an epidural for pain management.';
      case 'natural':
        return 'I want to try natural pain management techniques.';
      case 'open_to_options':
        return 'I\'m open to discussing all pain relief options during labor.';
      default:
        return 'I\'ll decide about pain management during labor.';
    }
  }

  String _getDeliveryPositionText() {
    switch (_deliveryPosition) {
      case 'lying_back':
        return 'I prefer lying back for delivery.';
      case 'squatting':
        return 'I\'d like to try squatting or upright positions for delivery.';
      case 'side_lying':
        return 'I prefer side-lying position for delivery.';
      case 'flexible':
        return 'I want to try different positions and see what feels right.';
      default:
        return 'I\'m flexible about delivery position.';
    }
  }

  String _getAfterBirthPreferences() {
    List<String> prefs = [];
    if (_skinToSkin) prefs.add('immediate skin-to-skin contact');
    if (_delayedCordClamping) prefs.add('delayed cord clamping');
    if (_breastfeedingImmediately) prefs.add('breastfeeding within the first hour');
    
    if (prefs.isEmpty) return 'Follow standard hospital procedures after birth.';
    return 'I would like: ${prefs.join(", ")}.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Birth Plan Creator'),
        backgroundColor: AppTheme.brandPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.brandPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Text('📋', style: TextStyle(fontSize: 32)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Create a birth plan that shares your wishes with your healthcare team. You can change it anytime!',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Labor Preferences
            const Text(
              'During Labor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _RadioOption(
              title: 'Move around freely',
              value: 'move_freely',
              groupValue: _laborPreference,
              onChanged: (v) => setState(() => _laborPreference = v!),
            ),
            _RadioOption(
              title: 'Stay in bed',
              value: 'stay_in_bed',
              groupValue: _laborPreference,
              onChanged: (v) => setState(() => _laborPreference = v!),
            ),
            _RadioOption(
              title: 'Use water therapy',
              value: 'water_therapy',
              groupValue: _laborPreference,
              onChanged: (v) => setState(() => _laborPreference = v!),
            ),

            const SizedBox(height: 24),

            // Pain Management
            const Text(
              'Pain Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _RadioOption(
              title: 'Plan to use epidural',
              value: 'epidural',
              groupValue: _painManagement,
              onChanged: (v) => setState(() => _painManagement = v!),
            ),
            _RadioOption(
              title: 'Try natural methods',
              value: 'natural',
              groupValue: _painManagement,
              onChanged: (v) => setState(() => _painManagement = v!),
            ),
            _RadioOption(
              title: 'Open to all options',
              value: 'open_to_options',
              groupValue: _painManagement,
              onChanged: (v) => setState(() => _painManagement = v!),
            ),

            const SizedBox(height: 24),

            // Delivery Position
            const Text(
              'Delivery Position',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _RadioOption(
              title: 'Lying back',
              value: 'lying_back',
              groupValue: _deliveryPosition,
              onChanged: (v) => setState(() => _deliveryPosition = v!),
            ),
            _RadioOption(
              title: 'Squatting or upright',
              value: 'squatting',
              groupValue: _deliveryPosition,
              onChanged: (v) => setState(() => _deliveryPosition = v!),
            ),
            _RadioOption(
              title: 'Side-lying',
              value: 'side_lying',
              groupValue: _deliveryPosition,
              onChanged: (v) => setState(() => _deliveryPosition = v!),
            ),
            _RadioOption(
              title: 'Stay flexible',
              value: 'flexible',
              groupValue: _deliveryPosition,
              onChanged: (v) => setState(() => _deliveryPosition = v!),
            ),

            const SizedBox(height: 24),

            // After Birth
            const Text(
              'After Birth',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('Immediate skin-to-skin contact'),
              value: _skinToSkin,
              onChanged: (v) => setState(() => _skinToSkin = v!),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Delayed cord clamping'),
              value: _delayedCordClamping,
              onChanged: (v) => setState(() => _delayedCordClamping = v!),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Breastfeed in first hour'),
              value: _breastfeedingImmediately,
              onChanged: (v) => setState(() => _breastfeedingImmediately = v!),
              controlAffinity: ListTileControlAffinity.leading,
            ),

            const SizedBox(height: 24),

            // Additional Information
            const Text(
              'Medical History (optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _medicalHistoryController,
              decoration: const InputDecoration(
                hintText: 'Any important medical history...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 20),

            const Text(
              'Concerns or Special Requests (optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _concernsController,
              decoration: const InputDecoration(
                hintText: 'Anything you want your care team to know...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 20),

            const Text(
              'Support People',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _supportPeopleController,
              decoration: const InputDecoration(
                hintText: 'Who will be with you? (partner, doula, family...)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 32),

            // Generate button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generateBirthPlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandPurple,
                  foregroundColor: Colors.white,
                ),
                child: _isGenerating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create My Birth Plan',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            // Generated plan
            if (_generatedPlan != null) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Birth Plan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brandPurple,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _generatedPlan!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied to clipboard!')),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () {
                          // TODO: Implement share/export functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Share functionality coming soon!')),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () {
                          // TODO: Implement PDF export
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('PDF export coming soon!')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  _generatedPlan!,
                  style: const TextStyle(fontSize: 15, height: 1.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RadioOption extends StatelessWidget {
  final String title;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _RadioOption({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      title: Text(title),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}

