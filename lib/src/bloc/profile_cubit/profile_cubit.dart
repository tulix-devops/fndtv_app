import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:commons/commons.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fndtv/src/data/data.dart';

part 'profile_state.dart';
part 'profile_cubit.freezed.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required GetAuthTokenUseCase getAuthTokenUseCase,
  })  : _getAuthTokenUseCase = getAuthTokenUseCase,
        super(const ProfileState());

  final GetAuthTokenUseCase _getAuthTokenUseCase;

  void onNameChanged(String name) {
    emit(state.copyWith(name: (value: name, error: _validateString(name))));
  }

  void onLastNameChanged(String lastName) {
    emit(
      state.copyWith(
        lastName: (value: lastName, error: _validateString(lastName)),
      ),
    );
  }

  void onPhoneNumberChanged(String phoneNumber) {
    emit(
      state.copyWith(
        phoneNumber: (value: phoneNumber, error: _validateString(phoneNumber)),
      ),
    );
  }

  void onFileChanged(String file) {}

  void verifySubscription() {}

  Future<void> cancelSubscription() async {}

  String? _validateString(String value) {
    if (value.isEmpty) {
      return 'Please fill out this field';
    }

    return null;
  }
}
