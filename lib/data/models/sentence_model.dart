import 'dart:convert';

/// Sentence Model for practice tasks and minimal pairs.
class SentenceModel {
  final String id;
  final String text;
  final String ipaTranscription;
  final String? sampleAudioUrl;
  final List<String> focusPhonemes;
  final int level; // 1: Easy, 2: Medium, 3: Hard
  final String topic;
  final String translation;

  SentenceModel({
    required this.id,
    required this.text,
    required this.ipaTranscription,
    this.sampleAudioUrl,
    required this.focusPhonemes,
    this.level = 1,
    this.topic = 'General',
    this.translation = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'ipa_transcription': ipaTranscription,
      'sample_audio_url': sampleAudioUrl,
      'focus_phonemes': jsonEncode(focusPhonemes),
      'level': level,
      'topic': topic,
      'translation': translation,
    };
  }

  factory SentenceModel.fromMap(Map<String, dynamic> map) {
    List<String> phonemes = [];
    final rawFocus = map['focus_phonemes'];
    if (rawFocus is String) {
      try {
        final decoded = jsonDecode(rawFocus);
        if (decoded is List) {
          phonemes = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    } else if (rawFocus is List) {
      phonemes = rawFocus.map((e) => e.toString()).toList();
    }

    return SentenceModel(
      id: map['id'] as String,
      text: map['text'] as String,
      ipaTranscription: map['ipa_transcription'] as String,
      sampleAudioUrl: map['sample_audio_url'] as String?,
      focusPhonemes: phonemes,
      level: (map['level'] as int?) ?? 1,
      topic: map['topic'] as String? ?? 'General',
      translation: map['translation'] as String? ?? '',
    );
  }
}

