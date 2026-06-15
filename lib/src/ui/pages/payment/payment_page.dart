// import 'package:commons/auth/domain/repositories/repositories.dart';
// import 'package:commons/shared/extensions.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:ui_kit/ui_kit.dart';
// import 'package:ui_kit/widgets/app_modal.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:fndtv/src/index.dart';

// class PaymentPage extends StatefulWidget {
//   const PaymentPage({
//     super.key,
//     required this.onPaymentProccessed,
//   });

//   final Function(String) onPaymentProccessed;
//   static const path = 'paymentPage';
//   static const name = 'paymentPage';

//   @override
//   State<PaymentPage> createState() => _PaymentPageState();
// }

// class _PaymentPageState extends State<PaymentPage> {
//   Map<String, dynamic>? paymentIntentData;
//   late final WebViewController webViewController = WebViewController();

//   String userToken = '';

//   @override
//   void initState() {
//     fetchTokenAndDefineUrl();

//     super.initState();
//   }

//   void delegateWebViewController(String? token) {
//     if (token != null) {
//       var paymentLink =
//           'https://pockochannel.13.bozztv.com/api/subscribe?accessToken=$token';
//       setState(() {
//         webViewController
//           ..setJavaScriptMode(JavaScriptMode.unrestricted)
//           ..setNavigationDelegate(NavigationDelegate(
//               onNavigationRequest: (NavigationRequest request) {
//             if (request.url.contains('checkout/fail')) {
//               // const String text = 'Payment failed';
//               // const NotificationType type = NotificationType.error;
//               // context.pop();
//               widget.onPaymentProccessed('fail');
//               // buildPaymentStatusDialog(true);
//               // context.read<NotificationBannerCubit>().showNotification(
//               //       type,
//               //       text,
//               //     );
//               // buildPaymentStatusDialog(false);
//               return NavigationDecision.navigate;
//             } else if (request.url.contains('success')) {
//               widget.onPaymentProccessed('success');
//               _initializePayment();
//               // context.read<NotificationBannerCubit>().showNotification(
//               //       NotificationType.success,
//               //       'Payment successful',
//               //     );
//               // context.pop();
//               // buildPaymentStatusDialog(true);
//               return NavigationDecision.navigate;
//             }
//             return NavigationDecision.navigate;
//           }))
//           ..loadRequest(
//             Uri.parse(paymentLink),
//           );
//       });
//     }
//   }

//   void fetchTokenAndDefineUrl() async {
//     final AuthRepository authRepo = context.read<AuthRepository>();
//     var token = await authRepo.getToken();
//     WidgetsBinding.instance.addPostFrameCallback(
//       (_) {
//         setState(() {
//           userToken = token.toString();
//         });
//       },
//     );
//     delegateWebViewController(token);
//   }

//   Future<void> _initializePayment() async {
//     context.read<AppCubit>().showOverlay();
//     AppCubit appCubit = context.read<AppCubit>();
//     Future.delayed(const Duration(seconds: 1), () async {
//       await appCubit.initUser();
//     });
//   }

//   Future<void> _checkPayment() async {
//     context.read<AppCubit>().showOverlay();
//     AppCubit appCubit = context.read<AppCubit>();
//     await appCubit.initUser();
//     bool isSubscribed = appCubit.state.isSubscribed;
//     Future.delayed(const Duration(seconds: 1), () async {
//       context.read<AppCubit>().hideOverlay();

//       if (isSubscribed) {
//         buildPaymentStatusDialog(true);
//         widget.onPaymentProccessed('success');
//       } else {
//         buildPaymentStatusDialog(false);
//         widget.onPaymentProccessed('fail');
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (context.isTv) {
//       return AppScaffold(
//         hasNavbar: false,
//         body: CustomScrollView(
//           slivers: [
//             // PageHeader(
//             //   isMainPage: context.isTv,
//             //   onPressed: () {
//             //     context.pop();
//             //   },
//             //   isTv: context.isTv,
//             //   page: 'Payment Screen',
//             // ),
//             if (context.isTv)
//               SliverPadding(
//                 padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
//                 sliver: SliverList.list(children: [
//                   Text(
//                     'Scan the QR code below or enter the link in your web browser to  make payment with Stripe',
//                     style: TextStyles.h3.surface(context),
//                     textAlign: TextAlign.start,
//                   ),
//                   Margins.vertical20,
//                   Container(
//                     alignment: Alignment.center,
//                     width: 200.0,
//                     height: 200.0,
//                     decoration: const BoxDecoration(
//                       color: Colors.black,
//                       borderRadius: BorderRadius.all(
//                         Radius.circular(10.0),
//                       ),
//                     ),
//                     child: QrImageView(
//                       embeddedImageStyle: const QrEmbeddedImageStyle(
//                         size: Size(60, 60),
//                       ),
//                       backgroundColor: Colors.white,
//                       data:
//                           'https://pockochannel.13.bozztv.com/api/subscribe?accessToken=$userToken',
//                       version: QrVersions.auto,
//                     ),
//                   ),
//                   Margins.vertical20,
//                   AppButton.primaryRounded(
//                       label: 'Check payment',
//                       onPressed: () {
//                         _checkPayment().then((value) {});
//                       })
//                 ]),
//               ),
//           ],
//         ),
//       );
//     }

//     if (!context.isTv) {
//       return SizedBox(
//         height: MediaQuery.of(context).size.height * 0.9,
//         child: WebViewWidget(
//           controller: webViewController,
//           gestureRecognizers: {
//             Factory<VerticalDragGestureRecognizer>(
//               () => VerticalDragGestureRecognizer(),
//             ),
//           },
//         ),
//       );
//     }
//     return const SizedBox.shrink();
//   }

//   void buildPaymentStatusDialog(bool isSuccuess) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AppModal(
//           title: isSuccuess ? 'Congratulations!' : 'Payment Failed.',
//           label: isSuccuess
//               ? 'You have successfully subscribed to premium. Enjoy the benefits!'
//               : 'Unfortunately your payment was not completed successfully. Please try again.',
//           icon: isSuccuess ? Assets.shieldDone : Assets.shieldFailed,
//           imageColor: context.uiColors.primary,
//           children: [
//             AppButton.primary(
//               label: 'OK',
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//             )
//           ],
//         );
//       },
//     ).then((value) {
//       if (isSuccuess) {
//         return context.pop();
//       }
//     });
//   }
// }
