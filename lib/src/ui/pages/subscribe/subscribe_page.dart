// import 'package:commons/commons.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:in_app_purchase/in_app_purchase.dart';
// import 'package:local_storage/local_storage.dart';

// import 'package:fndtv/src/index.dart';
// import 'package:ui_kit/ui_kit.dart';
// import 'package:ui_kit/widgets/app_modal.dart';

// class SubscribePage extends StatefulWidget {
//   const SubscribePage({super.key, this.profileEntity});

//   static const path = 'subscription';
//   static const name = 'subscription';

//   final ProfileModel? profileEntity;

//   @override
//   State<SubscribePage> createState() => _SubscribePageState();
// }

// class _SubscribePageState extends State<SubscribePage> {
//   bool paymentStatus = false;
//   // bool isSubscribed = false;

//   late final InAppPurchaseService inAppPurchaseService;

//   @override
//   void initState() {
//     if (widget.profileEntity != null) {}
//     // isSubscribed = context.read<AppCubit>().state.isSubscribed;

//     // Future.microtask(() {

//     // });

//     initInAppPurchase();

//     super.initState();
//   }

//   Future<void> initInAppPurchase() async {
//     final AuthRepository authRepo = context.read<AuthRepository>();
//     var token = await authRepo.getToken();

//     if (!mounted) return;

//     inAppPurchaseService = InAppPurchaseService(
//         localStorage: context.read<LocalStorage>(),
//         onPurchaseUpdated: (List<PurchaseDetails> purchaseDetailsList) {
//           if (purchaseDetailsList.isNotEmpty) {}
//         },
//         purchaseStatusUpdated: (bool purchaseStatus) async {
//           if (kDebugMode) {
//             print(purchaseStatus);
//             print("Purchase State Updated");
//           }

//           if (purchaseStatus) {
//             buildPaymentStatusDialog(purchaseStatus, '');
//             await context.read<AppCubit>().initUser();
//           } else {
//             buildPaymentStatusDialog(purchaseStatus, '');
//           }

//           if (kDebugMode) {
//             print(purchaseStatus);
//           }
//         },
//         initLoader: (bool loaderStatus) {
//           if (loaderStatus) {
//             context.read<AppCubit>().showOverlay();
//           } else {
//             context.read<AppCubit>().hideOverlay();
//           }
//         },
//         userToken: token ?? '');

//     setState(() {});
//   }

//   @override
//   void dispose() {
//     inAppPurchaseService.dispose();
//     super.dispose();
//   }

//   Future<void> cancelModal(
//       BuildContext context, ProfileCubit cubit, AppCubit app) {
//     return showModalBottomSheet<void>(
//       context: context,
//       builder: (BuildContext context) {
//         return AppBottomSheetModal(
//           label: 'Do you want to cancel?',
//           title: 'Cancel Subscription',
//           titleColor: context.uiColors.error,
//           children: [
//             AppButton.secondaryRounded(
//               label: 'Cancel',
//               onPressed: () {
//                 paymentStatus = false;
//                 context.pop();
//               },
//             ),
//             AppButton.primaryRounded(
//               label: 'Confirm',
//               onPressed: () async {
//                 paymentStatus = true;
//                 context.read<AppCubit>().showOverlay();
//                 // context.pushReplacementNamed(LoginPage.name)
//                 await cubit.cancelSubscription();
//                 await app.initUser();

//                 // ignore: use_build_context_synchronously
//                 context.pop();
//               },
//             )
//           ],
//         );
//       },
//     ).then((value) {
//       Future.delayed(const Duration(seconds: 2), () {
//         context.read<AppCubit>().hideOverlay();
//         buildSubscriptionCancelDialog(paymentStatus, '');
//       });
//     });
//   }

//   void _getProducts(BuildContext context) async {
//     try {
//       setState(() {
//         if (inAppPurchaseService.products.isNotEmpty) {
//           _showPurchaseModal(context, inAppPurchaseService.products[0]);
//         } else {
//           _showSnackBar('No products available'.toString());
//         }
//       });
//     } catch (e) {
//       _showSnackBar('PRODUCTS: ${e.toString()}');
//     }
//   }

