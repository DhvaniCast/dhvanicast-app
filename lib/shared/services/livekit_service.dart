import 'package:livekit_client/livekit_client.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';

class LiveKitService {
  Room? _room;
  LocalAudioTrack? _audioTrack;
  bool _isMuted = true;
  bool _isConnected = false;
  String? _currentFrequencyId;
  String? _token;

  bool get isMuted => _isMuted;
  bool get isConnected => _isConnected;

  /// Connect to LiveKit room for a frequency
  Future<void> connectToFrequency(
    String frequencyId,
    String userName,
    String authToken,
  ) async {
    try {
      print('🎙️ [LiveKit] Connecting to frequency: $frequencyId');
      print('👤 [LiveKit] User: $userName');

      // Get LiveKit token from backend
      final tokenData = await _getToken(frequencyId, userName, authToken);

      if (tokenData == null) {
        print('❌ [LiveKit] Failed to get token');
        return;
      }

      print('📦 [LiveKit] Token data: $tokenData');
      print('📦 [LiveKit] Token data type: ${tokenData.runtimeType}');
      print('📦 [LiveKit] URL type: ${tokenData['url'].runtimeType}');
      print('📦 [LiveKit] Token type: ${tokenData['token'].runtimeType}');

      final livekitUrl = tokenData['url'] as String;
      final livekitToken = tokenData['token'] as String;

      print('🔗 [LiveKit] Server URL: $livekitUrl');
      print('🎫 [LiveKit] Token received');

      // Create room instance with proper audio settings
      _room = Room(
        roomOptions: const RoomOptions(
          // Audio publishing options
          defaultAudioPublishOptions: AudioPublishOptions(
            name: 'microphone',
            dtx: false, // Disable discontinuous transmission for better audio
          ),
          // Audio capture options
          defaultAudioCaptureOptions: AudioCaptureOptions(
            noiseSuppression: true,
            echoCancellation: true,
            autoGainControl: true,
          ),
          // Critical: Enable auto-subscription for remote tracks
          defaultVideoPublishOptions: VideoPublishOptions(),
          adaptiveStream: true,
          dynacast: true,
        ),
      );

      // Setup event listeners before connecting
      _setupListeners();

      // Connect to LiveKit room
      await _room!.connect(livekitUrl, livekitToken);

      print('✅ [LiveKit] Connected to room');

      // Wait a moment for room state to settle
      await Future.delayed(const Duration(milliseconds: 500));

      // List current participants
      print(
        '👥 [LiveKit] Current participants: ${_room!.remoteParticipants.length}',
      );
      if (_room!.remoteParticipants.isNotEmpty) {
        for (var participant in _room!.remoteParticipants.values) {
          print('   - ${participant.name} (${participant.identity})');
        }
      }

      // Create and publish audio track (start unmuted for radio communication)
      print('🎤 [LiveKit] Creating audio track...');
      _audioTrack = await LocalAudioTrack.create(
        const AudioCaptureOptions(
          noiseSuppression: true,
          echoCancellation: true,
          autoGainControl: true,
        ),
      );
      print('✅ [LiveKit] Audio track created');

      // Publish the track
      print('📡 [LiveKit] Publishing audio track...');
      await _room?.localParticipant?.publishAudioTrack(_audioTrack!);
      print('✅ [LiveKit] Audio track published');

      // Start unmuted for radio communication
      print('🔊 [LiveKit] Unmuting microphone...');
      await _audioTrack!.unmute();
      _isMuted = false;
      _isConnected = true;
      _currentFrequencyId = frequencyId;

      print(
        '✅ [LiveKit] Audio track created, published and UNMUTED (ready to talk)',
      );
      print('🎤 [LiveKit] Microphone is ACTIVE and ready');
      print('🔊 [LiveKit] You can now speak and others will hear you');
      print(
        '👥 [LiveKit] Remote participants: ${_room!.remoteParticipants.length}',
      );
    } catch (e, stackTrace) {
      print('❌ [LiveKit] Connection error: $e');
      print('📍 [LiveKit] Stack trace: $stackTrace');
      _isConnected = false;

      // Cleanup on error
      if (_audioTrack != null) {
        try {
          await _audioTrack!.stop();
          await _audioTrack!.dispose();
          _audioTrack = null;
        } catch (cleanupError) {
          print('⚠️ [LiveKit] Cleanup error: $cleanupError');
        }
      }

      if (_room != null) {
        try {
          await _room!.disconnect();
          await _room!.dispose();
          _room = null;
        } catch (cleanupError) {
          print('⚠️ [LiveKit] Room cleanup error: $cleanupError');
        }
      }

      // Rethrow to notify caller
      rethrow;
    }
  }

