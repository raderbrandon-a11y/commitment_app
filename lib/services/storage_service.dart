import '../models/session.dart';

abstract class StorageService {
  Future<void> init();
  Future<void> saveSession(Session session);
  Future<List<Session>> loadSessions();
}
