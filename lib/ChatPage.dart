import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class ChatPage extends StatefulWidget {
  final BluetoothDevice server;

  ChatPage({Key? key, required this.server}) : super(key: key);

  static final clientID = 0;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  BluetoothConnection? connection;

  List<_Message> messages = List<_Message>.empty(growable: true);

  String _messageBuffer = '';

  bool isConnecting = true;
  bool isLightOn = false;
  bool isCarrierUp = false;
  bool isMovingForward = false;
  bool isMovingBackward = false;

  bool get isConnected => (connection?.isConnected ?? false);

  bool isDisconnecting = false;

  @override
  void initState() {
    super.initState();

    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection!.input!.listen((Uint8List data) => data).onDone(() {
        // Example: Detect which side closed the connection
        // There should be `isDisconnecting` flag to show are we are (locally)
        // in middle of disconnecting process, should be set before calling
        // `dispose`, `finish` or `close`, which all causes to disconnect.
        // If we except the disconnection, `onDone` should be fired as result.
        // If we didn't except this (no flag set), it means closing by remote.
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serverName = widget.server.name ?? "Unknown";

    void _sendMessage(String text) async {
      text = text.trim();

      if (text.length > 0) {
        try {
          connection!.output
              .add(Uint8List.fromList(utf8.encode(text + "\r\n")));
          await connection!.output.allSent;
        } catch (e) {
          // Ignore error, but notify state
          setState(() {});
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: (isConnecting
            ? Text('Connecting chat to ' + serverName + '...')
            : isConnected
                ? Text('Live chat with ' + serverName)
                : Text('Chat log with ' + serverName)),
      ),
      body: SafeArea(
        child: Container(
          margin: EdgeInsets.only(top: 100),
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  _sendMessage('f');
                  setState(() {
                    isMovingForward = true;
                    isMovingBackward = false;
                  });
                },
                style: ButtonStyle(
                  shape: MaterialStateProperty.all(CircleBorder()),
                  padding: MaterialStateProperty.all(EdgeInsets.all(25)),
                  backgroundColor: isMovingForward
                      ? MaterialStateProperty.all(Colors.red)
                      : MaterialStateProperty.all(
                          Colors.blue), // <-- Button color
                  overlayColor:
                      MaterialStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(MaterialState.pressed))
                      return Colors.red; // <-- Splash color
                  }),
                ),
                child: const Icon(
                  Icons.expand_less,
                  color: Colors.white,
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(vertical: 10),
                child: ElevatedButton(
                  onPressed: () {
                    _sendMessage('s');
                    setState(() {
                      isMovingBackward = false;
                      isMovingForward = false;
                    });
                  },
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all(CircleBorder()),
                    padding: MaterialStateProperty.all(EdgeInsets.all(25)),
                    backgroundColor: !isMovingBackward & !isMovingForward
                        ? MaterialStateProperty.all(Colors.red)
                        : MaterialStateProperty.all(
                            Colors.blue), // <-- Button color
                    overlayColor:
                        MaterialStateProperty.resolveWith<Color?>((states) {
                      if (states.contains(MaterialState.pressed))
                        return Colors.red; // <-- Splash color
                    }),
                  ),
                  child: const Icon(
                    Icons.stop,
                    color: Colors.white,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _sendMessage('b');
                  setState(() {
                    isMovingBackward = true;
                    isMovingForward = false;
                  });
                },
                style: ButtonStyle(
                  shape: MaterialStateProperty.all(CircleBorder()),
                  padding: MaterialStateProperty.all(EdgeInsets.all(25)),
                  backgroundColor: isMovingBackward
                      ? MaterialStateProperty.all(Colors.red)
                      : MaterialStateProperty.all(
                          Colors.blue), // <-- Button color
                  overlayColor:
                      MaterialStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(MaterialState.pressed))
                      return Colors.red; // <-- Splash color
                  }),
                ),
                child: const Icon(
                  Icons.expand_more,
                  color: Colors.white,
                ),
              ),
              Divider(),
              ElevatedButton(
                onPressed: () {
                  if (isLightOn) {
                    _sendMessage('o');
                    setState(() {
                      isLightOn = false;
                    });
                  } else {
                    _sendMessage('n');
                    setState(() {
                      isLightOn = true;
                    });
                  }
                },
                style: ButtonStyle(
                  shape: MaterialStateProperty.all(CircleBorder()),
                  padding: MaterialStateProperty.all(EdgeInsets.all(25)),
                  backgroundColor: MaterialStateProperty.all(
                      Colors.blue), // <-- Button color
                  overlayColor:
                      MaterialStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(MaterialState.pressed))
                      return Colors.red; // <-- Splash color
                  }),
                ),
                child: Icon(
                  isLightOn ? Icons.highlight : Icons.flashlight_on,
                  color: Colors.white,
                ),
              ),
              Divider(),
              ElevatedButton(
                onPressed: () {
                  if (isCarrierUp) {
                    _sendMessage('d');
                    setState(() {
                      isCarrierUp = false;
                    });
                  } else {
                    _sendMessage('u');
                    setState(() {
                      isCarrierUp = true;
                    });
                  }
                },
                style: ButtonStyle(
                  shape: MaterialStateProperty.all(CircleBorder()),
                  padding: MaterialStateProperty.all(EdgeInsets.all(25)),
                  backgroundColor: MaterialStateProperty.all(
                      Colors.blue), // <-- Button color
                  overlayColor:
                      MaterialStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(MaterialState.pressed))
                      return Colors.red; // <-- Splash color
                  }),
                ),
                child: Icon(
                  isCarrierUp
                      ? Icons.keyboard_double_arrow_down
                      : Icons.keyboard_double_arrow_up,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
