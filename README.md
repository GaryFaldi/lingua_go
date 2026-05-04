# lingua_go

A new Flutter project.

## Project Structure

### lib/

```
lib/
├── main.dart                               # Entry point, Hive init, ProviderScope, NotificationService
│
├── core/                                   # Core utilities & configurations
│   ├── services/
│   │   └── notification_service.dart       # Local notifications, push notifications
│   ├── theme/
│   │   └── app_theme.dart                  # Tokens warna, spacing, ThemeData Material 3
│   └── utils/
│       └── hash_helper.dart                # Password hashing utilities
│
├── data/                                   # Data layer - Repositories & Models
│   ├── local/
│   │   ├── database_helper.dart            # SQLite database operations
│   │   ├── linguaquest.db                  # Local database file
│   │   └── quest_data.dart                 # Local quest data management
│   ├── models/
│   │   ├── quest_model.dart                # Quest data model
│   │   └── user_model.dart                 # User profile data model
│   └── repositories/
│       ├── auth_repository.dart            # Authentication logic & API calls
│       └── profile_repository.dart         # User profile logic & API calls
│
└── features/                               # Feature modules
    ├── auth/                               # Authentication feature
    │   ├── auth_provider.dart              # Auth state management (Riverpod)
    │   ├── lock_screen.dart                # Biometric lock screen
    │   ├── login_page.dart                 # Login UI
    │   └── register_page.dart              # Registration UI
    │
    ├── home/                               # Home & main features
    │   ├── home_page.dart                  # Home screen
    │   ├── main_navigation.dart            # Main navigation routes (GoRouter)
    │   │
    │   ├── chatbot/                        # AI Chatbot feature
    │   │   ├── chatbot_page.dart           # Chatbot conversation UI
    │   │   └── chatbot_provider.dart       # Chatbot state & API integration
    │   │
    │   ├── dictionary/                     # Dictionary lookup feature
    │   │   └── dictionary_page.dart        # Dictionary search & translation UI
    │   │
    │   ├── main_quest/                     # Main language learning quests
    │   │   ├── quest_detail_page.dart      # Quest detail & execution
    │   │   ├── quest_list_page.dart        # List of available quests
    │   │   └── quest_provider.dart         # Quest state management (Riverpod)
    │   │
    │   └── side_quest/                     # Bonus mini-games
    │       ├── crack_the_egg_page.dart     # Mini-game: Crack the Egg
    │       ├── tilt_a_word_page.dart       # Mini-game: Tilt a Word
    │       └── word_bank_page.dart         # Mini-game: Word Bank
    │
    ├── profile/                            # User profile feature
    │   ├── profile_page.dart               # Profile display & settings
    │   └── profile_provider.dart           # Profile state management (Riverpod)
    │
    └── traveler/                           # Travel companion features
        ├── currency_page.dart              # Currency converter UI
        ├── currency_service.dart           # Currency conversion logic
        ├── language_center_page.dart       # Language learning center
        ├── time_conversion.dart            # Timezone/time conversion utilities
        └── traveler_page.dart              # Traveler hub UI
```

### Architecture Pattern
- **State Management**: Riverpod (providers in `*_provider.dart`)
- **Routing**: GoRouter (defined in `main_navigation.dart`)
- **Database**: SQLite via `database_helper.dart`
- **Authentication**: JWT-based auth with biometric support
- **UI Components**: Material 3 design system via `app_theme.dart`
