import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../cubits/symptom_checker_cubit.dart';
import '../cubits/symptom_checker_state.dart';
import '../widgets/symptom_chip.dart';

const _symptoms = [
  ('Head', 'Headache'),
  ('General', 'Fever'),
  ('Respiratory', 'Cough'),
  ('Respiratory', 'Sore Throat'),
  ('General', 'Fatigue'),
  ('Digestive', 'Nausea'),
  ('Head', 'Dizziness'),
  ('Cardiovascular', 'Chest Pain'),
  ('Respiratory', 'Shortness of Breath'),
  ('Digestive', 'Abdominal Pain'),
  ('Musculoskeletal', 'Back Pain'),
  ('Musculoskeletal', 'Joint Pain'),
  ('Skin', 'Rash'),
  ('Respiratory', 'Runny Nose'),
  ('Digestive', 'Diarrhea'),
  ('General', 'Chills'),
  ('Cardiovascular', 'Palpitations'),
  ('Digestive', 'Vomiting'),
  ('Skin', 'Swelling'),
  ('Other', 'Insomnia'),
];

class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<(String, String)> get _filteredSymptoms {
    if (_searchQuery.isEmpty) return _symptoms;
    final q = _searchQuery.toLowerCase();
    return _symptoms
        .where((s) => s.$2.toLowerCase().contains(q))
        .toList();
  }

  bool get _hasCustomSymptom {
    if (_searchQuery.isEmpty) return false;
    final q = _searchQuery.toLowerCase();
    return !_symptoms.any((s) => s.$2.toLowerCase() == q);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<SymptomCheckerCubit, SymptomCheckerState>(
      listener: (context, state) {
        if (state is SymptomCheckerResult) {
          context.pushNamed(
            RouteNames.symptomResult,
            extra: state.analysis,
          );
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.scaffoldLight,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientMiddle],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Symptom Checker',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Column(
          children: [
            _buildDisclaimer(isDark),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                style: AppTextStyles.bodyMd.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search symptoms...',
                  hintStyle:
                      AppTextStyles.bodyMd.copyWith(color: AppColors.textHint),
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textSecondary),
                  filled: true,
                  fillColor:
                      isDark ? AppColors.darkSurface : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BlocBuilder<SymptomCheckerCubit, SymptomCheckerState>(
                builder: (context, state) {
                  if (state is SymptomCheckerAnalyzing) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  final selected = switch (state) {
                    SymptomCheckerSelecting(:final selected) => selected,
                    _ => <String>[],
                  };

                  final filtered = _filteredSymptoms;
                  final showCustom = _hasCustomSymptom;
                  final totalCount =
                      filtered.length + (showCustom ? 1 : 0);

                  if (totalCount == 0) {
                    return Center(
                      child: Text(
                        'No symptoms found',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: totalCount,
                    itemBuilder: (context, index) {
                      if (showCustom && index == 0) {
                        final customName = _searchQuery;
                        return SymptomChip(
                          category: 'Custom',
                          name: customName,
                          isSelected: selected.contains(customName),
                          onTap: () => context
                              .read<SymptomCheckerCubit>()
                              .toggleSymptom(customName),
                        );
                      }
                      final symptomIndex = showCustom ? index - 1 : index;
                      final symptom = filtered[symptomIndex];
                      return SymptomChip(
                        category: symptom.$1,
                        name: symptom.$2,
                        isSelected: selected.contains(symptom.$2),
                        onTap: () => context
                            .read<SymptomCheckerCubit>()
                            .toggleSymptom(symptom.$2),
                      );
                    },
                  );
                },
              ),
            ),
            _buildAnalyzeButton(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimer(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2500) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: AppColors.warning, width: 3),
        ),
      ),
      child: Text(
        '⚠ AI suggestions are not a substitute for professional medical advice.',
        style: TextStyle(
          fontSize: 11,
          color: isDark ? const Color(0xFFD4A017) : const Color(0xFF92400E),
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton(bool isDark) {
    return BlocBuilder<SymptomCheckerCubit, SymptomCheckerState>(
      builder: (context, state) {
        final selected = switch (state) {
          SymptomCheckerSelecting(:final selected) => selected,
          _ => <String>[],
        };
        final isEnabled = selected.isNotEmpty;
        final isAnalyzing = state is SymptomCheckerAnalyzing;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SafeArea(
            top: false,
            child: GestureDetector(
              onTap: isEnabled && !isAnalyzing
                  ? () =>
                      context.read<SymptomCheckerCubit>().analyzeSymptoms()
                  : null,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: isEnabled
                      ? const LinearGradient(
                          colors: [
                            AppColors.gradientMiddle,
                            AppColors.gradientEnd
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                  color: isEnabled ? null : AppColors.divider,
                ),
                child: Center(
                  child: Text(
                    isAnalyzing
                        ? 'Analyzing...'
                        : 'Analyze Symptoms (${selected.length})',
                    style: AppTextStyles.button.copyWith(
                      color: isEnabled
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
