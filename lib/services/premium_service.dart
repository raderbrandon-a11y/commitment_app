import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PremiumService extends ChangeNotifier {
  // ✅ Android Public SDK Key
  static const String _googlePublicSdkKey =
      'goog_olOPoIRZFnUhxFkzKYiaGIzDWFf';

  // ✅ RevenueCat Entitlement Identifier
  static const String _entitlementId = 'premium';

  bool _inited = false;
  bool _busy = false;
  String? _lastError;

  CustomerInfo? _customerInfo;
  Offerings? _offerings;

  bool get isInitialized => _inited;
  bool get isBusy => _busy;
  String? get lastError => _lastError;

  Offerings? get offerings => _offerings;

  bool get isPremium {
    final info = _customerInfo;
    if (info == null) return false;
    return info.entitlements.active.containsKey(_entitlementId);
  }

  Future<void> init() async {
    _setBusy(true);
    _lastError = null;

    try {
      await Purchases.configure(
        PurchasesConfiguration(_googlePublicSdkKey),
      );
      _inited = true;
      await reload();
    } on PlatformException catch (e) {
      _lastError = e.toString();
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _setBusy(false);
      notifyListeners();
    }
  }

  Future<void> _refreshCustomerInfo() async {
    _customerInfo = await Purchases.getCustomerInfo();
  }

  Future<void> _refreshOfferings() async {
    _offerings = await Purchases.getOfferings();
  }

  Future<void> reload() async {
    _setBusy(true);
    _lastError = null;

    try {
      await _refreshCustomerInfo();
      await _refreshOfferings();
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> purchasePackage(Package package) async {
    _setBusy(true);
    _lastError = null;

    try {
      final result = await Purchases.purchasePackage(package);
      _customerInfo = result.customerInfo;
      notifyListeners();
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code != PurchasesErrorCode.purchaseCancelledError) {
        _lastError = e.toString();
        notifyListeners();
      }
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> restore() async {
    _setBusy(true);
    _lastError = null;

    try {
      _customerInfo = await Purchases.restorePurchases();
      notifyListeners();
    } on PlatformException catch (e) {
      _lastError = e.toString();
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  void _setBusy(bool v) {
    if (_busy == v) return;
    _busy = v;
    notifyListeners();
  }
}
