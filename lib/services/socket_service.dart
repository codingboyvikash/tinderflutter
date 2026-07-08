import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  io.Socket? _socket;

  io.Socket? get socket => _socket;

  void connect(Map<String, dynamic> userData) {
    if (_socket != null && _socket!.connected) return;

    final wsUrl = dotenv.env['WS_URL'] ?? 'http://10.0.2.2:5001';
    print("🔌 SocketService connecting to: $wsUrl");

    _socket = io.io(
      wsUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('🔌 Socket connected successfully to backend.');
      // Setup user session
      _socket!.emit('setup', userData);
    });

    _socket!.onDisconnect((_) {
      print('🔌 Socket disconnected.');
    });

    _socket!.onConnectError((data) {
      print('🔌 Socket connection error: $data');
    });
  }

  void joinChat(String room) {
    if (_socket == null) return;
    _socket!.emit('join_chat', room);
  }

  void sendTyping(String room) {
    if (_socket == null) return;
    _socket!.emit('typing', room);
  }

  void stopTyping(String room) {
    if (_socket == null) return;
    _socket!.emit('stop_typing', room);
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }
  }
}
