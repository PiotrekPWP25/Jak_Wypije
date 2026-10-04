import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/local/local_storage.dart';
import '../../data/location/location_provider.dart';
import '../../data/repositories/bar_repository.dart';
import '../../data/repositories/city_repository.dart';
import '../../data/repositories/place_repository.dart';
import '../../data/repositories/social_repository.dart';
import '../account/account_providers.dart';

/// Branded loading screen: the logo pops in while a beer "pours" into the
/// progress bar and the app preloads bars, city data and location.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key, this.resetUserData = false});

  /// "Wyczyść dane na tym urządzeniu" from Settings.
  final bool resetUserData;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _minimumDuration = Duration(milliseconds: 1600);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _minimumDuration,
  )..forward();

  late final Animation<double> _logoScale = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.45, curve: Curves.elasticOut),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.3, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _preload();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _preload() async {
    if (widget.resetUserData) {
      // Let the route transition finish first: the old tabs are still
      // mounted during it and would rebuild with an empty profile.
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      await ref.read(localStorageProvider).clearUserData();
      ref.invalidate(localStorageProvider);
    }
    // Ask for location only after the age gate and consents.
    final onboarding = needsOnboarding(ref.read(profileProvider));
    try {
      await Future.wait<Object?>([
        ref.read(barsProvider.future),
        ref.read(friendsProvider.future),
        ref.read(zonesProvider.future),
        ref.read(transitStopsProvider.future),
        ref.read(landmarksProvider.future),
        ref.read(tripsProvider.future),
        ref.read(eventsProvider.future),
        ref.read(districtsProvider.future),
        if (!onboarding)
          ref
              .read(userPositionProvider.future)
              .timeout(const Duration(seconds: 3), onTimeout: () => null),
        Future<void>.delayed(_minimumDuration),
      ]);
    } catch (_) {
      // Screens show their own error states; never block on the splash.
    }
    if (!mounted) return;
    // First run (or new Terms): age gate, consents, tourist or local.
    if (ref.read(passwordRecoveryPendingProvider)) {
      // A password-reset link started the app.
      ref.read(passwordRecoveryPendingProvider.notifier).state = false;
      context.go('/auth/new-password');
      return;
    }
    context.go(onboarding ? '/onboarding' : '/start');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 260,
                    height: 260,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) =>
                    _BeerProgress(value: _controller.value),
              ),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _fade,
                child: const Text(
                  'Zaplanuj wieczór. Odkryj perełki. Wróć bezpiecznie.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.brownSoft,
                    fontWeight: FontWeight.w700,
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

/// Progress bar drawn as a glass filling with beer and a foam head.
class _BeerProgress extends StatelessWidget {
  const _BeerProgress({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    const width = 200.0;
    const height = 18.0;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height),
        border: Border.all(color: AppColors.brown, width: 2.5),
        color: Colors.white,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.05, 1.0),
            heightFactor: 1,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.amber, Color(0xFFFFD54F), Colors.white],
                  stops: [0, 0.85, 1],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