  /// Get LiveKit token from backend
  Future<Map<String, dynamic>?> _getToken(
    String frequencyId,
    String userName,
    String authToken,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/livekit/token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'frequencyId': frequencyId,
          'participantName': userName,
        }),
      );

      print('📡 [LiveKit Token] Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📡 [LiveKit Token] Full response: $data');
        print('📡 [LiveKit Token] Success: ${data['success']}');
        print('📡 [LiveKit Token] Data: ${data['data']}');

        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>;
        }
      }

      print('❌ [LiveKit Token] Failed: ${response.body}');
      return null;
    } catch (e) {
      print('❌ [LiveKit Token] Error: $e');
      return null;
    }
  }

  /// Setup LiveKit event listeners
  void _setupListeners() {
    // Listen to room events using the EventsEmitter pattern
    _room?.createListener().on<RoomEvent>((event) {
      print('🔄 [LiveKit] Room event: ${event.runtimeType}');

      if (event is ParticipantConnectedEvent) {
        print('👤 [LiveKit] ✅ Participant joined: ${event.participant.name}');
        print(
          '👥 [LiveKit] Total participants now: ${_room!.remoteParticipants.length + 1}',
        );

        // Explicitly subscribe to remote participant's audio tracks
        _subscribeToParticipant(event.participant);
      } else if (event is ParticipantDisconnectedEvent) {
        print('👋 [LiveKit] ❌ Participant left: ${event.participant.name}');
        print(
          '👥 [LiveKit] Total participants now: ${_room!.remoteParticipants.length + 1}',
        );
      } else if (event is TrackSubscribedEvent) {
        if (event.track is RemoteAudioTrack) {
          print(
            '🔊 [LiveKit] ✅ Receiving audio from: ${event.participant.name}',
          );
          print('📡 [LiveKit] You should now hear ${event.participant.name}');

          // Enable the audio track explicitly
          final audioTrack = event.track as RemoteAudioTrack;
          audioTrack.enable();
          print('🔊 [LiveKit] Audio track enabled for playback');
        }
      } else if (event is TrackUnsubscribedEvent) {
        if (event.track is RemoteAudioTrack) {
          print('🔇 [LiveKit] ❌ Audio stopped from: ${event.participant.name}');
        }
      } else if (event is TrackMutedEvent) {
        print('🔇 [LiveKit] ${event.participant.name} muted their mic');
      } else if (event is TrackUnmutedEvent) {
        print('🔊 [LiveKit] ${event.participant.name} unmuted their mic');
      } else if (event is TrackPublishedEvent) {
        print('📡 [LiveKit] ${event.participant.name} published a track');

        // When a remote user publishes a track, subscribe to it
        if (event.publication.kind == TrackType.AUDIO) {
          print('🎤 [LiveKit] Audio track published, subscribing...');
        }
      } else if (event is LocalTrackPublishedEvent) {
        print('✅ [LiveKit] Your audio track is now published and broadcasting');
      }
    });

    // Subscribe to existing participants' tracks
    _subscribeToExistingParticipants();
  }

  /// Subscribe to a participant's audio tracks
  void _subscribeToParticipant(RemoteParticipant participant) {
    print('🔗 [LiveKit] Subscribing to ${participant.name}\'s tracks...');

    // Subscribe to all audio publications
    for (var publication in participant.audioTrackPublications) {
      if (publication.track != null && publication.track is RemoteAudioTrack) {
        final audioTrack = publication.track as RemoteAudioTrack;
        audioTrack.enable();
        print('🔊 [LiveKit] Enabled audio from ${participant.name}');
      } else if (!publication.subscribed) {
        // Try to subscribe if not already subscribed
        print(
          '📡 [LiveKit] Attempting to subscribe to ${participant.name}\'s audio',
        );
      }
    }
  }

  /// Subscribe to existing participants when joining
  void _subscribeToExistingParticipants() {
    if (_room == null) return;

    print('👥 [LiveKit] Checking existing participants...');
    for (var participant in _room!.remoteParticipants.values) {
      print('👤 [LiveKit] Found existing participant: ${participant.name}');
      _subscribeToParticipant(participant);
    }
  }

  /// Toggle microphone mute/unmute
  Future<void> toggleMute() async {
    if (!_isConnected || _audioTrack == null) {
      print('⚠️ [LiveKit] Cannot toggle - not connected');
      return;
    }

    try {
      _isMuted = !_isMuted;

      if (_isMuted) {
        // Mute the track
        await _audioTrack!.mute();
        print('🔇 [LiveKit] Microphone muted');
      } else {
        // Unmute the track
        await _audioTrack!.unmute();
        print('🔊 [LiveKit] Microphone unmuted');
      }

      print('🎤 [LiveKit] Mute state: $_isMuted');
    } catch (e) {
      print('❌ [LiveKit] Toggle mute error: $e');
      // Revert the state if there was an error
      _isMuted = !_isMuted;
    }
  }

  /// Set speaker phone mode (loudspeaker vs earpiece)
  Future<void> setSpeakerPhone(bool enabled) async {
    try {
      // Use Hardware API to control speaker phone
      await Hardware.instance.setSpeakerphoneOn(enabled);
      print(
        '🔊 [LiveKit] Speaker phone ${enabled ? 'enabled (loudspeaker)' : 'disabled (earpiece)'}',
      );
    } catch (e) {
      print('❌ [LiveKit] Set speaker phone error: $e');
    }
  }

  /// Disconnect from LiveKit
  Future<void> disconnect() async {
    try {
      print('👋 [LiveKit] Disconnecting...');

      if (_audioTrack != null) {
        await _audioTrack!.stop();
        await _audioTrack!.dispose();
        _audioTrack = null;
      }

      if (_room != null) {
        await _room!.disconnect();
        await _room!.dispose();
        _room = null;
      }

      _isConnected = false;
      _isMuted = true;
      _currentFrequencyId = null;

      print('✅ [LiveKit] Disconnected');
    } catch (e) {
      print('❌ [LiveKit] Disconnect error: $e');
    }
  }

  /// Get list of participants in room
  List<String> getParticipants() {
    if (_room == null) return [];

    return _room!.remoteParticipants.values.map((p) => p.identity).toList();
  }

  /// Dispose resources
  Future<void> dispose() async {
    await disconnect();
  }
}
