import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/colors.dart';
import 'ai/ask_ai_screen.dart';
import 'home/home_screen.dart';
import 'overlays/delete_confirm_dialog.dart';
import 'overlays/expense_form_screen.dart';
import 'overlays/toast_view.dart';
import 'overlays/transaction_detail_sheet.dart';
import 'transactions/transactions_screen.dart';
import 'widgets/basics.dart';
import 'widgets/bottom_nav.dart';

/// The app frame: background, active tab, floating nav, overlays and toast.
/// Overlays are driven by [AppState] (like the prototype) so the design-state
/// gallery can open them directly.
class RootShell extends StatelessWidget {
  const RootShell({super.key});

  static const _fast = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardOpen = inset > 0;
    final navBottom = ShellMetrics.navBottom(context);

    final hasTx = state.detailTransaction != null;
    final showSheet = hasTx && (state.overlay == OverlayKind.detail || state.overlay == OverlayKind.delete);
    final showDelete = hasTx && state.overlay == OverlayKind.delete;
    final showForm = state.overlay == OverlayKind.form && state.form != null;
    final hideNav = keyboardOpen && state.tab == AppTab.ai;

    final Widget tabBody = switch (state.tab) {
      AppTab.home => const HomeScreen(),
      AppTab.ai => const AskAiScreen(),
      AppTab.transactions => const TransactionsScreen(),
    };

    return PopScope(
      canPop: state.overlay == OverlayKind.none,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) state.handleBack();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              const Positioned.fill(child: _Backdrop()),
              Positioned.fill(
                child: SafeArea(
                  bottom: false,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: KeyedSubtree(key: ValueKey(state.tab), child: tabBody),
                  ),
                ),
              ),
              if (!hideNav)
                Positioned(left: 20, right: 20, bottom: navBottom, child: const BottomNavPill()),

              // Detail sheet: scrim + sheet sliding up from the bottom.
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !showSheet,
                  child: AnimatedOpacity(
                    opacity: showSheet ? 1 : 0,
                    duration: _fast,
                    child: GestureDetector(
                      onTap: state.overlay == OverlayKind.detail ? state.closeOverlay : null,
                      child: const ColoredBox(color: AppColors.sheetScrim),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) => SlideTransition(
                    position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(anim),
                    child: child,
                  ),
                  child: showSheet
                      ? const TransactionDetailSheet(key: ValueKey('sheet'))
                      : const SizedBox.shrink(key: ValueKey('no-sheet')),
                ),
              ),

              // Full-screen expense form.
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(anim),
                      child: child,
                    ),
                  ),
                  layoutBuilder: (current, previous) =>
                      Stack(fit: StackFit.expand, children: [...previous, ?current]),
                  child: showForm
                      ? ExpenseFormScreen(key: ValueKey('form-${state.formSession}'))
                      : const SizedBox.shrink(key: ValueKey('no-form')),
                ),
              ),

              // Delete confirmation (scrim included).
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !showDelete,
                  child: AnimatedSwitcher(
                    duration: _fast,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(scale: Tween(begin: 0.97, end: 1.0).animate(anim), child: child),
                    ),
                    layoutBuilder: (current, previous) =>
                        Stack(fit: StackFit.expand, children: [...previous, ?current]),
                    child: showDelete
                        ? const DeleteConfirmDialog(key: ValueKey('delete'))
                        : const SizedBox.shrink(key: ValueKey('no-delete')),
                  ),
                ),
              ),

              // Toast.
              Positioned(
                left: 20,
                right: 20,
                bottom: keyboardOpen ? inset + 12 : navBottom + 80,
                child: IgnorePointer(
                  child: AnimatedSwitcher(
                    duration: _fast,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(anim),
                        child: child,
                      ),
                    ),
                    child: state.toast == null
                        ? const SizedBox.shrink(key: ValueKey('no-toast'))
                        : ToastView(state.toast!, key: ValueKey(state.toast)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fixed vertical gradient: #D6E8DC at 0 px → #ECF3EE at 200 px → #F4F5F1 at 340 px.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final h = math.max(box.maxHeight, 340.0);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: const [AppColors.bgTop, AppColors.bgMid, AppColors.bgBase],
              stops: [0, 200 / h, 340 / h],
            ),
          ),
        );
      },
    );
  }
}
