import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/payment_entities.dart';

/// Persists the patient's preferred default payment method between sessions.
class PreferredPaymentMethodStore {
  static const _key = 'patient_preferred_payment_method';

  Future<PaymentMethod> read() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(_key);
    if (idx == null || idx < 0 || idx >= PaymentMethod.values.length) {
      return PaymentMethod.cash;
    }
    final method = PaymentMethod.values[idx];
    // Card flow isn't enabled yet (no CardIntegrationId). Fall back to cash so
    // the checkout doesn't pre-select an unavailable option.
    if (method == PaymentMethod.card) return PaymentMethod.cash;
    return method;
  }

  Future<void> write(PaymentMethod method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, method.index);
  }
}
