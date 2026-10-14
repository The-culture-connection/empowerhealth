import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';

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
      icon: Icons.cloud_outlined,
      message: 'Searching NPI registry...',
      subtext: 'Finding additional providers',
      progress: 0.35,
    ),
    LoadingStage(
      icon: Icons.people_outline,
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
      icon: Icons.shield_outlined,
      message: 'Adding community trust indicators...',
      subtext: 'Including reviews and identity tags',
      progress: 0.85,
    ),
    LoadingStage(
      icon: Icons.star_outline_rounded,
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
    final textTheme = Theme.of(context).textTheme;
    // Sits on the results screen's ground, so no fill of its own.
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // How the search works. Not AI output, so a cream note.
            HearthNote(
              icon: Icons.favorite_border,
              text:
                  'We match Ohio Medicaid and a national provider list to your ZIP, then apply the filters you chose.',
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Fields with * are required for the directory. Mama Approved™ appears when there are 3+ parent reviews averaging 4★+; tags come from the community, not insurers.',
                  style: hearthCardBodyStyle.copyWith(color: AppTheme.textMuted),
                ),
              ),
            ),

            const SizedBox(height: 24),

            HearthCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                children: [
                  // Large icon with changing images
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      key: ValueKey(_currentStageIndex),
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: AppTheme.tintWarm,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _loadingStages[_currentStageIndex].icon,
                        size: 36,
                        color: AppTheme.brandPurple,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Stage message (updates based on progress)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _loadingStages[_currentStageIndex].message,
                      key: ValueKey(_currentStageIndex),
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Stage subtext
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _loadingStages[_currentStageIndex].subtext,
                      key: ValueKey('subtext_$_currentStageIndex'),
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Progress bar (uses actual progress, not just animation)
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppTheme.borderWarm,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _currentProgress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.brandPurple,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Icon row showing progress steps. Circles shrink to fit
                  // narrow screens (6 x 44 is wider than an iPhone SE card).
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const gap = 4.0;
                      final count = _loadingStages.length;
                      final diameter =
                          ((constraints.maxWidth - gap * (count - 1)) / count)
                              .clamp(28.0, 44.0);
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(count, (index) {
                          final isActive = index <= _currentStageIndex;
                          final isCurrent = index == _currentStageIndex;
                          return Container(
                            width: diameter,
                            height: diameter,
                            decoration: BoxDecoration(
                              color: isActive ? AppTheme.tintWarm : AppTheme.ground,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isActive
                                    ? AppTheme.brandPurple
                                    : AppTheme.borderWarm,
                                width: isCurrent ? 3 : (isActive ? 2 : 1),
                              ),
                            ),
                            child: Icon(
                              _loadingStages[index].icon,
                              size: diameter * 20 / 44,
                              color: isActive
                                  ? AppTheme.brandPurple
                                  : AppTheme.textMuted,
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Personalization note
            Text(
              'Finding providers who are right for you',
              style: textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              'Finding your care team, ${_userName ?? 'there'}...',
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
