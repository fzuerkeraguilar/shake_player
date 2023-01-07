import 'package:flutter/foundation.dart';
import "package:flutter/material.dart";
import 'package:just_audio/just_audio.dart';
import "package:on_audio_query/on_audio_query.dart";
import 'package:google_fonts/google_fonts.dart';


class Player extends StatefulWidget {
  SongModel songInfo;
  final Function changeTrack;
  int currentIndex;
final GlobalKey<PlayerState> key;

  Player({required this.songInfo, required this.changeTrack, required this.currentIndex, required this.key});

  @override
  PlayerState createState() => PlayerState();
}

class PlayerState extends State<Player> {
  final OnAudioQuery audioQuery = OnAudioQuery();
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;
  bool loop = false;

  @override
  void initState() {
    super.initState();
    setSong(widget.songInfo);
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  setSong(SongModel songInfo) async {
    if (kDebugMode) {
      print(songInfo.uri);
    }
    await audioPlayer.setUrl(songInfo.uri ?? "");
    setState(() {
      widget.songInfo = songInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.songInfo.title,
          style: GoogleFonts.poppins(
            textStyle: const TextStyle(
              color: Colors.black,
            ),
          ),
        ),
        backgroundColor: Colors.indigo[50],
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  //TODO: Add album artwork
                  image: AssetImage('assets/images/icon.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            widget.songInfo.title,
            style: GoogleFonts.poppins(
              textStyle: const TextStyle(
                color: Colors.black,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            widget.songInfo.artist ?? "Unknown Artist",
            style: GoogleFonts.poppins(
              textStyle: const TextStyle(
                color: Colors.black,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  widget.changeTrack(false);
                },
                icon: const Icon(
                  Icons.skip_previous,
                  color: Colors.black,
                ),
              ),
              IconButton(
                onPressed: () {
                  if (isPlaying) {
                    audioPlayer.pause();
                  } else {
                    audioPlayer.play();
                  }
                  setState(() {
                    isPlaying = !isPlaying;
                  });
                },
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.black,
                ),
              ),
              IconButton(
                onPressed: () {
                  widget.changeTrack(true);
                },
                icon: const Icon(
                  Icons.skip_next,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    loop = !loop;
                  });
                  audioPlayer.setLoopMode(loop ? LoopMode.one : LoopMode.off);
                },
                icon:Icon(loop ? Icons.repeat_one : Icons.repeat, color: Colors.black),
              ),
              IconButton(
                onPressed: () {
                  audioPlayer.seek(Duration.zero);
                },
                icon: const Icon(
                  Icons.replay,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}