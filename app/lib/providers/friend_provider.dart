import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/friend_model.dart';
import '../features/users/services/friend_service.dart';
import '../features/chats/services/socket_service/socket_service.dart';
import '../core/services/token_manager.dart';

enum FriendshipStatus { none, sent, received, accepted, rejected }

class FriendProvider extends ChangeNotifier {
  final FriendService _service = FriendService();
  final SocketService socketService;

  List<FriendModel> _friends = [];
  List<Map<String, dynamic>> _pendingIncomingRequests = [];
  List<Map<String, dynamic>> _pendingOutgoingRequests = [];
  Set<String> _sentRequestPeerIds = {};
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _error;

  bool get hasLoadedFriends => _hasLoaded;

  List<FriendModel> get friends => _friends;
  List<Map<String, dynamic>> get pendingIncomingRequests =>
      _pendingIncomingRequests;
  List<Map<String, dynamic>> get pendingOutgoingRequests =>
      _pendingOutgoingRequests;
  Set<String> get sentRequestPeerIds => _sentRequestPeerIds;
  bool get isLoading => _isLoading;
  String? get error => _error;

  UserModel? _currentUser;

  FriendProvider({UserModel? currentUser, required this.socketService})
    : _currentUser = currentUser {
    _initSocketListeners();
  }

  void _initSocketListeners() {
    // A new incoming request arrived while the app is open — patch it in
    // live instead of waiting for the next manual/pull-to-refresh.
    socketService.onFriendRequestReceived = (request) {
      final id = request['_id']?.toString();
      if (id == null) return;
      if (_pendingIncomingRequests.any((r) => r['_id']?.toString() == id)) {
        return;
      }
      _pendingIncomingRequests = [request, ..._pendingIncomingRequests];
      notifyListeners();
    };

    // A request we sent was accepted/rejected elsewhere — refetch, since
    // acceptance also creates a chat we need the id for.
    socketService.onFriendRequestUpdated = (_) {
      loadFriendsAndRequests();
    };
  }

  void _clearSocketListeners() {
    socketService.onFriendRequestReceived = null;
    socketService.onFriendRequestUpdated = null;
  }

  void updateUser(UserModel? user) {
    if (_currentUser?.id == user?.id) return;
    _currentUser = user;
    if (user != null) {
      _initSocketListeners();
    } else {
      _clearSocketListeners();
      _friends = [];
      _pendingIncomingRequests = [];
      _sentRequestPeerIds = {};
      _hasLoaded = false;
      notifyListeners();
    }
  }

  String? get _token => TokenManager.token;

  Future<void> loadFriendsAndRequests({bool isSilent = false}) async {
    final token = _token;
    if (token == null) return;

    if (!isSilent && _friends.isEmpty && _pendingIncomingRequests.isEmpty) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final results = await Future.wait([
        _service.getFriends(),
        _service.getPendingRequests(),
      ]);
      final friendsData = results[0] as List;
      final pendingMap = results[1] as Map<String, List<Map<String, dynamic>>>;

      // ── Centralized Deduplication for Friends List ─────────────────
      final Map<String, FriendModel> uniqueFriendsMap = {};
      for (final raw in friendsData) {
        final f = FriendModel.fromJson(raw as Map<String, dynamic>);
        if (f.id.isNotEmpty) {
          uniqueFriendsMap[f.id] = f;
        }
      }
      _friends = uniqueFriendsMap.values.toList();

      // ── Centralized Deduplication for Incoming Requests ────────────
      final Map<String, Map<String, dynamic>> uniqueIncomingMap = {};
      for (final req in (pendingMap['incoming'] ?? [])) {
        final id = req['_id']?.toString() ?? '';
        if (id.isNotEmpty) {
          uniqueIncomingMap[id] = req;
        }
      }
      _pendingIncomingRequests = uniqueIncomingMap.values.toList();

      // ── Centralized Deduplication for Outgoing Requests ────────────
      final Map<String, Map<String, dynamic>> uniqueOutgoingMap = {};
      for (final req in (pendingMap['outgoing'] ?? [])) {
        final id = req['_id']?.toString() ?? '';
        if (id.isNotEmpty) {
          uniqueOutgoingMap[id] = req;
        }
      }
      _pendingOutgoingRequests = uniqueOutgoingMap.values.toList();

      _sentRequestPeerIds = _pendingOutgoingRequests
          .map((r) {
            final rec = r['receiver'];
            if (rec is Map) {
              return rec['_id']?.toString() ?? rec['id']?.toString() ?? '';
            }
            return rec?.toString() ?? '';
          })
          .where((id) => id.isNotEmpty)
          .toSet();

      _hasLoaded = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> sendRequest(String receiverId) async {
    final token = _token;
    if (token == null) return;
    // The server answers an empty receiver with a 400 whose message reads like
    // a client bug report; fail here where the caller can see what it did.
    if (receiverId.isEmpty) {
      throw ArgumentError('receiverId is empty — nobody to send a request to');
    }

    try {
      await _service.sendFriendRequest(receiverId);
      _sentRequestPeerIds = {..._sentRequestPeerIds, receiverId};
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to send friend request: $e');
      rethrow;
    }
  }

  Future<void> acceptRequest(String requestId) async {
    final token = _token;
    if (token == null) return;

    final removedIndex = _pendingIncomingRequests.indexWhere(
      (r) => r['_id']?.toString() == requestId,
    );
    Map<String, dynamic>? removedReq;
    if (removedIndex != -1) {
      removedReq = _pendingIncomingRequests.removeAt(removedIndex);
      notifyListeners();
    }

    try {
      await _service.updateFriendRequest(requestId, 'accepted');
      unawaited(loadFriendsAndRequests(isSilent: true));
    } catch (e) {
      if (removedReq != null && removedIndex != -1) {
        _pendingIncomingRequests.insert(removedIndex, removedReq);
        notifyListeners();
      }
      debugPrint('Failed to accept friend request: $e');
      rethrow;
    }
  }

  Future<void> rejectRequest(String requestId) async {
    final token = _token;
    if (token == null) return;

    final removedIndex = _pendingIncomingRequests.indexWhere(
      (r) => r['_id']?.toString() == requestId,
    );
    Map<String, dynamic>? removedReq;
    if (removedIndex != -1) {
      removedReq = _pendingIncomingRequests.removeAt(removedIndex);
      notifyListeners();
    }

    try {
      await _service.updateFriendRequest(requestId, 'rejected');
      unawaited(loadFriendsAndRequests(isSilent: true));
    } catch (e) {
      if (removedReq != null && removedIndex != -1) {
        _pendingIncomingRequests.insert(removedIndex, removedReq);
        notifyListeners();
      }
      debugPrint('Failed to reject friend request: $e');
      rethrow;
    }
  }

  FriendshipStatus getFriendshipStatus(String peerId) {
    if (_friends.any((f) => f.id == peerId)) {
      return FriendshipStatus.accepted;
    }

    final hasIncoming = _pendingIncomingRequests.any((r) {
      final sender = r['sender'];
      if (sender is Map<String, dynamic>) {
        return sender['_id'] == peerId;
      }
      return false;
    });
    if (hasIncoming) {
      return FriendshipStatus.received;
    }

    if (_sentRequestPeerIds.contains(peerId)) {
      return FriendshipStatus.sent;
    }

    return FriendshipStatus.none;
  }
}
