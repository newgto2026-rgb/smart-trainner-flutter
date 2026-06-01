import 'package:flutter/material.dart';
import 'package:smart_trainner_core_designsystem/smart_trainner_core_designsystem.dart';

class SmartTrainnerScreenChrome {
  const SmartTrainnerScreenChrome({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}

class SmartTrainnerScreenScaffold extends StatelessWidget {
  const SmartTrainnerScreenScaffold({
    required this.chrome,
    required this.children,
    super.key,
  });

  final SmartTrainnerScreenChrome chrome;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final view = View.of(context);
    final safeTop = view.padding.top / view.devicePixelRatio;
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: SmartTrainnerGradients.screen),
      child: ListView(
        padding: EdgeInsets.fromLTRB(18, 14 + safeTop, 18, 24),
        children: <Widget>[
          _SmartTrainnerScreenHeader(chrome: chrome),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _SmartTrainnerScreenHeader extends StatelessWidget {
  const _SmartTrainnerScreenHeader({required this.chrome});

  final SmartTrainnerScreenChrome chrome;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: SmartTrainnerGradients.brandLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                chrome.title,
                key: const Key('training_app_title'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: SmartTrainnerColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                chrome.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: SmartTrainnerColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SmartTrainnerSurface extends StatelessWidget {
  const SmartTrainnerSurface({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SmartTrainnerColors.surfaceRaised,
        border: Border.all(color: SmartTrainnerColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

class SmartTrainnerSectionTitle extends StatelessWidget {
  const SmartTrainnerSectionTitle({
    required this.text,
    this.keyName,
    super.key,
  });

  final String text;
  final String? keyName;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      key: keyName == null ? null : Key(keyName!),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: SmartTrainnerColors.ink,
      ),
    );
  }
}

class SmartTrainnerEmptyState extends StatelessWidget {
  const SmartTrainnerEmptyState({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SmartTrainnerSurface(
      child: Text(
        text,
        style: const TextStyle(color: SmartTrainnerColors.muted),
      ),
    );
  }
}

class SmartTrainnerBadge extends StatelessWidget {
  const SmartTrainnerBadge({
    required this.text,
    this.icon,
    this.containerColor = SmartTrainnerColors.steelSoft,
    this.contentColor = SmartTrainnerColors.ink,
    this.borderColor,
    super.key,
  });

  final String text;
  final IconData? icon;
  final Color containerColor;
  final Color contentColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(8),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 16, color: contentColor),
              const SizedBox(width: 5),
            ],
            Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: contentColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SmartTrainnerProgressBar extends StatelessWidget {
  const SmartTrainnerProgressBar({
    required this.progress,
    this.color = SmartTrainnerColors.green,
    this.trackColor = SmartTrainnerColors.line,
    super.key,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 8,
        child: LinearProgressIndicator(
          value: value,
          backgroundColor: trackColor,
          color: color,
        ),
      ),
    );
  }
}
