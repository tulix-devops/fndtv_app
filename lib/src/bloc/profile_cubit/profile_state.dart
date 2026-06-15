part of 'profile_cubit.dart';

@freezed
class ProfileState with _$ProfileState {
  const ProfileState._();

  const factory ProfileState({
    @Default('') String email,
    @Default((value: null, error: null)) InputModel name,
    @Default((value: null, error: null)) InputModel lastName,
    @Default((value: null, error: null)) InputModel phoneNumber,
    @Default(null) String? file,
    @Default(FormStatus.initial) FormStatus status,
    @Default(Status.initial) Status initStatus,
    String? formError,
    String? error,
  }) = _ProfileState;

  bool get isValidating => status == FormStatus.inProgress;

  bool get isValid =>
      name.value != null ||
      lastName.value != null ||
      phoneNumber.value != null ||
      file != null;

  bool get hasFormError => formError != null && formError!.isNotEmpty;

  String errorsToString(List<ValidationErrorModel> errors) =>
      errors.map((e) => e.errors).expand((i) => i).join('\n');
}
