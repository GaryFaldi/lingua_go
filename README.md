# Lingua-Go: Platform Pembelajaran Bahasa Inggris Interaktif

Lingua-Go adalah aplikasi Flutter untuk pembelajaran bahasa Inggris dengan fitur gamifikasi, AI chatbot, dan mini-games yang menyenangkan.

---

## 📱 Tech Stack

```
Frontend        : Flutter 3.11+, Material 3 Design System
State Mgmt      : Provider (ChangeNotifier Pattern)
Database        : SQLite via sqflite
Authentication  : Password hashing (crypto), Biometric (local_auth)
Backend APIs    : Gemini 2.5 Flash (AI Chatbot), External APIs
Notifications   : flutter_local_notifications (Android)
Utilities       : GetX, GoRouter, timezone, geolocator, geocoding
```

---

## 🏗️ Arsitektur Aplikasi

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                       PRESENTATION LAYER                         │
│  (UI Pages + Widgets: LoginPage, HomePage, QuestDetailPage, etc) │
└──────────────────────────┬──────────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│                    STATE MANAGEMENT LAYER                        │
│  AuthProvider (ChangeNotifier) │ QuestProvider │ ChatBotProvider │
└──────────────────────────┬──────────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│                      REPOSITORY LAYER                            │
│   AuthRepository │ ProfileRepository (Business Logic)            │
└──────────────────────────┬──────────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
    ┌────────┐      ┌──────────────┐   ┌──────────┐
    │ Local  │      │  HTTP Client │   │ External │
    │ SQLite │      │  (Gemini)    │   │   APIs   │
    │Database│      └──────────────┘   └──────────┘
    └────────┘
