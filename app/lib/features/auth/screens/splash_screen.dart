import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../core/theme/app_theme.dart';

const double _logoLaunchSize = 192.0;

const double _logoSize = 120.0;

/// How much larger the logo starts than it ends.
const double _launchScale = _logoLaunchSize / _logoSize;

const double _lottieCircleFraction = 0.92 * 0.995;

final ImageProvider _splashLogo = ResizeImage(
  const AssetImage('assets/images/logo.png'),
  width: 768,
);

/// The splash animation, once [precacheSplashLogo] has read it. Null means the
/// asset was missing or unparseable and the splash should use the still logo.
LottieComposition? _splashAnimation;

Future<void> precacheSplashLogo() async {
  // Never let a stalled load hold up app startup indefinitely.
  await _loadAnimation().timeout(const Duration(seconds: 4), onTimeout: () {});
  if (_splashAnimation == null) {
    await _decodeLogo().timeout(const Duration(seconds: 2), onTimeout: () {});
  }
}

Future<void> _decodeLogo() {
  final completer = Completer<void>();
  final stream = _splashLogo.resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;

  void finish() {
    if (!completer.isCompleted) completer.complete();
    stream.removeListener(listener);
  }

  listener = ImageStreamListener(
    (_, _) => finish(),
    onError: (_, _) => finish(),
  );
  stream.addListener(listener);
  return completer.future;
}

