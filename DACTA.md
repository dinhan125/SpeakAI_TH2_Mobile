# ĐẶC TẢ THIẾT KẾ PHẦN MỀM (SOFTWARE DESIGN SPECIFICATION)
**Tên dự án:** Ứng dụng học tiếng Anh với tính năng phân tích phát âm AI (SpeakAI)  
**Nền tảng phát triển:** Flutter (iOS & Android)  
**Phiên bản:** 1.0.0  

---

## 1. TỔNG QUAN HỆ THỐNG (SYSTEM OVERVIEW)

### 1.1. Mục đích dự án
Xây dựng một ứng dụng di động đa nền tảng bằng Flutter giúp người dùng rèn luyện kỹ năng phát âm tiếng Anh thông qua công nghệ Trí tuệ Nhân tạo (AI), đồng thời duy trì thói quen học tập hàng ngày thông qua hệ thống theo dõi tiến độ, nhắc nhở và tính toán chuỗi ngày học liên tiếp (Streak).

### 1.2. Phạm vi hệ thống (Mapping với 7 hạng mục yêu cầu)
1. **Quản lý dữ liệu:** Lưu trữ thông tin người dùng, lịch sử luyện tập, từ vựng/câu mẫu và kết quả phân tích chi tiết.
2. **Tính kỷ luật & Tiến độ:** Theo dõi chuỗi ngày học (Streak), đếm thời gian học thực tế, thiết lập mục tiêu hàng ngày.
3. **Thu âm & Nhận diện giọng nói:** Thu âm giọng nói chất lượng cao (PCM 16-bit, 16kHz) và truyền tải tới dịch vụ Speech-to-Text / Pronunciation Assessment.
4. **Phân tích âm vị bằng AI:** Đánh giá độ chính xác phát âm dựa trên so sánh âm vị (Phoneme Comparison - chuẩn IPA), chấm điểm chi tiết.
5. **Module Phản hồi (Feedback):** Trực quan hóa điểm số, tô màu (xanh/vàng/đỏ) từng từ/âm vị phát âm sai, phát lại âm thanh và gợi ý bài tập khắc phục.
6. **Hệ thống Thông báo & Thống kê:** Local Push Notification nhắc nhở học tập định kỳ; Dashboard biểu đồ trực quan hóa tiến độ.
7. **Kiểm thử & Đánh giá:** Quy trình kiểm thử đa giọng đọc (Accents), độ ồn môi trường và hiệu năng ứng dụng.

---

## 2. KIẾN TRÚC HỆ THỐNG & CÔNG NGHỆ (ARCHITECTURE & TECH STACK)

### 2.1. Kiến trúc phần mềm
Ứng dụng áp dụng kiến trúc **Clean Architecture** kết hợp với mẫu thiết kế quản lý trạng thái **BLoC (Business Logic Component)** hoặc **Riverpod** để đảm bảo tính phân tách, dễ bảo trì và dễ kiểm thử.

*   **Presentation Layer (UI & State):** Flutter Widgets, BLoC/Riverpod, Custom Painters (vẽ sóng âm, biểu đồ).
*   **Domain Layer (Business Logic):** Use Cases (Tính Streak, Chấm điểm, Đề xuất bài tập), Entities, Repository Interfaces.
*   **Data Layer (Data Access):** Repository Implementations, Remote Data Sources (AI API, Firebase), Local Data Sources (SQLite/Isar, SharedPreferences).

```
+-----------------------------------------------------------------------+
|                         PRESENTATION LAYER                            |
|  [Screens / Widgets] <---> [BLoC / Riverpod (State Management)]       |
+-----------------------------------------------------------------------+
                                    |
                                    v
+-----------------------------------------------------------------------+
|                            DOMAIN LAYER                               |
|  [Use Cases: EvaluateSpeech, UpdateStreak, GenerateRecommendation]    |
|  [Entities: User, PracticeSession, PhonemeResult, DailyProgress]      |
+-----------------------------------------------------------------------+
                                    |
                                    v
+-----------------------------------------------------------------------+
|                             DATA LAYER                                |
|  [Repositories Implementation]                                        |
|         |                                           |                 |
|         v                                           v                 |
|  [Remote Data Source]                        [Local Data Source]      |
|  - Azure Speech AI / OpenAI + Kaldi          - Isar / SQLite (Offline)|
|  - Cloud Firestore & Auth                    - Flutter Local Notif    |
+-----------------------------------------------------------------------+
```

