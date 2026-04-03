import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xeboki_ordering/core/config/brand_config.dart';
import 'package:xeboki_ordering/core/services/firestore_service.dart';
import 'package:xeboki_ordering/core/types.dart';
import 'app_providers.dart';

const _kCustomerId = 'customer_id';
const _kCustomerName = 'customer_name';
const _kCustomerEmail = 'customer_email';
const _kCustomerPhone = 'customer_phone';
const _kCustomerToken = 'customer_token';
const _kLoyaltyPoints = 'loyalty_points';
const _kStoreCredit = 'store_credit';

class AuthNotifier extends StateNotifier<CustomerAuth?> {
  final OrderingClient _client;

  AuthNotifier(this._client) : super(null) {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kCustomerToken);
    final id = prefs.getString(_kCustomerId);
    final name = prefs.getString(_kCustomerName);
    if (token != null && id != null && name != null) {
      state = CustomerAuth(
        customer: OrderingCustomer.fromJson({
          'id': id,
          'name': name,
          'email': prefs.getString(_kCustomerEmail),
          'phone': prefs.getString(_kCustomerPhone),
          'loyalty_points': prefs.getInt(_kLoyaltyPoints) ?? 0,
          'store_credit': prefs.getDouble(_kStoreCredit) ?? 0.0,
        }),
        token: token,
      );
    }
  }

  bool get _useFirebase =>
      BrandConfig.instance.features.firebaseAuth &&
      FirestoreService.instance.isInitialised;

  Future<void> login({required String email, required String password}) async {
    CustomerAuth auth;
    if (_useFirebase) {
      auth = await _firebaseLogin(email: email, password: password);
    } else {
      auth = await _client.loginCustomer(email: email, password: password);
    }
    await _persist(auth);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('guest_mode');
    state = auth;
  }

  Future<CustomerAuth> _firebaseLogin({
    required String email,
    required String password,
  }) async {
    final fbAuth = FirestoreService.instance.auth;
    try {
      final credential = await fbAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final idToken = await credential.user!.getIdToken();
      return _client.firebaseVerify(idToken!);
    } on FirebaseAuthException catch (e) {
      throw Exception(_firebaseMessage(e));
    }
  }

  Future<void> register({
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    CustomerAuth auth;
    if (_useFirebase) {
      auth = await _firebaseRegister(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
    } else {
      auth = await _client.registerCustomer(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
    }
    await _persist(auth);
    state = auth;
  }

  Future<CustomerAuth> _firebaseRegister({
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    final fbAuth = FirestoreService.instance.auth;
    try {
      final credential = await fbAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Update Firebase display name for convenience
      if (fullName != null) {
        await credential.user!.updateDisplayName(fullName);
      }
      final idToken = await credential.user!.getIdToken();
      return _client.firebaseRegister(
        idToken: idToken!,
        fullName: fullName,
        phone: phone,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_firebaseMessage(e));
    }
  }

  Future<void> refresh() async {
    final current = state;
    if (current == null) return;
    final updated = await _client.getCustomer(current.customer.id);
    if (updated != null) {
      final auth = CustomerAuth(customer: updated, token: current.token);
      await _persist(auth);
      state = auth;
    }
  }

  Future<void> logout() async {
    if (_useFirebase) await FirestoreService.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCustomerId);
    await prefs.remove(_kCustomerName);
    await prefs.remove(_kCustomerEmail);
    await prefs.remove(_kCustomerPhone);
    await prefs.remove(_kCustomerToken);
    await prefs.remove(_kLoyaltyPoints);
    await prefs.remove(_kStoreCredit);
    state = null;
  }

  String _firebaseMessage(FirebaseAuthException e) => switch (e.code) {
        'user-not-found' || 'wrong-password' || 'invalid-credential' =>
          'Invalid email or password.',
        'email-already-in-use' => 'An account with this email already exists.',
        'weak-password' => 'Password is too weak. Use at least 6 characters.',
        'invalid-email' => 'Please enter a valid email address.',
        'too-many-requests' =>
          'Too many attempts. Please try again in a few minutes.',
        'network-request-failed' =>
          'Network error. Check your connection and try again.',
        _ => e.message ?? 'Authentication failed.',
      };

  Future<void> _persist(CustomerAuth auth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCustomerId, auth.customer.id);
    await prefs.setString(_kCustomerName, auth.customer.name);
    await prefs.setString(_kCustomerToken, auth.token);
    if (auth.customer.email != null) {
      await prefs.setString(_kCustomerEmail, auth.customer.email!);
    }
    if (auth.customer.phone != null) {
      await prefs.setString(_kCustomerPhone, auth.customer.phone!);
    }
    await prefs.setInt(_kLoyaltyPoints, auth.customer.loyaltyPoints);
    await prefs.setDouble(_kStoreCredit, auth.customer.storeCredit);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, CustomerAuth?>(
  (ref) => AuthNotifier(ref.watch(orderingClientProvider)),
);

final isLoggedInProvider = Provider<bool>((ref) => ref.watch(authProvider) != null);

/// True once the user explicitly taps "Continue as Guest" — persisted in prefs.
final guestModeProvider = StateNotifierProvider<_GuestModeNotifier, bool>(
  (_) => _GuestModeNotifier(),
);

class _GuestModeNotifier extends StateNotifier<bool> {
  _GuestModeNotifier() : super(false) {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('guest_mode') ?? false;
  }

  Future<void> enable() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('guest_mode', true);
  }

  Future<void> disable() async {
    state = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('guest_mode');
  }
}
