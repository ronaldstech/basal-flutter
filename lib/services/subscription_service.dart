import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MobileOperator {
  final int id;
  final String name;
  final String refId;
  final String shortCode;
  final String? logo;
  final String country;
  final String currency;

  MobileOperator({
    required this.id,
    required this.name,
    required this.refId,
    required this.shortCode,
    this.logo,
    required this.country,
    required this.currency,
  });

  factory MobileOperator.fromJson(Map<String, dynamic> json) {
    return MobileOperator(
      id: json['id'],
      name: json['name'],
      refId: json['ref_id'],
      shortCode: json['short_code'],
      logo: json['logo'],
      country: json['supported_country']['name'],
      currency: json['supported_country']['currency'],
    );
  }
}

class SubscriptionService {
  final String baseUrl = 'https://unimarket-mw.com/basal/paychangu';

  Future<List<MobileOperator>> getMobileOperators() async {
    debugPrint('[BASAL_API] Fetching mobile operators: $baseUrl/get_operators.php');
    dev.log('Fetching mobile operators', name: 'SubscriptionService', error: '$baseUrl/get_operators.php');
    final response = await http.get(Uri.parse('$baseUrl/get_operators.php'));
    debugPrint('[BASAL_API] Operators Response (${response.statusCode}): ${response.body}');
    dev.log('Operators Response (${response.statusCode})', name: 'SubscriptionService', error: response.body);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        final List<dynamic> operatorsJson = data['data'];
        return operatorsJson
            .map((json) => MobileOperator.fromJson(json))
            .toList();
      }
    }
    throw Exception('Failed to load mobile operators');
  }

  Future<Map<String, dynamic>> initializePayment({
    required String mobile,
    required double amount,
    required String email,
    required String operatorId,
    required String firstName,
    required String lastName,
    required String txRef,
  }) async {
    debugPrint('[BASAL_API] Initializing payment for $mobile, amount: $amount');
    dev.log('Initializing payment', name: 'SubscriptionService', error: 'mobile: $mobile, amount: $amount, operator: $operatorId, ref: $txRef');
    final response = await http.post(
      Uri.parse('$baseUrl/initialize_payment.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': mobile,
        'amount': amount,
        'email': email,
        'operator_id': operatorId,
        'first_name': firstName,
        'last_name': lastName,
        'txRef': txRef,
      }),
    );

    debugPrint('[BASAL_API] Initialize Response (${response.statusCode}): ${response.body}');
    dev.log('Initialize Response (${response.statusCode})', name: 'SubscriptionService', error: response.body);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to initialize payment');
  }

  Future<Map<String, dynamic>> verifyPayment(String txRef) async {
    debugPrint('[BASAL_API] Verifying payment: $txRef');
    dev.log('Verifying payment', name: 'SubscriptionService', error: 'txRef: $txRef');
    final response =
        await http.get(Uri.parse('$baseUrl/verify_payment.php?txRef=$txRef'));
    debugPrint('[BASAL_API] Verify Response (${response.statusCode}): ${response.body}');
    dev.log('Verify Response (${response.statusCode})', name: 'SubscriptionService', error: response.body);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to verify payment');
  }
}

final subscriptionServiceProvider = Provider((ref) => SubscriptionService());

final mobileOperatorsProvider = FutureProvider<List<MobileOperator>>((ref) {
  return ref.watch(subscriptionServiceProvider).getMobileOperators();
});
