import "package:flutter/material.dart";
import 'package:just_audio/just_audio.dart';
import "package:on_audio_query/on_audio_query.dart";
import 'package:google_fonts/google_fonts.dart';


class Player extends StatefulWidget {
  SongModel songInfo;
  final Function changeTrack;
  final GlobalKey<PlayerState> key;
  int currentIndex = 0;

  Player({required this.songInfo, required this.changeTrack, required this.key});

  @override
  PlayerState createState() => PlayerState();
}

class PlayerState extends State<Player> {
  final AudioPlayer audioPlayer = AudioPlayer();

  setSong(SongModel songInfo) async {
    await audioPlayer.setUrl(songInfo.data);
    setState(() {
      widget.songInfo = songInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
  
}