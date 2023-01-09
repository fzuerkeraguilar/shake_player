import 'package:flutter/material.dart';
import "package:shake_player/pages/tracks.dart";

void main() {
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
