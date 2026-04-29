import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/token_storage.dart';
import '../../domain/entities/doctor_profile_entities.dart';
import '../cubits/edit_doctor_profile_cubit.dart';
import '../cubits/edit_doctor_profile_state.dart';

class DoctorEditProfileScreen extends StatefulWidget {
  const DoctorEditProfileScreen({super.key});

  @override
  State<DoctorEditProfileScreen> createState() =>
      _DoctorEditProfileScreenState();
}

class _DoctorEditProfileScreenState extends State<DoctorEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bioCtrl;
  late final TextEditingController _clinicNameCtrl;
  late final TextEditingController _clinicAddressCtrl;
  late final TextEditingController _feeCtrl;
  late final TextEditingController _experienceCtrl;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _bioCtrl = TextEditingController();
    _clinicNameCtrl = TextEditingController();
    _clinicAddressCtrl = TextEditingController();
    _feeCtrl = TextEditingController();
    _experienceCtrl = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = await sl<TokenStorage>().getUserId();
    if (userId != null && mounted) {
      context.read<EditDoctorProfileCubit>().loadProfile(userId);
    }
  }

  void _populateFields(DoctorDetails details) {
    if (_initialized) return;
    _initialized = true;
    _bioCtrl.text = details.bio ?? '';
    _clinicNameCtrl.text = details.clinicName ?? '';
    _clinicAddressCtrl.text = details.clinicAddress ?? '';
    _feeCtrl.text = details.consultationFee.toString();
    _experienceCtrl.text = details.experienceYears.toString();
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _clinicNameCtrl.dispose();
    _clinicAddressCtrl.dispose();
    _feeCtrl.dispose();
    _experienceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    context.read<EditDoctorProfileCubit>().saveProfile(
          UpdateDoctorProfileParams(
            bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
            clinicName: _clinicNameCtrl.text.trim().isEmpty
                ? null
                : _clinicNameCtrl.text.trim(),
            clinicAddress: _clinicAddressCtrl.text.trim().isEmpty
                ? null
                : _clinicAddressCtrl.text.trim(),
            consultationFee: double.tryParse(_feeCtrl.text.trim()),
            experienceYears: int.tryParse(_experienceCtrl.text.trim()),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          BlocBuilder<EditDoctorProfileCubit, EditDoctorProfileState>(
            builder: (context, state) {
              final saving = state is EditDoctorProfileSaving;
              return TextButton(
                onPressed: saving ? null : _save,
                child: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<EditDoctorProfileCubit, EditDoctorProfileState>(
        listener: (context, state) {
          if (state is EditDoctorProfileLoaded) {
            _populateFields(state.details);
          }
          if (state is EditDoctorProfileSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully')),
            );
            context.pop();
          }
          if (state is EditDoctorProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is EditDoctorProfileLoading ||
              state is EditDoctorProfileInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is EditDoctorProfileError &&
              state is! EditDoctorProfileLoaded) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loadProfile,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _bioCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    maxLength: 1000,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _clinicNameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Clinic Name'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _clinicAddressCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Clinic Address'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _feeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Consultation Fee',
                            prefixText: '\$',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (v) {
                            if (v != null &&
                                v.isNotEmpty &&
                                double.tryParse(v) == null) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _experienceCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Experience (years)',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v != null &&
                                v.isNotEmpty &&
                                int.tryParse(v) == null) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.schedule_outlined),
                    label: const Text('Manage Availability'),
                    onPressed: () => context.push('/doctor/home/availability'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