Future<void> _loadAnimation() async {
  try {
    _splashAnimation = await AssetLottie(
      'assets/animations/splash_dots.json',
    ).load();
  } catch (error, stack) {
    debugPrint('Splash animation unavailable, using the still logo: $error');
    debugPrintStack(stackTrace: stack);
  }
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Eased sub-interval of [t]: 0 before [begin], 1 after [end].
double _phase(
  double t,
  double begin,
  double end, [
  Curve curve = Curves.linear,
]) {
  if (t <= begin) return 0;
  if (t >= end) return 1;
  return curve.transform((t - begin) / (end - begin));
}

double _settleScale(double t) {
  if (t < 0.58) {
    return _lerp(_launchScale, 0.92, _phase(t, 0.0, 0.58, Curves.easeOutCubic));
  }
  return _lerp(0.92, 1.0, _phase(t, 0.58, 0.86, Curves.easeOutCubic));
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.ready = false, this.onRevealComplete});

  final bool ready;

  /// Called once the reveal has finished and nothing of the splash is left
  /// covering the content underneath.
  final VoidCallback? onRevealComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  /// The logo's settle from launch size to resting size.
  late final AnimationController _intro;

  /// The exit reveal.
  late final AnimationController _reveal;

  /// Drives [_splashAnimation] across its three marked acts. Idle when the
  /// animation could not be loaded and the still logo is standing in.
  late final AnimationController _anim;

  /// Normalised bounds of the animation's loop act, from its Lottie markers.
  double _loopStart = 0;
  double _loopEnd = 1;

  /// Set the moment the exit is committed to, so the loop stops re-arming.
  bool _exiting = false;

  @override
  void initState() {
    super.initState();

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    );
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );

    _intro.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      // `ready` may well have arrived while the entrance was still playing; this
      // is the earliest point at which we're willing to act on it.
      _maybeReveal();
    });

    _reveal.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onRevealComplete?.call();
    });

    final animation = _splashAnimation;
    _anim = AnimationController(vsync: this, duration: animation?.duration);
    if (animation != null) {
      final loop = animation.markers
          .where((m) => m.matchesName('loop'))
          .firstOrNull;
      if (loop != null) {
        _loopStart = loop.start;
        _loopEnd = loop.end;
      }
      // Play the entrance and the first typing cycle straight through, then hold
      // on the loop for as long as the app takes to boot.
      _anim.animateTo(_loopEnd, duration: animation.duration * _loopEnd).then((
        _,
      ) {
        if (mounted && !_exiting) {
          _anim.repeat(
            min: _loopStart,
            max: _loopEnd,
            period: animation.duration * (_loopEnd - _loopStart),
          );
        }
      });
    }

    _intro.forward();
  }

  @override
  void didUpdateWidget(SplashScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ready && !oldWidget.ready) _maybeReveal();
  }

  /// Begins the exit if the app is booted *and* the entrance has played out.
  void _maybeReveal() {
    if (!widget.ready) return;
    if (!_intro.isCompleted) return;
    if (_exiting) return;
    _exiting = true;
    _finishAnimationThenReveal();
  }

  Future<void> _finishAnimationThenReveal() async {
    final animation = _splashAnimation;
    if (animation != null && _anim.value < 1.0) {
      _anim.stop();
      if (_anim.value < _loopEnd) {
        final rest = animation.duration * (_loopEnd - _anim.value);
        const cap = Duration(milliseconds: 340);
        await _anim.animateTo(_loopEnd, duration: rest > cap ? cap : rest);
        if (!mounted) return;
      }
      await _anim.animateTo(
        1.0,
        duration: animation.duration * (1.0 - _loopEnd),
      );
    }
    if (!mounted) return;
    _reveal.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    _reveal.dispose();
    _anim.dispose();
    super.dispose();
  }

  double _holeRadius(double t, Size size, Offset center) {
    const rest = _logoSize / 2;
    const dip = 0.93;
    if (t <= 0.2) {
      return rest * _lerp(1.0, dip, _phase(t, 0.0, 0.2, Curves.easeInOut));
    }
    final dx = math.max(center.dx, size.width - center.dx);
    final dy = math.max(center.dy, size.height - center.dy);
    final maxRadius = math.sqrt(dx * dx + dy * dy);
    return _lerp(
      rest * dip,
      maxRadius,
      _phase(t, 0.2, 1.0, Curves.easeInOutCubic),
    );
  }

  Widget _buildMark() {
    final composition = _splashAnimation;
    if (composition == null) {
      return Image(
        image: _splashLogo,
        width: _logoSize,
        height: _logoSize,
        filterQuality: FilterQuality.low,
      );
    }
    // The animation's circle is inset within its canvas, so the box has to be
    // larger than the circle we actually want on screen.
    final box = _logoSize / _lottieCircleFraction;
    return RepaintBoundary(
      // The animation is the only thing repainting while the app boots. Without
      // this its every frame would dirty the full-screen backdrop too.
      child: SizedBox(
        width: box,
        height: box,
        child: Lottie(
          composition: composition,
          controller: _anim,
          filterQuality: FilterQuality.low,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppTheme.darkBg : AppTheme.lightBg;

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          // The logo sits dead centre — the same place the native launch screen
          // puts it — which also makes it the origin of the reveal.
          final center = size.center(Offset.zero);

          return AnimatedBuilder(
            animation: Listenable.merge([_intro, _reveal]),
            child: _buildMark(),
            builder: (context, child) {
              final t = _reveal.value;
              final radius = t > 0 ? _holeRadius(t, size, center) : null;

              return Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _Backdrop(
                      color: background,
                      center: center,
                      radius: radius,
                    ),
                  ),
                  // Painted over the hole, so it can ride the hole's rim.
                  _Logo(
                    intro: _intro.value,
                    reveal: t,
                    holeRadius: radius,
                    child: child!,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Backdrop extends CustomPainter {
  const _Backdrop({
    required this.color,
    required this.center,
    required this.radius,
  });

  final Color color;
  final Offset center;

  /// Null until the reveal starts.
  final double? radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final r = radius;
    if (r == null) {
      canvas.drawRect(Offset.zero & size, paint);
      return;
    }
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addOval(Rect.fromCircle(center: center, radius: r)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_Backdrop old) =>
      old.radius != radius || old.center != center || old.color != color;
}

/// The logo: settles in over the native launch screen, plays the animation, then
/// expands with the hole so its edge reads as the edge of the opening.
class _Logo extends StatelessWidget {
  const _Logo({
    required this.intro,
    required this.reveal,
    required this.holeRadius,
    required this.child,
  });

  final double intro;
  final double reveal;

  /// Non-null once the reveal is running; the logo is scaled so its rim sits on
  /// the rim of the hole.
  final double? holeRadius;

  /// The mark, built once by the state and passed through untouched so it is not
  /// rebuilt on every frame.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double scale;
    final double opacity;

    if (holeRadius != null) {
      scale = holeRadius! * 2 / _logoSize;
      opacity = 1 - _phase(reveal, 0.22, 0.52, Curves.easeIn);
    } else {
      scale = _settleScale(intro);
      opacity = 1;
    }

    // Opacity short-circuits at 1.0, so the saveLayer it would otherwise force
    // is only ever paid during the reveal's fade — not for the whole boot wait.
    return Center(
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.scale(scale: scale, child: child),
      ),
    );
  }
}