### 2.2. Danh sách thư viện Flutter đề xuất (`pubspec.yaml`)
*   **Quản lý trạng thái & DI:** `flutter_bloc` hoặc `flutter_riverpod`, `get_it`, `injectable`
*   **Cơ sở dữ liệu & Lưu trữ:** `cloud_firestore`, `firebase_auth` (Đám mây), `sqflite` hoặc `isar` (Lưu trữ Offline tốc độ cao), `shared_preferences`
*   **Xử lý Âm thanh & Giọng nói:** 
    *   `record`: Thu âm dưới dạng file WAV (Linear PCM 16-bit, 16kHz mono) để gửi lên AI API.
    *   `just_audio` / `audioplayers`: Phát âm thanh mẫu và phát lại bản thu của người dùng.
    *   `flutter_tts`: Text-to-Speech phát âm mẫu khi offline.
*   **Mạng & API:** `dio`, `retrofit` (Gọi RESTful API / WebSockets tới AI Server).
*   **Thông báo & Tác vụ nền:** `flutter_local_notifications`, `timezone`.
*   **Giao diện & Biểu đồ:** `fl_chart` (Biểu đồ thống kê), `lottie` (Hiệu ứng chúc mừng Streak), `audio_waveforms` (Hiển thị sóng âm khi thu).

---

## 3. THIẾT KẾ CƠ SỞ DỮ LIỆU (HẠNG MỤC 01)

Hệ thống sử dụng mô hình **Offline-First**: Dữ liệu được ghi vào cơ sở dữ liệu cục bộ (SQLite/Isar) ngay lập tức để phản hồi mượt mà, sau đó đồng bộ ngầm lên Cloud Firestore.

### 3.1. Sơ đồ quan hệ thực thể (ERD)

```
+-------------------+       1:N       +-----------------------+
|       USERS       |---------------->|      DAILY_LOGS       |
+-------------------+                 +-----------------------+
| PK id (String)    |                 | PK id (String)        |
|    name           |                 | FK user_id            |
|    email          |                 |    date (YYYY-MM-DD)  |
|    daily_goal_min |                 |    study_seconds      |
|    reminder_time  |                 |    is_goal_met        |
|    current_streak |                 +-----------------------+
|    longest_streak |
|    last_study_date|       1:N       +-----------------------+
+-------------------+---------------->|   PRACTICE_SESSIONS   |
                                      +-----------------------+
+-------------------+                 | PK id (String)        |
|     SENTENCES     |       1:N       | FK user_id            |
+-------------------+---------------->| FK sentence_id        |
| PK id (String)    |                 |    audio_path         |
|    content_text   |                 |    overall_score      |
|    ipa_standard   |                 |    accuracy_score     |
|    difficulty     |                 |    fluency_score      |
|    target_phonemes|                 |    completeness_score |
+-------------------+                 |    created_at         |
                                      +-----------------------+
                                                  | 1:N
                                                  v
                                      +-----------------------+
                                      |   PHONEME_ASSESSMENTS |
                                      +-----------------------+
                                      | PK id (String)        |
                                      | FK session_id         |
                                      |    word               |
                                      |    phoneme_expected   |
                                      |    phoneme_actual     |
                                      |    score              |
                                      |    error_type         |
                                      +-----------------------+
```

### 3.2. Chi tiết các bảng dữ liệu (Data Models)

#### 1. Bảng `users` (Thông tin người dùng & Cài đặt kỷ luật)
| Tên trường | Kiểu dữ liệu | Mô tả |
| :--- | :--- | :--- |
| `id` | `String (UUID)` | Khóa chính |
| `full_name` | `String` | Tên hiển thị của người dùng |
| `daily_goal_minutes`| `int` | Mục tiêu số phút học mỗi ngày (Mặc định: 15 phút) |
| `reminder_time` | `String` | Giờ nhắc nhở hàng ngày định dạng `HH:mm` (VD: `"20:00"`) |
| `current_streak` | `int` | Số ngày học liên tiếp hiện tại |
| `longest_streak` | `int` | Kỷ lục chuỗi ngày học dài nhất |
| `last_active_date` | `String` | Ngày gần nhất hoàn thành mục tiêu (`YYYY-MM-DD`) |

