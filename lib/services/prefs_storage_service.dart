import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/session.dart';
import 'storage_service.dart';

class PrefsStorageService implements StorageService {
  static const _kSessions = 'sessions_v1';

  late SharedPreferences _prefs;

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<void> saveSession(Session session) async {
    final sessions = await loadSessions();
    sessions.insert(0, session); // newest first

    final jsonList = sessions.map((s) => s.toJson()).toList();
    await _prefs.setString(_kSessions, jsonEncode(jsonList));
  }

  @override
  Future<List<Session>> loadSessions() async {
    final raw = _prefs.getString(_kSessions);
    if (raw == null || raw.trim().isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((m) => Session.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }
}
