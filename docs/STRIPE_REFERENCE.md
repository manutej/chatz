# Stripe Payment Integration Reference

This document provides integration guidance for Stripe payments in the Chatz application for wallet recharges and microtransactions.

## Overview

Flutter Stripe SDK enables seamless payment experiences in Flutter apps, allowing users to recharge their wallet and pay for calls.

## Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_stripe: ^10.0.0
  http: ^1.1.0
```

## Basic Setup

### 1. Initialize Stripe

```dart
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set publishable key
  Stripe.publishableKey = 'pk_test_YOUR_PUBLISHABLE_KEY';

  runApp(MyApp());
}
```

### 2. Backend Integration

Your backend must create Payment Intents. Here's a Node.js example:

```javascript
// server.js
const stripe = require('stripe')('sk_test_YOUR_SECRET_KEY');
const express = require('express');
const app = express();

app.use(express.json());

app.post('/create-payment-intent', async (req, res) => {
  try {
    const { amount, currency = 'usd', customerId } = req.body;

    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount * 100, // Convert to cents
      currency: currency,
      customer: customerId,
      automatic_payment_methods: {
        enabled: true,
      },
    });

    res.json({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

app.listen(4242, () => console.log('Server running on port 4242'));
```

## Chatz Wallet Recharge Implementation

### 1. Payment Service

```dart
class StripePaymentService {
  static const String _baseUrl = 'YOUR_BACKEND_URL';

  Future<void> rechargeWallet({
    required double amount,
    required String userId,
  }) async {
    try {
      // 1. Create payment intent on backend
      final paymentIntent = await _createPaymentIntent(amount, userId);

      // 2. Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'Chatz',
          paymentIntentClientSecret: paymentIntent['clientSecret'],
          customerEphemeralKeySecret: paymentIntent['ephemeralKey'],
          customerId: paymentIntent['customer'],
          style: ThemeMode.system,
        ),
      );

      // 3. Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      // 4. Payment successful - update wallet
      await _updateWalletBalance(userId, amount);

    } on StripeException catch (e) {
      _handleStripeError(e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _createPaymentIntent(double amount, String userId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/create-payment-intent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': amount,
        'currency': 'usd',
        'userId': userId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create payment intent');
    }
  }

  Future<void> _updateWalletBalance(String userId, double amount) async {
    // Update Firestore wallet balance
    await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .update({
        'walletBalance': FieldValue.increment(amount),
      });

    // Record transaction
    await FirebaseFirestore.instance
      .collection('transactions')
      .doc(userId)
      .collection('transactions')
      .add({
        'type': 'recharge',
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
        'description': 'Wallet recharge via Stripe',
      });
  }

  void _handleStripeError(StripeException error) {
    switch (error.error.code) {
      case FailureCode.Canceled:
        print('Payment canceled by user');
        break;
      case FailureCode.Failed:
        print('Payment failed: ${error.error.message}');
        break;
      default:
        print('Stripe error: ${error.error.localizedMessage}');
    }
  }
}
```

### 2. Wallet Recharge Screen

```dart
class WalletRechargeScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<WalletRechargeScreen> createState() => _WalletRechargeScreenState();
}

class _WalletRechargeScreenState extends ConsumerState<WalletRechargeScreen> {
  final StripePaymentService _paymentService = StripePaymentService();
  bool _isProcessing = false;

  final List<double> _rechargeAmounts = [5, 10, 25, 50, 100, 200];

  Future<void> _rechargeWallet(double amount) async {
    setState(() => _isProcessing = true);

    try {
      final userId = ref.read(currentUserProvider)?.id;

      await _paymentService.rechargeWallet(
        amount: amount,
        userId: userId!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wallet recharged successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Recharge Wallet')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Amount',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: _rechargeAmounts.length,
              itemBuilder: (context, index) {
                final amount = _rechargeAmounts[index];
                return ElevatedButton(
                  onPressed: _isProcessing ? null : () => _rechargeWallet(amount),
                  child: Text('\$${amount.toStringAsFixed(0)}'),
                );
              },
            ),
            if (_isProcessing)
              Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
```

### 3. Card Input Widget

For custom payment forms:

```dart
class CardInputScreen extends StatefulWidget {
  @override
  State<CardInputScreen> createState() => _CardInputScreenState();
}

class _CardInputScreenState extends State<CardInputScreen> {
  final _controller = CardFormEditController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_update);
  }

  void _update() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_update);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePayment() async {
    if (!_controller.details.complete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please complete card details')),
      );
      return;
    }

    try {
      // Create payment method
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      // Confirm payment on backend
      await _confirmPayment(paymentMethod.id);

    } on StripeException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.error.localizedMessage}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payment')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CardFormField(
              controller: _controller,
              style: CardFormStyle(
                borderColor: Colors.grey,
                textColor: Colors.black,
                placeholderColor: Colors.grey,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _controller.details.complete ? _handlePayment : null,
              child: Text('Pay'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Payment Sheet Customization

```dart
await Stripe.instance.initPaymentSheet(
  paymentSheetParameters: SetupPaymentSheetParameters(
    merchantDisplayName: 'Chatz',
    paymentIntentClientSecret: clientSecret,
    customerId: customerId,
    customerEphemeralKeySecret: ephemeralKey,

    // Appearance customization
    appearance: PaymentSheetAppearance(
      colors: PaymentSheetAppearanceColors(
        primary: Color(0xFF075E54), // Chatz primary color
        background: Colors.white,
        componentBackground: Color(0xFFF5F5F5),
      ),
      shapes: PaymentSheetShape(
        borderRadius: 12,
        borderWidth: 1,
      ),
      primaryButton: PaymentSheetPrimaryButtonAppearance(
        colors: PaymentSheetPrimaryButtonTheme(
          light: PaymentSheetPrimaryButtonThemeColors(
            background: Color(0xFF075E54),
            text: Colors.white,
          ),
        ),
      ),
    ),

    // Additional options
    allowsDelayedPaymentMethods: false,
    googlePay: PaymentSheetGooglePay(
      merchantCountryCode: 'US',
      testEnv: true,
    ),
    applePay: PaymentSheetApplePay(
      merchantCountryCode: 'US',
    ),
  ),
);
```

## Webhook Handling (Backend)

```javascript
// Handle Stripe webhooks
app.post('/webhook', express.raw({type: 'application/json'}), async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const endpointSecret = 'whsec_YOUR_WEBHOOK_SECRET';

  let event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, endpointSecret);
  } catch (err) {
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle event
  switch (event.type) {
    case 'payment_intent.succeeded':
      const paymentIntent = event.data.object;
      await handleSuccessfulPayment(paymentIntent);
      break;

    case 'payment_intent.payment_failed':
      const failedPayment = event.data.object;
      await handleFailedPayment(failedPayment);
      break;

    default:
      console.log(`Unhandled event type ${event.type}`);
  }

  res.json({received: true});
});

async function handleSuccessfulPayment(paymentIntent) {
  // Update user's wallet in Firestore
  const userId = paymentIntent.metadata.userId;
  const amount = paymentIntent.amount / 100;

  await admin.firestore().collection('users').doc(userId).update({
    walletBalance: admin.firestore.FieldValue.increment(amount),
  });

  // Record transaction
  await admin.firestore()
    .collection('transactions')
    .doc(userId)
    .collection('transactions')
    .add({
      type: 'recharge',
      amount: amount,
      paymentIntentId: paymentIntent.id,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: 'completed',
    });
}
```

## Testing

### Test Card Numbers

```dart
// Test cards (use in test mode only)
const testCards = {
  'success': '4242424242424242',
  'requires3DS': '4000002500003155',
  'declined': '4000000000009995',
};
```

### Test Mode Configuration

```dart
// Use test keys
Stripe.publishableKey = 'pk_test_YOUR_TEST_KEY';

// Enable test environment
await Stripe.instance.initPaymentSheet(
  paymentSheetParameters: SetupPaymentSheetParameters(
    testEnv: true, // Enable test mode
    // ... other parameters
  ),
);
```

## Error Handling

```dart
try {
  await Stripe.instance.presentPaymentSheet();
} on StripeException catch (e) {
  switch (e.error.code) {
    case FailureCode.Canceled:
      // User canceled the payment
      print('Payment canceled');
      break;

    case FailureCode.Failed:
      // Payment failed
      print('Payment failed: ${e.error.message}');
      _showErrorDialog(e.error.message ?? 'Payment failed');
      break;

    case FailureCode.Timeout:
      // Payment timed out
      print('Payment timed out');
      break;

    default:
      print('Stripe error: ${e.error.localizedMessage}');
  }
}
```

## Best Practices

1. **Never expose secret keys** in client-side code
2. **Always validate payments** on the backend
3. **Use webhooks** for reliable payment confirmation
4. **Implement idempotency** for payment requests
5. **Store customer IDs** for repeat customers
6. **Test thoroughly** with test cards before going live
7. **Handle all error cases** gracefully
8. **Use HTTPS** for all API calls
9. **Comply with PCI requirements**
10. **Log transactions** for audit trails

## Platform-Specific Setup

### Android

Add to `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 34

    defaultConfig {
        minSdkVersion 21
    }
}
```

### iOS

Minimum iOS version 13.0 required in `ios/Podfile`:

```ruby
platform :ios, '13.0'
```

## Production Checklist

- [ ] Replace test keys with live keys
- [ ] Set up webhook endpoints
- [ ] Configure proper error handling
- [ ] Implement transaction logging
- [ ] Test with real cards
- [ ] Set up Stripe dashboard monitoring
- [ ] Configure email receipts
- [ ] Implement refund handling
- [ ] Add fraud detection rules
- [ ] Comply with local regulations

## Resources

- [Flutter Stripe Docs](https://pub.dev/packages/flutter_stripe)
- [Stripe API Documentation](https://stripe.com/docs/api)
- [Payment Intents Guide](https://stripe.com/docs/payments/payment-intents)
- [Stripe Dashboard](https://dashboard.stripe.com/)
