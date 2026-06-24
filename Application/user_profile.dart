import 'package:dio/dio.dart';
import '../models/user_profile.dart';
import '../models/vital_reading.dart';
import '../models/symptom_log.dart';
import '../models/pill_reminder.dart';
import '../models/emergency_contact.dart';
import '../models/chat_message.dart';

// ── CONFIGURE YOUR PYTHON BACKEND HERE ──────────────────────
const String _baseUrl = 'http://localhost:5000';
const String _apiKey  = 'YOUR_API_KEY_HERE';
// ────────────────────────────────────────────────────────────

class ApiService {
  final Dio _dio;

  ApiService() : _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    },
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));

  Future<UserProfile?> getProfile() async {
    try {
      final res = await _dio.get('/user-profiles');
      final list = res.data as List;
      return list.isNotEmpty ? UserProfile.fromJson(list.first) : null;
    } catch (_) { return null; }
  }

  Future<UserProfile> createProfile(UserProfile profile) async {
    final res = await _dio.post('/user-profiles', data: profile.toJson());
    return UserProfile.fromJson(res.data);
  }

  Future<List<VitalReading>> getVitalReadings({int limit = 50}) async {
    try {
      final res = await _dio.get('/vital-readings?limit=$limit');
      return (res.data as List).map((e) => VitalReading.fromJson(e)).toList();
    } catch (_) { return []; }
  }

  Future<void> saveVitalReading(VitalReading reading) async {
    try { await _dio.post('/vital-readings', data: reading.toJson()); } catch (_) {}
  }

  Future<List<SymptomLog>> getSymptomLogs({int limit = 50}) async {
    try {
      final res = await _dio.get('/symptom-logs?limit=$limit');
      return (res.data as List).map((e) => SymptomLog.fromJson(e)).toList();
    } catch (_) { return []; }
  }

  Future<SymptomLog> createSymptomLog(SymptomLog log) async {
    final res = await _dio.post('/symptom-logs', data: log.toJson());
    return SymptomLog.fromJson(res.data);
  }

  Future<List<PillReminder>> getPillReminders() async {
    try {
      final res = await _dio.get('/pill-reminders');
      return (res.data as List).map((e) => PillReminder.fromJson(e)).toList();
    } catch (_) { return []; }
  }

  Future<PillReminder> createPillReminder(PillReminder reminder) async {
    final res = await _dio.post('/pill-reminders', data: reminder.toJson());
    return PillReminder.fromJson(res.data);
  }

  Future<void> deletePillReminder(String id) async {
    try { await _dio.delete('/pill-reminders/$id'); } catch (_) {}
  }

  Future<List<EmergencyContact>> getEmergencyContacts() async {
    try {
      final res = await _dio.get('/emergency-contacts');
      return (res.data as List).map((e) => EmergencyContact.fromJson(e)).toList();
    } catch (_) { return []; }
  }

  Future<EmergencyContact> createEmergencyContact(EmergencyContact contact) async {
    final res = await _dio.post('/emergency-contacts', data: contact.toJson());
    return EmergencyContact.fromJson(res.data);
  }

  Future<void> deleteEmergencyContact(String id) async {
    try { await _dio.delete('/emergency-contacts/$id'); } catch (_) {}
  }

  Future<List<ChatMessage>> getChatMessages(String conversationId) async {
    try {
      final res = await _dio.get('/chat-messages?conversation_id=$conversationId');
      return (res.data as List).map((e) => ChatMessage.fromJson(e)).toList();
    } catch (_) { return []; }
  }

  /// Calls your Python AI backend for chat response
  Future<String> getAIResponse({
    required String userMessage,
    required String conversationId,
    Map<String, dynamic>? context,
  }) async {
    final res = await _dio.post('/ai/chat', data: {
      'message': userMessage,
      'conversation_id': conversationId,
      'context': context,
    });
    return res.data['response'] as String;
  }

  /// Get latest AI analysis from Python serial reader
  Future<Map<String, dynamic>?> getLatestReading() async {
    try {
      final res = await _dio.get('/latest');
      return res.data as Map<String, dynamic>;
    } catch (_) { return null; }
  }
}
