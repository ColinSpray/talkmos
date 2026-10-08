import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../../core/config/api_config.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/app_permissions.dart';
import '../../../../core/services/screen_share_service.dart';
import '../../../../core/services/socket_auth_error.dart';
import '../../../users/services/blocked_users_store.dart';
import '../call_notification_service.dart';
import '../../utils/call_title.dart';
import '../call_activity_service.dart';

part 'connect.dart';
part 'on_incoming_call.dart';
part 'reconcile_from_native_call.dart';
part 'apply_incoming_call.dart';
part 'update_state_to_connected.dart';
part 'on_participant_joined.dart';
part 'matches_current_call.dart';
part 'on_call_declined.dart';
part 'on_call_ringing.dart';
part 'on_call_ended.dart';
part 'on_call_details.dart';
part 'on_call_participant_left.dart';
part 'on_call_error.dart';
part 'on_call_history.dart';
part 'on_call_initiated.dart';
part 'peer_from_participants.dart';
part 'request_call_history.dart';
part 'start_outgoing_call.dart';
part 'accept_incoming_call.dart';
part 'reject_incoming_call.dart';
part 'ring_timeout.dart';
part 'wait_for_socket_connected.dart';
part 'invite_to_call.dart';
part 'clean_up.dart';
part 'disconnect.dart';
part 'toggle_screen_share.dart';

part 'room_getters.dart';
part 'local_video_track.dart';
part 'remote_video_track.dart';
part 'video_track_for.dart';
part 'on_livekit_token.dart';
part 'fetch_livekit_token.dart';
part 'connect_to_room.dart';
part 'wire_room_events.dart';
part 'sync_peer_name.dart';
part 'toggle_microphone.dart';
part 'toggle_camera.dart';
part 'switch_camera.dart';
part 'toggle_speakerphone.dart';
part 'reapply_audio_preferences.dart';
part 'upgrade_to_video.dart';

part 'reaction_getters.dart';
part 'on_data_received.dart';
part 'toggle_raise_hand.dart';
part 'send_reaction.dart';

part 'on_activity_accept.dart';
part 'on_activity_decline.dart';
part 'on_notification_event.dart';
part 'flush_pending_accept.dart';

enum CallState { idle, ringingIncoming, ringingOutgoing, connected, ended }

class CallReactionEvent {
  final int id;
  final String senderIdentity;
  final String emoji;
  const CallReactionEvent({
    required this.id,
    required this.senderIdentity,
    required this.emoji,
  });
}

class ActiveCallInProgressException implements Exception {
  @override
  String toString() => 'You are already on a call';
}

/// What ringing somebody actually did.
enum CallStartOutcome {
  /// A new call, ringing them now.
  started,

  /// There was already a call in progress, so they were invited into it
  /// instead — the caller opens the call that is already running.
  invitedToActiveCall,
}

class CallSignalingService with ChangeNotifier {
  IO.Socket? _socket;

  String? _currentToken;
  Timer? _healthCheckTimer;

  /// The call socket's token was refused — same session, same verdict as the
  /// chat socket's.
  void Function()? onSessionEnded;

  // LiveKit media session (null while idle / ringing before join).
  Room? _room;
  EventsListener<RoomEvent>? _roomListener;
  Completer<Map<String, dynamic>>? _tokenCompleter;
  bool _frontCamera = true;

  CallState _state = CallState.idle;
  String? _currentCallId;
  String? _peerId;
  String? _peerName;
  String? _peerAvatar;
  String? _callType; // 'audio' or 'video'
  String? _currentUserId; // this device's own user id (set on connect)
  String? _currentUserName; // this device's own display name (set on connect)
  bool _isMicMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = false;
  bool _cleaningUp = false;

  bool _isOutgoing = false;

  /// True once the callee's device has confirmed (via the `call_ringing`
  /// socket event) that it's actually ringing.
  bool _calleeRinging = false;

  bool _presumedRinging = false;
  Timer? _presumedRingingTimer;

  Timer? _ringTimeoutTimer;

  /// Held while the last remote participant is gone but the server is still
  /// keeping the call open for them (see CALL_RECONNECT_GRACE_MS on the
  /// backend). A web peer reloading its page leaves the LiveKit room and comes
  /// straight back, so tearing down on the first disconnect ends a call that
  /// is about to resume.
  Timer? _peerReconnectTimer;
  bool _peerReconnecting = false;

