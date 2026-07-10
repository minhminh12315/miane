import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../features/subscription/presentation/controllers/pro_upgrade_controller.dart';
import '../theme/app_theme.dart';

Color iosGroupedBackground(BuildContext context) => AppTheme.canvasDark;

Color iosGroupedSurface(BuildContext context) => AppTheme.surfaceDark;

Color iosTertiarySurface(BuildContext context) => AppTheme.surfaceSecondaryDark;

Color iosSeparator(BuildContext context) =>
    CupertinoColors.separator.resolveFrom(context).withValues(alpha: 0.18);

class IosLoading extends StatelessWidget {
  const IosLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CupertinoActivityIndicator(radius: 12));
  }
}

class IosAnimatedEntry extends StatelessWidget {
  final Widget child;
  final double delay;
  final double dy;
  final double scaleBegin;
  final Duration duration;

  const IosAnimatedEntry({
    super.key,
    required this.child,
    this.delay = 0,
    this.dy = 18,
    this.scaleBegin = 0.98,
    this.duration = const Duration(milliseconds: 920),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.linear,
      builder: (context, animation, child) {
        final safeDelay = delay.clamp(0.0, 0.92);
        final raw = ((animation - safeDelay) / (1 - safeDelay)).clamp(0.0, 1.0);
        final progress = Curves.easeOutCubic.transform(raw);

        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, (1 - progress) * dy),
            child: Transform.scale(
              scale: scaleBegin + ((1 - scaleBegin) * progress),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class ModernPage extends StatelessWidget {
  final Widget child;

  const ModernPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppTheme.canvasDark,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF070707),
            AppTheme.canvasDark,
            AppTheme.canvasDark,
          ],
        ),
      ),
      child: child,
    );
  }
}

class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;
  final Color? color;
  final double radius;
  final VoidCallback? onTap;

  const ModernCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.gradient,
    this.color,
    this.radius = AppTheme.radiusLg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppTheme.surfaceDark,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border:
            Border.all(color: CupertinoColors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Padding(padding: padding, child: child),
      ),
    );

    if (onTap == null) return content;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: content,
    );
  }
}

class ModernGlass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const ModernGlass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.radius = AppTheme.radiusLg,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppTheme.surfaceSecondaryDark.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
                color: CupertinoColors.white.withValues(alpha: 0.12)),
          ),
          child: child,
        ),
      ),
    );
  }
}

Future<T?> showGlassBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double heightFactor = 0.88,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    barrierDismissible: true,
    filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
    builder: (context) {
      return _GlassBottomSheetRoute<T>(
        heightFactor: heightFactor,
        child: builder(context),
      );
    },
  );
}

class GlassBottomSheetScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const GlassBottomSheetScaffold({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 44,
          height: 5,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey.resolveFrom(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.headlineMd(),
                ),
              ),
              if (trailing != null) ...[
                trailing!,
                const SizedBox(width: 6),
              ],
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(42, 42),
                onPressed: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey4
                        .resolveFrom(context)
                        .withValues(alpha: 0.32),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.xmark,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _GlassBottomSheetRoute<T> extends StatefulWidget {
  final Widget child;
  final double heightFactor;

  const _GlassBottomSheetRoute({
    required this.child,
    required this.heightFactor,
  });

  @override
  State<_GlassBottomSheetRoute<T>> createState() =>
      _GlassBottomSheetRouteState<T>();
}

class _GlassBottomSheetRouteState<T> extends State<_GlassBottomSheetRoute<T>> {
  double _dragOffset = 0;

  void _handleDragEnd(DragEndDetails details) {
    if (_dragOffset > 90 ||
        details.primaryVelocity != null && details.primaryVelocity! > 700) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _dragOffset = 0);
  }

  @override
  Widget build(BuildContext context) {
    final heightFactor = widget.heightFactor.clamp(0.5, 0.94);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black.withValues(alpha: 0.24),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1, end: 0),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutBack,
            builder: (context, animation, child) {
              return Transform.translate(
                offset: Offset(0, animation * 320 + _dragOffset),
                child: child,
              );
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta == null) return;
                setState(() {
                  _dragOffset =
                      (_dragOffset + details.primaryDelta!).clamp(0.0, 260.0);
                });
              },
              onVerticalDragEnd: _handleDragEnd,
              child: FractionallySizedBox(
                heightFactor: heightFactor,
                widthFactor: 1,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(36),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark.withValues(alpha: 0.82),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(36),
                        ),
                        border: Border(
                          top: BorderSide(
                            color:
                                CupertinoColors.white.withValues(alpha: 0.16),
                            width: 0.8,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                CupertinoColors.black.withValues(alpha: 0.55),
                            blurRadius: 34,
                            offset: const Offset(0, -14),
                          ),
                        ],
                      ),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ModernActionCircle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const ModernActionCircle({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.28)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.labelSm(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}

class ModernBottomNavItem {
  final IconData icon;
  final String label;

  const ModernBottomNavItem({required this.icon, required this.label});
}

class ModernBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<ModernBottomNavItem> items;
  final ValueChanged<int> onTap;
  final int? prominentIndex;

  const ModernBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.prominentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final prominent = prominentIndex;
    final visibleItems = [
      for (var i = 0; i < items.length; i++)
        if (i != prominent) _ModernNavEntry(index: i, item: items[i]),
    ];
    final prominentItem =
        prominent != null && prominent >= 0 && prominent < items.length
            ? items[prominent]
            : null;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _LiquidGlassShell(
                radius: 30,
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
                child: Row(
                  children: [
                    for (final entry in visibleItems)
                      Expanded(
                        child: _ModernBottomNavButton(
                          index: entry.index,
                          item: entry.item,
                          selected: entry.index == currentIndex,
                          onTap: onTap,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (prominentItem != null) ...[
              const SizedBox(width: 12),
              _ProminentSearchNavButton(
                index: prominent!,
                item: prominentItem,
                selected: prominent == currentIndex,
                onTap: onTap,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModernNavEntry {
  final int index;
  final ModernBottomNavItem item;

  const _ModernNavEntry({required this.index, required this.item});
}

class _LiquidGlassShell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const _LiquidGlassShell({
    required this.child,
    required this.padding,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6
                .resolveFrom(context)
                .withValues(alpha: 0.20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                CupertinoColors.white.withValues(alpha: 0.28),
                AppTheme.surfaceSecondaryDark.withValues(alpha: 0.62),
                AppTheme.surfaceDark.withValues(alpha: 0.76),
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: CupertinoColors.white.withValues(alpha: 0.18),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.32),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: AppTheme.iosBlue.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ModernBottomNavButton extends StatelessWidget {
  final int index;
  final ModernBottomNavItem item;
  final bool selected;
  final ValueChanged<int> onTap;

  const _ModernBottomNavButton({
    required this.index,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactive = CupertinoColors.secondaryLabel.resolveFrom(context);
    final color = selected ? AppTheme.iosBlue : inactive;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(54, 58),
      onPressed: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        height: 58,
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.iosBlue.withValues(alpha: 0.18)
              : CupertinoColors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: selected
              ? Border.all(
                  color: AppTheme.iosBlue.withValues(alpha: 0.24),
                  width: 0.8,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.08 : 1,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: Icon(item.icon, color: color, size: selected ? 25 : 22),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.labelXs(color: color).copyWith(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProminentSearchNavButton extends StatelessWidget {
  final int index;
  final ModernBottomNavItem item;
  final bool selected;
  final ValueChanged<int> onTap;

  const _ProminentSearchNavButton({
    required this.index,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(66, 66),
      onPressed: () => onTap(index),
      child: AnimatedScale(
        scale: selected ? 1.06 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: _LiquidGlassShell(
          radius: 33,
          padding: EdgeInsets.zero,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? AppTheme.iosBlue.withValues(alpha: 0.28)
                  : CupertinoColors.white.withValues(alpha: 0.08),
              gradient: selected
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF9FDAFF),
                        Color(0xFF5EA8FF),
                        AppTheme.iosBlue,
                      ],
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.iosBlue.withValues(
                    alpha: selected ? 0.38 : 0.16,
                  ),
                  blurRadius: selected ? 30 : 18,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(
              item.icon,
              color: selected ? CupertinoColors.white : AppTheme.iosBlue,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}

class IosEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;

  const IosEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = CupertinoColors.secondaryLabel.resolveFrom(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.surfaceSecondaryDark,
                shape: BoxShape.circle,
                border: Border.all(
                    color: CupertinoColors.white.withValues(alpha: 0.08)),
              ),
              child: Icon(icon, color: textColor, size: 34),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTheme.titleSm(
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTheme.bodySm(color: textColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class IosSection extends StatelessWidget {
  final String? header;
  final String? footer;
  final List<Widget> children;

  const IosSection({
    super.key,
    this.header,
    this.footer,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                header!,
                style: AppTheme.labelSm(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
          ModernCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i != children.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 58),
                      child:
                          Container(height: 0.5, color: iosSeparator(context)),
                    ),
                ],
              ],
            ),
          ),
          if (footer != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Text(
                footer!,
                style: AppTheme.labelSm(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class IosListTile extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  const IosListTile({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final color = destructive ? AppTheme.iosRed : label;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: CupertinoColors.transparent,
        child: Row(
          children: [
            if (icon != null) ...[
              _IosIconBox(icon: icon!, color: iconColor ?? AppTheme.iosBlue),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyMd(color: color).copyWith(
                      fontWeight:
                          destructive ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodySm(color: secondary),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTheme.bodySm(color: secondary),
                ),
              ),
            ],
            if (trailing != null) ...[
              const SizedBox(width: 10),
              trailing!,
            ] else if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(CupertinoIcons.chevron_right, color: secondary, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _IosIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IosIconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 19),
    );
  }
}

class IosPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const IosPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton.filled(
        minimumSize: const Size(50, 52),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const CupertinoActivityIndicator(color: CupertinoColors.white)
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class IosSecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  const IosSecondaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        minimumSize: const Size(50, 52),
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: AppTheme.iosBlue),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IosTextField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final String? label;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const IosTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.label,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTheme.labelSm(color: secondary)),
          const SizedBox(height: 8),
        ],
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          prefix: prefixIcon == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(prefixIcon, color: AppTheme.iosBlue, size: 18),
                ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          clearButtonMode: OverlayVisibilityMode.editing,
          onChanged: onChanged,
          decoration: BoxDecoration(
            color: AppTheme.surfaceSecondaryDark,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
                color: CupertinoColors.white.withValues(alpha: 0.08)),
          ),
        ),
      ],
    );
  }
}

Future<void> showIosMessage(
  BuildContext context, {
  String title = 'Thông báo',
  required String message,
  bool isError = false,
}) {
  return showCupertinoDialog<void>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(isError ? 'Có lỗi xảy ra' : title),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(message),
      ),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<bool> showIosConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Đồng ý',
  bool destructive = false,
}) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(title),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(message),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Hủy'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: destructive,
          isDefaultAction: !destructive,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<void> showIosProSheet(
  BuildContext context, {
  String featureName = 'MIANE Pro',
}) {
  return showCupertinoModalPopup<void>(
    context: context,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(proUpgradeControllerProvider);
        final isPurchasing = state.status == ProUpgradeStatus.purchasing;

        ref.listen(proUpgradeControllerProvider, (previous, next) {
          if (next.status == ProUpgradeStatus.success) {
            ref.read(proUpgradeControllerProvider.notifier).reset();
            Navigator.of(sheetContext).pop();
            showIosMessage(context, message: 'Chào mừng bạn đến với MIANE Pro!');
          }
        });

        return CupertinoActionSheet(
          title: const Text('Mở khóa MIANE Pro'),
          message: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tính năng "$featureName" thuộc gói Pro: không giới hạn chuyến đi, thành viên, đa tiền tệ, AI OCR và trợ lý lịch trình.',
              ),
              if (state.status == ProUpgradeStatus.error && state.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.errorMessage!,
                  style: const TextStyle(color: CupertinoColors.systemRed),
                ),
              ],
            ],
          ),
          actions: [
            CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: isPurchasing
                  ? () {}
                  : () => ref.read(proUpgradeControllerProvider.notifier).purchasePro(),
              child: isPurchasing
                  ? const CupertinoActivityIndicator()
                  : const Text('Nâng cấp 99.000 đ / tháng'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: const Text('Để sau'),
          ),
        );
      },
    ),
  );
}

String formatMoney(double amount) {
  final roundedAmount = amount.round();
  final isNegative = roundedAmount < 0;
  final value = roundedAmount.abs().toString();
  final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
  final formatted = value.replaceAllMapped(reg, (match) => '${match[1]}.');
  return isNegative ? '-$formatted' : formatted;
}

double? parseMoneyInput(String input) {
  final digitsOnly = input.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitsOnly.isEmpty) return null;
  return double.tryParse(digitsOnly);
}

class MoneyInputFormatter extends TextInputFormatter {
  const MoneyInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return TextEditingValue.empty;

    final formatted = formatMoney(double.parse(digitsOnly));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
