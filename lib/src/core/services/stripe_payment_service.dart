// import 'dart:convert';

// import 'package:flutter/material.dart';
// // import 'package:flutter_stripe/flutter_stripe.dart';
// import 'package:http/http.dart' as http;

// class StripePaymentService {
//   Future<bool> initializeStripePayment(BuildContext context) async {
//     Map<String, dynamic> payment = await createPaymentIntent(context);

//     try {
//       Map<String, dynamic> paymentIntentData = payment;
//       // {
//       //   "id": "pi_3P1BQXGCHxnGqewS0TWzPB0v",
//       //   "object": "payment_intent",
//       //   "amount": 55,
//       //   "amount_capturable": 0,
//       //   "amount_details": {"tip": {}},
//       //   "amount_received": 0,
//       //   "application": null,
//       //   "application_fee_amount": null,
//       //   "automatic_payment_methods": {"allow_redirects": "always", "enabled": true},
//       //   "canceled_at": null,
//       //   "cancellation_reason": null,
//       //   "capture_method": "automatic",
//       //   "client_secret": "pi_3P1BQXGCHxnGqewS0TWzPB0v_secret_NUBPg5ywQ8P2LTR2V4MyWb6dL",
//       //   "confirmation_method": "automatic",
//       //   "created": 1712080037,
//       //   "currency": "usd",
//       //   "customer": null,
//       //   "description": null,
//       //   "invoice": null,
//       //   "last_payment_error": null,
//       //   "latest_charge": null,
//       //   "livemode": false,
//       //   "metadata": {},
//       //   "next_action": null,
//       //   "on_behalf_of": null,
//       //   "payment_method": null,
//       //   "payment_method_configuration_details": null,
//       //   "payment_method_options": {
//       //     "card": {
//       //       "installments": null,
//       //       "mandate_options": null,
//       //       "network": null,
//       //       "request_three_d_secure": "automatic"
//       //     }
//       //   },
//       //   "payment_method_types": ["card"],
//       //   "processing": null,
//       //   "receipt_email": null,
//       //   "review": null,
//       //   "setup_future_usage": null,
//       //   "shipping": null,
//       //   "source": null,
//       //   "statement_descriptor": null,
//       //   "statement_descriptor_suffix": null,
//       //   "status": "requires_payment_method",
//       //   "transfer_data": null,
//       //   "transfer_group": null
//       // };

//       await Stripe.instance.initPaymentSheet(
//         paymentSheetParameters: SetupPaymentSheetParameters(
//           paymentIntentClientSecret: paymentIntentData['client_secret'],
//           merchantDisplayName: 'Pocko',
//         ),
//       );

//       await Stripe.instance.presentPaymentSheet();

//       return true;
//     } on StripeException catch (stripeEx) {
//       throw StripeServiceException(stripeEx.error.localizedMessage.toString());
//     } catch (e) {
//       throw PaymentFailedException('Payment failed: $e');
//     }
//   }

//   Future<Map<String, dynamic>> createPaymentIntent(BuildContext context) async {
//     const String url = 'https://api.stripe.com/v1/payment_intents';
//     const String apiKey = 'REPLACE_WITH_KEY_FROM_SECURE_BACKEND';
//     String basicAuth = 'Basic ${base64Encode(utf8.encode('$apiKey:'))}';

//     try {
//       final response = await http.post(
//         Uri.parse(url),
//         headers: {
//           'Content-Type': 'application/x-www-form-urlencoded',
//           'Authorization': basicAuth,
//         },
//         body: {
//           'amount': '55',
//           'currency': 'usd',
//           'automatic_payment_methods[enabled]': 'true',
//         },
//       );

//       if (response.statusCode == 200) {
//         // If the server returns a 200 OK response, parse the JSON and return it.
//         return json.decode(response.body);
//       } else {
//         // If the server did not return a 200 OK response, log the error and return an error map.
//         print('Request failed with status: ${response.statusCode}.');
//         return {'error': 'Failed to create payment intent. Status code: ${response.statusCode}'};
//       }
//     } catch (e) {
//       print('Caught exception: $e');
//       // Optionally, return an error map or rethrow the exception.
//       return {'error': 'Exception occurred: $e'};
//     }
//   }
// }

// class PaymentFailedException implements Exception {
//   final String message;
//   PaymentFailedException(this.message);
// }

// class StripeServiceException implements Exception {
//   final String message;
//   StripeServiceException(this.message);
// }
