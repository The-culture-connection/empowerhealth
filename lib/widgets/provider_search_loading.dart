import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/ai_disclaimer_banner.dart';

/// Represents a loading stage with icon, message, and progress threshold
class LoadingStage {
  final IconData icon;
  final String message;
  final String subtext;
  final double progress; // Progress value (0.0-1.0) when this stage should be shown

  const LoadingStage({
    required this.icon,
    required this.message,
    required this.subtext,
    required this.progress,
  });
}

/// Loading animation with straight progress bar and changing icons
/// Matches NewUI design with progress bar and step icons
/// Now tracks realistic progress based on actual search stages
class ProviderSearchLoading extends StatefulWidget {
  final VoidCallback? onComplete;
  final Duration? duration;
  final ValueNotifier<double>? progressNotifier; // Optional: for real-time progress updates

  const ProviderSearchLoading({
    super.key,
    this.onComplete,
    this.duration,
    this.progressNotifier,
  });

  @override
  State<ProviderSearchLoading> createState() => _ProviderSearchLoadingState();
}

class _ProviderSearchLoadingState extends State<ProviderSearchLoading>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _iconController;
  late Animation<double> _progressAnimation;
  String? _userName;
  
  // Loading stages that match actual search process
  final List<LoadingStage> _loadingStages = [
    LoadingStage(
      icon: Icons.search,
      message: 'Searching Ohio Medicaid directories...',
      subtext: 'Looking through thousands of providers',
      progress: 0.0,
    ),
    LoadingStage(
      icon: Icons.cloud,
      message: 'Searching NPI registry...',
      subtext: 'Finding additional providers',
      progress: 0.35,
    ),
    LoadingStage(
      icon: Icons.people,
      message: 'Searching community directory...',
      subtext: 'Including BIPOC and verified providers',
      progress: 0.55,
    ),
    LoadingStage(
      icon: Icons.merge_type,
      message: 'Deduplicating results...',
      subtext: 'Removing duplicate entries',
      progress: 0.70,
    ),
    LoadingStage(
      icon: Icons.shield,
      message: 'Adding community trust indicators...',
      subtext: 'Including reviews and identity tags',
      progress: 0.85,
    ),
    LoadingStage(
      icon: Icons.star,
      message: 'Almost ready...',
      subtext: 'Preparing your personalized results',
      progress: 0.95,
    ),
  ];
  int _currentStageIndex = 0;
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    
    // Progress bar animation - longer duration for more accurate tracking
    // Default to 15 seconds to allow for actual search time
    _progressController = AnimationController(
      duration: widget.duration ?? const Duration(seconds: 15),
      vsync: this,
    );

    // Stage change animation (changes based on progress)
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Use a more realistic progress curve that doesn't top out early
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Listen to progress animation
    _progressAnimation.addListener(() {
      if (mounted) {
        final progress = _progressAnimation.value;
        setState(() {
          _currentProgress = progress;
          // Update stage based on progress
          for (int i = _loadingStages.length - 1; i >= 0; i--) {
            if (progress >= _loadingStages[i].progress) {
              if (_currentStageIndex != i) {
                _currentStageIndex = i;
              }
              break;
            }
          }
        });
      }
    });

    // Listen to external progress updates if provided
    widget.progressNotifier?.addListener(_onProgressUpdate);

    // Start progress animation with slower, more realistic progression
    _progressController.forward().then((_) {
      // Complete to 100% when done
      if (mounted) {
        setState(() {
          _currentProgress = 1.0;
          _currentStageIndex = _loadingStages.length - 1;
        });
        // Wait a moment before calling onComplete
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && widget.onComplete != null) {
            widget.onComplete!();
          }
        });
      }
    });
  }

  void _onProgressUpdate() {
    if (mounted && widget.progressNotifier != null) {
      final progress = widget.progressNotifier!.value;
      setState(() {
        _currentProgress = progress.clamp(0.0, 1.0);
        // Update stage based on progress
        for (int i = _loadingStages.length - 1; i >= 0; i--) {
          if (_currentProgress >= _loadingStages[i].progress) {
            if (_currentStageIndex != i) {
              _currentStageIndex = i;
            }
            break;
          }
        }
      });
      // Update animation controller to match
      _progressController.value = progress.clamp(0.0, 0.95);
    }
  }

  Future<void> _loadUserName() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        final userData = userDoc.data();
        if (mounted) {
          setState(() {
            _userName = userData?['username'] ?? 'there';
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _userName = 'there';
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _userName = 'there';
        });
      }
    }
  }

  @override
  void dispose() {
    widget.progressNotifier?.removeListener(_onProgressUpdate);
    _progressController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF8F6F8)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              
              // Disclaimer Banner (matching NewUI)
              AIDisclaimerBanner(
                customMessage: 'How search works: We search Ohio Medicaid directories + NPI registry, then filter by community trust indicators.',
                customSubMessage: 'Filters marked with * are required by the directory. "Mama Approved™" and identity tags are community-powered filters.',
              ),
              
              const SizedBox(height: 40),
              
              // Main loading card (matching NewUI "Almost ready..." design)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Large icon with changing images
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        key: ValueKey(_currentStageIndex),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F0E8), // Light beige background
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _loadingStages[_currentStageIndex].icon,
                          size: 40,
                          color: const Color(0xFF663399),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Stage message (updates based on progress)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _loadingStages[_currentStageIndex].message,
                        key: ValueKey(_currentStageIndex),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Stage subtext
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _loadingStages[_currentStageIndex].subtext,
                        key: ValueKey('subtext_$_currentStageIndex'),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Progress bar (uses actual progress, not just animation)
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F0E8), // Light beige background
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _currentProgress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF663399),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Icon row showing progress steps
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(_loadingStages.length, (index) {
                        final isActive = index <= _currentStageIndex;
                        final isCurrent = index == _currentStageIndex;
                        return Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isActive 
                                ? const Color(0xFF663399).withOpacity(isCurrent ? 0.2 : 0.1)
                                : Colors.grey.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isActive 
                                  ? const Color(0xFF663399)
                                  : Colors.grey.shade300,
                              width: isCurrent ? 3 : (isActive ? 2 : 1),
                            ),
                          ),
                          child: Icon(
                            _loadingStages[index].icon,
                            size: 24,
                            color: isActive 
                                ? const Color(0xFF663399)
                                : Colors.grey.shade400,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Personalization note
              Text(
                'Finding providers who are right for you',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Finding your care team, ${_userName ?? 'there'}...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
