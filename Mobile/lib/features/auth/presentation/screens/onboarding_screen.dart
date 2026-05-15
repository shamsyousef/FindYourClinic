import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Persisted data
  String? _selectedRole;
  String? _selectedGoal;
  String? _selectedLocation;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (_selectedRole != null) await prefs.setString('onboarding_role', _selectedRole!);
    if (_selectedGoal != null) await prefs.setString('onboarding_goal', _selectedGoal!);
    if (_selectedLocation != null) await prefs.setString('onboarding_location', _selectedLocation!);

    if (!mounted) return;
    context.goNamed(RouteNames.login);
  }

  void _next() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  void _previous() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.scaffoldLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back / skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      onPressed: _previous,
                    )
                  else
                    const SizedBox(width: 48),
                  if (_currentPage < 4)
                    TextButton(
                      onPressed: _complete,
                      child: Text('Skip', style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary)),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: List.generate(5, (index) {
                  final isActive = index <= _currentPage;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),

            // Slides
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Prevent swipe to force interaction
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildSlide0(isDark),
                  _buildSlide1(isDark),
                  _buildSlide2(isDark),
                  _buildSlide3(isDark),
                  _buildSlide4(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Slide 0: Welcome
  Widget _buildSlide0(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.health_and_safety_rounded, size: 100, color: AppColors.primary),
          const SizedBox(height: 32),
          Text(
            'Welcome to\nFind Your Clinic',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading1.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Let\'s personalize your experience to serve you better.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLg.copyWith(color: AppColors.textSecondary),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: _next,
              child: const Text('Let\'s Go'),
            ),
          ),
        ],
      ),
    );
  }

  // Slide 1: Role
  Widget _buildSlide1(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you a patient or a doctor?',
            style: AppTextStyles.heading2.copyWith(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'We will customize the app based on your role.',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: [
                _OptionCard(
                  icon: Icons.person_rounded,
                  title: 'I am a Patient',
                  subtitle: 'Looking to book appointments and manage health.',
                  isSelected: _selectedRole == 'patient',
                  isDark: isDark,
                  onTap: () => setState(() => _selectedRole = 'patient'),
                ),
                const SizedBox(height: 16),
                _OptionCard(
                  icon: Icons.medical_services_rounded,
                  title: 'I am a Doctor',
                  subtitle: 'Looking to manage my clinic and patients.',
                  isSelected: _selectedRole == 'doctor',
                  isDark: isDark,
                  onTap: () => setState(() => _selectedRole = 'doctor'),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: _selectedRole == null ? null : _next,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  // Slide 2: Goal
  Widget _buildSlide2(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What brings you here today?',
            style: AppTextStyles.heading2.copyWith(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your primary goal so we can guide you.',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
              children: [
                _GridOptionCard(
                  icon: Icons.calendar_month_rounded,
                  title: 'Book\nCheckup',
                  isSelected: _selectedGoal == 'checkup',
                  isDark: isDark,
                  onTap: () => setState(() => _selectedGoal = 'checkup'),
                ),
                _GridOptionCard(
                  icon: Icons.local_hospital_rounded,
                  title: 'Urgent\nCare',
                  isSelected: _selectedGoal == 'urgent',
                  isDark: isDark,
                  onTap: () => setState(() => _selectedGoal = 'urgent'),
                ),
                _GridOptionCard(
                  icon: Icons.psychology_rounded,
                  title: 'Find\nSpecialist',
                  isSelected: _selectedGoal == 'specialist',
                  isDark: isDark,
                  onTap: () => setState(() => _selectedGoal = 'specialist'),
                ),
                _GridOptionCard(
                  icon: Icons.science_rounded,
                  title: 'Lab\nResults',
                  isSelected: _selectedGoal == 'labs',
                  isDark: isDark,
                  onTap: () => setState(() => _selectedGoal = 'labs'),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: _selectedGoal == null ? null : _next,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  // Slide 3: Location
  Widget _buildSlide3(bool isDark) {
    final cities = ['Cairo', 'Alexandria', 'Giza', 'Mansoura', 'Tanta', 'Other'];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where are you located?',
            style: AppTextStyles.heading2.copyWith(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'We will show doctors available near you.',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: cities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final city = cities[index];
                final isSelected = _selectedLocation == city;
                return InkWell(
                  onTap: () => setState(() => _selectedLocation = city),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : (isDark ? AppColors.darkSurface : Colors.white),
                      border: Border.all(color: isSelected ? AppColors.primary : (isDark ? AppColors.darkSurfaceAlt : AppColors.divider)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined, color: isSelected ? AppColors.primary : AppColors.textSecondary),
                        const SizedBox(width: 16),
                        Text(
                          city,
                          style: AppTextStyles.bodyLg.copyWith(
                            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected) Icon(Icons.check_circle_rounded, color: AppColors.primary),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: _selectedLocation == null ? null : _next,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  // Slide 4: Completion
  Widget _buildSlide4(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.green),
          ),
          const SizedBox(height: 32),
          Text(
            'You\'re all set!',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading1.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your profile is ready. Let\'s find the perfect clinic for you.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLg.copyWith(color: AppColors.textSecondary),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: _complete,
              child: const Text('Get Started'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : (isDark ? AppColors.darkSurface : Colors.white),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkSurfaceAlt : AppColors.divider),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : (isDark ? AppColors.darkSurfaceAlt : AppColors.scaffoldLight),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.white : AppColors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.heading3.copyWith(
                      color: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _GridOptionCard({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : (isDark ? AppColors.darkSurface : Colors.white),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkSurfaceAlt : AppColors.divider),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : (isDark ? AppColors.darkSurfaceAlt : AppColors.scaffoldLight),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.white : AppColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.label.copyWith(
                color: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
