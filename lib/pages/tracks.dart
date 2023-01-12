import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shake_player/pages/player.dart';
import 'package:shake_player/utils/ble-gyroscope.dart';

class Tracks extends StatefulWidget {
  const Tracks({super.key});

  @override
  TracksState createState() => TracksState();
}

class TracksState extends State<Tracks> {
  final OnAudioQuery audioQuery = OnAudioQuery();
  GlobalKey<BLEGyroscopeState> bleGyroscopeKey = GlobalKey<BLEGyroscopeState>();
  late BLEGyroscope bleGyroscope = BLEGyroscope(key: bleGyroscopeKey);
  List<SongModel> songs = [];
  int currentIndex = 0;
  final GlobalKey<PlayerState> playerKey = GlobalKey<PlayerState>();

  @override
  void initState() {
    super.initState();
    getTracks();
  }

  void getTracks() async {
    await audioQuery.permissionsRequest();
    audioQuery.querySongs().then((value) {
      setState(() {
        songs = value;
      });
    });
  }

  void changeTrack(bool forward) {
    if (forward) {
      if (currentIndex != songs.length - 1) currentIndex++;
    } else if (currentIndex != 0) {
      currentIndex--;
    }
    playerKey.currentState?.setSong(songs[currentIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: Scrollbar(
        child: ListView.separated(
            separatorBuilder: (context, index) => const Divider(),
            itemCount: songs.length,
            itemBuilder: (ctx, i) {
              return FutureBuilder(
                future: audioQuery.queryArtwork(songs[i].id, ArtworkType.AUDIO),
                builder: (ctx, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                      return const Center(child: CircularProgressIndicator());
                    default:
                      if (snapshot.hasError) {
                        return const Center(child: Text("Error"));
                      } else {
                        return ListTile(
                          leading: CircleAvatar(
                              backgroundImage: snapshot.data == null
                                  ? const AssetImage('assets/images/icon.png')
                                  : Image.memory(snapshot.data as Uint8List)
                                      .image),
                          title: Text(
                            songs[i].title,
                            style: GoogleFonts.poppins(
                              textStyle: const TextStyle(
                                color: Colors.black,
                              ),
                            ),
                          ),
                          subtitle: Text(
                            songs[i].artist ?? "Unknown Artist",
                            style: GoogleFonts.poppins(
                              textStyle: const TextStyle(
                                color: Colors.black,
                              ),
                            ),
                          ),
                          onTap: () {
                            currentIndex = i;
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => Player(
                                  initSongInfo: songs[i],
                                  changeTrack: changeTrack,
                                  initIndex: currentIndex,
                                  key: playerKey,
                                  shakeStream: bleGyroscopeKey.currentState
                                          ?.simpleShakeStream(35, 1000) ??
                                      const Stream.empty(),
                                ),
                              ),
                            );
                          },
                        );
                      }
                  }
                },
              );
            }),
      ),
      floatingActionButton: bleGyroscope,
    );
  }

  AppBar _appBar() {
    return AppBar(
      title: Text(
        "SHAKE player",
        style: GoogleFonts.poppins(
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      backgroundColor: Colors.indigo[900],
      centerTitle: true,
      elevation: 0,
    );
  }
}
