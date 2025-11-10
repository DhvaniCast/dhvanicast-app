import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../core/websocket_client.dart';

class WebRTCService extends ChangeNotifier {
  static final WebRTCService _instance = WebRTCService._internal();
  factory WebRTCService() => _instance;
  WebRTCService._internal();

  final WebSocketClient _socketClient = WebSocketClient();
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, MediaStream> _remoteStreams = {};
  
  MediaStream? _localStream;
  String? _currentFrequencyId;
  final Map<String, Map<String, dynamic>> _connectedUsers = {};
  bool _isMuted = false;

  // STUN/TURN Configuration - See COTURN_SETUP_GUIDE.md
  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      // Free STUN servers
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
    'iceTransportPolicy': 'all',
    'iceCandidatePoolSize': 10,
  };

  final Map<String, dynamic> _pcConstraints = {
    'mandatory': {},
    'optional': [{'DtlsSrtpKeyAgreement': true}],
  };

  final Map<String, dynamic> _mediaConstraints = {
    'audio': {'echoCancellation': true, 'noiseSuppression': true, 'autoGainControl': true},
    'video': false,
  };

  bool get isMuted => _isMuted;
  String? get currentFrequencyId => _currentFrequencyId;
  Map<String, Map<String, dynamic>> get connectedUsers => _connectedUsers;
  int get connectedUsersCount => _connectedUsers.length;
  bool get isInCall => _currentFrequencyId != null && _localStream != null;

  Future<void> initializeForFrequency(String frequencyId, String userId) async {
    _currentFrequencyId = frequencyId;
    await _initializeLocalStream();
    _setupSignalingListeners(userId);
    _socketClient.socket?.emit('webrtc_ready', {'frequencyId': frequencyId, 'userId': userId});
    notifyListeners();
  }

  Future<void> _initializeLocalStream() async {
    _localStream = await navigator.mediaDevices.getUserMedia(_mediaConstraints);
  }

  void _setupSignalingListeners(String myUserId) {
    _socketClient.socket?.on('user_joined_frequency', (data) async {
      final userId = data['userId'] as String?;
      if (userId != null && userId != myUserId) {
        _connectedUsers[userId] = data['userInfo'] as Map<String, dynamic>? ?? {};
        notifyListeners();
        await _createOffer(userId);
      }
    });

    _socketClient.socket?.on('user_left_frequency', (data) {
      final userId = data['userId'] as String?;
      if (userId != null) {
        _closePeerConnection(userId);
        _connectedUsers.remove(userId);
        notifyListeners();
      }
    });

    _socketClient.socket?.on('webrtc_offer', (data) async {
      await _handleOffer(data['from'] as String, data['offer'] as Map<String, dynamic>);
    });

    _socketClient.socket?.on('webrtc_answer', (data) async {
      await _handleAnswer(data['from'] as String, data['answer'] as Map<String, dynamic>);
    });

    _socketClient.socket?.on('webrtc_ice_candidate', (data) async {
      await _handleIceCandidate(data['from'] as String, data['candidate'] as Map<String, dynamic>);
    });

    _socketClient.socket?.on('frequency_users', (data) async {
      final users = data['users'] as List<dynamic>?;
      if (users != null) {
        for (var user in users) {
          final userId = user['userId'] as String?;
          if (userId != null && userId != myUserId) {
            _connectedUsers[userId] = user['userInfo'] as Map<String, dynamic>? ?? {};
            await _createOffer(userId);
          }
        }
        notifyListeners();
      }
    });
  }

  Future<RTCPeerConnection> _createPeerConnection(String userId) async {
    final pc = await createPeerConnection(_iceServers, _pcConstraints);
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) => pc.addTrack(track, _localStream!));
    }
    
    pc.onIceCandidate = (candidate) {
      _socketClient.socket?.emit('webrtc_ice_candidate', {
        'to': userId,
        'frequencyId': _currentFrequencyId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStreams[userId] = event.streams[0];
        notifyListeners();
      }
    };

    pc.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        _closePeerConnection(userId);
      }
    };

    _peerConnections[userId] = pc;
    return pc;
  }

  Future<void> _createOffer(String userId) async {
    try {
      final pc = await _createPeerConnection(userId);
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      _socketClient.socket?.emit('webrtc_offer', {
        'to': userId,
        'frequencyId': _currentFrequencyId,
        'offer': {'type': offer.type, 'sdp': offer.sdp},
      });
    } catch (e) {
      if (kDebugMode) print('Error creating offer: ');
    }
  }

  Future<void> _handleOffer(String userId, Map<String, dynamic> offer) async {
    try {
      final pc = await _createPeerConnection(userId);
      await pc.setRemoteDescription(RTCSessionDescription(offer['sdp'] as String, offer['type'] as String));
      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);
      _socketClient.socket?.emit('webrtc_answer', {
        'to': userId,
        'frequencyId': _currentFrequencyId,
        'answer': {'type': answer.type, 'sdp': answer.sdp},
      });
    } catch (e) {
      if (kDebugMode) print('Error handling offer: ');
    }
  }

  Future<void> _handleAnswer(String userId, Map<String, dynamic> answer) async {
    try {
      final pc = _peerConnections[userId];
      if (pc != null) {
        await pc.setRemoteDescription(RTCSessionDescription(answer['sdp'] as String, answer['type'] as String));
      }
    } catch (e) {
      if (kDebugMode) print('Error handling answer: ');
    }
  }

  Future<void> _handleIceCandidate(String userId, Map<String, dynamic> candidate) async {
    try {
      final pc = _peerConnections[userId];
      if (pc != null) {
        await pc.addCandidate(RTCIceCandidate(
          candidate['candidate'] as String,
          candidate['sdpMid'] as String,
          candidate['sdpMLineIndex'] as int,
        ));
      }
    } catch (e) {
      if (kDebugMode) print('Error adding ICE candidate: ');
    }
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_localStream != null) {
      _localStream!.getAudioTracks().forEach((track) => track.enabled = !_isMuted);
    }
    notifyListeners();
  }

  void _closePeerConnection(String userId) {
    _peerConnections[userId]?.close();
    _peerConnections.remove(userId);
    _remoteStreams.remove(userId);
    notifyListeners();
  }

  Future<void> leaveFrequency() async {
    for (var userId in _peerConnections.keys.toList()) {
      _closePeerConnection(userId);
    }
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) => track.stop());
      await _localStream!.dispose();
      _localStream = null;
    }
    _connectedUsers.clear();
    _currentFrequencyId = null;
    _isMuted = false;
    notifyListeners();
  }

  @override
  void dispose() {
    leaveFrequency();
    super.dispose();
  }
}
