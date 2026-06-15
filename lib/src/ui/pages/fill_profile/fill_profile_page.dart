// import 'dart:io';

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:commons/commons.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_cache_manager/flutter_cache_manager.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:fndtv/src/index.dart';

// import 'package:ui_kit/ui_kit.dart';

// class FillProfilePage extends StatelessWidget {
//   const FillProfilePage({super.key});

//   static const path = 'profile-page';
//   static const name = 'profile-page';

//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<ProfileCubit, ProfileState>(
//       listenWhen: (previous, current) => previous.status != current.status,
//       listener: (context, state) {
//         _listener(context, state);
//       },
//       child: AppScaffold(
//         hasNavbar: false,
//         body: CustomScrollView(
//           slivers: [
//             PageHeader(
//               isTv: context.isTv,
//               onPressed: () {
//                 context.pop();
//               },
//               isMainPage: false,
//               page: 'Fill profile',
//             ),
//             const SliverPadding(
//               padding: EdgeInsets.symmetric(horizontal: 16),
//               sliver: SliverList(
//                 delegate: SliverChildListDelegate.fixed([
//                   _Form(),
//                   Margins.vertical16,
//                 ]),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _listener(BuildContext ctx, ProfileState state) {
//     final NotificationBannerCubit cubit = ctx.read<NotificationBannerCubit>();

//     switch (state.status) {
//       case FormStatus.inProgress:
//         ctx.read<AppCubit>().showOverlay();
//       case FormStatus.success:
//         ctx.read<AppCubit>().hideOverlay();

//         cubit.showNotification(
//           NotificationType.success,
//           'Profile updated successfully',
//         );

//       case FormStatus.failure:
//         ctx.read<AppCubit>().hideOverlay();

//         cubit.showNotification(NotificationType.error, _getError(ctx, state));

//       default:
//         null;
//     }
//   }

//   String _getError(BuildContext context, ProfileState state) {
//     return state.hasFormError ? state.formError! : 'Try again later';
//   }
// }

// class _Form extends StatelessWidget {
//   const _Form();

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         const _ProfileAvatar(),
//         Margins.vertical16,
//         BlocSelector<ProfileCubit, ProfileState,
//             ({InputModel inputModel, ProfileModel? profileInfo})>(
//           selector: (s) {
//             return (
//               inputModel: s.name,
//               profileInfo: context.read<AppCubit>().state.userInfo,
//             );
//           },
//           builder: (context, state) {
//             return AppInput.text(
//               isDeviceTv: false,
//               hintText: 'Enter your name',
//               onChanged: context.read<ProfileCubit>().onNameChanged,
//               prefixIcon: Assets.profile,
//               textInputAction: TextInputAction.next,
//               value: state.inputModel.value ?? state.profileInfo?.name,
//               fieldError: state.inputModel.error,
//             );
//           },
//         ),
//         Margins.vertical16,
//         BlocSelector<ProfileCubit, ProfileState,
//             ({InputModel inputModel, ProfileModel? profileInfo})>(
//           selector: (s) {
//             return (
//               inputModel: s.lastName,
//               profileInfo: context.read<AppCubit>().state.userInfo,
//             );
//           },
//           builder: (context, state) {
//             return AppInput.text(
//               isDeviceTv: false,
//               hintText: 'Enter your last name',
//               onChanged: context.read<ProfileCubit>().onLastNameChanged,
//               prefixIcon: Assets.profile,
//               textInputAction: TextInputAction.next,
//               value: state.inputModel.value ?? state.profileInfo?.lastName,
//               fieldError: state.inputModel.error,
//             );
//           },
//         ),
//         Margins.vertical16,
//         BlocSelector<ProfileCubit, ProfileState,
//             ({InputModel inputModel, ProfileModel? profileInfo})>(
//           selector: (s) {
//             return (
//               inputModel: s.phoneNumber,
//               profileInfo: context.read<AppCubit>().state.userInfo,
//             );
//           },
//           builder: (context, state) {
//             return AppInput.phone(
//               isDeviceTv: false,
//               hintText: 'Phone number',
//               onChanged: context.read<ProfileCubit>().onPhoneNumberChanged,
//               prefixIcon: Assets.whatsApp,
//               value: state.inputModel.value ?? state.profileInfo?.phoneNumber,
//               textInputAction: TextInputAction.next,
//               fieldError: state.inputModel.error,
//             );
//           },
//         ),
//         Margins.vertical16,
//         BlocBuilder<ProfileCubit, ProfileState>(
//           builder: (context, state) {
//             return AppButton.primary(
//               label: 'Submit',
//               onPressed: () => _onSubmit(context),
//             );
//           },
//         ),
//       ],
//     );
//   }
// }

// class _ProfileAvatar extends StatefulWidget {
//   const _ProfileAvatar();

//   @override
//   State<_ProfileAvatar> createState() => _ProfileAvatarState();
// }

// class _ProfileAvatarState extends State<_ProfileAvatar> {
//   final ImagePicker _picker = ImagePicker();

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       alignment: Alignment.center,
//       children: [
//         Material(
//           color: Colors.transparent,
//           shape: const CircleBorder(),
//           child: InkWell(
//             borderRadius: const BorderRadius.all(Radius.circular(100)),
//             splashColor: context.uiColors.primary.withOpacity(0.1),
//             onTap: () => _openImagePicker(context),
//             child: BlocSelector<ProfileCubit, ProfileState, String>(
//               selector: (state) {
//                 if (state.file != null && state.file!.isNotEmpty) {
//                   return state.file!;
//                 }

//                 return context.read<AppCubit>().state.userInfo?.imgName ?? '';
//               },
//               builder: (context, filePath) {
//                 return Ink(
//                   height: 100,
//                   width: 100,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     image: DecorationImage(image: _getImage(filePath)),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ),
//         Positioned(
//           bottom: 0,
//           right: 0,
//           left: 60,
//           top: 70,
//           child: GestureDetector(
//             onTap: () => _openImagePicker(context),
//             child: AppIcon(
//               Assets.editSquare,
//               color: context.uiColors.primary,
//               height: 24,
//               width: 24,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   ImageProvider _getImage(String path) {
//     if (path.isEmpty) {
//       return const AssetImage(Assets.defaultAvatar);
//     }

//     if (path.contains('.webp')) {
//       return CachedNetworkImageProvider(APIList.storage(path));
//     }

//     return FileImage(File(path));
//   }

//   void _openImagePicker(BuildContext context) async {
//     final XFile? pickedImage = await _picker.pickImage(
//       source: ImageSource.gallery,
//       imageQuality: 80,
//       maxWidth: 300,
//       maxHeight: 300,
//     );

//     if (pickedImage == null) return;

//     if (!context.mounted) return;

//     context.read<ProfileCubit>().onFileChanged(pickedImage.path);
//   }
// }

// // This Function is library scoped for both widgets
// void _onSubmit(BuildContext context) async {
//   final DefaultCacheManager cache = DefaultCacheManager();

//   final ProfileState state = context.read<ProfileCubit>().state;

//   final bool isFileNotPicked =
//       state.file == null || (state.file?.isEmpty ?? true);

//   String imgName = context.read<AppCubit>().state.userInfo?.imgName ?? '';

//   if (imgName.isNotEmpty && isFileNotPicked) {
//     imgName = (await cache.getSingleFile(APIList.storage(imgName))).path;

//     if (!context.mounted) return;

//     context.read<ProfileCubit>().onFileChanged(imgName);
//   }

//   context.read<ProfileCubit>().onSubmit();

//   context.read<AppCubit>().initUser();
// }
