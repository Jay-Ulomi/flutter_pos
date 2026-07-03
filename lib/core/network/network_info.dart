import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../constants/api_constants.dart';

class NetworkInfo {
  final Connectivity _connectivity;
  bool _isConnected = true;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  /// Fast, interface-level check (connectivity_plus). True if *some* network
  /// interface is up — but that includes captive portals / no-uplink routers.
  bool get isConnected => _isConnected;

  NetworkInfo(this._connectivity);

  /// Actual reachability of the API server (not just the interface). Opens a
  /// short TCP connection to the API host:port. Use this to gate *background*
  /// sync so we don't hammer HTTP on a captive portal — NEVER use it to gate
  /// checkout (a false negative must never block a sale).
  Future<bool> hasInternet() async {
    if (!_isConnected) return false;
    try {
      final uri = Uri.parse(ApiConstants.baseUrl);
      final port =
          uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
      final socket = await Socket.connect(
        uri.host,
        port,
        timeout: const Duration(seconds: 3),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> initialize() async {
    final results = await _connectivity.checkConnectivity();
    _isConnected = !results.contains(ConnectivityResult.none);
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final connected = !results.contains(ConnectivityResult.none);
      if (_isConnected != connected) {
        _isConnected = connected;
        _connectivityController.add(connected);
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}
