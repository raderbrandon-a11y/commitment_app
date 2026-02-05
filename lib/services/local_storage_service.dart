import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/session.dart';
import 'storage_service.dart';

class LocalStorageService implements StorageService {
  static const _sessionsKey = 'sessions';
  late SharedPreferences _prefs;

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<void> saveSession(Session session) async {
    final list = _prefs.getStringList(_sessionsKey) ?? <String>[];
    final encoded = jsonEncode(session.toJson());
    await _prefs.setStringList(_sessionsKey, [...list, encoded]);
  }

  @override
  Future<List<Session>> loadSessions() async {
    final list = _prefs.getStringList(_sessionsKey) ?? <String>[];
    return list
        .map((s) => Session.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }
}