```

---

## 📂 Struktur Project Lengkap

```
lib/
├── main.dart                               # ★ Entry point utama aplikasi
│
├── core/                                   # ★ Shared utilities & configurations
│   ├── services/
│   │   └── notification_service.dart       # Local notifications scheduling
│   │       ├── init() → Inisialisasi Flutter Local Notifications
│   │       ├── scheduleDailySevenAM() → Jadwal notif harian 7 AM
│   │       └── showTestNotification() → Test notifikasi
│   │
│   ├── theme/
│   │   └── app_theme.dart                  # Material 3 ThemeData
│   │       ├── colorScheme: Custom color palette
│   │       ├── textTheme: Typography setup
│   │       └── appBarTheme, buttonTheme: Widget styling
│   │
│   └── utils/
│       └── hash_helper.dart                # Password security utilities
│           ├── hashPassword(password, salt) → SHA-256 hashing
│           └── verifyPassword(pwd, salt, hash) → Verify password
│
├── data/                                   # ★ Data layer (Models + Repositories)
│   ├── models/
│   │   ├── user_model.dart                 # User data model
│   │   │   ├── Fields: id, username, passwordHash, salt, photoPath, xp, currentLevel, createdAt
│   │   │   ├── toMap() → Convert model ke Map<String, dynamic>
│   │   │   └── fromMap() → Create instance dari Map
│   │   │
│   │   └── quest_model.dart                # Learning quest models
│   │       ├── class QuestLevel
│   │       │   ├── level: int
│   │       │   ├── title, subtitle, emoji: String
│   │       │   ├── vocabs: List<VocabItem>
│   │       │   └── xpReward: int (default 100)
│   │       │
│   │       └── class VocabItem
│   │           ├── word, meaning, example, pronunciation: String
│   │           └── category: String (e.g., 'saved', 'daily')
│   │
│   ├── local/
│   │   ├── database_helper.dart            # ★ SQLite Database Layer
│   │   │   ├── Singleton pattern: DatabaseHelper.instance
│   │   │   ├── _initDB() → Open/create database
│   │   │   ├── _createDB() → Create tables (users, quest_progress, word_bank, suggestions)
│   │   │   ├── User CRUD: registerUser(), loginUser(), getUserById()
│   │   │   ├── Quest CRUD: getQuestProgress(), updateProgress()
│   │   │   ├── Word Bank: getWordBank(), addWordToBank(), removeWordFromBank()
│   │   │   └── Suggestions: addSuggestion()
│   │   │
│   │   ├── quest_data.dart                 # Static quest data
│   │   │   └── QuestData.levels: List<QuestLevel> (hardcoded quest levels)
│   │   │
│   │   └── linguaquest.db                  # SQLite database file
│   │
│   └── repositories/
│       ├── auth_repository.dart            # ★ Authentication business logic
│       │   ├── register(username, password)
│       │   │   ├── Validate username uniqueness
│       │   │   ├── Hash password with salt
│       │   │   └── Insert user to database
│       │   │
│       │   ├── login(username, password)
│       │   │   ├── Query user from database
│       │   │   ├── Verify password hash
│       │   │   └── Return UserModel if valid
│       │   │
│       │   ├── getUserById(userId) → Fetch user profile
│       │   └── updateUserPhoto(userId, photoPath) → Update profile picture
│       │
│       └── profile_repository.dart         # User profile operations
│           ├── updateProfile(userId, data)
│           ├── getProfileStats(userId)
│           └── uploadProfilePicture(userId, imagePath)
│
└── features/                               # ★ Feature modules (Clean Architecture)
    │
    ├── auth/                               # Authentication feature
    │   ├── auth_provider.dart              # ★ State management (ChangeNotifier)
    │   │   ├── Fields:
    │   │   │   ├── _currentUser: UserModel?
    │   │   │   ├── _isLoading: bool
    │   │   │   ├── _errorMessage: String?
    │   │   │   └── _lockedUsername: String? (untuk lock screen)
    │   │   │
    │   │   ├── Methods:
    │   │   │   ├── tryRestoreSession() → Restore session dari SharedPreferences
    │   │   │   ├── register(username, pwd) → Register user baru
    │   │   │   ├── login(username, pwd) → Login user
    │   │   │   ├── unlockWithPassword(pwd) → Unlock lock screen
    │   │   │   ├── unlockWithBiometric() → Unlock dengan fingerprint/face
    │   │   │   ├── logout() → Clear session
    │   │   │   └── changePassword(oldPwd, newPwd) → Change password
    │   │   │
    │   │   ├── Getters:
    │   │   │   ├── currentUser: UserModel?
    │   │   │   ├── isLoggedIn: bool
    │   │   │   ├── isLoading: bool
    │   │   │   └── errorMessage: String?
    │   │   │
    │   │   └── Session Persistence: SharedPreferences
    │   │       ├── Key 'user_id': int
    │   │       └── Key 'locked_username': String
    │   │
    │   ├── login_page.dart                 # Login UI
    │   │   ├── TextFormField: username, password
    │   │   ├── Button: Login
    │   │   ├── Link: Register page
    │   │   └── Form validation
    │   │
    │   ├── register_page.dart              # Registration UI
    │   │   ├── TextFormField: username, password, confirm password
    │   │   ├── Validation: Password strength, match check
    │   │   └── Button: Register
    │   │
    │   └── lock_screen.dart                # Biometric lock screen
    │       ├── Display locked_username
    │       ├── Biometric unlock button (fingerprint/face)
    │       ├── Fallback: Password input
    │       └── Logout option
    │
    ├── home/                               # Home & main navigation hub
    │   ├── main_navigation.dart            # ★ GoRouter setup
    │   │   ├── Routes:
    │   │   │   ├── /login → LoginPage
    │   │   │   ├── /register → RegisterPage
    │   │   │   ├── /lock → LockScreen
    │   │   │   ├── / → HomePage
    │   │   │   ├── /quest → QuestListPage
    │   │   │   ├── /quest/:id → QuestDetailPage
    │   │   │   ├── /profile → ProfilePage
    │   │   │   ├── /traveler → TravelerPage
    │   │   │   ├── /chatbot → ChatbotPage
    │   │   │   └── /side-quest/:id → SideQuestPage
    │   │   │
    │   │   └── Route guards: Check auth status
    │   │
    │   ├── home_page.dart                  # Home screen UI
    │   │   ├── Display: User name, current XP, level
    │   │   ├── Quick links: Quest, Mini-games, Chatbot, Traveler
    │   │   ├── Daily challenge reminder
    │   │   └── Stats dashboard
    │   │
    │   ├── chatbot/                        # AI-powered learning assistant
    │   │   ├── chatbot_provider.dart       # ★ Chatbot state management
    │   │   │   ├── Fields:
    │   │   │   │   ├── _messages: List<ChatMessage>
    │   │   │   │   ├── _isLoading: bool
    │   │   │   │   ├── _apiKey: String (from .env)
    │   │   │   │   └── _systemPrompt: String (LinguaBot personality)
    │   │   │   │
    │   │   │   ├── Constants:
    │   │   │   │   └── _apiUrl: 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent'
    │   │   │   │
    │   │   │   ├── Methods:
    │   │   │   │   ├── sendMessage(text) → Send user message
    │   │   │   │   │   ├── Build conversation history
    │   │   │   │   │   ├── POST to Gemini API
    │   │   │   │   │   ├── Parse response
    │   │   │   │   │   └── Update messages list
    │   │   │   │   │
    │   │   │   │   └── Getters:
    │   │   │   │       ├── messages: List<ChatMessage> (unmodifiable)
    │   │   │   │       └── isLoading: bool
    │   │   │   │
    │   │   │   └── ChatMessage model:
    │   │   │       ├── text: String
    │   │   │       ├── isUser: bool
    │   │   │       └── time: DateTime
    │   │   │
    │   │   ├── chatbot_page.dart           # Chatbot UI
    │   │   │   ├── ListView: Message display
    │   │   │   ├── TextField: User input
    │   │   │   ├── Loading indicator
    │   │   │   └── Markdown support for bot responses
    │   │   │
    │   │   └── API Specification:
    │   │       ├── Endpoint: Gemini 2.5 Flash
    │   │       ├── Method: POST
    │   │       ├── Request body:
    │   │       │   ├── system_instruction: { parts: [{ text: systemPrompt }] }
    │   │       │   ├── contents: [ { role: "user"|"model", parts: [{ text }] } ]
    │   │       │   └── generationConfig: { temperature: 0.7 }
    │   │       │
    │   │       └── Response:
    │   │           └── candidates[0].content.parts[0].text: String (response)
    │   │
    │   ├── dictionary/                     # Word lookup & translation
    │   │   └── dictionary_page.dart        # Dictionary search UI
    │   │       ├── SearchBar: Find words
    │   │       ├── Display: Word, meaning, pronunciation, examples
    │   │       ├── Save to word bank
    │   │       └── Integration with external dictionary API (optional)
    │   │
    │   ├── main_quest/                     # Main learning quests system
    │   │   ├── quest_provider.dart         # ★ Quest state management (ChangeNotifier)
    │   │   │   ├── Fields:
    │   │   │   │   ├── userId: int (required)
    │   │   │   │   ├── _levels: List<QuestLevel>
    │   │   │   │   ├── _currentXp: int
    │   │   │   │   ├── _completedLevels: int
    │   │   │   │   ├── _wordBank: List<VocabItem>
    │   │   │   │   └── _isLoading: bool
    │   │   │   │
    │   │   │   ├── Getters:
    │   │   │   │   ├── levels: List<QuestLevel>
    │   │   │   │   ├── currentXp: int
    │   │   │   │   ├── completedLevels: int
    │   │   │   │   ├── wordBank: List<VocabItem>
    │   │   │   │   ├── currentLevel: int (derivable)
    │   │   │   │   └── isLoading: bool
    │   │   │   │
    │   │   │   ├── Methods:
    │   │   │   │   ├── _init() → Load quest data from database
    │   │   │   │   │   ├── Fetch quest progress
    │   │   │   │   │   ├── Fetch word bank
    │   │   │   │   │   └── Load QuestData.levels
    │   │   │   │   │
    │   │   │   │   ├── addXp(amount) → Add XP after quest completion
    │   │   │   │   │   ├── Increment _currentXp
    │   │   │   │   │   ├── Update database
    │   │   │   │   │   └── notifyListeners()
    │   │   │   │   │
    │   │   │   │   ├── completeLevel(level) → Mark level complete
    │   │   │   │   │   ├── Update _completedLevels
    │   │   │   │   │   └── Update database
    │   │   │   │   │
    │   │   │   │   ├── addToWordBank(vocab) → Save vocabulary
    │   │   │   │   │   ├── Add to _wordBank list
    │   │   │   │   │   └── Insert to database
    │   │   │   │   │
    │   │   │   │   ├── removeFromWordBank(word) → Remove saved word
    │   │   │   │   │
    │   │   │   │   └── isInWordBank(word) → Check if word saved
    │   │   │   │
    │   │   │   └── Database operations via DatabaseHelper
    │   │   │
    │   │   ├── quest_list_page.dart        # List all available quests
    │   │   │   ├── GridView: Quest cards
    │   │   │   ├── Display: Level, title, emoji, lock status
    │   │   │   ├── Unlocked levels clickable
    │   │   │   └── Show required XP for locked levels
    │   │   │
    │   │   └── quest_detail_page.dart      # Quest execution & learning
    │   │       ├── Display: QuestLevel details
    │   │       ├── Show vocabulary items
    │   │       ├── Quiz/Challenge mechanics
    │   │       ├── XP reward on completion
    │   │       └── Add vocab to word bank
    │   │
    │   └── side_quest/                     # Mini-games for engagement
    │       ├── crack_the_egg_page.dart     # Mini-game #1: Crack the Egg
    │       │   └── Gameplay: Tap to crack eggs revealing words/meanings
    │       │
    │       ├── tilt_a_word_page.dart       # Mini-game #2: Tilt a Word
    │       │   └── Gameplay: Use accelerometer to tilt device and match letters
    │       │       (Uses: sensors_plus package for device tilt sensing)
    │       │
    │       └── word_bank_page.dart         # Mini-game #3: Word Bank Manager
    │           ├── Display saved vocabulary
    │           ├── Review pronunciation
    │           ├── Search & filter
    │           └── Delete words
    │
    ├── profile/                            # User profile management
    │   ├── profile_provider.dart           # ★ Profile state management (ChangeNotifier)
    │   │   ├── Fields:
    │   │   │   ├── _user: UserModel?
    │   │   │   ├── _stats: Map<String, dynamic> (XP, level, progress)
    │   │   │   ├── _isLoading: bool
    │   │   │   └── _errorMessage: String?
    │   │   │
    │   │   ├── Methods:
    │   │   │   ├── loadProfile(userId) → Fetch user profile
    │   │   │   ├── updateProfilePicture(imagePath) → Change avatar
    │   │   │   ├── updateStats() → Refresh statistics
    │   │   │   └── logout() → Clear profile data
    │   │   │
    │   │   └── Database: SQLite via ProfileRepository
    │   │
    │   └── profile_page.dart               # Profile UI
    │       ├── Display: User info, avatar, level, XP, statistics
    │       ├── Buttons: Edit profile, Change password, Settings, Logout
    │       ├── Stats: Quests completed, words learned, XP earned
    │       └── Photo picker: Update avatar
    │
    └── traveler/                           # Travel companion utilities
        ├── traveler_page.dart              # Traveler hub UI
        │   ├── Navigation: Currency, Language Center, Time Conversion
        │   ├── Map integration (optional)
        │   └── Travel tips
        │
        ├── currency_page.dart              # Currency converter UI
        │   ├── Input: Amount & currencies
        │   └── Display: Converted amounts
        │
        ├── currency_service.dart           # Currency conversion logic
        │   ├── fetchExchangeRates() → Get live rates
        │   ├── convertCurrency(amount, from, to) → Calculate conversion
        │   └── API: External currency API (or hardcoded rates)
        │
        ├── language_center_page.dart       # Language learning center
        │   ├── Country guides
        │   ├── Travel phrases
        │   └── Cultural tips
        │
        └── time_conversion.dart            # Timezone utilities
            ├── getTimeInTimezone(timezone) → Get current time
            ├── convertTime(time, from, to) → Convert between timezones
            ├── Uses: timezone package with IANA database
            ├── Uses: lat_lng_to_timezone for GPS-based timezone
            └── Uses: geolocator for GPS coordinates
