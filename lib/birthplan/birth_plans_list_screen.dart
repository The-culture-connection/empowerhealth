import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import '../models/birth_plan.dart';
import 'birth_plan_display_screen.dart';
import 'comprehensive_birth_plan_screen.dart';

/// Landing screen: reassurance note, plan list, footer note.
class BirthPlansListScreen extends StatelessWidget {
  const BirthPlansListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.ground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HearthPushedHeader(
                backLabel: 'Home',
                padding: const EdgeInsets.only(top: 12),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Birth Plan Builder',
                          style: textTheme.displaySmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Share your preferences with your care team',
                          style: textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: AppTheme.brandPurple,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ComprehensiveBirthPlanScreen(),
                          ),
                        );
                      },
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.add,
                          color: AppTheme.onPurple,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _reassuranceCard(),
              const SizedBox(height: 24),
              const HearthSectionHeading('Your birth plans'),
              const SizedBox(height: 14),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('birth_plans')
                    .where('userId', isEqualTo: userId)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _emptyState(context);
                  }

                  return Column(
                    children: snapshot.data!.docs.map((doc) {
                      final birthPlan = BirthPlan.fromFirestore(doc);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _planCard(context, birthPlan),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 12),
              _footerCard(),
            ],
          ),
        ),
      ),
    );
  }

  // Brief supportive line (replaces the large intro reassurance card).
  Widget _reassuranceCard() {
    return _supportiveLine(
      'Your birth plan helps you share your preferences with your care team.',
    );
  }

  // Brief supportive line (replaces the large footer card).
  Widget _footerCard() {
    return _supportiveLine('You can update your birth plan anytime.');
  }

  // The heart icon stands in for the emoji the copy used to start with.
  Widget _supportiveLine(String message) {
    return HearthNote(icon: Icons.favorite_border, text: message);
  }

  Widget _emptyState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            const SizedBox(
              width: 80,
              height: 80,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.brandPurple,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_border,
                  size: 40,
                  color: AppTheme.onPurple,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No birth plans yet',
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first plan to capture your preferences.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            HearthButton.primary(
              expand: false,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ComprehensiveBirthPlanScreen(),
                  ),
                );
              },
              icon: Icons.add,
              label: 'Create birth plan',
            ),
          ],
        ),
      ),
    );
  }

  Widget _planCard(BuildContext context, BirthPlan birthPlan) {
    final isIncomplete = birthPlan.status == 'incomplete';

    return HearthCard(
      padding: const EdgeInsets.all(20),
      onTap: () {
        if (birthPlan.status == 'incomplete' &&
            birthPlan.progressData != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComprehensiveBirthPlanScreen(
                incompletePlanId: birthPlan.id,
                savedProgress: birthPlan.progressData,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  BirthPlanDisplayScreen(birthPlan: birthPlan),
            ),
          );
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HearthIconChip(Icons.favorite_border),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wrap so the "Incomplete" badge drops below the title
                // instead of overflowing at large text sizes.
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Birth Plan',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (isIncomplete) const HearthTag('Incomplete'),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 14,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _formatDate(birthPlan.createdAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: hearthCaptionStyle,
                      ),
                    ),
                  ],
                ),
                if (birthPlan.dueDate != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Due ${_formatDate(birthPlan.dueDate!)}',
                    style: hearthCaptionStyle,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Icon(
              Icons.chevron_right,
              size: 20,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }
}
