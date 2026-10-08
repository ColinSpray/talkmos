import 'dart:async';

import 'package:flutter/foundation.dart';
import '../features/users/services/block_service.dart';
import '../features/users/services/blocked_users_store.dart';
import '../models/user_model.dart';

class BlockProvider extends ChangeNotifier {
  final BlockService _service = BlockService();

  List<UserModel> _blockedUsers = [];
  bool _isLoading = false;
  String? _error;

  List<UserModel> get blockedUsers => _blockedUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool isBlocked(String userId) => _blockedUsers.any((u) => u.id == userId);

  void _syncMirror() {
    unawaited(BlockedUsersStore.sync(_blockedUsers.map((u) => u.id)));
  }

  Future<void> loadBlockedUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final raw = await _service.getBlockedUsers();
      _blockedUsers = raw.map((json) => UserModel.fromJson(json)).toList();
      _syncMirror();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading blocked users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> blockUser(UserModel user) async {
    final wasBlocked = isBlocked(user.id);
    if (!wasBlocked) {
      _blockedUsers = [..._blockedUsers, user];
      _syncMirror();
      notifyListeners();
    }
    try {
      await _service.blockUser(user.id);
    } catch (e) {
      if (!wasBlocked) {
        _blockedUsers = _blockedUsers.where((u) => u.id != user.id).toList();
        _syncMirror();
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> unblockUser(String userId) async {
    final removed = _blockedUsers.where((u) => u.id == userId).toList();
    _blockedUsers = _blockedUsers.where((u) => u.id != userId).toList();
    _syncMirror();
    notifyListeners();
    try {
      await _service.unblockUser(userId);
    } catch (e) {
      if (removed.isNotEmpty) {
        _blockedUsers = [..._blockedUsers, removed.first];
        _syncMirror();
        notifyListeners();
      }
      rethrow;
    }
  }

  void reset() {
    _blockedUsers = [];
    _syncMirror();
    notifyListeners();
  }
}
