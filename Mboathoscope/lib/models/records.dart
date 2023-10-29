
import 'dart:io';
import 'package:audio_waveforms/audio_waveforms.dart';
final String records = 'recordings';

class RFields{
  static final List<String> values = [
    id, pathname, filename, dateTime, audio
  ];
  static final String  id = 'id';
  static final String  pathname = 'pathname';
  static final String  filename = 'filename';
  static final String  dateTime = 'dateTime';
  static final String  audio = 'audio';
  static final String playerController = 'playerController';
}


class Recordings {

  String? id;
  final String pathname; // to save the path of memory location where the file is stored
  final String filename; // name of recording
  final DateTime dateTime; // date of recording    // time of recording
  // duration of recording
  final PlayerController? playerController;
  File audio;

  Recordings({
     this.id,
    required this.pathname,
    required this.filename,
    required this.dateTime,
    required this.audio,
    this.playerController,

  });

  Recordings copy( {
    String? id,
    String? pathname,
    String? filename,
    DateTime? dateTime,
    PlayerController? playerController,
    File? audio,

  }) =>
  Recordings(
      id: id ?? this.id,
      pathname: pathname ?? this.pathname,
      filename: filename ?? this.filename,
      dateTime: dateTime ?? this.dateTime,
      audio: audio ?? this.audio,
    playerController: playerController ?? this.playerController,
  );

  static Recordings fromJson(Map<String, Object?> json) =>
      Recordings(
          id: json[RFields.id] as String,
          pathname: json[RFields.pathname] as String,
          filename: json[RFields.filename] as String,
          dateTime: json[RFields.dateTime] as DateTime,
          audio: json[RFields.audio] as File,
          playerController: json[RFields.playerController] as PlayerController,
      );

  Map<String, Object?> toJson()=>{
    RFields.id: this.id,
    RFields.filename: this.filename,
    RFields.dateTime: this.dateTime.toIso8601String(),
    RFields.pathname: this.pathname,
    RFields.audio: this.audio,
    RFields.playerController: this.playerController
  };
}
