import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F0C29),
                  Color(0xFF302B63),
                  Color(0xFF24243E),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Profile Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage: user?.photoURL != null 
                              ? NetworkImage(user!.photoURL!) 
                              : null,
                            backgroundColor: AppTheme.surfaceColor,
                            child: user?.photoURL == null 
                              ? const Icon(Iconsax.user, size: 60, color: Colors.white24)
                              : null,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          user?.displayName ?? 'Basal User',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                        ),
                        Text(
                          user?.email ?? 'user@example.com',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Settings Card
                  GlassmorphicContainer(
                    width: double.infinity,
                    height: 300,
                    borderRadius: 24,
                    blur: 20,
                    alignment: Alignment.center,
                    border: 1.5,
                    linearGradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.05),
                        Colors.white.withOpacity(0.01),
                      ],
                    ),
                    borderGradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.2),
                        AppTheme.secondaryColor.withOpacity(0.2),
                      ],
                    ),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildSettingsTile(
                          icon: Iconsax.user_edit,
                          title: 'Edit Profile',
                          onTap: () {},
                        ),
                        _buildSettingsTile(
                          icon: Iconsax.setting_2,
                          title: 'Settings',
                          onTap: () {},
                        ),
                        _buildSettingsTile(
                          icon: Iconsax.info_circle,
                          title: 'Help & Support',
                          onTap: () {},
                        ),
                        const Divider(color: Colors.white10),
                        _buildSettingsTile(
                          icon: Iconsax.logout,
                          title: 'Sign Out',
                          iconColor: AppTheme.errorColor,
                          textColor: AppTheme.errorColor,
                          onTap: () async {
                            await ref.read(authRepositoryProvider).signOut();
                            if (context.mounted) Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListActionTile(
      icon: icon,
      title: title,
      onTap: onTap,
      iconColor: iconColor,
      textColor: textColor,
    );
  }
}

class ListActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const ListActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor ?? Colors.white70),
      title: Text(
        title,
        style: TextStyle(color: textColor ?? Colors.white, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Iconsax.arrow_right_3, size: 18, color: Colors.white24),
    );
  }
}
