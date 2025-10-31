import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService extends ChangeNotifier {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  double _recordingVolume = 0.0;
  double _playbackVolume = 1.0;
  Duration _recordingDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;
  Duration _playbackDuration = Duration.zero;
  String? _currentRecordingPath;
  Timer? _recordingTimer;

  // Getters
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  double get recordingVolume => _recordingVolume;
  double get playbackVolume => _playbackVolume;
  Duration get recordingDuration => _recordingDuration;
  Duration get playbackPosition => _playbackPosition;
  Duration get playbackDuration => _playbackDuration;
  String? get currentRecordingPath => _currentRecordingPath;

  AudioService() {
    _initializePlayer();
  }

  void _initializePlayer() {
    _player.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    _player.onPositionChanged.listen((position) {
      _playbackPosition = position;
      notifyListeners();
    });

    _player.onDurationChanged.listen((duration) {
      _playbackDuration = duration;
      notifyListeners();
    });
  }

  /// Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        print('✅ Microphone permission granted');
        return true;
      } else if (status.isPermanentlyDenied) {
        print('❌ Microphone permission permanently denied');
        openAppSettings();
        return false;
      } else {
        print('❌ Microphone permission denied');
        return false;
      }
    } catch (e) {
      print('❌ Error requesting microphone permission: $e');
      return false;
    }
  }

  /// Start recording audio
  Future<bool> startRecording() async {
    try {
      if (_isRecording) {
        print('⚠️ Already recording');
        return false;
      }

      // Request permission
      final hasPermission = await requestMicrophonePermission();
      if (!hasPermission) {
        return false;
      }

      // Check if recorder is available
      if (!await _recorder.hasPermission()) {
        print('❌ No permission to record');
        return false;
      }

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/audio_$timestamp.m4a';

      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      _recordingDuration = Duration.zero;

      // Start recording timer
      _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (
        timer,
      ) async {
        final amplitude = await _recorder.getAmplitude();
        _recordingVolume = amplitude.current.clamp(0.0, 1.0);
        _recordingDuration = Duration(milliseconds: timer.tick * 100);
        notifyListeners();
      });

      print('🎤 Recording started: $_currentRecordingPath');
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error starting recording: $e');
      _isRecording = false;
      notifyListeners();
      return false;
    }
  }

  /// Stop recording audio
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        print('⚠️ Not recording');
        return null;
      }

      final path = await _recorder.stop();
      _recordingTimer?.cancel();
      _recordingTimer = null;
      _isRecording = false;
      _recordingVolume = 0.0;

      print('🎤 Recording stopped: $path');
      notifyListeners();
      return path;
    } catch (e) {
      print('❌ Error stopping recording: $e');
      _isRecording = false;
      notifyListeners();
      return null;
    }
  }

  /// Cancel recording
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _recordingTimer?.cancel();
        _recordingTimer = null;
        _isRecording = false;
        _recordingVolume = 0.0;

        // Delete the recording file
        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }

        _currentRecordingPath = null;
        print('🎤 Recording cancelled');
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error cancelling recording: $e');
    }
  }

  /// Play audio from path
  Future<bool> playAudio(String path) async {
    try {
      await _player.stop();
      await _player.play(DeviceFileSource(path));
      print('▶️ Playing audio: $path');
      return true;
    } catch (e) {
      print('❌ Error playing audio: $e');
      return false;
    }
  }

  /// Play audio from URL
  Future<bool> playAudioUrl(String url) async {
    try {
      await _player.stop();
      await _player.play(UrlSource(url));
      print('▶️ Playing audio from URL: $url');
      return true;
    } catch (e) {
      print('❌ Error playing audio URL: $e');
      return false;
    }
  }

  /// Pause playback
  Future<void> pausePlayback() async {
    try {
      await _player.pause();
      print('⏸️ Playback paused');
    } catch (e) {
      print('❌ Error pausing playback: $e');
    }
  }

  /// Resume playback
  Future<void> resumePlayback() async {
    try {
      await _player.resume();
      print('▶️ Playback resumed');
    } catch (e) {
      print('❌ Error resuming playback: $e');
    }
  }

  /// Stop playback
  Future<void> stopPlayback() async {
    try {
      await _player.stop();
      _playbackPosition = Duration.zero;
      print('⏹️ Playback stopped');
      notifyListeners();
    } catch (e) {
      print('❌ Error stopping playback: $e');
    }
  }

  /// Set playback volume (0.0 to 1.0)
  Future<void> setPlaybackVolume(double volume) async {
    try {
      _playbackVolume = volume.clamp(0.0, 1.0);
      await _player.setVolume(_playbackVolume);
      notifyListeners();
    } catch (e) {
      print('❌ Error setting volume: $e');
    }
  }

  /// Seek to position
  Future<void> seekTo(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      print('❌ Error seeking: $e');
    }
  }

  /// Get audio file size in bytes
  Future<int> getAudioFileSize(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      print('❌ Error getting file size: $e');
      return 0;
    }
  }

  /// Get audio file as bytes (for upload)
  Future<List<int>?> getAudioBytes(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      print('❌ Error reading audio bytes: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }
}
