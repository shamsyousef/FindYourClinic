import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/health_record_entity.dart';
import '../cubits/health_record_cubit.dart';
import '../cubits/health_record_state.dart';

class AddHealthRecordScreen extends StatefulWidget {
  final HealthRecordEntity? existingRecord;

  const AddHealthRecordScreen({super.key, this.existingRecord});

  @override
  State<AddHealthRecordScreen> createState() => _AddHealthRecordScreenState();
}

class _AddHealthRecordScreenState extends State<AddHealthRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _valueController;
  late final TextEditingController _unitController;
  late final TextEditingController _notesController;

  late HealthRecordType _selectedType;
  late DateTime _selectedDate;

  bool get _isEditing => widget.existingRecord != null;

  static const _typeLabels = <HealthRecordType, String>{
    HealthRecordType.bloodPressure: 'Blood Pressure',
    HealthRecordType.heartRate: 'Heart Rate',
    HealthRecordType.labResult: 'Lab Result',
    HealthRecordType.prescription: 'Prescription',
    HealthRecordType.bloodTest: 'Blood Test',
    HealthRecordType.radiology: 'Radiology',
    HealthRecordType.vaccination: 'Vaccination',
    HealthRecordType.bloodSugar: 'Blood Sugar',
    HealthRecordType.temperature: 'Temperature',
    HealthRecordType.weight: 'Weight',
    HealthRecordType.spO2: 'SpO2',
    HealthRecordType.other: 'Other',
  };

  static const _defaultUnits = <HealthRecordType, String>{
    HealthRecordType.bloodPressure: 'mmHg',
    HealthRecordType.heartRate: 'bpm',
    HealthRecordType.bloodSugar: 'mg/dL',
    HealthRecordType.temperature: '°C',
    HealthRecordType.weight: 'kg',
    HealthRecordType.spO2: '%',
  };

  @override
  void initState() {
    super.initState();
    final r = widget.existingRecord;
    _titleController = TextEditingController(text: r?.title ?? '');
    _valueController = TextEditingController(text: r?.value ?? '');
    _unitController = TextEditingController(text: r?.unit ?? '');
    _notesController = TextEditingController(text: r?.notes ?? '');
    _selectedType = r?.type ?? HealthRecordType.bloodPressure;
    _selectedDate = r?.recordedAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _valueController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTypeChanged(HealthRecordType? type) {
    if (type == null) return;
    setState(() {
      _selectedType = type;
      if (_unitController.text.isEmpty || _defaultUnits.containsValue(_unitController.text)) {
        _unitController.text = _defaultUnits[type] ?? '';
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<HealthRecordCubit>();
    if (_isEditing) {
      await cubit.updateRecord(
        id: widget.existingRecord!.id,
        title: _titleController.text.trim(),
        type: _selectedType,
        value: _valueController.text.trim().isEmpty ? null : _valueController.text.trim(),
        unit: _unitController.text.trim().isEmpty ? null : _unitController.text.trim(),
        recordedAt: _selectedDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
    } else {
      await cubit.createRecord(
        title: _titleController.text.trim(),
        type: _selectedType,
        value: _valueController.text.trim().isEmpty ? null : _valueController.text.trim(),
        unit: _unitController.text.trim().isEmpty ? null : _unitController.text.trim(),
        recordedAt: _selectedDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Record' : 'Add Record'),
      ),
      body: BlocListener<HealthRecordCubit, HealthRecordState>(
        listener: (context, state) {
          if (state is HealthRecordError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'e.g. Morning blood pressure',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                // ignore: deprecated_member_use
                DropdownButtonFormField<HealthRecordType>(
                  value: _selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: _typeLabels.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: _onTypeChanged,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _valueController,
                        decoration: const InputDecoration(labelText: 'Value'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(labelText: 'Unit'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 28),
                BlocBuilder<HealthRecordCubit, HealthRecordState>(
                  builder: (context, state) {
                    final loading = state is HealthRecordActionInProgress;
                    return FilledButton(
                      onPressed: loading ? null : _save,
                      child: loading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : Text(_isEditing ? 'Save Changes' : 'Add Record'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
