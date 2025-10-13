import 'package:flutter/material.dart';
import '../../../core/network/endpoints.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketManager extends ChangeNotifier {
  static final SocketManager _instance = SocketManager._internal();
  factory SocketManager() => _instance;
  SocketManager._internal();

  IO.Socket? _socket;
  bool _isSocketInitialized = false;
  final Set<String> _processedLabels = <String>{};

  // Callbacks untuk setiap ViewModel
  final List<Function(Map<String, dynamic>)> _labelInsertedCallbacks = [];

  bool get isConnected => _socket?.connected ?? false;
  bool get isInitialized => _isSocketInitialized;

  void initSocket() {
    // Prevent multiple socket initialization
    if (_isSocketInitialized && _socket != null && _socket!.connected) {
      print('🔌 Socket already initialized and connected');
      return;
    }

    // Dispose existing socket first
    _disposeSocket();

    _socket = IO.io(
      ApiConstants.socketBaseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('🔌 Socket connected successfully');
      _isSocketInitialized = true;
      _socket!.emit('test', {'message': 'Hello from Flutter SocketManager'});
    });

    _socket!.onConnectError((error) {
      print('❌ Socket connection error: $error');
      _isSocketInitialized = false;
    });

    // Remove any existing listeners first
    _socket!.off('label_inserted');

    _socket!.on('label_inserted', (data) {
      print('📦 Raw socket data received: $data');

      // Ensure data is Map
      if (data is! Map<String, dynamic>) {
        print('❌ Socket data is not a Map: ${data.runtimeType}');
        return;
      }

      final Map<String, dynamic> labelData = data;

      // Create unique key to prevent duplicates
      final labelKey = '${labelData['noso']}_${labelData['nomorLabel']}_${labelData['timestamp']}';

      // Check if we already processed this label
      if (_processedLabels.contains(labelKey)) {
        print('🚫 Label already processed: $labelKey');
        return;
      }

      // Mark this label as processed
      _processedLabels.add(labelKey);

      // Notify all registered callbacks
      for (final callback in _labelInsertedCallbacks) {
        try {
          callback(labelData);
        } catch (e) {
          print('❌ Error in callback: $e');
        }
      }
    });

    _socket!.onDisconnect((_) {
      print('❌ Socket disconnected');
      _isSocketInitialized = false;
      notifyListeners();
    });
  }

  // Register callback for label_inserted events
  void registerLabelInsertedCallback(Function(Map<String, dynamic>) callback) {
    if (!_labelInsertedCallbacks.contains(callback)) {
      _labelInsertedCallbacks.add(callback);
      print('✅ Callback registered. Total callbacks: ${_labelInsertedCallbacks.length}');
    }
  }

  // Unregister callback
  void unregisterLabelInsertedCallback(Function(Map<String, dynamic>) callback) {
    _labelInsertedCallbacks.remove(callback);
    print('✅ Callback unregistered. Total callbacks: ${_labelInsertedCallbacks.length}');
  }

  // Clear all processed labels (useful when changing filters)
  void clearProcessedLabels() {
    _processedLabels.clear();
    print('🧹 Processed labels cleared');
  }

  // Dispose socket properly
  void _disposeSocket() {
    if (_socket != null) {
      print('🔌 Disposing existing socket connection');
      _socket!.off('label_inserted');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isSocketInitialized = false;
    }
  }

  // Reconnect socket if needed
  void reconnect() {
    print('🔄 Reconnecting socket...');
    _disposeSocket();
    initSocket();
  }

  @override
  void dispose() {
    _disposeSocket();
    _labelInsertedCallbacks.clear();
    super.dispose();
  }
}