#### 2. Bảng `sentences` (Ngân hàng câu/từ luyện tập)
| Tên trường | Kiểu dữ liệu | Mô tả |
| :--- | :--- | :--- |
| `id` | `String` | Khóa chính |
| `text` | `String` | Văn bản tiếng Anh (VD: *"She sells seashells"*) |
| `ipa_transcription`| `String` | Phiên âm chuẩn IPA (VD: `"/ʃiː sɛlz ˈsiːˌʃɛlz/"`) |
| `sample_audio_url` | `String` | Đường dẫn file âm thanh mẫu của người bản xứ |
| `focus_phonemes` | `List<String>`| Danh sách các âm vị trọng tâm trong câu (VD: `["ʃ", "s", "z"]`) |
| `level` | `int` | Độ khó (1: Dễ, 2: Trung bình, 3: Khó) |

#### 3. Bảng `practice_sessions` (Lịch sử luyện tập & Kết quả chấm điểm)
| Tên trường | Kiểu dữ liệu | Mô tả |
| :--- | :--- | :--- |
| `id` | `String` | Khóa chính |
| `user_id` | `String` | Khóa ngoại tham chiếu `users.id` |
| `sentence_id` | `String` | Khóa ngoại tham chiếu `sentences.id` |
| `user_audio_path` | `String` | Đường dẫn file ghi âm của người dùng |
| `overall_score` | `double` | Tổng điểm phát âm ($0.0 - 100.0$) |
| `accuracy_score` | `double` | Điểm độ chính xác phát âm âm vị |
| `fluency_score` | `double` | Điểm độ trôi chảy (tốc độ nói, ngắt nghỉ) |
| `word_details_json`| `JSON String` | Chuỗi JSON lưu chi tiết điểm của từng từ và từng âm vị (Phoneme) |
| `duration_seconds` | `int` | Thời gian thực hiện bài tập (giây) |
| `created_at` | `DateTime` | Thời điểm chấm điểm |

#### 4. Bảng `weak_phonemes` (Thống kê âm vị yếu để đề xuất bài tập)
| Tên trường | Kiểu dữ liệu | Mô tả |
| :--- | :--- | :--- |
| `phoneme` | `String` | Ký hiệu âm vị IPA hoặc ARPAbet (VD: `/θ/`, `/ð/`, `/ʃ/`) |
| `total_attempts` | `int` | Tổng số lần người dùng đã phát âm âm vị này |
| `average_score` | `double` | Điểm trung bình của âm vị này |
| `need_practice` | `bool` | Cờ đánh dấu cần ưu tiên đề xuất bài tập (Khi `average_score < 65`) |

---

## 4. THIẾT KẾ CHI TIẾT CÁC MODULE CHỨC NĂNG

### 4.1. Module Theo dõi Tiến độ & Chuỗi ngày học - Streak (Hạng mục 02 & 06)

#### A. Thuật toán tính toán Streak (Streak Calculation Logic)
Gọi $D_{today}$ là ngày hiện tại (theo múi giờ thiết bị) và $D_{last}$ là `last_active_date` được lưu trong DB. Khoảng cách ngày là $\Delta D = D_{today} - D_{last}$ (tính theo đơn vị ngày lịch):

1. **Khi khởi động ứng dụng (App Launch Check):**
   * Nếu $\Delta D > 1$: Người dùng đã bỏ lỡ ít nhất 1 ngày hôm qua $\rightarrow$ Reset `current_streak = 0`.
   * Nếu $\Delta D \le 1$: Giữ nguyên `current_streak`.
2. **Khi người dùng hoàn thành một phiên học (Session Completed):**
   * Cộng dồn `duration_seconds` vào `study_seconds` của bảng `daily_logs` trong ngày $D_{today}$.
   * Kiểm tra điều kiện đạt mục tiêu ngày: $\text{study\_seconds} \ge \text{daily\_goal\_minutes} \times 60$.
   * Nếu đạt mục tiêu và trước đó trong ngày chưa được tính Streak:
     * Nếu $\Delta D == 1$ (Hôm qua có học) hoặc $D_{last} == \text{null}$: Tăng `current_streak = current_streak + 1`.
     * Nếu $\Delta D > 1$: Đặt `current_streak = 1`.
     * Cập nhật `last_active_date` $= D_{today}$.
     * Nếu `current_streak > longest_streak` $\rightarrow$ Cập nhật `longest_streak = current_streak`.

