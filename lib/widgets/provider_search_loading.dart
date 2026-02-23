import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/ai_disclaimer_banner.dart';

/// Loading animation with straight progress bar and changing icons
/// Matches NewUI design with progress bar and step icons
class ProviderSearchLoading extends StatefulWidget {
  final VoidCallback? onComplete;
  final Duration? duration;

  const ProviderSearchLoading({
    super.key,
    this.onComplete,
    this.duration,
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
  
  // Icons that change during loading (matching NewUI)
  final List<IconData> _loadingIcons = [
    Icons.search,
    Icons.shield,
    Icons.favorite,
    Icons.star,
  ];
  int _currentIconIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    
    // Progress bar animation (0 to 100%)
    _progressController = AnimationController(
      duration: widget.duration ?? const Duration(seconds: 5),
      vsync: this,
    );

    // Icon change animation (changes every 1.25 seconds)
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 1250),
      vsync: this,
    )..repeat();

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Listen to icon changes
    _iconController.addListener(() {
      if (_iconController.value >= 1.0) {
        setState(() {
          _currentIconIndex = (_currentIconIndex + 1) % _loadingIcons.length;
        });
        _iconController.reset();
      }
    });

    // Start progress animation
    _progressController.forward().then((_) {
      if (mounted && widget.onComplete != null) {
        widget.onComplete!();
      }
    });
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
                        key: ValueKey(_currentIconIndex),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F0E8), // Light beige background
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _loadingIcons[_currentIconIndex],
                          size: 40,
                          color: const Color(0xFF663399),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // "Almost ready..." text
                    const Text(
                      'Almost ready...',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    const Text(
                      'Preparing your personalized results',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Straight progress bar (not zig-zag)
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F0E8), // Light beige background
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progressAnimation.value,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF663399),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Icon row showing progress steps
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(_loadingIcons.length, (index) {
                        final isActive = index <= _currentIconIndex;
                        return Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isActive 
                                ? const Color(0xFF663399).withOpacity(0.1)
                                : Colors.grey.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isActive 
                                  ? const Color(0xFF663399)
                                  : Colors.grey.shade300,
                              width: isActive ? 2 : 1,
                            ),
                          ),
                          child: Icon(
                            _loadingIcons[index],
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
