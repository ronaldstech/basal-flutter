import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/auth_provider.dart';
import '../views/profile_view.dart';
import '../views/settings_view.dart';
import '../views/whats_new_view.dart';
import '../theme/app_theme.dart';
import '../views/transactions_view.dart';
import 'package:basal/providers/audio_provider.dart';
import '../providers/firestore_provider.dart';
import 'create_playlist_dialog.dart';
import '../views/notifications_view.dart';

class ProfileDrawer extends ConsumerWidget {
  const ProfileDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final premiumDetails = ref.watch(premiumDetailsProvider).value;
    final isPremium = premiumDetails?['isPremium'] ?? false;
    final premiumUntil = premiumDetails?['premiumUntil'] as Timestamp?;

    final unreadCount = ref.watch(unreadNotificationsCountProvider).value ?? 0;

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
          border: const Border(
            left: BorderSide(color: Colors.white12, width: 1),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.surfaceColor,
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? const Icon(Iconsax.user,
                              size: 30, color: Colors.white70)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'Guest User',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white60,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPremium
                                  ? AppTheme.primaryColor
                                  : Colors.white12,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(isPremium ? Iconsax.crown5 : Iconsax.music,
                                    size: 12,
                                    color: isPremium
                                        ? Colors.white
                                        : Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  isPremium
                                      ? (premiumUntil != null
                                          ? 'Premium • Expires ${DateFormat('MMM dd').format(premiumUntil.toDate())}'
                                          : 'Premium Member')
                                      : 'Free Plan',
                                  style: TextStyle(
                                    color: isPremium
                                        ? Colors.white
                                        : Colors.white38,
                                    fontSize: 10,
                                    fontWeight: isPremium
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, thickness: 1, height: 1),
              const SizedBox(height: 16),

              // Menu Items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Iconsax.music_square,
                      title: 'Create Playlist',
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        showDialog(
                          context: context,
                          builder: (context) => const CreatePlaylistDialog(),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Iconsax.user,
                      title: 'Profile',
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                              builder: (context) => const ProfileView()),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Iconsax.discover,
                      title: 'What\'s new',
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                              builder: (context) => const WhatsNewView()),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Iconsax.setting,
                      title: 'Settings',
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                              builder: (context) => const SettingsView()),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Iconsax.receipt_2,
                      title: 'Payments & Subscriptions',
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                              builder: (context) => const TransactionsView()),
                        );
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Text(
                        'Support & Feedback',
                        style: TextStyle(
                          color: Colors.white30,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Iconsax.notification,
                      title: 'Notifications',
                      trailing: unreadCount > 0
                          ? Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                unreadCount > 99
                                    ? '99+'
                                    : unreadCount.toString(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                              builder: (context) => const NotificationsView()),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Iconsax.notification_status,
                      title: 'Verify Notifications',
                      onTap: () async {
                        final messaging = FirebaseMessaging.instance;
                        final token = await messaging.getToken();
                        final snackBar = SnackBar(
                          content: Text(token != null
                              ? 'FCM Token active! Check console.'
                              : 'FCM Token missing. Check setup.'),
                          behavior: SnackBarBehavior.floating,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        }
                        print("FCM DEBUG TOKEN: $token");
                      },
                    ),
                  ],
                ),
              ),

              // Logout button at the bottom
              const Divider(color: Colors.white12, thickness: 1, height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: _buildMenuItem(
                  context,
                  icon: Iconsax.logout,
                  title: 'Logout',
                  color: Colors.redAccent,
                  onTap: () async {
                    Navigator.pop(context); // Close drawer
                    await ref.read(authRepositoryProvider).signOut();
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Dynamic padding to clear MiniPlayer
              Consumer(
                builder: (context, ref, child) {
                  final audioState = ref.watch(audioProvider);
                  return audioState.currentSong != null
                      ? const SizedBox(height: 80)
                      : const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.white,
    Widget? trailing,
  }) {
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -3),
      leading: Icon(icon, color: color, size: 24),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      hoverColor: Colors.white.withOpacity(0.05),
    );
  }
}
