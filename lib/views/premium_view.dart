import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../providers/firestore_provider.dart';
import '../widgets/payment_modal.dart';
import 'transactions_view.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PremiumView extends ConsumerStatefulWidget {
  const PremiumView({super.key});

  @override
  ConsumerState<PremiumView> createState() => _PremiumViewState();
}

class _PremiumViewState extends ConsumerState<PremiumView> {
  @override
  Widget build(BuildContext context) {
    final premiumDetailsAsync = ref.watch(premiumDetailsProvider);
    final pricingPlansAsync = ref.watch(pricingPlansStreamProvider);

    return Scaffold(
      body: premiumDetailsAsync.when(
        data: (details) {
          final isPremium = details['isPremium'] ?? false;
          final premiumUntil = details['premiumUntil'] as Timestamp?;
          final formattedDate = premiumUntil != null 
              ? DateFormat('MMM dd, yyyy').format(premiumUntil.toDate()) 
              : null;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF6A11CB), // Deep Purple
                          const Color(0xFF2575FC), // Vibrant Blue
                          Theme.of(context).scaffoldBackgroundColor,
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -50,
                          top: -50,
                          child: Icon(
                            Iconsax.crown,
                            size: 250,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Iconsax.crown,
                                size: 80,
                                color: Colors.white,
                              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                              const SizedBox(height: 16),
                              const Text(
                                'Basal Premium',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (isPremium) _buildCurrentPlanCard(context, formattedDate),
                    const SizedBox(height: 24),
                    const Text(
                      'Exclusive Benefits',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildFeatureItem(Iconsax.music_play, 'Ad-free Experience', 'Enjoy uninterrupted music without any ads.'),
                    _buildFeatureItem(Iconsax.arrow_down_2, 'Offline Listening', 'Download your favorite songs and listen anywhere.'),
                    _buildFeatureItem(Iconsax.microphone_2, 'Live Synced Lyrics', 'Sing along with real-time, synced lyrics.'),
                    _buildFeatureItem(Iconsax.music_playlist, 'Unlimited Playlists', 'Create as many playlists as your heart desires.'),
                    _buildFeatureItem(Iconsax.music_filter, 'High-End Audio', 'Experience 320kbps high-fidelity sound quality.'),
                    _buildFeatureItem(Iconsax.repeat, 'Unlimited Skips', 'Skip any song you want, anytime.'),
                    const SizedBox(height: 40),
                    const Text(
                      'Available Plans',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    pricingPlansAsync.when(
                      data: (plans) {
                        if (plans.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text('No premium plans available right now.', style: TextStyle(color: Colors.white54)),
                            ),
                          );
                        }
                        return Column(
                          children: plans.map((plan) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildPlanCard(
                                context,
                                title: plan['name'] ?? 'Premium Plan',
                                price: '${plan['price'] ?? '0'} MWK',
                                period: '/ ${plan['period'] ?? 'month'}',
                                description: plan['description'] ?? 'Full access to all premium features.',
                                color: AppTheme.primaryColor,
                                amount: double.tryParse(plan['price'].toString()) ?? 0,
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(color: AppTheme.primaryColor),
                        ),
                      ),
                      error: (e, st) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text('Error loading plans: $e', style: const TextStyle(color: Colors.redAccent)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TransactionsView()),
                          );
                        },
                        icon: const Icon(Iconsax.receipt_2, size: 18),
                        label: const Text('View Transaction History'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white60,
                        ),
                      ),
                    ),
                    const SizedBox(height: 120),
                  ]),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildCurrentPlanCard(BuildContext context, String? formattedDate) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 110,
      borderRadius: 16,
      blur: 20,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        colors: [
          AppTheme.primaryColor.withOpacity(0.2),
          Colors.white.withOpacity(0.05),
        ],
      ),
      borderGradient: LinearGradient(
        colors: [
          AppTheme.primaryColor.withOpacity(0.5),
          Colors.white.withOpacity(0.2),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            const Icon(Iconsax.verify, color: AppTheme.primaryColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YOUR CURRENT PLAN',
                    style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.white70),
                  ),
                  const Text(
                    'Premium Individual',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (formattedDate != null)
                    Text(
                      'Valid until $formattedDate',
                      style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w500),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    required String period,
    required String description,
    required Color color,
    required double amount,
  }) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 180,
      borderRadius: 24,
      blur: 20,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withOpacity(0.15),
          Colors.white.withOpacity(0.05),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withOpacity(0.6),
          Colors.white.withOpacity(0.3),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 12, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: price,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text: period,
                        style: const TextStyle(fontSize: 12, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    useRootNavigator: true,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => PaymentModal(
                      planTitle: title,
                      amount: amount,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'UPGRADE NOW',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
