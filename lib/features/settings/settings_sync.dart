import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';

class SettingsSync extends ConsumerWidget {
  const SettingsSync({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(appSettingsProvider, (previous, next) {
      final settings = next.asData?.value;
      if (settings == null) {
        return;
      }

      ref.read(darkModeProvider.notifier).state = settings.darkMode;
      ref.read(autoPlayOnOpenProvider.notifier).state = settings.autoPlayOnOpen;
      ref.read(resumeRecentOnLaunchProvider.notifier).state =
          settings.resumeRecentOnLaunch;
      ref
          .read(playerControllerProvider.notifier)
          .setVolume(settings.defaultVolume);
    });

    return child;
  }
}
