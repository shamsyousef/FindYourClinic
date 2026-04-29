import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/doctor_profile_cubit.dart';
import '../cubits/doctor_profile_state.dart';

class AddReviewBottomSheet extends StatefulWidget {
  final String doctorId;

  const AddReviewBottomSheet({super.key, required this.doctorId});

  @override
  State<AddReviewBottomSheet> createState() => _AddReviewBottomSheetState();
}

class _AddReviewBottomSheetState extends State<AddReviewBottomSheet> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<DoctorProfileCubit, DoctorProfileState>(
      listener: (context, state) {
        if (state is DoctorProfileReviewSuccess) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Review submitted')),
          );
        }
        if (state is DoctorProfileReviewError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Write a Review', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('Your Rating', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) {
                final filled = i < _rating;
                return GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: const Color(0xFFF59E0B),
                      size: 36,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentCtrl,
              decoration: const InputDecoration(
                labelText: 'Your experience (optional)',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            BlocBuilder<DoctorProfileCubit, DoctorProfileState>(
              builder: (context, state) {
                final submitting = state is DoctorProfileReviewError
                    ? false
                    : (state is DoctorProfileReviewSuccess);
                return FilledButton(
                  onPressed: _rating == 0 || submitting
                      ? null
                      : () => context.read<DoctorProfileCubit>().addReview(
                            widget.doctorId,
                            _rating,
                            _commentCtrl.text.trim().isEmpty
                                ? null
                                : _commentCtrl.text.trim(),
                          ),
                  child: submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Review'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
