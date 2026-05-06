import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkInfo {
  final Connectivity _connectivity;
  bool _isConnected = true;

  NetworkInfo({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    _isConnected = !results.contains(ConnectivityResult.none);
    return _isConnected;
  }

  bool get lastKnownStatus => _isConnected;

  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((results) {
      _isConnected = !results.contains(ConnectivityResult.none);
      return _isConnected;
    });
  }
}
