import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/subscription_service.dart';
import '../providers/firestore_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class PaymentModal extends ConsumerStatefulWidget {
  final String planTitle;
  final double amount;

  const PaymentModal({
    super.key,
    required this.planTitle,
    required this.amount,
  });

  @override
  ConsumerState<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends ConsumerState<PaymentModal> {
  int _step = 1; // 1: Select Operator, 2: Enter Phone, 3: Verifying
  MobileOperator? _selectedOperator;
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  Timer? _verificationTimer;
  String? _txRef;
  String? _transactionDocId;
  int _months = 1;

  @override
  void dispose() {
    _phoneController.dispose();
    _verificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializePayment() async {
    if (_selectedOperator == null) return;
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Please enter your phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw Exception('User not logged in');

      _txRef = 'basal_${DateTime.now().millisecondsSinceEpoch}';

      final names = (user.displayName ?? 'Basal User').split(' ');
      final firstName = names.isNotEmpty ? names.first : 'Basal';
      final lastName = names.length > 1 ? names.last : 'User';

      final totalAmount = widget.amount * _months;
      final result =
          await ref.read(subscriptionServiceProvider).initializePayment(
                mobile: phone,
                amount: totalAmount,
                email: user.email ?? '',
                operatorId: _selectedOperator!.refId,
                firstName: firstName,
                lastName: lastName,
                txRef: _txRef!,
              );

      if (result['status'] == 'success') {
        _transactionDocId =
            await ref.read(firestoreServiceProvider).saveTransaction({
          'txRef': _txRef,
          'amount': totalAmount,
          'months': _months,
          'plan': widget.planTitle,
          'operator': _selectedOperator?.name,
          'status': 'pending',
          'mobile': phone,
        });

        setState(() {
          _step = 3;
          _isLoading = false;
        });
        _startVerificationPolling();
      } else {
        throw Exception(result['message'] ?? 'Failed to initialize payment');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _startVerificationPolling() {
    _verificationTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_txRef == null) return;
      try {
        final result =
            await ref.read(subscriptionServiceProvider).verifyPayment(_txRef!);
        if (result['status'] == 'success') {
          _verificationTimer?.cancel();
          if (_transactionDocId != null) {
            await ref.read(firestoreServiceProvider).updateTransactionStatus(
                  _transactionDocId!,
                  'success',
                  result['data'] ?? {},
                );
          }
          _handleSuccess(result['data'] ?? {});
        } else if (result['status'] == 'failed') {
          _verificationTimer?.cancel();
          if (_transactionDocId != null) {
            await ref.read(firestoreServiceProvider).updateTransactionStatus(
              _transactionDocId!,
              'failed',
              {'message': result['message'] ?? 'Payment failed'},
            );
          }
          setState(() {
            _step = 2;
            _error = result['message'] ?? 'Payment failed. Please try again.';
          });
        }
      } catch (e) {
        // Continue polling
      }
    });

    // Timeout after 5 minutes
    Future.delayed(const Duration(minutes: 5), () {
      if (_verificationTimer?.isActive ?? false) {
        _verificationTimer?.cancel();
        if (mounted) {
          setState(() {
            _step = 2;
            _error =
                'Verification timed out. If you were charged, please contact support.';
          });
        }
      }
    });
  }

  Future<void> _handleSuccess(Map<String, dynamic> data) async {
    try {
      final expiryDate = await ref
          .read(firestoreServiceProvider)
          .updatePremiumStatus(true, months: _months);

      if (_transactionDocId != null && expiryDate != null) {
        await ref.read(firestoreServiceProvider).updateTransactionStatus(
          _transactionDocId!,
          'success',
          {'expiryDate': Timestamp.fromDate(expiryDate)},
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome to Basal Premium!'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      setState(() => _error =
          'Payment successful, but failed to update profile. Contact support.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.planTitle,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(height: 32, color: Colors.white10),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          if (_step == 1) _buildOperatorSelection(),
          if (_step == 2) _buildPhoneInput(),
          if (_step == 3) _buildVerifyingState(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOperatorSelection() {
    final operatorsAsync = ref.watch(mobileOperatorsProvider);

    return operatorsAsync.when(
      data: (operators) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Mobile Operator',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          ...operators.map((op) => ListTile(
                onTap: () => setState(() {
                  _selectedOperator = op;
                  _step = 2;
                }),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _selectedOperator == op
                        ? AppTheme.primaryColor
                        : Colors.white10,
                  ),
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Iconsax.mobile, color: Colors.white54),
                ),
                title: Text(op.name),
                subtitle: Text(op.country),
                trailing: const Icon(Iconsax.arrow_right_3, size: 18),
              )),
        ],
      ),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      ),
      error: (e, st) => Center(
        child:
            Text('Error: $e', style: const TextStyle(color: Colors.redAccent)),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _step = 1),
              child: const Icon(Iconsax.arrow_left, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Paying via ${_selectedOperator?.name}',
                style: const TextStyle(color: Colors.white70)),
          ],
        ),
        const Text('Subscription Duration',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_months ${_months == 1 ? 'Month' : 'Months'}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed:
                        _months > 1 ? () => setState(() => _months--) : null,
                    icon: const Icon(Iconsax.minus_cirlce,
                        color: AppTheme.primaryColor),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _months++),
                    icon: const Icon(Iconsax.add_circle,
                        color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Total Amount: MWK ${widget.amount * _months}',
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          autofocus: true,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText:
                _selectedOperator?.name.toLowerCase().contains('airtel') == true
                    ? '0990000000'
                    : (_selectedOperator?.name.toLowerCase().contains('tnm') ==
                            true
                        ? '0880000000'
                        : '099XXXXXXX'),
            labelText: 'Phone Number',
            prefixIcon: const Icon(Iconsax.call, color: AppTheme.primaryColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _initializePayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black))
              : const Text('PAY NOW',
                  style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildVerifyingState() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const CircularProgressIndicator(color: AppTheme.primaryColor),
        const SizedBox(height: 24),
        const Text(
          'Waiting for payment confirmation...',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Please confirm the payment on your phone. This may take a minute.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 40),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel and close',
              style: TextStyle(color: Colors.white38)),
        ),
      ],
    );
  }
}