#### B. Hệ thống đếm thời gian học thực tế (Study Time Tracker)
* Sử dụng một `Stopwatch` kết hợp với `WidgetsBindingObserver` trong Flutter để lắng nghe vòng đời ứng dụng (`AppLifecycleState`).
* Chỉ tính thời gian khi người dùng đang ở màn hình Luyện tập (`PracticeScreen`) và ứng dụng ở trạng thái `resumed`. Tự động `pause()` đồng hồ khi ứng dụng xuống nền (`paused`/`inactive`).

#### C. Hệ thống Thông báo nhắc nhở (Daily Notification)
* Sử dụng `flutter_local_notifications` với phương thức `zonedSchedule` và tham số `matchDateTimeComponents: DateTimeComponents.time`.
* **Cơ chế thông minh:** Nếu trong ngày $D_{today}$ người dùng đã đạt mục tiêu (`is_goal_met == true`), hệ thống sẽ tự động hủy thông báo của tối hôm đó và đặt lại lịch cho ngày hôm sau để tránh làm phiền.

---

### 4.2. Module Thu âm & Tích hợp AI Phân tích Phát âm (Hạng mục 03 & 04)

#### A. Quy trình xử lý âm thanh (Audio Pipeline)
Để mô hình AI chấm điểm âm vị chính xác nhất, không sử dụng bộ nhận diện giọng nói mặc định của bàn phím điện thoại (chỉ trả về text), mà phải gửi luồng âm thanh thô (Raw Audio) lên Engine đánh giá phát âm chuyên dụng.

* **Thông số thu âm chuẩn:** Định dạng `WAV (PCM 16-bit)`, tần số lấy mẫu `16,000 Hz` (16kHz), kênh `Mono` (1 channel).
* **Tiền xử lý (Pre-processing):** Sử dụng Voice Activity Detection (VAD) hoặc cắt bỏ khoảng lặng đầu/cuối quá dài trước khi gửi API để giảm dung lượng và độ trễ.

#### B. Giải pháp tích hợp AI & So sánh âm vị (Phoneme Comparison)
Đề xuất sử dụng 1 trong 2 phương án kiến trúc AI sau trong ứng dụng Flutter:

* **Phương án 1 (Khuyên dùng cho Production - Độ chính xác cao, dễ tích hợp):** Sử dụng **Microsoft Azure Cognitive Services - Pronunciation Assessment API** hoặc **SpeechSuper API**.
  * *Đầu vào:* File Audio `.wav` + Reference Text (Câu tiếng Anh mẫu).
  * *Cơ chế:* AI tự động tách từ, phân rã thành các âm vị theo chuẩn IPA/ARPAbet, căn chỉnh thời gian (Forced Alignment) và chấm điểm GOP (Goodness of Pronunciation) cho từng âm vị.
* **Phương án 2 (Tự xây dựng AI Backend - Phù hợp nghiên cứu sâu):** 
  * Xây dựng Python FastAPI Server chạy mô hình **Wav2Vec2-CTC** (Fine-tuned cho nhận diện âm vị tiếng Anh) kết hợp thuật toán **Needleman-Wunsch** hoặc **Levenshtein Distance** để gióng hàng chuỗi âm vị thực tế của người dùng ($P_{actual}$) với chuỗi âm vị chuẩn ($P_{expected}$).

#### C. Công thức chấm điểm và Phân loại lỗi
Mỗi âm vị $p_i$ trong từ sẽ nhận một điểm số $S(p_i) \in [0, 100]$.
* **Điểm của một từ ($S_{word}$):** Trung bình có trọng số của các âm vị cấu thành từ đó:
  $$S_{word} = \frac{1}{N} \sum_{i=1}^{N} S(p_i)$$
* **Điểm tổng kết câu ($S_{overall}$):** Kết hợp từ điểm Chính xác ($S_{accuracy}$), điểm Trôi chảy ($S_{fluency}$) và điểm Hoàn thiện ($S_{completeness}$):
  $$S_{overall} = 0.6 \times S_{accuracy} + 0.2 \times S_{fluency} + 0.2 \times S_{completeness}$$

