// import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class SubscriptionResult {
//   final List<IAPItem> items;
//   final dynamic error;

//   SubscriptionResult({required this.items, this.error});
// }

// class InAppPurchaseService {
//   static final InAppPurchaseService _instance =
//       InAppPurchaseService._internal();

//   factory InAppPurchaseService() {
//     return _instance;
//   }

//   InAppPurchaseService._internal();

//   Future<void> initialize() async {
//     await FlutterInappPurchase.instance.initialize();
//     await _setPurchaseListener();
//   }

//   Future<void> dispose() async {
//     await FlutterInappPurchase.instance.finalize();
//   }

//   Future<List<IAPItem>> getProducts(List<String> productIds) async {
//     try {
//       List<IAPItem> items =
//           await FlutterInappPurchase.instance.getProducts(productIds);
//       return items;
//     } catch (error) {
//       print('Error fetching products: $error');
//       return [];
//     }
//   }

//   Future<SubscriptionResult> getSubscriptions(List<String> productIds) async {
//     try {
//       List<IAPItem> items =
//           await FlutterInappPurchase.instance.getSubscriptions(productIds);
//       return SubscriptionResult(items: items);
//     } catch (error) {
//       return SubscriptionResult(items: [], error: error);
//     }
//   }

//   Future<void> purchaseProduct(String productId) async {
//     try {
//       await FlutterInappPurchase.instance.requestPurchase(productId);
//     } catch (error) {
//       print('Error purchasing product: $error');
//     }
//   }

//   Future<void> _setPurchaseListener() async {
//     FlutterInappPurchase.purchaseUpdated.listen((purchasedItem) {
//       _verifyPurchase(purchasedItem?.transactionReceipt ?? '');
//     });

//     FlutterInappPurchase.purchaseError.listen((purchaseError) {
//       print('Purchase Error: $purchaseError');
//     });
//   }

//   Future<void> _verifyPurchase(String receipt) async {
//     final response = await http.post(
//       Uri.parse('https://your-backend.com/validate-receipt'),
//       headers: <String, String>{
//         'Content-Type': 'application/json; charset=UTF-8',
//       },
//       body: jsonEncode(<String, String>{
//         'receipt-data': receipt,
//       }),
//     );

//     if (response.statusCode == 200) {
//       print('Purchase verified successfully.');
//     } else {
//       print('Failed to verify purchase.');
//     }
//   }
// }
