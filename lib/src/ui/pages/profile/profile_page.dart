// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:commons/commons.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// import 'package:ui_kit/ui_kit.dart';
// import 'package:ui_kit/widgets/app_modal.dart';
// import 'package:fndtv/src/index.dart';

// class ProfilePage extends StatelessWidget {
//   const ProfilePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return RefreshIndicator.adaptive(
//       onRefresh: () {
//         context.read<AppCubit>().initUser();
//         return Future.value();
//       },
//       child: BlocBuilder<AppCubit, AppState>(
//         bloc: context.read<AppCubit>()..initUser(),
//         buildWhen: (previous, current) =>
//             previous.userInitStatus != current.userInitStatus,
//         builder: (context, state) {
//           return AppStatusWidget(
//             status: state.userInitStatus,
//             loaderWidget: const Center(child: AppLoadingIndicator(size: 70)),
//             errorWidget: Center(
//               child: Text(state.userInfoError ?? 'An error occurred'),
//             ),
//             widget: const _Body(),
//           );
//         },
//       ),
//     );
//   }
// }

// class _Body extends StatefulWidget {
//   const _Body();

//   @override
//   State<_Body> createState() => _BodyState();
// }

// class _BodyState extends State<_Body> {
//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<AppCubit, AppState>(
//       builder: (context, state) {
//         final bool isAuthenticated = state.isAuthenticated;
//         return CustomScrollView(
//           slivers: [
//             SliverPadding(
//               padding: const EdgeInsets.symmetric(horizontal: 24),
//               sliver: SliverList(
//                 delegate: SliverChildListDelegate([
//                   if (isAuthenticated)
//                     DeviceWrapper(
//                       widget: Column(
//                         children: [_UserInfoRow(profileInfo: state.userInfo)],
//                       ),
//                       tvWidget: const SizedBox.shrink(),
//                     ),
//                   const SizedBox(height: 24),
//                   _ButtonList(isAuthenticated: isAuthenticated),
//                   const SizedBox(height: 124),
//                 ]),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

// class _ButtonList extends StatefulWidget {
//   const _ButtonList({required this.isAuthenticated});
//   final bool isAuthenticated;

//   @override
//   State<_ButtonList> createState() => _ButtonListState();
// }