//   void _showSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   Future<void> showPaymentModal(
//       BuildContext context, ProfileCubit cubit, AppCubit app) {
//     return showModalBottomSheet<void>(
//       context: context,
//       isScrollControlled: true,
//       builder: (BuildContext context) {
//         return FractionallySizedBox(
//             heightFactor: 0.75,
//             child: PaymentPage(
//               onPaymentProccessed: (String status) async {
//                 if (status == 'fail') {
//                   setState(() {
//                     paymentStatus = false;
//                   });
//                   context.pop();
//                 } else if (status == 'success') {
//                   setState(() {
//                     paymentStatus = true;
//                   });
//                   context.read<AppCubit>().showOverlay();
//                   // await context.read<AppCubit>().initUser();

//                   context.pop();
//                 }
//               },
//             ));
//       },
//     ).then((value) {
//       Future.delayed(const Duration(seconds: 1), () {
//         context.read<AppCubit>().hideOverlay();
//         buildPaymentStatusDialog(paymentStatus, '');
//       });
//     });
//   }

//   void _showPurchaseModal(BuildContext scontext, ProductDetails item) {
//     showModalBottomSheet(
//       context: scontext,
//       builder: (BuildContext context) {
//         return Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(item.title, style: const TextStyle(fontSize: 24)),
//               const SizedBox(height: 18),
//               Text(item.description, style: const TextStyle(fontSize: 16)),
//               const SizedBox(height: 32),
//               Text(item.price,
//                   style: const TextStyle(
//                       fontSize: 31, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 32),
//               ElevatedButton(
//                 onPressed: () {
//                   inAppPurchaseService.purchase();
//                   context.pop();
//                 },
//                 child: Text(
//                   'Subscribe',
//                   style: TextStyles.bodyMediumBold.surface(context).copyWith(
//                         fontSize: 35,
//                         color: context.uiColors.primary,
//                       ),
//                 ),
//               ),
//               const SizedBox(height: 40),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Future<void> cancelSubscriptionModal() {
//     return showModalBottomSheet<void>(
//       context: context,
//       isScrollControlled: true,
//       builder: (BuildContext context) {
//         return FractionallySizedBox(
//             heightFactor: 0.75,
//             child: PaymentPage(
//               onPaymentProccessed: (String status) {
//                 if (status == 'fail') {
//                   setState(() {
//                     paymentStatus = false;
//                   });
//                   // context.pop();
//                 } else if (status == 'success') {
//                   setState(() {
//                     // isSubscribed = context.select<AppCubit, bool>((value) => value.state.isSubscribed);
//                     // isSubscribed = context.read<AppCubit>().state.isSubscribed;
//                     paymentStatus = true;
//                   });
//                   // context.pop();
//                 }
//               },
//             ));
//       },
//     ).then((value) {
//       context.read<AppCubit>().showOverlay();

//       Future.delayed(const Duration(seconds: 1), () {
//         context.read<AppCubit>().hideOverlay();
//         buildPaymentStatusDialog(paymentStatus, '');
//         context.pop();
//       });
//     });
//   }

//   Future<String?> getToken() async {
//     final AuthRepository authRepo = context.read<AuthRepository>();
//     var token = await authRepo.getToken();
//     return token;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<AppCubit, AppState>(
//       listener: (context, state) {},
//       child: BlocSelector<AppCubit, AppState, bool>(
//         selector: (state) {
//           return state.isSubscribed;
//         },
//         builder: (context, isSubscribed) {
//           return AppScaffold(
//             hasNavbar: false,
//             body: CustomScrollView(
//               slivers: [
//                 PageHeader(
//                   isTv: context.isTv,
//                   onPressed: () {
//                     context.pop();
//                   },
//                   isMainPage: false,
//                   page: '',
//                 ),
//                 SliverPadding(
//                   padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
//                   sliver: SliverToBoxAdapter(
//                     child: SingleChildScrollView(
//                       child: Column(
//                         children: [
//                           isSubscribed
//                               ? _subscribedWidget(context)
//                               : _subscribeToChannelWidget(context),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _subscribedWidget(BuildContext context) => Column(
//         children: [
//           _subscriptionBasedWidget(
//             context,
//             '\$14.99',
//             DateTime(
//               2024,
//               9,
//               7,
//               30,
//             ),
//           ),
//           Margins.vertical10,
//           _upcomingSubscription(
//             context,
//             '\$14.99',
//             (
//               expireDate: context
//                       .read<AppCubit>()
//                       .state
//                       .userInfo
//                       ?.subscription
//                       .expires_at ??
//                   '',
//               createdAtDate: context
//                       .read<AppCubit>()
//                       .state
//                       .userInfo
//                       ?.subscription
//                       .created_at ??
//                   DateTime.now()
//             ),
//           ),
//           Margins.vertical10,
//           InkWell(
//             borderRadius: BorderRadius.circular(35),
//             onTap: () {
//               cancelModal(context, context.read<ProfileCubit>(),
//                   context.read<AppCubit>());
//             },
//             child: Container(
//               height: 50,
//               width:
//                   context.isTv ? MediaQuery.of(context).size.width / 2 : null,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(35),
//                 color: context.uiColors.primary,
//               ),
//               alignment: Alignment.center,
//               child: Text(
//                 'Cancel Subscription',
//                 style: TextStyles.bodyMediumBold,
//               ),
//             ),
//           ),
//           const SizedBox(height: 100),
//         ],
//       );

