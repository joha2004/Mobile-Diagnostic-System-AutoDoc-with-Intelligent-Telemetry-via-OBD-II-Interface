import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _apiKeyController.text = ref.read(geminiServiceProvider);
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(localeProvider);
    final currentLang = ref.watch(languageProvider);
    final isDemoMode = ref.watch(isDemoModeProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => ref.read(bottomNavIndexProvider.notifier).state = 1, // Go to Dashboard
                  ),
                  const SizedBox(width: 8),
                  Text(t.get('settings_title'), style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
              const SizedBox(height: 24),

              // Language
              _SettingsSection(
                title: t.get('settings_language'),
                child: Row(
                  children: [
                    Expanded(
                      child: _LangButton(
                        label: '🇷🇺 ${t.get('settings_russian')}',
                        isActive: currentLang == 'ru',
                        onTap: () => ref.read(languageProvider.notifier).setLanguage('ru'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LangButton(
                        label: '🇬🇧 ${t.get('settings_english')}',
                        isActive: currentLang == 'en',
                        onTap: () => ref.read(languageProvider.notifier).setLanguage('en'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // API Key
              _SettingsSection(
                title: t.get('settings_api_key'),
                child: Column(
                  children: [
                    TextField(
                      controller: _apiKeyController,
                      obscureText: true,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: t.get('settings_api_key_hint'),
                        hintStyle: const TextStyle(color: AppColors.textTertiary),
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.save, color: AppColors.primary),
                          onPressed: () {
                            ref.read(geminiServiceProvider.notifier).setApiKey(_apiKeyController.text);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(t.get('settings_api_key_saved'))),
                            );
                          },
                        ),
                      ),
                      onSubmitted: (value) {
                        ref.read(geminiServiceProvider.notifier).setApiKey(value);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(t.get('settings_api_key_saved'))),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Demo Mode
              _SettingsSection(
                title: t.get('settings_demo_mode'),
                child: SwitchListTile(
                  value: isDemoMode,
                  onChanged: (val) => ref.read(isDemoModeProvider.notifier).state = val,
                  title: Text(t.get('connection_demo_desc'), style: Theme.of(context).textTheme.bodyMedium),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 16),

              // Clear History
              _SettingsSection(
                title: t.get('settings_clear_history'),
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(appDatabaseProvider).clearAllSessions();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(t.get('success'))),
                    );
                  },
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  label: Text(t.get('delete'), style: const TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                ),
              ),
              const SizedBox(height: 16),

              // About
              _SettingsSection(
                title: t.get('settings_about'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${t.get('app_name')} v1.0.0', style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 4),
                    Text(
                      'OBD-II диагностика с AI анализом',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '© 2026 AI Auto Doctor',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _SettingsSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _LangButton({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withAlpha(30) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
