import 'package:th2/core/constants/app_constants.dart';
import 'package:th2/data/models/sentence_model.dart';
import 'package:th2/data/models/user_model.dart';

/// Preloaded curated sentences covering common phoneme challenges:
/// - Minimal pairs: /θ/ vs /s/, /ʃ/ vs /s/, /v/ vs /b/, /r/ vs /l/
/// - Tricky vowel contrasts: /iː/ vs /ɪ/, /æ/ vs /e/
class SampleData {
  SampleData._();

  static UserModel get defaultUser => UserModel(
    id: AppConstants.defaultUserId,
    fullName: AppConstants.defaultUserName,
    dailyGoalMinutes: AppConstants.defaultDailyGoalMinutes,
    reminderTime: AppConstants.defaultReminderTime,
    currentStreak: 3,
    longestStreak: 7,
    lastActiveDate: null,
    isNotificationEnabled: true,
    preferredAccent: 'en-US',
  );

  static List<SentenceModel> get initialSentences => [
    // 1. Classic Tongue Twister /ʃ/ vs /s/
    SentenceModel(
      id: 'sen_1',
      text: 'She sells seashells by the seashore',
      ipaTranscription: '/ʃiː sɛlz ˈsiːˌʃɛlz baɪ ðə ˈsiːˌʃɔːr/',
      focusPhonemes: ['ʃ', 's', 'z'],
      level: 2,
      topic: 'Pronunciation Challenge',
      translation: 'Cô ấy bán vỏ sò bên bờ biển',
    ),

    // 2. Minimal Pair /θ/ vs /s/
    SentenceModel(
      id: 'sen_2',
      text: 'I think the sink is full of water',
      ipaTranscription: '/aɪ θɪŋk ðə sɪŋk ɪz fʊl ʌv ˈwɔːtər/',
      focusPhonemes: ['θ', 's', 'ŋ'],
      level: 1,
      topic: 'Minimal Pairs (/θ/ - /s/)',
      translation: 'Tôi nghĩ bồn rửa đã đầy nước',
    ),

    // 3. Dental fricatives /ð/ and /θ/
    SentenceModel(
      id: 'sen_3',
      text: 'These three brothers think together',
      ipaTranscription: '/ðiːz θriː ˈbrʌðərz θɪŋk təˈɡɛðər/',
      focusPhonemes: ['ð', 'θ', 'ʌ'],
      level: 2,
      topic: 'Dental Sounds (/ð/ - /θ/)',
      translation: 'Ba người anh em này cùng suy nghĩ',
    ),

    // 4. Labiodental /v/ vs Bilabial /b/
    SentenceModel(
      id: 'sen_4',
      text: 'Victor bought a very best violin',
      ipaTranscription: '/ˈvɪktər bɔːt ə ˈvɛri bɛst ˌvaɪəˈlɪn/',
      focusPhonemes: ['v', 'b', 'ɔː'],
      level: 1,
      topic: 'Minimal Pairs (/v/ - /b/)',
      translation: 'Victor đã mua một cây vĩ cầm tốt nhất',
    ),

    // 5. Liquid Consonants /r/ vs /l/
    SentenceModel(
      id: 'sen_5',
      text: 'Red lorry yellow lorry roll along',
      ipaTranscription: '/rɛd ˈlɔːri ˈjɛloʊ ˈlɔːri roʊl əˈlɔːŋ/',
      focusPhonemes: ['r', 'l', 'ɔː'],
      level: 2,
      topic: 'Liquids (/r/ - /l/)',
      translation: 'Xe tải đỏ xe tải vàng lăn bánh',
    ),

    // 6. Vowel contrast /iː/ vs /ɪ/ (sheep vs ship)
    SentenceModel(
      id: 'sen_6',
      text: 'The sheep sleeps on the big green ship',
      ipaTranscription: '/ðə ʃiːp sliːps ɑːn ðə bɪɡ ɡriːn ʃɪp/',
      focusPhonemes: ['iː', 'ɪ', 'ʃ'],
      level: 1,
      topic: 'Vowels (/iː/ vs /ɪ/)',
      translation: 'Con cừu ngủ trên con tàu xanh lớn',
    ),

    // 7. Everyday Conversation
    SentenceModel(
      id: 'sen_7',
      text: 'Thank you very much for your wonderful support',
      ipaTranscription: '/θæŋk juː ˈvɛri mʌtʃ fɔːr jɔːr ˈwʌndərfʊl səˈpɔːrt/',
      focusPhonemes: ['θ', 'v', 'tʃ'],
      level: 1,
      topic: 'Daily Conversation',
      translation: 'Cảm ơn bạn rất nhiều vì sự hỗ trợ tuyệt vời',
    ),

    // 8. Advanced Fluency
    SentenceModel(
      id: 'sen_8',
      text: 'Artificial intelligence enhances language acquisition',
      ipaTranscription: '/ˌɑːrtəˈfɪʃl ɪnˈtɛlədʒəns ɛnˈhænsɪz ˈlæŋɡwɪdʒ ˌækwəˈzɪʃn/',
      focusPhonemes: ['ʃ', 'dʒ', 'ŋ', 'z'],
      level: 3,
      topic: 'Advanced Technology',
      translation: 'Trí tuệ nhân tạo nâng cao việc học ngôn ngữ',
    ),
  ];
}
