import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ServiceRequestAiService {
  ServiceRequestAiService._();
  static final instance = ServiceRequestAiService._();

  Future<Map<String, dynamic>?> analyzeRequest({
    required String requestType,
    required String title,
    required String description,
  }) async {
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      );
      final response = await model.generateContent([
        Content.text(
          '''You are an advisory triage assistant for a university Directorate of Students' Welfare (DSW).
Analyze this request without making an official decision. Return JSON only with exactly these keys:
summary (string), priority (one of LOW, NORMAL, HIGH, URGENT), priorityReason (string), suggestedOffice (string), riskTags (array of short strings).
Escalate only when the text indicates safety risk, harassment, medical emergency, violence, severe financial distress, or a time-critical institutional deadline.
Request type: $requestType
Title: $title
Description: $description''',
        ),
      ]);
      final decoded = jsonDecode(response.text ?? '{}');
      if (decoded is! Map) return null;
      final priority = _normalizePriority(decoded['priority']);
      return {
        'summary': _text(decoded['summary']),
        'priority': priority,
        'priorityReason': _text(decoded['priorityReason']),
        'suggestedOffice': _text(decoded['suggestedOffice']),
        'riskTags': decoded['riskTags'] is List
            ? (decoded['riskTags'] as List)
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .take(6)
                .toList()
            : <String>[],
      };
    } catch (_) {
      return _fallbackRequestAnalysis(
        requestType: requestType,
        title: title,
        description: description,
      );
    }
  }

  Future<String?> analyzeStoredImage({
    required String storagePath,
    required String title,
    required String description,
  }) async {
    try {
      final reference = FirebaseStorage.instance.ref(storagePath);
      final metadata = await reference.getMetadata();
      final mimeType = metadata.contentType ?? '';
      if (mimeType != 'image/jpeg' && mimeType != 'image/png') return null;
      final Uint8List? bytes = await reference.getData(5 * 1024 * 1024);
      if (bytes == null || bytes.isEmpty) return null;

      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
      );
      final response = await model.generateContent([
        Content.multi([
          TextPart(
            '''This image was uploaded as supporting evidence for a university DSW complaint/request.
Describe only visible, relevant evidence in 2-4 sentences. Do not identify people, infer sensitive attributes, or make an official decision. Mention if the image is unclear or unrelated.
Title: $title
Description: $description''',
          ),
          InlineDataPart(mimeType, bytes),
        ]),
      ]);
      final text = response.text?.trim();
      return text == null || text.isEmpty ? null : text;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> assessDuplicate({
    required String currentText,
    required String candidateText,
  }) async {
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      );
      final response = await model.generateContent([
        Content.text(
          '''Compare two university DSW requests. Return JSON only with: isDuplicate (boolean), confidence (number from 0 to 1), reason (string).
Treat them as duplicates only when they describe substantially the same incident/request, not merely the same topic.
CURRENT: $currentText
CANDIDATE: $candidateText''',
        ),
      ]);
      final decoded = jsonDecode(response.text ?? '{}');
      if (decoded is! Map) return null;
      final raw = decoded['confidence'];
      final confidence = raw is num
          ? raw.toDouble().clamp(0, 1)
          : (double.tryParse(raw?.toString() ?? '') ?? 0).clamp(0, 1);
      return {
        'isDuplicate': decoded['isDuplicate'] == true,
        'confidence': confidence,
        'reason': _text(decoded['reason']),
      };
    } catch (_) {
      return null;
    }
  }


  Map<String, dynamic> _fallbackRequestAnalysis({
    required String requestType,
    required String title,
    required String description,
  }) {
    final text = '$title $description'.toLowerCase();
    String priority = 'NORMAL';
    final tags = <String>[];

    bool hasAny(List<String> words) => words.any(text.contains);

    if (hasAny([
      'emergency',
      'danger',
      'unsafe',
      'violence',
      'threat',
      'harassment',
      'medical emergency',
      'fire',
      'suicide',
      'assault',
    ])) {
      priority = 'URGENT';
      tags.add('safety');
    } else if (hasAny([
      'urgent',
      'medical',
      'severe',
      'deadline today',
      'deadline tomorrow',
      'no food',
      'financial crisis',
    ])) {
      priority = 'HIGH';
      tags.add('time-sensitive');
    } else if (hasAny(['delay', 'repeated', 'broken', 'not working', 'without water'])) {
      priority = 'NORMAL';
      tags.add('service-impact');
    }

    final office = switch (requestType) {
      'hall_related' => 'Hall / DSW Coordination',
      'financial_assistance' => 'Student Welfare / Financial Assistance',
      'student_welfare' => 'Student Welfare Office',
      'event_permission' => 'DSW Administration',
      'certificate_recommendation' => 'DSW Administration',
      'general_grievance' => 'DSW Office',
      _ => 'DSW Office',
    };

    return {
      'summary': title.trim().isEmpty
          ? 'Student submitted a DSW service request for review.'
          : '${title.trim()} requires DSW review.',
      'priority': priority,
      'priorityReason':
          'Fallback advisory triage based on request wording because the online AI service was unavailable.',
      'suggestedOffice': office,
      'riskTags': tags,
    };
  }

  static String _normalizePriority(dynamic value) {
    final p = value?.toString().trim().toUpperCase();
    return ['LOW', 'NORMAL', 'HIGH', 'URGENT'].contains(p) ? p! : 'NORMAL';
  }

  static String _text(dynamic value) => value?.toString().trim() ?? '';
}
