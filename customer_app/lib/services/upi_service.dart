import 'package:url_launcher/url_launcher.dart';

class UpiService {
  /// Generate a UPI payment deep link
  static String generateUpiLink({
    required String upiId,
    required String payeeName,
    required double amount,
    String? transactionNote,
    String currency = 'INR',
  }) {
    final params = <String, String>{
      'pa': upiId,
      'pn': payeeName,
      'cu': currency,
    };

    if (amount > 0) {
      params['am'] = amount.toStringAsFixed(2);
    }

    if (transactionNote != null && transactionNote.isNotEmpty) {
      params['tn'] = transactionNote;
    }

    final queryString =
        params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');

    return 'upi://pay?$queryString';
  }

  /// Launch UPI payment intent
  static Future<bool> launchUpiPayment({
    required String upiId,
    required String payeeName,
    required double amount,
    String? transactionNote,
  }) async {
    final upiLink = generateUpiLink(
      upiId: upiId,
      payeeName: payeeName,
      amount: amount,
      transactionNote: transactionNote,
    );

    final uri = Uri.parse(upiLink);

    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    return false;
  }

  /// Check if UPI apps are available
  static Future<bool> isUpiAvailable() async {
    final uri = Uri.parse('upi://pay');
    return await canLaunchUrl(uri);
  }
}
