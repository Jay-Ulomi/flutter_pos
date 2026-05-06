import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkInfo {
  final Connectivity _connectivity;
  bool _isConnected = true;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  Stream<bool> get onConnectivityChanged => _connectivityController.stream;
  bool get isConnected => _isConnected;

  NetworkInfo(this._connectivity);

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
