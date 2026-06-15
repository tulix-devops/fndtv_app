import 'package:equatable/equatable.dart';
import 'package:fndtv/src/data/models/ad_model/ad_detail.dart';

class AdModel extends Equatable {
  final bool showAd;
  final AdDetails ad;

  const AdModel({required this.showAd, required this.ad});

  factory AdModel.fromJson(Map<String, dynamic> json) {
    return AdModel(
      showAd: json['showAd'] as bool,
      ad: AdDetails.fromJson(json['ad']),
    );
  }

  @override
  List<Object?> get props => [showAd, ad];
}