```

---

## 🗄️ Database Schema

```sql
-- Users table: Stores user authentication & profile data
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,       -- SHA-256 hashed with salt
  salt TEXT NOT NULL,                -- Used in hashing (username lowercase)
  photo_path TEXT,                   -- Profile picture path
  xp INTEGER DEFAULT 0,              -- Total experience points
  current_level INTEGER DEFAULT 1,   -- Current level (derivable from XP)
  created_at TEXT NOT NULL           -- ISO 8601 datetime
);

-- Quest progress: Tracks user progress in main quests
CREATE TABLE quest_progress (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL UNIQUE,   -- Foreign key to users
  xp INTEGER DEFAULT 0,              -- XP earned from quests
  completed_levels INTEGER DEFAULT 0,-- Number of completed quest levels
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Word bank: User's personal vocabulary collection
CREATE TABLE word_bank (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,          -- Foreign key to users
  word TEXT NOT NULL,                -- English word
  meaning TEXT,                      -- Indonesian translation
  example TEXT,                      -- Example sentence
  category TEXT,                     -- Category (e.g., 'saved', 'daily')
  added_at TEXT NOT NULL,            -- ISO 8601 datetime
  FOREIGN KEY (user_id) REFERENCES users(id),
  UNIQUE(user_id, word)              -- Prevent duplicate words per user
);

-- Suggestions: User feedback & suggestions
CREATE TABLE suggestions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  kesan TEXT,                        -- User impression/feedback
  saran TEXT,                        -- Suggestion
  created_at TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

---

## 🔐 Authentication & Security

### Password Hashing Strategy
```dart
// Using crypto package (SHA-256)
String hashPassword(String password, String salt) {
  return sha256.convert(utf8.encode(password + salt)).toString();
}

bool verifyPassword(String password, String salt, String hash) {
  return hashPassword(password, salt) == hash;
}

// Salt = username.toLowerCase() (consistent & unique per user)
```

### Session Persistence
```dart
// SharedPreferences keys:
// 'user_id' → User database ID
// 'locked_username' → Username for lock screen display

// Flow:
// 1. App starts → tryRestoreSession()
// 2. If user_id exists → Show LockScreen
// 3. Unlock with biometric or password → Set _currentUser
// 4. If no user_id → Show LoginPage
```

### Biometric Authentication
```dart
// Uses local_auth package
// Support: Fingerprint, Face recognition (Android)

LocalAuthentication().authenticate(
  localizedReason: 'Unlock Lingua-Go',
  options: AndroidAuthenticationOptions(...)
)
```

---

## 🔌 External API Integration

### 1. Gemini AI API (Chatbot)
**Purpose**: Power the AI chatbot for language learning assistance

```http
POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=YOUR_KEY

Content-Type: application/json

{
  "system_instruction": {
    "parts": [{
      "text": "Kamu adalah LinguaBot, asisten belajar bahasa Inggris yang ramah..."
    }]
  },
  "contents": [
    {
      "role": "user",
      "parts": [{ "text": "Apa itu 'serendipity'?" }]
    },
    {
      "role": "model",
      "parts": [{ "text": "Serendipity adalah..." }]
    }
  ],
  "generationConfig": {
    "temperature": 0.7,
    "maxOutputTokens": 256
  }
}
```

**Response**:
```json
{
  "candidates": [{
    "content": {
      "parts": [{
        "text": "Serendipity artinya penemuan kebahagiaan secara tidak terduga..."
      }]
    }
  }]
}
```

**Key Points**:
- API key stored in `.env` file (GEMINI_API_KEY)
- Conversation history built from previous messages
- Role: 'user' or 'model' (not 'assistant')
- Supports Markdown in responses

---

## 📊 State Management Architecture

### Provider Pattern (ChangeNotifier)

```dart
// Example: QuestProvider
class QuestProvider extends ChangeNotifier {
  final int userId;  // Scoped to user
  
  Future<void> _init() {
    // Load initial state
    notifyListeners();  // Notify UI subscribers
  }
  
  Future<void> addXp(int amount) {
    // Modify state
    await _db.updateProgress(...);
    notifyListeners();  // Trigger UI rebuild
  }
}

// Usage in UI:
Consumer<QuestProvider>(
  builder: (context, questProvider, _) {
    return Text(questProvider.currentXp.toString());
  }
)
```

### Key Providers:
1. **AuthProvider** - Authentication state (current user, loading, errors)
2. **QuestProvider** - Quest progression (XP, levels, word bank)
3. **ChatBotProvider** - Chatbot conversations
4. **ProfileProvider** - User profile statistics

---

## 🎮 Gamification System

### XP & Leveling
- **Quest Completion**: 100 XP per level
- **Mini-games**: Variable XP rewards
- **Daily Challenge**: +50 XP (via scheduled notification)

### Level Progression
```
Current Level = (Total XP / 100) + 1

Example:
- 0-99 XP → Level 1
- 100-199 XP → Level 2
- 200+ XP → Level 3
```

### Word Bank
- Users save vocabulary from quests
- Tracked in SQLite (unique per user per word)
- Used in "Word Bank" mini-game
- Supports categories & examples

---

## 🔔 Notifications System

### Implementation: flutter_local_notifications

```dart
// Initialization (in main.dart)
await NotificationService.init();

// Schedule daily notification at 7 AM
await NotificationService.scheduleDailySevenAM();

// Notification Details:
// Title: "Lingua-Go: Tantangan Hari Ini!"
// Body: "Yuk selesaikan Daily Challenge kamu dan dapatkan +50 XP! 🔥"
// Channel: 'daily_reminders'
// Priority: high, Importance: max
```

### Time Zone Handling
- Timezone database: timezone package (IANA)
- Default location: Asia/Jakarta (set in main.dart)
- Can be changed based on user location

---

## 🛣️ Navigation Flow

```
App Launch
    ↓
tryRestoreSession()
    ↓
┌─── Has user_id? ───┐
│                    │
├─ Yes → LockScreen   └─ No → LoginPage
    ↓                          ↓
Unlock (Biometric/Pwd)    ┌─ Login Success? ─┐
    ↓                     │                  │
    └─→ HomePage ←────────┴─ Register Pwd ──┘
         ↓
    ┌────┴────┬─────────┬──────────┬──────────┐
    │          │         │          │          │
    ↓          ↓         ↓          ↓          ↓
 Quest      Profile   Chatbot   Traveler   SideQuest
  List                              ↓
    ↓                         ┌──────┴──────┐
QuestDetail                   │             │
    ↓                      Currency    TimeZone
Complete Level                        Converter
+ Add XP
+ Update Word Bank
```

---

## 📦 Dependencies Overview

| Package | Purpose | Usage |
|---------|---------|-------|
| `flutter` | Core framework | UI, widgets |
| `provider` | State management | ChangeNotifier, Consumer |
| `sqflite` | Local database | SQLite operations |
| `http` | HTTP requests | API calls (Gemini) |
| `local_auth` | Biometric auth | Fingerprint, Face unlock |
| `shared_preferences` | Session storage | user_id, locked_username |
| `flutter_local_notifications` | Push notifications | Daily reminders |
| `timezone` | Timezone handling | Schedule notifications |
| `geolocator` | GPS coordinates | Location services |
| `geocoding` | Reverse geocoding | Coordinates → Address |
| `lat_lng_to_timezone` | GPS to timezone | Coordinate-based timezone |
| `sensors_plus` | Device sensors | Accelerometer for tilt games |
| `image_picker` | Photo selection | Profile picture upload |
| `flutter_markdown` | Markdown rendering | Chatbot response formatting |
| `google_fonts` | Typography | Custom fonts |
| `get` | Navigation helpers | Alternative routing |
| `intl` | Internationalization | Date/time formatting |

---

## 🚀 Running the Application

### Prerequisites
- Flutter 3.11+
- Dart 3.0+
- Android SDK 21+ / iOS 11+
- Gemini API key from Google AI Studio

### Setup Steps

1. **Clone & Install**
   ```bash
   flutter pub get
   ```

2. **Configure Environment**
   ```bash
   # Create .env file in project root
   echo "GEMINI_API_KEY=your_api_key_here" > .env
   echo "DB_NAME=linguaquest.db" >> .env
   echo "DB_VERSION=4" >> .env
   ```

3. **Run Application**
   ```bash
   flutter run              # Development
   flutter run --profile   # Performance testing
   flutter run --release   # Production
   ```

4. **Build APK/App**
   ```bash
   flutter build apk       # Android APK
   flutter build ios       # iOS app
   ```

---

## 🏛️ Project Architecture Philosophy

- **Clean Architecture**: Separation of concerns (UI → State → Repository → Data)
- **Single Responsibility**: Each file has one reason to change
- **Testability**: Repositories abstract database operations
- **Reusability**: Core services shared across features
- **Scalability**: Feature modules can be developed independently

---

## 📝 Key Classes & Methods Summary

### Core Classes

| Class | File | Purpose |
|-------|------|---------|
| `UserModel` | data/models/user_model.dart | User entity & serialization |
| `QuestLevel` | data/models/quest_model.dart | Quest definition |
| `VocabItem` | data/models/quest_model.dart | Vocabulary item |
| `DatabaseHelper` | data/local/database_helper.dart | SQLite singleton & operations |
| `AuthRepository` | data/repositories/auth_repository.dart | Auth business logic |
| `AuthProvider` | features/auth/auth_provider.dart | Auth state management |
| `QuestProvider` | features/home/main_quest/quest_provider.dart | Quest state management |
| `ChatBotProvider` | features/home/chatbot/chatbot_provider.dart | Chatbot state & API |
| `NotificationService` | core/services/notification_service.dart | Notification scheduling |

---

## 🎯 Future Enhancement Opportunities

1. **Backend API**: Replace SQLite with REST API for cloud sync
2. **Offline Support**: Add local caching for API responses
3. **Analytics**: Track user behavior & learning patterns
4. **Leaderboards**: Competitive XP rankings
5. **Achievements/Badges**: Reward system for milestones
6. **Social Features**: Share progress, collaborate with friends
7. **Advanced NLP**: Spell correction, pronunciation analysis
8. **Multiple Languages**: Support more language pairs
9. **Adaptive Learning**: AI-based difficulty adjustment
10. **Offline Translation**: Local translation model (edge computing)
