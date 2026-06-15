// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/widgets.dart';
// import 'package:in_app_purchase/in_app_purchase.dart';
// import 'package:in_app_purchase_android/in_app_purchase_android.dart';
// import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
// import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
// import 'package:local_storage/local_storage.dart';

// import 'package:http/http.dart' as http;
// import 'package:fndtv/src/core/services/consumable_store.dart';

// const String _kConsumableId = 'pocko_1499_1m';
// // Auto-consume must be true on iOS.
// // To try without auto-consume on another platform, change `true` to `false` here.
// final bool _kAutoConsume = Platform.isIOS || true;

// class InAppPurchaseService {
//   final InAppPurchase _inAppPurchase = InAppPurchase.instance;
//   late StreamSubscription<List<PurchaseDetails>> _subscription;
//   List<String> notFoundIds = <String>[];
//   List<ProductDetails> products = <ProductDetails>[];
//   List<PurchaseDetails> purchases = <PurchaseDetails>[];
//   List<String> consumables = <String>[];
//   bool isAvailable = false;
//   bool purchasePending = false;
//   bool loading = true;
//   String? queryProductError;

//   final void Function(List<PurchaseDetails> purchaseDetailsList)
//   onPurchaseUpdated;

//   final void Function(bool purchaseStatus) purchaseStatusUpdated;

//   final void Function(bool loaderStatus) initLoader;

//   final String userToken;

//   final List<String> _kProductIds = const <String>['pocko_1499_1m'];

//   late ConsumableStore consumableStore;

//   InAppPurchaseService({
//     required LocalStorage localStorage,
//     required this.onPurchaseUpdated,
//     required this.purchaseStatusUpdated,
//     required this.initLoader,
//     required this.userToken,
//   }) {
//     consumableStore = ConsumableStore(localStorage: localStorage);

//     final Stream<List<PurchaseDetails>> purchaseUpdated =
//         _inAppPurchase.purchaseStream;

//     _subscription = purchaseUpdated.listen(
//       _listenToPurchaseUpdated,
//       onError: (error) {
//         print(error);
//         print("Stream Error");
//       },
//     );
//     // _subscription = purchaseUpdated.listen((List<PurchaseDetails> purchaseDetailsList)  async {
//     //   print(purchaseDetailsList);
//     //   print('purchaseDetailsList.length ${purchaseDetailsList.length}');
//     //   for (var item in purchaseDetailsList) {
//     //     print('item.pendingCompletePurchase ${item.pendingCompletePurchase}');
//     //   }

//     //   onPurchaseUpdated(purchaseDetailsList);
//     // }, onDone: () {
//     //   _subscription.cancel();
//     // }, onError: (Object error) {
//     //   // handle error here.
//     //   print(error);
//     // });
//     // resetService();
//     initStoreInfo();
//   }

//   void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
//     purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
//       print(purchaseDetails.status);
//       print(purchaseDetails);
//       print("Purchase details above");
//       if (purchaseDetails.status == PurchaseStatus.pending) {
//         initLoader(true);

//         // _showPendingUI();
//       } else {
//         if (purchaseDetails.status == PurchaseStatus.error) {
//           initLoader(false);
//         } else if (purchaseDetails.status == PurchaseStatus.purchased) {
//           // purchaseDetails.status == PurchaseStatus.restored
//           print(purchaseDetails.transactionDate);
//           print(purchaseDetails.status);
//           print("hello Status Porfavor");

//           await _verifyPurchase(purchaseDetails);
//         } else if (purchaseDetails.status == PurchaseStatus.canceled) {
//           initLoader(false);
//         }
//         if (purchaseDetails.pendingCompletePurchase) {
//           await InAppPurchase.instance.completePurchase(purchaseDetails);
//         }
//       }
//     });
//   }

//   void resetService() {
//     isAvailable = false;
//     products = <ProductDetails>[];
//     purchases = <PurchaseDetails>[];
//     notFoundIds = <String>[];
//     consumables = <String>[];
//     purchasePending = false;
//     loading = false;
//     return;
//   }

//   Future<void> initStoreInfo() async {
//     print("how many times do store info update");
//     final bool isAvailable = await _inAppPurchase.isAvailable();
//     if (!isAvailable) {
//       this.isAvailable = isAvailable;
//       products = <ProductDetails>[];
//       purchases = <PurchaseDetails>[];
//       notFoundIds = <String>[];
//       this.consumables = <String>[];
//       purchasePending = false;
//       loading = false;
//       return;
//     }

