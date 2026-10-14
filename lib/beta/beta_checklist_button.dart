import 'package:flutter/material.dart';

import '../app_router.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import 'beta_checklist_service.dart';

/// Home header button that opens the beta checklist, with a count of what is
/// left to try. Hidden when beta testing is off or nobody is signed in.
class BetaChecklistButton extends StatelessWidget {
  const BetaChecklistButton({super.key});

  @override
  Widget build(BuildContext context) {
    final service = BetaChecklistService.instance;
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        if (!service.isVisible) return const SizedBox.shrink();
        final remaining = service.remainingCount;
        // The tooltip names the button for screen readers; the badge reads
        // its count.
        return Stack(
          clipBehavior: Clip.none,
          children: [
            HearthCircleButton(
              icon: Icons.checklist,
              iconSize: 22,
              iconColor: AppTheme.brandPurple,
              tooltip: 'Beta checklist',
              onPressed: () =>
                  Navigator.pushNamed(context, Routes.betaChecklist),
            ),
            if (remaining > 0)
              Positioned(
                top: -4,
                right: -4,
                child: IgnorePointer(
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.brandPurple,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: AppTheme.surface, width: 1.5),
                    ),
                    child: Text(
                      '$remaining',
                      style: const TextStyle(
                        fontFamily: AppTheme.sansFamily,
                        fontSize: 11,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onPurple,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
