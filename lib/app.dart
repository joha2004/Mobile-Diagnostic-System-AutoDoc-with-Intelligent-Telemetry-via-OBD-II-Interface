import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/screens/connection/connection_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/errors/errors_screen.dart';
import 'presentation/screens/history/history_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/analysis/analysis_screen.dart';
import 'presentation/screens/service_map/service_map_screen.dart';
import 'presentation/screens/step_diagnosis/step_diagnosis_screen.dart';
import 'presentation/screens/chat/ai_chat_screen.dart';
import 'core/theme/app_colors.dart';

class AutoDoctorApp extends ConsumerWidget {
  const AutoDoctorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to language changes to rebuild
    ref.watch(languageProvider);
    final t = ref.watch(localeProvider);

    return MaterialApp(
      title: 'AI Auto Doctor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _AppShell(t: t),
    );
  }
}

class _AppShell extends ConsumerWidget {
  final dynamic t;
  const _AppShell({required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navIndex = ref.watch(bottomNavIndexProvider);

    // Map indices to screens
    final screens = <Widget>[
      const ConnectionScreen(),     // 0
      const DashboardScreen(),      // 1
      const ErrorsScreen(),         // 2
      const HistoryScreen(),        // 3
      const SettingsScreen(),       // 4
      const AnalysisScreen(),       // 5 (not in bottom nav)
      const ServiceMapScreen(),     // 6
      const StepDiagnosisScreen(),  // 7 (not in bottom nav)
      const AiChatScreen(),         // 8
    ];

    // Show Analysis/Map as full-screen overlay if selected
    // Hide bottom nav ONLY on AnalysisScreen (5) and StepDiagnosisScreen (7)
    final showBottomNav = navIndex != 5 && navIndex != 7;
    final currentScreen = navIndex < screens.length ? screens[navIndex] : screens[0];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Main Body
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              child: KeyedSubtree(
                key: ValueKey(navIndex),
                child: currentScreen,
              ),
            ),
          ),
          
          // Floating Glassmorphism Bottom Navigation
          if (showBottomNav)
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: SafeArea(
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(40),
                        blurRadius: 20,
                        spreadRadius: -5,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondary.withAlpha(200),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withAlpha(30),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _NavItem(
                              icon: Icons.bluetooth_connected,
                              label: t.get('nav_connection'),
                              isActive: navIndex == 0,
                              onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 0,
                            ),
                            _NavItem(
                              icon: Icons.dashboard,
                              label: t.get('nav_dashboard'),
                              isActive: navIndex == 1,
                              onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 1,
                            ),
                            _NavItem(
                              icon: Icons.error_outline,
                              label: t.get('nav_errors'),
                              isActive: navIndex == 2,
                              onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 2,
                              badgeCount: ref.watch(dtcCodesProvider).length,
                            ),
                            _NavItem(
                              icon: Icons.map_outlined,
                              label: 'СТО',
                              isActive: navIndex == 6,
                              onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 6,
                            ),
                            _NavItem(
                              icon: Icons.smart_toy,
                              label: 'AI Чат',
                              isActive: navIndex == 8,
                              onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 8,
                            ),
                            _NavItem(
                              icon: Icons.settings,
                              label: t.get('nav_settings'),
                              isActive: navIndex == 4,
                              onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppColors.primary.withAlpha(80) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: isActive ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    size: 26,
                    color: isActive ? AppColors.primary : AppColors.textTertiary,
                    shadows: isActive ? [
                      BoxShadow(color: AppColors.primary.withAlpha(150), blurRadius: 10)
                    ] : [],
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -10,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.backgroundSecondary, width: 1.5),
                        boxShadow: [
                          BoxShadow(color: AppColors.error.withAlpha(150), blurRadius: 8)
                        ],
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
              ],
            ),
            AnimatedOpacity(
              opacity: isActive ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: isActive ? 16 : 0,
                margin: EdgeInsets.only(top: isActive ? 4 : 0),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.visible,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