//     final paymentWrapper = SKPaymentQueueWrapper();
//     final transactions = await paymentWrapper.transactions();
//     transactions.forEach((transaction) async {
//       await paymentWrapper.finishTransaction(transaction);
//     });

//     if (Platform.isIOS) {
//       final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
//           _inAppPurchase
//               .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
//       await iosPlatformAddition.setDelegate(AppPaymentQueueDelegate());
//     }

//     final ProductDetailsResponse productDetailResponse = await _inAppPurchase
//         .queryProductDetails(_kProductIds.toSet());
//     if (productDetailResponse.error != null ||
//         productDetailResponse.productDetails.isEmpty) {
//       queryProductError = productDetailResponse.error?.message;
//       this.isAvailable = isAvailable;
//       products = productDetailResponse.productDetails;

//       purchases = <PurchaseDetails>[];
//       notFoundIds = productDetailResponse.notFoundIDs;
//       this.consumables = <String>[];
//       purchasePending = false;
//       loading = false;
//       return;
//     }

//     final List<String> consumables = await consumableStore.load();
//     // print(productDetailResponse.);
//     print(productDetailResponse.productDetails.first.price);
//     print("test )r8");
//     this.isAvailable = isAvailable;
//     products = productDetailResponse.productDetails;
//     notFoundIds = productDetailResponse.notFoundIDs;
//     this.consumables = consumables;
//     purchasePending = false;
//     loading = false;
//     print("here");
//     await InAppPurchase.instance.restorePurchases();
//   }

//   Future<void> confirmPriceChange(BuildContext context) async {
//     // Price changes for Android are not handled by the application, but are
//     // instead handled by the Play Store. See
//     // https://developer.android.com/google/play/billing/price-changes for more
//     // information on price changes on Android.
//     if (Platform.isIOS) {
//       final InAppPurchaseStoreKitPlatformAddition iapStoreKitPlatformAddition =
//           _inAppPurchase
//               .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
//       await iapStoreKitPlatformAddition.showPriceConsentIfNeeded();
//     }
//   }

//   Future<void> _verifyPurchase(PurchaseDetails details) async {
//     initLoader(true);

//     print(details.verificationData.serverVerificationData);
//     print("VerificationData");
//     print(userToken);
//     print("testTOken");
//     try {
//       final response = await http.post(
//         Uri.parse(
//           'https://pockochannel.13.bozztv.com/api/subscriptions/inapp/verify?accessToken=$userToken',
//         ),
//         headers: <String, String>{
//           'Content-Type': 'application/json; charset=UTF-8',
//         },
//         body: jsonEncode(<String, dynamic>{
//           'receipt-data': details.verificationData.serverVerificationData,
//         }),
//       );

//       if (response.statusCode == 200) {
//         initLoader(false);

//         purchaseStatusUpdated(true);
//       } else {
//         initLoader(false);
//         purchaseStatusUpdated(false);
//       }
//     } catch (e) {
//       initLoader(false);
//       purchaseStatusUpdated(false);
//       print(e);
//     }
//   }

//   void purchase() async {
//     // await InAppPurchase.instance.restorePurchases();
//     // _inAppPurchase.completePurchase(purchase);
//     late PurchaseParam purchaseParam;

//     final ProductDetails productDetails =
//         products.where((ProductDetails element) {
//           print(element);
//           print("is Element Here??");
//           return element.id == _kConsumableId;
//         }).first;

//     if (Platform.isAndroid) {
//       purchaseParam = GooglePlayPurchaseParam(productDetails: productDetails);
//     } else {
//       purchaseParam = PurchaseParam(productDetails: productDetails);
//     }

//     if (productDetails.id != _kConsumableId) return;

//     try {
//       final bool purchaseStatus = await _inAppPurchase.buyConsumable(
//         purchaseParam: purchaseParam,
//         autoConsume: _kAutoConsume,
//       );

//       if (purchaseStatus) {
//         print("SUCCESSS");
//       } else {
//         print("Falsee");
//       }
//     } catch (e) {
//       print(e.toString());
//     }
//   }

//   void dispose() {
//     if (Platform.isIOS) {
//       final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
//           _inAppPurchase
//               .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();

//       iosPlatformAddition.setDelegate(null);
//     }

//     _subscription.cancel();
//   }
// }

// class AppPaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
//   @override
//   bool shouldContinueTransaction(
//     SKPaymentTransactionWrapper transaction,
//     SKStorefrontWrapper storefront,
//   ) {
//     return true;
//   }

//   @override
//   bool shouldShowPriceConsent() {
//     return false;
//   }
// }
