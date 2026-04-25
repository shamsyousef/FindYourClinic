import '../../domain/entities/specialty_entity.dart';

sealed class SpecialtyState {}

class SpecialtyInitial extends SpecialtyState {}

class SpecialtyLoading extends SpecialtyState {}

class SpecialtyLoaded extends SpecialtyState {
  final List<Specialty> specialties;
  SpecialtyLoaded(this.specialties);
}

class SpecialtyError extends SpecialtyState {
  final String message;
  SpecialtyError(this.message);
}
