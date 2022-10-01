// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:flutter_application_2/pages/home.dart';
import 'package:flutter_application_2/pages/overlay.dart';
import 'dart:async';
import 'dart:convert';
import 'package:sound_stream/sound_stream.dart';
import 'package:web_socket_channel/io.dart';
import 'package:permission_handler/permission_handler.dart';

const serverUrl =
    'wss://api.deepgram.com/v1/listen?encoding=linear16&sample_rate=16000&language=en-GB';
const apiKey = '9cb8f512a08470fc29cbed96d81ca4ba601c72ba';

//import './pages/overlay.dart';

void main() {
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<void> _initStream() async {
    channel = IOWebSocketChannel.connect(Uri.parse(serverUrl),
        headers: {'Authorization': 'Token $apiKey'});

    channel.stream.listen((event) async {
      final parsedJson = jsonDecode(event);

      updateText(parsedJson['channel']['alternatives'][0]['transcript']);
    });

    _audioStream = _recorder.audioStream.listen((data) {
      channel.sink.add(data);
    });

    _recorderStatus = _recorder.status.listen((status) {
      if (mounted) {
        setState(() {});
      }
    });

    await Future.wait([
      _recorder.initialize(),
    ]);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance?.addPostFrameCallback(onLayoutDone);
  }

  void _startRecord() async {
    resetText();
    _initStream();

    await _recorder.start();

    setState(() {});
  }

  void _stopRecord() async {
    await _recorder.stop();

    setState(() {});
  }

  void onLayoutDone(Duration timeStamp) async {
    await Permission.microphone.request();
    setState(() {});
  }

  @override
  void dispose() {
    _recorderStatus.cancel();
    _audioStream.cancel();
    channel.sink.close();

    super.dispose();
  }

  @override
  String myText = "To start transcribing your voice, press start.";
  final RecorderStream _recorder = RecorderStream();

  late StreamSubscription _recorderStatus;
  late StreamSubscription _audioStream;

  late IOWebSocketChannel channel;
  void updateText(newText) {
    setState(() {
      myText = myText + ' ' + newText;
    });
  }

  void resetText() {
    setState(() {
      myText = '';
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Live Transcription with Deepgram'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    width: 150,
                    child: Text(
                      myText,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 50,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  OutlinedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.blue),
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.white),
                    ),
                    onPressed: () {
                      updateText('');

                      _startRecord();
                    },
                    child: const Text('Start', style: TextStyle(fontSize: 30)),
                  ),
                  const SizedBox(width: 5),
                  OutlinedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.red),
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.white),
                    ),
                    onPressed: () {
                      _stopRecord();
                    },
                    child: const Text('Stop', style: TextStyle(fontSize: 30)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
