import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class RemoteControlPage extends StatefulWidget {
  final String deviceId;
  final String deviceName;

  const RemoteControlPage({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  @override
  State<RemoteControlPage> createState() => _RemoteControlPageState();
}

class _RemoteControlPageState extends State<RemoteControlPage> {
  late WebSocketChannel channel;
  String _status = "Disconnected";
  List<String> _logs = [];
  bool _isConnected = false;
  String get _shortDeviceId {
    final id = widget.deviceId.trim();
    if (id.isEmpty) return "-";
    if (id.length <= 8) return id;
    return id.substring(0, 8);
  }

  @override
  void initState() {
    super.initState();
    _connectToServer();
  }

  void _connectToServer() {
    try {
      channel = WebSocketChannel.connect(
        Uri.parse('wss://ws-dalangstore.my.id:8027/remote-control'),
      );

      setState(() {
        _status = "Connected";
        _isConnected = true;
      });

      _addLog("Connected to server");
      channel.sink.add(
        '{"type":"register","deviceId":"${widget.deviceId}","deviceName":"${widget.deviceName}"}',
      );

      channel.stream.listen(
        (message) {
          _addLog("Received: $message");
          _processCommand(message);
        },
        onError: (error) {
          _addLog("Error: $error");
          _disconnect();
        },
        onDone: () {
          _addLog("Connection closed");
          _disconnect();
        },
      );
    } catch (e) {
      _addLog("Connection failed: $e");
    }
  }

  void _processCommand(String command) {
    if (command.startsWith('{') && command.endsWith('}')) {
      _addLog("Server JSON: $command");
      return;
    }

    switch (command) {
      case "GET_STATUS":
        _sendResponse("Device: ${widget.deviceName}, Status: Online");
        break;
      default:
        _addLog("Unknown command: $command");
    }
  }

  void _sendResponse(String response) {
    if (_isConnected) {
      channel.sink.add(response);
      _addLog("Sent: $response");
    }
  }

  void _disconnect() {
    setState(() {
      _status = "Disconnected";
      _isConnected = false;
    });
  }

  void _addLog(String log) {
    setState(() {
      _logs.insert(0, "${DateTime.now().toString().split(' ')[1]}: $log");
    });
  }

  @override
  void dispose() {
    if (_isConnected) {
      channel.sink.close(status.goingAway);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Remote Control - ${widget.deviceName}'),
        backgroundColor: _isConnected
            ? const Color(0xFF4F8BFF)
            : const Color(0xFF7A5CFF),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1F2448),
            child: Row(
              children: [
                Icon(
                  _isConnected ? Icons.wifi : Icons.wifi_off,
                  color: _isConnected
                      ? const Color(0xFF4F8BFF)
                      : const Color(0xFF7A5CFF),
                ),
                const SizedBox(width: 10),
                Text(_status, style: const TextStyle(fontSize: 16)),
                const Spacer(),
                Text(
                  "ID: $_shortDeviceId...",
                  style: const TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF6B66A6),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildControlButton('Get Status', Icons.info, Colors.blue),
                _buildControlButton(
                  'Flash LED',
                  Icons.lightbulb,
                  const Color(0xFF70B4FF),
                ),
                _buildControlButton(
                  'Get Location',
                  Icons.location_on,
                  const Color(0xFF4F8BFF),
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              color: Colors.black,
              child: ListView.builder(
                reverse: true,
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      _logs[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: _logs[index].contains('Error')
                            ? const Color(0xFF7A5CFF)
                            : const Color(0xFF4F8BFF),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(String label, IconData icon, Color color) {
    return ElevatedButton.icon(
      onPressed: _isConnected
          ? () => _sendResponse(label.toUpperCase().replaceAll(' ', '_'))
          : null,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
      ),
    );
  }
}
