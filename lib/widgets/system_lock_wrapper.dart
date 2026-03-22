import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../providers/firestore_provider.dart';
import '../theme/app_theme.dart';

class SystemLockWrapper extends ConsumerWidget {
  final Widget child;
  static const String appVersion = "1.0.0";

  const SystemLockWrapper({super.key, required this.child});

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse('https://unimarket-mw.com/basal');
    try {
      if (!await launchUrl(url)) {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching url: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(systemConfigStreamProvider);

    return Stack(
      children: [
        // The underlying application
        child,

        // Overlay if config dictates lockdown
        configAsync.when(
          data: (config) {
            if (config == null) return const SizedBox.shrink();

            final update = config['update']?.toString().toLowerCase();
            final system = config['system']?.toString().toLowerCase();
            final firestoreVersion = config['version']?.toString();

            if (update == 'on' && firestoreVersion != appVersion) {
              return _buildLockScreen(
                context,
                title: 'Update Required',
                message:
                    'A new version of Basal Music is available. Please update to continue enjoying your premium experience.',
                icon: Iconsax.document_download,
                iconColor: AppTheme.primaryColor,
                actionWidget: ElevatedButton.icon(
                  onPressed: _launchUrl,
                  icon: const Icon(Iconsax.document_download),
                  label: const Text('Download New Version'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              );
            }

            if (system == 'off') {
              final timestamp = config['time'] as Timestamp?;
              final timeString = timestamp != null
                  ? DateFormat('MMMM dd, yyyy \'at\' h:mm a')
                      .format(timestamp.toDate())
                  : 'shortly';

              return _buildLockScreen(
                context,
                title: 'System Maintenance',
                message:
                    'Basal Music is currently down for scheduled maintenance. The system will be back online by $timeString.\n\nThank you for your patience!',
                icon: Iconsax.setting_2,
                iconColor: Colors.orangeAccent,
              );
            }

            return const SizedBox.shrink();
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildLockScreen(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    Widget? actionWidget,
  }) {
    // Return a Scaffold to block all touch events and show UI
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.95),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              iconColor.withOpacity(0.15),
              Colors.black,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: GlassmorphicContainer(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.65,
              borderRadius: 24,
              blur: 30,
              alignment: Alignment.center,
              border: 2,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.02),
                ],
              ),
              borderGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.0),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: iconColor.withOpacity(0.3), width: 2),
                      ),
                      child: Icon(icon, size: 64, color: iconColor),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (actionWidget != null) ...[
                      const SizedBox(height: 40),
                      actionWidget,
                    ],
                  ],
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
