import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/index.dart';

import 'package:ui_kit/ui_kit.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.pageTitle,
    required this.child,
    required this.submitWidget,
    required this.authActionWidget,
    this.forgotPasswordWidget,
  });

  /// Title : Welcome!
  final String pageTitle;

  /// ON LOGIN/CONTINUE PRESS
  final Widget child;

  final ({String label, VoidCallback onPressed}) submitWidget;

  final Widget? forgotPasswordWidget;

  final Widget authActionWidget;

  @override
  Widget build(BuildContext context) {
    const EdgeInsets pagePadding = EdgeInsets.fromLTRB(15, 0, 15, 0);

    return UiOverlayProvider(
      child: OverlayStack(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: context.uiColors.surface,
          body: SafeArea(
            child: Padding(
              padding: pagePadding,
              child: _Body(
                title: pageTitle,
                submitWidget: submitWidget,
                authActionWidget: authActionWidget,
                forgotPasswordWidget: forgotPasswordWidget,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({
    this.forgotPasswordWidget,
    required this.title,
    required this.child,
    required this.submitWidget,
    required this.authActionWidget,
  });

  final String title;

  final Widget child;

  final ({String label, VoidCallback onPressed}) submitWidget;

  final Widget authActionWidget;
  final Widget? forgotPasswordWidget;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          fillOverscroll: false,
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 10),
              _PageHeader(title: widget.title),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                child: Builder(
                  builder: (context) {
                    final bool isInitialized = context.select<AppCubit, bool>(
                      (cubit) => cubit.state.isInitialized,
                    );

                    return LoadingWidget(
                      status: isInitialized ? Status.success : Status.loading,
                      loader: const Shimmer(
                        child: ShimmerLoading(
                          isLoading: true,
                          child: Skeleton(
                            width: double.infinity,
                            height: 48,
                            radius: 12,
                          ),
                        ),
                      ),
                      child: widget.child,
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: AppButton.primaryRounded(
                  onPressed: widget.submitWidget.onPressed,
                  label: widget.submitWidget.label,
                ),
              ),
              // if (widget.forgotPasswordWidget != null) widget.forgotPasswordWidget!,
              const SizedBox(height: 20),
              widget.authActionWidget,
            ],
          ),
        ),
        const SliverToBoxAdapter(child: Margins.vertical48),
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title});

  final String title;
  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      Image.asset(
        Assets.logo,
        fit: BoxFit.cover,
        height: context.isTv ? 100 : 170,
      ),

      Text(
        title,
        style: TextStyles.h3.surface(context),
        textAlign: TextAlign.center,
      ),
      // const HeaderDivider(),
    ];

    return context.isTv
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: children.reversed.toList(),
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: children,
          );
  }
}