* **Ngưỡng phân loại chất lượng phát âm âm vị:**
  * $S(p_i) \ge 80$: **Chính xác (Good)** $\rightarrow$ Hiển thị màu **Xanh lá (`#2ECC71`)**.
  * $60 \le S(p_i) < 80$: **Tạm được / Lệch nhẹ (Warning)** $\rightarrow$ Hiển thị màu **Vàng cam (`#F39C12`)**.
  * $S(p_i) < 60$: **Phát âm sai / Bỏ sót (Mispronounced/Omission)** $\rightarrow$ Hiển thị màu **Đỏ (`#E74C3C`)**.

#### D. Cấu trúc JSON trả về từ tầng xử lý AI (Chuẩn hóa trong Flutter)
```json
{
  "overall_score": 78.5,
  "accuracy_score": 76.0,
  "fluency_score": 85.0,
  "completeness_score": 100.0,
  "words": [
    {
      "word": "think",
      "ipa": "θɪŋk",
      "score": 62.0,
      "error_type": "Mispronunciation",
      "phonemes": [
        {"phoneme": "θ", "actual_spoken": "s", "score": 35.0, "status": "bad"},
        {"phoneme": "ɪ", "actual_spoken": "ɪ", "score": 85.0, "status": "good"},
        {"phoneme": "ŋ", "actual_spoken": "n", "score": 58.0, "status": "bad"},
        {"phoneme": "k", "actual_spoken": "k", "score": 90.0, "status": "good"}
      ]
    }
  ]
}
```

---

### 4.3. Module Phản hồi & Đề xuất Bài tập Cải thiện (Hạng mục 05)

#### A. Giao diện Phản hồi Trực quan (Interactive Feedback UI)
1. **RichText Highlighting:** Hiển thị câu vừa đọc, mỗi từ và ký tự phiên âm IPA bên dưới được tô màu động (Xanh/Vàng/Đỏ) dựa trên dữ liệu JSON trả về.
2. **Phoneme Inspector BottomSheet:** Khi người dùng chạm vào một từ bị màu đỏ (VD: từ *"think"*):
   * Hiển thị chi tiết: *"Bạn đã phát âm âm **/θ/** nghe giống như âm **/s/** (Điểm: 35/100)"*.
   * Hướng dẫn khẩu hình miệng (Mouth/Tongue Position tip): *"Đặt đầu lưỡi nhẹ giữa hai hàm răng và thổi hơi ra, không rung dây thanh quản."*
   * Nút **Nghe so sánh:** Phát 2 luồng âm thanh nối tiếp nhau: `[Giọng chuẩn bản xứ cắt theo timestamp của từ]` $\rightarrow$ `[Giọng thu âm của người dùng tại từ đó]`.

#### B. Thuật toán Đề xuất Bài tập Cải thiện (Recommendation Engine)
Sau mỗi phiên luyện tập, hệ thống cập nhật bảng `weak_phonemes` bằng công thức trung bình trượt hàm mũ (Exponential Moving Average - EMA) để phản ánh phong độ hiện tại của người dùng đối với âm vị $p$:
$$\text{Score}_{new}(p) = \alpha \cdot S_{current}(p) + (1 - \alpha) \cdot \text{Score}_{old}(p) \quad (\text{với } \alpha = 0.3)$$

* **Quy tắc kích hoạt đề xuất:**
  1. Lọc ra tối đa 3 âm vị có $\text{Score}_{new}(p) < 65.0$.
  2. Truy vấn cơ sở dữ liệu `sentences` để tìm các bài tập có `focus_phonemes` chứa các âm vị yếu này, ưu tiên các bài tập **Minimal Pairs** (Cặp tối thiểu, ví dụ người dùng hay nhầm `/θ/` và `/s/` sẽ được gợi ý luyện cặp từ: *think - sink*, *thick - sick*, *mouth - mouse*).
  3. Hiển thị danh sách **"Bài tập khắc phục dành riêng cho bạn"** ngay dưới màn hình kết quả và trên màn hình Trang chủ.

---

## 5. THIẾT KẾ GIAO DIỆN NGƯỜI DÙNG (UI/UX WIREFRAMES & СТРУКТУРА)

