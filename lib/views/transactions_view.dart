import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/firestore_provider.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';

class TransactionsView extends ConsumerStatefulWidget {
  const TransactionsView({super.key});

  @override
  ConsumerState<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends ConsumerState<TransactionsView> {
  bool _isVerifying = false;
  String? _verifyingDocId;

  Future<void> _reVerifyTransaction(Map<String, dynamic> tx) async {
    final txRef = tx['txRef'];
    final docId = tx['id'];
    if (txRef == null || docId == null) return;

    setState(() {
      _isVerifying = true;
      _verifyingDocId = docId;
    });

    try {
      final result = await ref.read(subscriptionServiceProvider).verifyPayment(txRef);
      if (result['status'] == 'success') {
        final expiryDate = await ref.read(firestoreServiceProvider).updatePremiumStatus(true, months: tx['months'] ?? 1);
        await ref.read(firestoreServiceProvider).updateTransactionStatus(
              docId,
              'success',
              {
                ...(result['data'] ?? {}),
                if (expiryDate != null) 'expiryDate': Timestamp.fromDate(expiryDate),
              },
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment verified successfully! Welcome to Premium.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Payment still pending or failed.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error verifying payment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _verifyingDocId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.card_pos, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('No transactions found', style: TextStyle(color: Colors.white54)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return _buildTransactionCard(context, tx);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, Map<String, dynamic> tx) {
    final status = tx['status'] ?? 'pending';
    final amount = tx['amount'] ?? 0.0;
    final plan = tx['plan'] ?? 'Premium';
    final months = tx['months'] ?? 1;
    final message = tx['message'] ?? (status == 'success' ? 'Payment successful' : 'Check status');
    final expiryDate = tx['expiryDate'] as Timestamp?;
    final date = tx['timestamp'] != null 
        ? (tx['timestamp'] as dynamic).toDate() 
        : DateTime.now();
    final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    final isPendingOrFailed = status == 'pending' || status == 'failed';
    final isProcessing = _isVerifying && _verifyingDocId == tx['id'];

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'success':
        statusColor = Colors.greenAccent;
        statusIcon = Iconsax.tick_circle;
        break;
      case 'failed':
        statusColor = Colors.redAccent;
        statusIcon = Iconsax.close_circle;
        break;
      default:
        statusColor = Colors.orangeAccent;
        statusIcon = Iconsax.timer;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 160, 
        borderRadius: 20,
        blur: 20,
        alignment: Alignment.center,
        border: 1,
        linearGradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.01),
          ],
        ),
        borderGradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          formattedDate,
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$months ${months == 1 ? 'Month' : 'Months'}',
                          style: const TextStyle(color: AppTheme.primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'MWK $amount',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        if (message.toString().isNotEmpty)
                          Text(
                            message.toString(),
                            style: const TextStyle(color: Colors.white30, fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (expiryDate != null)
                          Text(
                            'Premium until: ${DateFormat('MMM dd, yyyy').format(expiryDate.toDate())}',
                            style: const TextStyle(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ),
                  if (isPendingOrFailed)
                    ElevatedButton(
                      onPressed: isProcessing ? null : () => _reVerifyTransaction(tx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white10,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: isProcessing
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('RE-VERIFY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
