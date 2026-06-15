class FillProfileInfoParams {
  FillProfileInfoParams({
    required this.name,
    required this.lastName,
    required this.phoneNumber,
    required this.file,
  });

  final String? name;
  final String? lastName;
  final String? phoneNumber;
  // img path
  final String? file;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'file': file,
    };
  }
}

class CancelSubscriptionParam {
  CancelSubscriptionParam({
    required this.token,
  });

  final String token;

  Map<String, dynamic> toJson() {
    return {
      'token': token,
    };
  }
}
