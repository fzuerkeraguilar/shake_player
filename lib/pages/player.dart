import 'package:flutter/foundation.dart';
import "package:flutter/material.dart";
import 'package:just_audio/just_audio.dart';
import "package:on_audio_query/on_audio_query.dart";
import 'package:google_fonts/google_fonts.dart';


class Player extends StatefulWidget {
  final SongModel initSongInfo;
  final Function initChangeTrack;
  final int initIndex;

  const Player({super.key, required this.initSongInfo, required this.initChangeTrack, required this.initIndex});

  @override
  PlayerState createState() => PlayerState();
}

class PlayerState extends State<Player> {
  final OnAudioQuery audioQuery = OnAudioQuery();
  final AudioPlayer audioPlayer = AudioPlayer();
  late SongModel songInfo;
  late int currentIndex;
  bool isPlaying = false;
  bool loop = false;

  @override
  void initState() {
    super.initState();
    songInfo = widget.initSongInfo;
    currentIndex = widget.initIndex;
    setSong(widget.initSongInfo);
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
      this.songInfo = songInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          songInfo.title,
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
            songInfo.title,
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
            songInfo.artist ?? "Unknown Artist",
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
                  widget.initChangeTrack(false);
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
                  widget.initChangeTrack(true);
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