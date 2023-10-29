import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:mboathoscope/controller/appDirectorySingleton.dart';
import 'package:mboathoscope/controller/helpers.dart';
import 'package:mboathoscope/views/widgets/alert_dialog_model.dart';
import 'package:simple_ripple_animation/simple_ripple_animation.dart';
import 'package:noise_meter/noise_meter.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/log.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';

class headerbtn extends StatefulWidget {
  const headerbtn({Key? key}) : super(key: key);

  @override
  State<headerbtn> createState() => _headerbtnState();
}
  NoiseMeter _noiseMeter = new NoiseMeter();
  StreamSubscription<NoiseReading>? _noiseSubscription;



class _headerbtnState extends State<headerbtn> {
  late final RecorderController recorderController;
  bool isRecordingCompleted = false;

  ///for time to determine whether to save or delete
  bool isRecording = false;

  ///for time to determine whether to show microphone or not
  late String path;
  static Directory appDirectory = AppDirectorySingleton().appDirectory;
  AppDirectorySingleton appDirectorySingleton = AppDirectorySingleton();
  String heartBeatFileFolderPath = AppDirectorySingleton.heartBeatParentPath;

  Future<void> simpleNoiseCancellation() async {
    // Load the recorded audio signal and noise profile
    final recordedSignal = await loadAudioFile(path);
    final noiseProfile = await loadAudioFile('noise_profile.wav');

    // Estimate the noise component from the noise profile
    final noiseComponent = calculateNoiseComponent(noiseProfile);

    // Perform noise cancellation
    final cleanedSignal = subtractNoiseComponent(recordedSignal, noiseComponent);

    // Save the cleaned signal to an output file
    await saveAudioFile('cleaned_audio.wav', cleanedSignal);
  }

  Future<List<double>> loadAudioFile(String filePath) async {
    final fileBytes = await rootBundle.load(filePath);
    final sampleSize = 2; // 16-bit = 2 bytes
    final audioData = fileBytes.buffer.asUint8List();
    final numSamples = audioData.length ~/ sampleSize;
    final audioSamples = List<double>.filled(numSamples, 0.0);

    for (var i = 0; i < numSamples; i++) {
      final sample = audioData.sublist(i * sampleSize, (i + 1) * sampleSize);
      final sampleValue = sample.buffer.asInt16List().single;
      audioSamples[i] = sampleValue / pow(2, 15);
    }

    return audioSamples;
  }

  double calculateNoiseComponent(List<double> noiseProfile) {
    final noiseSum = noiseProfile.reduce((a, b) => a + b);
    final noiseComponent = noiseSum / noiseProfile.length;
    return noiseComponent;
  }

  List<double> subtractNoiseComponent(List<double> recordedSignal, double noiseComponent) {
    final cleanedSignal = List<double>.filled(recordedSignal.length, 0.0);
    for (var i = 0; i < recordedSignal.length; i++) {
      cleanedSignal[i] = recordedSignal[i] - noiseComponent;
    }
    return cleanedSignal;
  }

  Future<void> saveAudioFile(String filePath, List<double> audioSamples) async {
    final sampleSize = 2; // 16-bit = 2 bytes
    final numSamples = audioSamples.length;
    final audioData = Uint8List(numSamples * sampleSize);

    for (var i = 0; i < numSamples; i++) {
      final sampleValue = (audioSamples[i] * pow(2, 15)).toInt();
      final sampleBytes = ByteData(sampleSize);
      sampleBytes.setInt16(0, sampleValue, Endian.little);
      audioData.setRange(i * sampleSize, (i + 1) * sampleSize, sampleBytes.buffer.asUint8List());
    }

    await writeToFile(filePath, audioData);
  }

  Future<void> writeToFile(String filePath, List<int> data) async {
    final file = await File(filePath).create(recursive: true);
    await file.writeAsBytes(data);
  }

  @override
  void initState() {
    _initialiseController();
    super.initState();
  }

  ///Initializes Recorder
  void _initialiseController() {
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 16000;
  }