//   Widget _upcomingSubscription(BuildContext context, String amount,
//       ({String expireDate, DateTime createdAtDate}) dates) {
//     // String expireDate =
//     //     DateFormat('dd MMM yyyy').format(DateTime.parse(dates.expireDate));
//     // String createdAtDate =
//     //     DateFormat('dd MMM yyyy').format(dates.createdAtDate);

//     return Container(
//       padding: const EdgeInsets.all(24),
//       width: context.isTv ? MediaQuery.of(context).size.width / 2 : null,
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Next payment: $amount',
//                 // style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 style: TextStyles.bodyMediumBold.surface(context).copyWith(
//                       fontSize: 18,
//                     ),
//               ),
//               Text(
//                 '',
//                 style: TextStyles.bodyMediumBold.surface(context).copyWith(
//                       fontSize: 16,
//                     ),
//               ),
//             ],
//           ),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Previous purchase:',
//                 // style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 style: TextStyles.bodyMediumBold.surface(context).copyWith(
//                       fontSize: 18,
//                     ),
//               ),
//               Text(
//                 '',
//                 style: TextStyles.bodyMediumBold.surface(context).copyWith(
//                       fontSize: 16,
//                     ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _subscriptionBasedWidget(
//           BuildContext context, String amount, DateTime purchaseDate) =>
//       InkWell(
//         borderRadius: const BorderRadius.all(Radius.circular(32)),
//         onTap: () {},
//         child: Container(
//           width: context.isTv ? MediaQuery.of(context).size.width / 2 : null,
//           padding: const EdgeInsets.all(24),
//           decoration: BoxDecoration(
//             border: Border.all(color: context.uiColors.success, width: 1),
//             borderRadius: const BorderRadius.all(Radius.circular(32)),
//           ),
//           child: BlocSelector<AppCubit, AppState, bool>(
//             selector: (state) {
//               return state.isSubscribed;
//             },
//             builder: (context, isSubscribed) {
//               return Column(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   context.isTv
//                       ? AppIcon(
//                           width: 32,
//                           height: 32,
//                           Assets.crown,
//                           color: context.uiColors.success,
//                         )
//                       : AppIcon(
//                           Assets.crown,
//                           color: context.uiColors.success,
//                         ),
//                   const SizedBox(height: 16),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         'Subscribed',
//                         style: TextStyles.h5.surface(context),
//                       ),
//                       Text(
//                         '',
//                         style: TextStyles.bodyXLargeMedium.surface(context),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//                   const AppDivider(),
//                   const SizedBox(height: 20),
//                   _Content(
//                       label: 'Watch all you want.', isSubscribed: isSubscribed),
//                   _Content(
//                       label: 'Allow streaming of 4k.',
//                       isSubscribed: isSubscribed),
//                   _Content(
//                       label: 'Video & Audio Quality is Better.',
//                       isSubscribed: isSubscribed),
//                 ],
//               );
//             },
//           ),
//         ),
//       );

