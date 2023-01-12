import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import "package:shake_player/pages/tracks.dart";

Future<void> main() async {
  await JustAudioBackground.init(
    androidNotificationChannelId: 'edu.kit.informatik.shake_player.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  runApp(
    MaterialApp(
      title: 'SHAKE Player',
      initialRoute: '/home',
      routes: {
        '/home': (context) => const Tracks(),
      },
    ),
  );
}