  ///
  Widget recordBody() {

    if (isRecording) {
      ///recorderController.isRecording: could have used this but issuing stoprecorder doesn't change it state, will investigate why it doesn't refresh
      return InkWell(
        onTap: () {
          ///For Start or Stop Recording
          _startOrStopRecording();
        },
        child: SafeArea(

          child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: RippleAnimation(
                repeat: true,
                color: const Color(0xff3D79FD),
                minRadius: 65,
                ripplesCount: 6,
                child: const CircleAvatar(
                  maxRadius: 65.0,
                  backgroundColor: Colors.blueAccent,
                  child: Icon(
                    Icons.stop,
                    color: Colors.white,
                    size: 70.0,
                  ),
                ),
              )
          ),
        ),
      );
    } else {
      ///Applies when recording is completed and saved or start of the page
      return InkWell(
        child: CircleAvatar(
          maxRadius: 80.0,
          backgroundColor: Colors.white,
          child: Image.asset(
            'assets/images/img_record.png',
            height: 150,
            width: 150,
          ),
        ),
        onTap: () {
          ///Start or Stop Recording
          _startOrStopRecording();
        },
      );
    }
  }



  ///Starts and Stops Recorder
  _startOrStopRecording() async {
    helpers().checkForMicrophonePermission(recorderController);
    try {
      if (recorderController.isRecording) {
        recorderController.reset();

        // Stops recording and returns path, saves file automatically here
        recorderController.stop(false).then((value) async {
           String outputPath = await executeFFmpegCommand(path!);
          DialogUtils.showCustomDialog(
              context, title: 'title', path: outputPath);
          await simpleNoiseCancellation(); // Apply noise cancellation
        });

        setState(() {
          isRecording = !isRecording;
        });
        _noiseSubscription?.cancel();
      } else {
        path = "${appDirectory.path}/$heartBeatFileFolderPath${DateTime.now().millisecondsSinceEpoch}.mpeg4";

        _noiseSubscription = _noiseMeter.noise.listen((NoiseReading reading) {
          double noiseLevel = reading.meanDecibel;
        });
        await recorderController.record(path: path);

        setState(() {
          isRecording = !isRecording;
        });
      }
    } catch (error) {
      debugPrint(error.toString());
    }
  }
  Future<String> executeFFmpegCommand(String input) async {

    String path = '${appDirectory!.path}/${'audio_message'.substring(0, min('audio_message'.length, 100))}_${DateTime.now().millisecondsSinceEpoch.toString()}.aac';
    await FFmpegKit
        .execute(
        '-y -i $input -af "asplit[a][b],[a]adelay=32S|32S[a],[b][a]anlms=order=128:leakage=0.0005:mu=.5:out_mode=o" $path')
        .then((session) async{
      await session.getLogs().then((value) {
        for (Log i in value) {
          if (kDebugMode) {
            print(i.getMessage());
          }
        }
      });

      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        if (kDebugMode) {
          print("FFmpeg process completed successfully.");
        }
      } else if (ReturnCode.isCancel(returnCode)) {
        if (kDebugMode) {
          print("FFmpeg process cancelled.");
        }
        path = "";
      } else {
        if (kDebugMode) {
          print("FFmpeg process failed.");
        }
        path = "";
      }
    });
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 34.0, left: 20, right: 30),
          child: Row(
            children: <Widget>[

              Expanded(
                flex: 5,
                child: Image.asset(
                  'assets/images/img_head.png',
                  height: 80,
                  width: 80,
                ),
              ),

              const SizedBox(
                width: 150,
              ),

              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.only(top: 28.0),
                  child: Stack(
                    children: <Widget>[
                      Positioned(
                        child: Image.asset(
                          'assets/images/img_notiblack.png',
                          height: 35,
                          width: 32,
                          color: const Color(0xff3D79FD),
                        ),
                      ),

                      const Positioned(
                        bottom: 0.02,
                        right: 3,
                        child: CircleAvatar(
                          radius: 5,
                          backgroundColor: Color(0xff3D79FD),
                          foregroundColor: Colors.white,
                        ), //CircularAvatar
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 20,
        ),

        Padding(
          padding: const EdgeInsets.only(
            right: 8.0,
            left: 8.0,
            top: 20.0,
            bottom: 20.0,
          ),

          child: Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(
                    right: 8.0,
                    left: 8.0,
                    top: 20.0,
                    bottom: 7.0,
                  ),
                  child: recordBody(),
                ),
              )
            ],
          ),
        ),
        const Text(
          'Put phone Mic against your Sternum, 3 ribs down and press record',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
          ),
        ),
        const Padding(
          padding:
          EdgeInsets.only(top: 10.0, bottom: 8.0, left: 35.0, right: 35.0),
          child: Text(
            'Noise cancelation head phones would better increase sound quality',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: const [
            Padding(
              padding: EdgeInsets.only(left: 18.0, top: 17.0),
              child: Text(
                'Recordings',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