### 5.1. Sơ đồ luồng màn hình (Screen Navigation Flow)
Ứng dụng gồm 4 Tab chính trên `BottomNavigationBar`:
1. **Trang chủ (Home Dashboard):** Hiển thị chuỗi Streak, tiến độ mục tiêu ngày (Circular Progress), danh sách bài tập đề xuất khắc phục lỗi sai và các chủ đề học.
2. **Luyện tập (Practice Screen):** Màn hình thu âm, hiển thị sóng âm, chấm điểm AI và hiển thị phản hồi chi tiết.
3. **Thống kê (Analytics & Progress):** Lịch Streak (Heatmap Calendar), biểu đồ thời gian học 7 ngày qua, bảng xếp hạng các âm vị mạnh nhất/yếu nhất.
4. **Cá nhân & Cài đặt (Profile & Settings):** Chỉnh sửa mục tiêu phút học mỗi ngày, bật/tắt và chọn giờ thông báo nhắc nhở, đổi giọng mẫu (Anh-Mỹ / Anh-Anh).

### 5.2. Phác thảo bố cục màn hình Luyện tập & Phản hồi (Practice & Feedback Screen)

```
+---------------------------------------------------+
|  < Quay lại      Luyện phát âm AI         [3/10]  |
+---------------------------------------------------+
|                                                   |
|   "She sells seashells by the seashore"           |
|    /ʃiː   sɛlz   ˈsiːˌʃɛlz  baɪ  ðə  ˈsiːˌʃɔːr/   |
|    [Xanh] [Xanh]  [ ĐỎ ]   [Xanh][Vàng] [ ĐỎ ]    |
|     (92)   (88)    (45)     (95)  (72)   (50)     |
|                                                   |
|   [🔊 Nghe mẫu]              [🎧 Nghe lại giọng]  |
+---------------------------------------------------+
|  ĐIỂM TỔNG: 73/100 (Khá)                          |
|  - Chính xác: 68%  | Trôi chảy: 82% | Đầy đủ: 100%|
|                                                   |
|  ⚠️ Phát hiện lỗi âm vị cần sửa:                  |
|  +---------------------------------------------+  |
|  | Âm /ʃ/ trong "seashells" bị đọc thành /s/   |  |
|  | 💡 Mẹo: Chu môi nhẹ về phía trước khi thổi  |  |
|  | [👉 Luyện ngay 3 từ chứa âm /ʃ/]            |  |
|  +---------------------------------------------+  |
+---------------------------------------------------+
|              ((( 🎙️ Nhấn để đọc lại )))           |
+---------------------------------------------------+
```

---

## 6. CẤU TRÚC THƯ MỤC DỰ ÁN FLUTTER (PROJECT STRUCTURE)

```text
lib/
├── core/
│   ├── constants/         # Màu sắc, ngưỡng điểm, cấu hình API
│   ├── error/             # Xử lý ngoại lệ (Mất mạng, Lỗi Micro, Lỗi AI API)
│   ├── services/          # NotificationService, AudioRecorderService
│   └── utils/             # DateTimeHelper (tính Streak), AudioNormalizer
├── data/
│   ├── datasources/
│   │   ├── local/         # SQLite / Isar Database, DAO
│   │   └── remote/        # SpeechAssessmentApiService (Azure/FastAPI)
│   ├── models/            # JSON Serializable Models (SessionModel, PhonemeModel)
│   └── repositories/      # Triển khai các Repository
├── domain/
│   ├── entities/          # User, Sentence, AssessmentResult, StreakInfo
│   ├── repositories/      # Abstract Interfaces
│   └── usecases/
│       ├── evaluate_pronunciation_usecase.dart
│       ├── update_streak_and_progress_usecase.dart
│       └── get_recommended_exercises_usecase.dart
├── presentation/
│   ├── blocs/             # PracticeBloc, StreakBloc, AnalyticsBloc
│   ├── screens/
│   │   ├── home/
│   │   ├── practice/
│   │   ├── analytics/
│   │   └── settings/
│   └── widgets/
│       ├── phoneme_colored_text.dart
│       ├── streak_flame_badge.dart
│       └── audio_waveform_recorder.dart
└── main.dart
```

---

## 7. KẾ HOẠCH KIỂM THỬ HỆ THỐNG & AI (HẠNG MỤC 07)

