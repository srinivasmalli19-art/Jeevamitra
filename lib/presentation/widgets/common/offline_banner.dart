import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/connectivity/connectivity_provider.dart';

/// Wraps [child] with a persistent amber banner at the top when the device
/// has no network connectivity. The banner disappears automatically when
/// connectivity is restored.
class OfflineBanner extends ConsumerWidget {
  final Widget child;
  const OfflineBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: isOnline
              ? const SizedBox.shrink()
              : Material(
                  color: const Color(0xFFFFF3CD),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.wifi_off_rounded,
                              size: 18, color: Color(0xFF856404)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No internet connection. Some features may be unavailable.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: const Color(0xFF856404)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