// class _ButtonListState extends State<_ButtonList> {
//   void _showDeleteAccountDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => AppModal(
//         title: 'Are you sure you want to delete the account?',
//         label: '',
//         icon: Assets.deleteFilter,
//         imageColor: context.uiColors.primary,
//         children: [
//           AppButton.secondary(
//             label: 'Cancel',
//             onPressed: () => context.pop(),
//           ),
//           const SizedBox(width: 10),
//           AppButton.primary(
//             label: 'Confirm',
//             onPressed: () {
//               context.read<AppCubit>().onLogout();
//               context.pop();
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   final List<FocusNode> focusNodes = List.generate(1, (index) => FocusNode());
//   @override
//   void initState() {
//     focusNodes.first.requestFocus();
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final Iterable<_ButtonData> categories = [
//       if (!widget.isAuthenticated)
//         _ButtonData(
//           icon: Assets.videoLock,
//           label: 'Log In',
//           onPressed: () => context.pushNamed(LoginPage.path),
//         ),

//       // _ButtonData(
//       //   icon: Assets.infoSquare,
//       //   label: 'About Us',
//       //   onPressed: () => context.pushNamed(TermsOfUsePage.path),
//       // ),
//     ];

//     return Column(
//       children: [
//         if (!widget.isAuthenticated)
//           TextButton(
//             onPressed: () {
//               context.pushNamed(LoginPage.path);
//             },
//             style:
//                 TextButton.styleFrom(foregroundColor: context.uiColors.primary),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 AppIcon(
//                   Assets.videoLock,
//                   height: 32,
//                   width: 32,
//                   color: context.uiColors.primary,
//                 ),
//                 Margins.horizontal20,
//                 Text(
//                   'Log In',
//                   style: TextStyles.bodyXLargeSemiBold.copyWith(
//                     fontSize: 24,
//                     color: context.uiColors.primary,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         const SizedBox(height: 24),
//         if (widget.isAuthenticated)
//           BlocProvider.value(
//             value: context.read<AppCubit>(),
//             child: const _LogoutButton(),
//           ),
//       ],
//     );
//   }
// }

// class _LogoutButton extends StatefulWidget {
//   const _LogoutButton();

//   @override
//   State<_LogoutButton> createState() => _LogoutButtonState();
// }

// class _LogoutButtonState extends State<_LogoutButton> {
//   late final FocusNode focusNode;

//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return TextButton(
//       // focusNode: focusNode,
//       onPressed: () {
//         final AppCubit cubit = context.read<AppCubit>();
//         _showLogoutModal(context, cubit);
//       },
//       style: TextButton.styleFrom(foregroundColor: context.uiColors.primary),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           AppIcon(
//             Assets.logoutOutlined,
//             height: 32,
//             width: 32,
//             color: context.uiColors.error,
//           ),
//           Margins.horizontal20,
//           Text(
//             'Logout',
//             style: TextStyles.bodyXLargeSemiBold.copyWith(
//               fontSize: 24,
//               color: context.uiColors.error,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _showLogoutModal(BuildContext context, AppCubit cubit) {
//     final FocusNode cancelFocusNode = FocusNode()..requestFocus();
//     return showModalBottomSheet<void>(
//       context: context,
//       builder: (BuildContext context) {
//         return AppBottomSheetModal(
//           label: 'Are you sure you want to',
//           title: 'Logout',
//           titleColor: context.uiColors.error,
//           children: [
//             AppButton.secondaryRounded(
//               label: 'Cancel',
//               focusNode: cancelFocusNode,
//               onPressed: () {
//                 context.pop();
//               },
//             ),
//             AppButton.primaryRounded(
//               label: 'Yes, Log out',
//               onPressed: () {
//                 context.read<AppCubit>().onLogout();

//                 cubit.initUser();
//                 context.pop();
//                 // context.pushReplacementNamed(LoginPage.path);
//               },
//             ),
//           ],
//         );
//       },
//     ).then((value) {
//       // context.pop();
//     });
//   }
// }

// class _UserInfoRow extends StatelessWidget {
//   const _UserInfoRow({required this.profileInfo});

//   final ProfileModel? profileInfo;

//   @override
//   Widget build(BuildContext context) {
//     if (profileInfo == null) {
//       return const SizedBox.shrink();
//     }

//     final Widget img = profileInfo!.imgName.isEmpty
//         ? Image.asset(Assets.defaultAvatar, fit: BoxFit.cover)
//         : CachedNetworkImage(
//             imageUrl: APIList.storage(profileInfo!.imgName),
//             fit: BoxFit.cover,
//           );

//     return Row(
//       children: [
//         CircleAvatar(
//           radius: 50,
//           backgroundColor: Colors.transparent,
//           child: ClipRRect(
//             borderRadius: const BorderRadius.all(Radius.circular(100)),
//             child: img,
//           ),
//         ),
//         Margins.horizontal20,
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               '${profileInfo!.name} ${profileInfo!.lastName}',
//               style: TextStyles.h5.surface(context),
//             ),
//             Text(
//               profileInfo!.email,
//               style: TextStyles.bodyMediumMedium.surface(context),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }

// class _Category extends StatelessWidget {
//   const _Category({
//     required this.leadingIcon,
//     required this.label,
//     required this.action,
//     required this.onPressed,
//     this.isAuthenticated,
//     required this.focusNode,
//   });

//   final String leadingIcon;
//   final String label;
//   final Widget action;
//   final bool? isAuthenticated;
//   final Function(BuildContext context) onPressed;
//   final FocusNode focusNode;

//   @override
//   Widget build(BuildContext context) {
//     const RoundedRectangleBorder customBorder = RoundedRectangleBorder(
//       borderRadius: BorderRadius.all(Radius.circular(12)),
//     );
//     return InkWell(
//       focusNode: focusNode,
//       customBorder: customBorder,
//       onTap: () {
//         if (isAuthenticated != null) {
//           if (isAuthenticated == true) {
//             onPressed(context);
//             return;
//           } else {
//             return;
//           }
//         } else {
//           onPressed(context);
//           return;
//         }
//       },
//       child: Padding(
//         padding: const EdgeInsets.all(4.0),
//         child: Row(
//           children: [
//             AppIcon(
//               leadingIcon,
//               height: 35,
//               width: 35,
//               color: context.uiColors.onSurface.withOpacity(
//                 isAuthenticated != null && isAuthenticated == false ? 0.3 : 1.0,
//               ),
//             ),
//             Margins.horizontal20,
//             Text(
//               label,
//               style: TextStyles.bodyXLargeSemiBold.surface(context).copyWith(
//                     fontSize: 24,
//                     color: context.uiColors.onSurface.withOpacity(
//                       isAuthenticated != null && isAuthenticated == false
//                           ? 0.3
//                           : 1.0,
//                     ),
//                   ),
//             ),
//             const Spacer(),
//             action,
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _Icon extends StatelessWidget {
//   const _Icon();

//   @override
//   Widget build(BuildContext context) {
//     return AppIcon(
//       width: 24,
//       height: 24,
//       Assets.singleArrowRight,
//       color: context.uiColors.onSurface,
//       fit: BoxFit.cover,
//     );
//   }
// }

// class _ButtonData {
//   final String icon;
//   final String label;
//   final VoidCallback onPressed;
//   final bool? isClickable;

//   _ButtonData({
//     required this.icon,
//     required this.label,
//     required this.onPressed,
//     this.isClickable = true,
//   });
// }
