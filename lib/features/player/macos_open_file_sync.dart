import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_router.dart';
import 'local_file_opener.dart';

class MacosOpenFileSync extends ConsumerStatefulWidget {
  const MacosOpenFileSync({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MacosOpenFileSync> createState() => _MacosOpenFileSyncState();
}

class _MacosOpenFileSyncState extends ConsumerState<MacosOpenFileSync> {
  MacosOpenFileListener? _listener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _listener ??= MacosOpenFileListener(
      ref: ref,
      router: ref.read(appRouterProvider),
    )..start();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