Để đảm bảo độ chính xác của hệ thống phân tích AI và tính ổn định của ứng dụng với nhiều đối tượng người dùng khác nhau, kế hoạch kiểm thử được chia thành 4 giai đoạn:

### 7.1. Kiểm thử Độ chính xác của AI theo Đa dạng Giọng nói (AI & Acoustic Testing)
Thực hiện thu thập tập dữ liệu kiểm thử từ tối thiểu **15 - 20 người dùng tình nguyện** với các đặc điểm giọng nói khác nhau:

| Nhóm kịch bản kiểm thử | Mô tả chi tiết | Tiêu chí đạt (Acceptance Criteria) |
| :--- | :--- | :--- |
| **Đa dạng vùng miền & Giới tính** | Nam/Nữ ở các độ tuổi khác nhau, người mới bắt đầu (vùng miền Bắc, Trung, Nam) và người có trình độ IELTS Speaking $\ge 7.0$. | Độ lệch chuẩn giữa điểm AI chấm và điểm do giáo viên tiếng Anh chấm thủ công không vượt quá $\pm 10\%$. |
| **Kiểm thử Phát âm sai có chủ đích (Negative Testing)** | Người kiểm thử cố tình đọc sai các âm khó đối với người Việt: đọc `/θ/` thành `/t/` hoặc `/s/`, bỏ âm cuối (Ending sounds `/k/`, `/t/`, `/s/`). | AI phải bắt được lỗi và đánh dấu màu đỏ ($< 60$ điểm) đúng vào âm vị bị đọc sai hoặc bị bỏ sót với tỷ lệ phát hiện $\ge 90\%$. |
| **Môi trường và Thiết bị thu âm** | Kiểm thử trong phòng kín yên tĩnh ($< 30\text{ dB}$), phòng có tiếng quạt/điều hòa, và quán cà phê ồn nhẹ ($50 - 60\text{ dB}$); thử nghiệm trên cả micro mặc định của máy và tai nghe Bluetooth. | Hệ thống lọc nhiễu hoạt động ổn định; cảnh báo người dùng nếu âm thanh thu vào quá nhỏ hoặc quá ồn thay vì chấm điểm 0 vô lý. |
| **Tốc độ nói (Fluency Testing)** | Đọc ngắt quãng từng từ rời rạc so với đọc nối âm tự nhiên. | Điểm `accuracy_score` có thể tương đương nhưng `fluency_score` của lần đọc ngắt quãng phải thấp hơn rõ rệt ($< 60$). |

### 7.2. Kiểm thử Logic Chuỗi ngày học & Thông báo (Unit & Integration Tests)
*   **Mocking DateTime:** Viết Unit Test trong Flutter (`flutter_test`) giả lập việc thay đổi thời gian hệ thống:
    *   *Test case 1:* Học đủ 15 phút ngày hôm nay $\rightarrow$ Tăng Streak lên 1. Học tiếp 15 phút nữa trong cùng ngày $\rightarrow$ Streak vẫn giữ nguyên là 1.
    *   *Test case 2:* Giả lập đồng hồ sang ngày hôm sau và hoàn thành mục tiêu $\rightarrow$ Streak tăng lên 2.
    *   *Test case 3:* Giả lập bỏ qua 1 ngày không học $\rightarrow$ Khi mở app vào ngày thứ 3, `current_streak` tự động về 0 nhưng `longest_streak` vẫn bảo toàn kỷ lục cũ.
*   **Kiểm thử Thông báo:** Kiểm tra thông báo đẩy hiển thị đúng giờ đã cài đặt ngay cả khi ứng dụng đã bị đóng hoàn toàn (Terminated state) hoặc sau khi khởi động lại điện thoại (nhờ `BOOT_COMPLETED` receiver trên Android).

### 7.3. Kiểm thử Hiệu năng (Performance Benchmarks)
*   **Thời gian phản hồi chấm điểm AI:** Từ lúc người dùng bấm dừng thu âm đến khi hiển thị bảng phân tích màu sắc âm vị không vượt quá **2.5 giây** (với mạng 4G/Wi-Fi tiêu chuẩn).
*   **Tốc độ khung hình (UI Frame Rate):** Màn hình vẽ sóng âm thời gian thực khi thu âm duy trì ổn định ở mức **60 FPS**, không gây giật lag giao diện.