  /// Slightly longer than the server's own window, so the call is not torn
  /// down while the backend still considers it live.
  static const Duration peerReconnectGrace = Duration(seconds: 18);

  /// Set when the call reaches [CallState.connected]; used to compute
  /// duration for the `call_ended` analytics event.
  DateTime? _connectedAt;

  /// Set when the backend rejects a join (`call_error`), so an in-flight
  /// room connection can abort instead of publishing media into a dead call.
  bool _joinRejected = false;

  bool _isScreenSharing = false;

  /// Whether the camera was publishing when screen sharing took over, so it
  /// can be put back afterwards. Android cannot capture the camera and the
  /// screen at once, so starting a share has to stop the camera.
  bool _cameraSuspendedForShare = false;

  // ─── Raise hand / reactions (client-only, over LiveKit's data channel) ──
  bool _isHandRaised = false;
  final Set<String> _raisedHandIdentities = {};
  int _reactionCounter = 0;
  final StreamController<CallReactionEvent> _reactionController =
      StreamController<CallReactionEvent>.broadcast();

  List<Map<String, dynamic>> _callHistory = [];
  List<Map<String, dynamic>> get callHistory => _callHistory;

  StreamSubscription<CallNotificationEvent>? _notificationSub;
  StreamSubscription<Map<String, dynamic>>? _activityAcceptSub;
  StreamSubscription<Map<String, dynamic>>? _activityDeclineSub;

  final StreamController<void> _activeCallReadyController =
      StreamController<void>.broadcast();
  Stream<void> get onActiveCallReady => _activeCallReadyController.stream;

  bool _hasActiveCallScreenOpen = false;
  bool get hasActiveCallScreenOpen => _hasActiveCallScreenOpen;

  void markActiveCallScreenOpened() {
    _hasActiveCallScreenOpen = true;
    // Coming back to a call that is already running: the platform may have
    // re-routed the audio while the screen was gone.
    unawaited(reapplyAudioPreferences());
    _notifyAfterBuild();
  }

  void markActiveCallScreenClosed() {
    _hasActiveCallScreenOpen = false;
    _notifyAfterBuild();
  }

  void _notifyAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }

  void _notify() => notifyListeners();

  CallSignalingService() {
    CallNotificationService.setUp();
    CallActivityService.initialize();
    _notificationSub = CallNotificationService.onEvent.listen(
      _onNotificationEvent,
    );
    _activityAcceptSub = CallActivityService.onCallAccepted.listen(
      _onActivityAccept,
    );
    _activityDeclineSub = CallActivityService.onCallDeclined.listen(
      _onActivityDecline,
    );
  }

  /// An Accept that landed before login; replayed once [connect] runs.
  CallNotificationPayload? _pendingAcceptPayload;

  // Remembered so the history request can be re-issued on every (re)connect —
  // the socket often isn't up yet when the calls screen first asks for it.
  bool _pendingHistoryRequest = false;
  int _historyLimit = 50;

  void Function(List<Map<String, dynamic>> history)? onCallHistoryReceived;

  /// Something the call was asked to do failed, without ending it — an
  /// invite the server refused, most of all. For telling the user.
  void Function(String message)? onNonFatalCallError;

  CallState get state => _state;
  bool get isOutgoing => _isOutgoing;

  bool get calleeRinging => _calleeRinging || _presumedRinging;

  /// A call is up (ringing or connected), so the mic is spoken for.
  bool get hasActiveCallSession =>
      _state != CallState.idle && _state != CallState.ended;
  String? get currentCallId => _currentCallId;
  String? get peerId => _peerId;
  String? get peerName => _peerName;
  String? get peerAvatar => _peerAvatar;
  String? get callType => _callType;
  bool get isMicMuted => _isMicMuted;
  bool get isCameraOff => _isCameraOff;
  bool get isSpeakerOn => _isSpeakerOn;

  DateTime? get connectedAt => _connectedAt;

  /// The other side dropped and is being waited for, rather than gone.
  bool get isPeerReconnecting => _peerReconnecting;

  @override
  void dispose() {
    _healthCheckTimer?.cancel();
    _ringTimeoutTimer?.cancel();
    _presumedRingingTimer?.cancel();
    _peerReconnectTimer?.cancel();
    _notificationSub?.cancel();
    _activityAcceptSub?.cancel();
    _activityDeclineSub?.cancel();
    _activeCallReadyController.close();
    _reactionController.close();
    disconnect();
    super.dispose();
  }
}
