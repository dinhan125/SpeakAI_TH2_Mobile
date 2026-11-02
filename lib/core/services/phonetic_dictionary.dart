/// Comprehensive phonetic dictionary providing IPA transcriptions,
/// common substitution errors for learners, and tongue/mouth position guides.
class PhonemeGuide {
  final String phoneme;
  final String ipaExample;
  final String descriptionVi;
  final String mouthPositionVi;
  final String commonVietnameseError;
  final List<String> practiceWords;

  const PhonemeGuide({
    required this.phoneme,
    required this.ipaExample,
    required this.descriptionVi,
    required this.mouthPositionVi,
    required this.commonVietnameseError,
    required this.practiceWords,
  });
}

class PhoneticDictionary {
  PhoneticDictionary._();

  static const Map<String, PhonemeGuide> phonemeGuides = {
    'θ': PhonemeGuide(
      phoneme: 'θ',
      ipaExample: '/θɪŋk/ (think)',
      descriptionVi: 'Âm răng vô thanh (Voiceless dental fricative)',
      mouthPositionVi:
          'Đặt nhẹ đầu lưỡi giữa hai hàm răng trên và dưới. Thổi luồng hơi nhẹ qua khe hở giữa lưỡi và răng trên. Không làm rung dây thanh quản.',
      commonVietnameseError: 'Thường bị đọc nhầm thành âm /s/ hoặc /t/ ("think" thành "sink" hoặc "tink").',
      practiceWords: ['think', 'thank', 'three', 'bath', 'mouth', 'theater'],
    ),
    'ð': PhonemeGuide(
      phoneme: 'ð',
      ipaExample: '/ðiːz/ (these)',
      descriptionVi: 'Âm răng hữu thanh (Voiced dental fricative)',
      mouthPositionVi:
          'Vị trí lưỡi và răng tương tự như âm /θ/, nhưng cần làm rung mạnh dây thanh quản khi thổi luồng hơi ra.',
      commonVietnameseError: 'Thường bị đọc nhầm thành âm /d/ hoặc /z/ ("this" thành "dis").',
      practiceWords: ['this', 'that', 'these', 'mother', 'brother', 'weather'],
    ),
    'ʃ': PhonemeGuide(
      phoneme: 'ʃ',
      ipaExample: '/ʃiː/ (she)',
      descriptionVi: 'Âm vòm họng vô thanh (Voiceless postalveolar fricative)',
      mouthPositionVi:
          'Chu nhẹ môi về phía trước theo hình tròn nhỏ. Nâng thân lưỡi áp sát vòm họng trên và đẩy luồng hơi mạnh ra như khi ra hiệu "suỵt".',
      commonVietnameseError: 'Thường bị đọc bẹt miệng thành âm /s/ ("she" thành "see", "seashells" thành "seassells").',
      practiceWords: ['she', 'ship', 'shoe', 'fish', 'ocean', 'special'],
    ),
    'ʒ': PhonemeGuide(
      phoneme: 'ʒ',
      ipaExample: '/ˈvɪʒn/ (vision)',
      descriptionVi: 'Âm vòm họng hữu thanh (Voiced postalveolar fricative)',
      mouthPositionVi:
          'Khẩu hình môi chu nhẹ giống âm /ʃ/, đồng thời làm rung thanh quản.',
      commonVietnameseError: 'Thường bị nuốt âm hoặc phát âm thành âm /z/ hoặc /dʒ/.',
      practiceWords: ['vision', 'measure', 'pleasure', 'leisure', 'asia', 'genre'],
    ),
    's': PhonemeGuide(
      phoneme: 's',
      ipaExample: '/sɪŋk/ (sink)',
      descriptionVi: 'Âm lợi xát vô thanh (Voiceless alveolar fricative)',
      mouthPositionVi:
          'Hai mép môi mở rộng sang hai bên (cười nhẹ), đầu lưỡi nâng gần chạm gờ lợi trên. Ép luồng hơi đi qua rãnh hẹp giữa lưỡi và răng.',
      commonVietnameseError: 'Thường bị bỏ quên ở âm đuôi (ending sounds: "books", "nice", "face").',
      practiceWords: ['sink', 'see', 'summer', 'books', 'dance', 'class'],
    ),
    'z': PhonemeGuide(
      phoneme: 'z',
      ipaExample: '/zuː/ (zoo)',
      descriptionVi: 'Âm lợi xát hữu thanh (Voiced alveolar fricative)',
      mouthPositionVi:
          'Khẩu hình tương tự âm /s/, nhưng kết hợp rung dây thanh quản.',
      commonVietnameseError: 'Thường bị mất độ rung thành âm /s/ ở đuôi từ ("is", "has", "goes").',
      practiceWords: ['zoo', 'zero', 'easy', 'music', 'has', 'boys'],
    ),
    'v': PhonemeGuide(
      phoneme: 'v',
      ipaExample: '/ˈvɛri/ (very)',
      descriptionVi: 'Âm môi răng hữu thanh (Voiced labiodental fricative)',
      mouthPositionVi:
          'Răng cửa trên chạm nhẹ vào môi dưới. Đẩy luồng hơi thoát ra qua kẽ răng đồng thời rung dây thanh quản.',
      commonVietnameseError: 'Thường bị đọc thành âm /b/ hoặc /w/ ("very" thành "berry" hoặc "wery").',
      practiceWords: ['very', 'voice', 'violin', 'give', 'leave', 'travel'],
    ),
    'b': PhonemeGuide(
      phoneme: 'b',
      ipaExample: '/bɛst/ (best)',
      descriptionVi: 'Âm đôi môi tắc hữu thanh (Voiced bilabial plosive)',
      mouthPositionVi:
          'Hai môi mím chặt chặn hoàn toàn luồng hơi, sau đó mở môi thật nhanh để luồng hơi bật mạnh ra kết hợp rung thanh quản.',
      commonVietnameseError: 'Nhầm lẫn với âm /v/ hoặc /p/.',
      practiceWords: ['best', 'boat', 'boy', 'job', 'table', 'brother'],
    ),
    'iː': PhonemeGuide(
      phoneme: 'iː',
      ipaExample: '/ʃiːp/ (sheep)',
      descriptionVi: 'Nguyên âm dài mở hẹp phía trước (Long high front vowel)',
      mouthPositionVi:
          'Môi kéo dẹt căng sang hai bên như đang cười tươi, nâng cuống lưỡi lên cao. Giữ âm kéo dài hơn âm /ɪ/.',
      commonVietnameseError: 'Đọc quá ngắn thành âm /ɪ/ ("sheep" nghe như "ship").',
      practiceWords: ['sheep', 'sleep', 'green', 'seat', 'eat', 'feet'],
    ),
    'ɪ': PhonemeGuide(
      phoneme: 'ɪ',
      ipaExample: '/ʃɪp/ (ship)',
      descriptionVi: 'Nguyên âm ngắn mở nửa hẹp (Short near-close vowel)',
      mouthPositionVi:
          'Môi thả lỏng tự nhiên, không căng dẹt, miệng mở rộng hơn một chút so với /iː/. Phát âm nhanh dứt khoát.',
      commonVietnameseError: 'Bị kéo dài thành âm /iː/ ("ship" nghe như "sheep").',
      practiceWords: ['ship', 'sit', 'big', 'milk', 'fish', 'listen'],
    ),
    'æ': PhonemeGuide(
      phoneme: 'æ',
      ipaExample: '/kæt/ (cat)',
      descriptionVi: 'Nguyên âm bẹt mở rộng (Short open front vowel)',
      mouthPositionVi:
          'Mở rộng miệng cả chiều ngang lẫn chiều dọc (hạ cằm xuống sâu), đầu lưỡi tì vào mặt trong răng cửa dưới.',
      commonVietnameseError: 'Đọc thành âm /e/ ngắn như trong tiếng Việt ("man" thành "men").',
      practiceWords: ['cat', 'apple', 'black', 'man', 'hand', 'bank'],
    ),
  };

  /// Get phonetic guide for a phoneme symbol
  static PhonemeGuide? getGuide(String phoneme) {
    // Strip slashes if present
    final clean = phoneme.replaceAll('/', '').trim();
    return phonemeGuides[clean];
  }
}

