import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_functions_service.dart';
import '../services/database_service.dart';
import '../models/user_profile.dart';
import '../cors/ui_theme.dart';

class ModuleDetailScreen extends StatefulWidget {
  final String title;
  final String trimester;
  final String type;
  final String? preloadedContent;

  const ModuleDetailScreen({
    super.key,
    required this.title,
    required this.trimester,
    required this.type,
    this.preloadedContent,
  });

  @override
  State<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen> {
  final FirebaseFunctionsService _functionsService = FirebaseFunctionsService();
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _content;
  bool _isLoading = false;
  String? _error;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    if (widget.preloadedContent != null) {
      _content = widget.preloadedContent;
    } else {
      _loadUserProfileAndContent();
    }
  }

  Future<void> _loadUserProfileAndContent() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      _userProfile = await _databaseService.getUserProfile(userId);
    }
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.type == 'rights') {
        final result = await _functionsService.generateRightsContent(
          topic: widget.title,
        );
        setState(() {
          _content = result['content'];
          _isLoading = false;
        });
      } else {
        // Prepare user profile data for personalization
        Map<String, dynamic>? profileData;
        if (_userProfile != null) {
          profileData = {
            'chronicConditions': _userProfile!.chronicConditions,
            'healthLiteracyGoals': _userProfile!.healthLiteracyGoals,
            'insuranceType': _userProfile!.insuranceType,
            'providerPreferences': _userProfile!.providerPreferences,
            'educationLevel': _userProfile!.educationLevel,
          };
        }

        final result = await _functionsService.generateLearningContent(
          topic: widget.title,
          trimester: widget.trimester,
          moduleType: widget.type,
          userProfile: profileData,
        );
        setState(() {
          _content = result['content'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppTheme.brandPurple,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading content...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading content',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadContent,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_content == null) {
      return const Center(child: Text('No content available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trimester badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.brandPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${widget.trimester} Trimester',
              style: const TextStyle(
                color: AppTheme.brandPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Content with markdown support
          MarkdownBody(
            data: _content!,
            styleSheet: MarkdownStyleSheet(
              h1: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.brandPurple,
              ),
              h2: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.brandPurple,
              ),
              h3: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              p: const TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
              listBullet: const TextStyle(
                fontSize: 16,
                color: AppTheme.brandPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

