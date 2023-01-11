import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/foundation.dart';
import "package:flutter/material.dart";
import 'package:just_audio/just_audio.dart';
import "package:on_audio_query/on_audio_query.dart";
import 'package:google_fonts/google_fonts.dart';


class Player extends StatefulWidget {
  final SongModel initSongInfo;
  final Function changeTrack;
  final int initIndex;
  final Stream<bool> shakeStream;

  const Player({super.key, required this.initSongInfo, required this.changeTrack, required this.initIndex, required this.shakeStream});

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
    widget.shakeStream.listen((event) {
      if(event){
        togglePlayPause();
      }
    });
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

  void togglePlayPause() {
    if (isPlaying) {
      audioPlayer.pause();
    } else {
      audioPlayer.play();
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  FutureBuilder<Uint8List?> _extractArtwork(SongModel songInfo) {
    return FutureBuilder(
      future: audioQuery.queryArtwork(songInfo.id, ArtworkType.AUDIO),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: Image.memory(snapshot.data!).image,
                fit: BoxFit.cover,
              ),
            ),
          );
        } else {
          return Container(
            width: 200,
            height: 200,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage('assets/images/icon.png'),
                fit: BoxFit.cover,
              ),
            ),
          );
        }
      },
    );
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
            child: _extractArtwork(songInfo),
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
          AudioProgressBar(audioPlayer: audioPlayer),
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
                onPressed: togglePlayPause,
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

class AudioProgressBar extends StatelessWidget {
  const AudioProgressBar({
    Key? key,
    required this.audioPlayer,
  }) : super(key: key);

  final AudioPlayer audioPlayer;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
      child:StreamBuilder<Duration?>(
        stream: audioPlayer.durationStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var duration = snapshot.data!;
            return StreamBuilder<Duration>(
              stream: audioPlayer.positionStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var position = snapshot.data!;
                  return StreamBuilder<Duration>(
                    stream: audioPlayer.bufferedPositionStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        var bufferedPosition = snapshot.data!;
                        return ProgressBar(
                          progress: position,
                          buffered: bufferedPosition,
                          total: duration,
                          onSeek: (duration) {
                            audioPlayer.seek(duration);
                          },
                        );
                      } else {
                        return ProgressBar(
                          progress: position,
                          total: duration,
                          onSeek: (value) {
                          audioPlayer.seek(value);
                          }
                        );
                      }
                    },
                  );
                } else {
                  return const ProgressBar(progress: Duration.zero, total: Duration.zero);
                }
              },
            );
          } else {
            return const ProgressBar(progress: Duration.zero, total: Duration.zero);
          }
        },
      )
    );
  }
}