//   Widget _subscribeToChannelWidget(BuildContext context) => Column(
//         children: [
//           Image.asset(
//             Assets.pockoLogo,
//             width: double.infinity,
//             height: MediaQuery.sizeOf(context).height * 0.2,
//           ),
//           Text(
//             'Subscribe',
//             style: TextStyles.h4.copyWith(color: context.uiColors.primary),
//           ),
//           Margins.vertical10,
//           Text(
//             'Enjoy watching Full-HD movies, without restriction and  without ads',
//             style: TextStyles.bodyLarge.surface(context),
//             textAlign: TextAlign.center,
//           ),
//           Margins.vertical24,
//           BlocSelector<AppCubit, AppState, bool>(
//             selector: (state) {
//               return state.isSubscribed;
//             },
//             builder: (context, isSubscribed) {
//               return _SubscriptionCard(
//                 price: '14.99',
//                 time: 'month',
//                 isSubscribed: isSubscribed,
//               );
//             },
//           ),
//           Margins.vertical24,
//           InkWell(
//             borderRadius: BorderRadius.circular(35),
//             onTap: () {
//               // context.isTv
//               //     ? context.pushNamed(PaymentPage.path)
//               //     // : showPaymentModal(context, context.read<ProfileCubit>(), context.read<AppCubit>());
//               //     : _getProducts(context);
//               // showPaymentModal();
//               // context.isTv ?  : processPayment();
//             },
//             child: Container(
//               height: 50,
//               width:
//                   context.isTv ? MediaQuery.of(context).size.width / 2 : null,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(35),
//                 color: context.uiColors.primary,
//               ),
//               alignment: Alignment.center,
//               child: Text(
//                 'Purchase Subscription',
//                 style: TextStyles.bodyMediumBold,
//               ),
//             ),
//           ),
//           Margins.vertical24
//         ],
//       );

//   void buildPaymentStatusDialog(bool isSuccuess, String errorMessage) {
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
//     );
//   }

//   void buildSubscriptionCancelDialog(bool isSuccuess, String errorMessage) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AppModal(
//           title: isSuccuess
//               ? 'Congratulations!'
//               : 'Subscription Cancelation Failed.',
//           label: isSuccuess
//               ? 'You have successfully unsubscribed from Pocko premium!'
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
//         context.pop();
//       }
//     });
//   }
// }

// class _SubscriptionCard extends StatelessWidget {
//   const _SubscriptionCard(
//       {required this.price, required this.time, required this.isSubscribed});

//   final String price;
//   final String time;
//   final bool isSubscribed;

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       borderRadius: const BorderRadius.all(Radius.circular(32)),
//       onTap: () {},
//       child: Container(
//         width: context.isTv ? MediaQuery.of(context).size.width / 2 : null,
//         padding: const EdgeInsets.all(24),
//         decoration: BoxDecoration(
//           border: Border.all(color: context.uiColors.primary, width: 1),
//           borderRadius: const BorderRadius.all(Radius.circular(32)),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             context.isTv
//                 ? AppIcon(
//                     width: 32,
//                     height: 32,
//                     Assets.crown,
//                     gradient: context.uiColors.primaryGradient,
//                   )
//                 : AppIcon(
//                     Assets.crown,
//                     gradient: context.uiColors.primaryGradient,
//                   ),
//             const SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   '\$$price',
//                   style: TextStyles.h3.surface(context),
//                 ),
//                 Text(
//                   '/$time',
//                   style: TextStyles.bodyXLargeMedium.surface(context),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             const AppDivider(),
//             const SizedBox(height: 20),
//             _Content(label: 'Watch all you want.', isSubscribed: isSubscribed),
//             _Content(
//                 label: 'Allow streaming of 4k.', isSubscribed: isSubscribed),
//             _Content(
//                 label: 'Video & Audio Quality is Better.',
//                 isSubscribed: isSubscribed),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _Content extends StatelessWidget {
//   const _Content({required this.label, required this.isSubscribed});

//   final String label;
//   final bool isSubscribed;
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         isSubscribed
//             ? AppIcon(Assets.checkmark, color: context.uiColors.success)
//             : AppIcon(Assets.checkmark,
//                 gradient: context.uiColors.primaryGradient),
//         const SizedBox(width: 20),
//         Flexible(
//           child: Text(
//             label,
//             style: TextStyles.bodyLarge.surface(context),
//           ),
//         ),
//       ],
//     );
//   }
// }
