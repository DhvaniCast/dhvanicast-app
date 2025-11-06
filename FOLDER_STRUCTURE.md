# 📁 Harborleaf Radio App - Folder Structure Documentation

## 🎯 Overview
Yeh project **Feature-First Architecture** follow karta hai jo modern Flutter development ka best practice hai. Is approach mein har feature apne aap mein complete hota hai with its own data, domain, and presentation layers.

## 🏗️ Architecture Pattern
**Clean Architecture + Feature-First Organization**
- ✅ Clear separation of concerns
- ✅ Easy to locate code
- ✅ Scalable and maintainable
- ✅ Team-friendly structure

---

## 📂 Complete Folder Structure

```
lib/
├── main.dart                    # App entry point
├── injection.dart               # Dependency injection setup (GetIt)
│
├── features/                    # ✨ Feature-wise organization
│   │
│   ├── auth/                    # 🔐 Authentication Feature
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── user.dart
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user_entity.dart
│   │   │   └── usecases/
│   │   │       └── login_user.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── login_screen.dart
│   │       │   └── signup_screen.dart
│   │       └── state/
│   │           ├── auth_bloc.dart
│   │           ├── auth_event.dart
│   │           ├── auth_state.dart
│   │           └── auth_provider.dart
│   │
│   ├── radio/                   # 📻 Live Radio/Broadcast Feature
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── frequency_model.dart
│   │   │   │   └── group_model.dart
│   │   │   └── repositories/
│   │   │       ├── frequency_repository.dart
│   │   │       └── group_repository.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── frequency_entity.dart
│   │   │   └── usecases/
│   │   │       ├── join_frequency.dart
│   │   │       └── stream_audio.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── live_radio_screen.dart
│   │       │   ├── private_frequency_screen.dart
│   │       │   └── radio_controls.dart
│   │       └── state/
│   │           └── radio_provider.dart
│   │
│   ├── communication/           # 💬 Communication/Chat Feature
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── message_model.dart
│   │   │   └── repositories/
│   │   │       └── communication_repository.dart
│   │   └── presentation/
│   │       └── screens/
│   │           ├── communication_screen.dart
│   │           └── communication_screen_api.dart
│   │
│   ├── dialer/                  # 📞 Dialer Feature
│   │   └── presentation/
│   │       └── screens/
│   │           └── dialer_screen.dart
│   │
│   ├── moderation/              # 🛡️ Moderation Feature
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── moderation_model.dart
│   │   │   │   └── transcript_model.dart
│   │   │   └── repositories/
│   │   │       ├── moderation_repository.dart
│   │   │       └── stt_repository.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── transcript_entity.dart
│   │   │   └── usecases/
│   │   │       ├── detect_toxicity.dart
│   │   │       ├── moderate_user.dart
│   │   │       └── store_evidence.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── moderator_dashboard.dart
│   │       │   ├── transcript_viewer.dart
│   │       │   └── user_flag_screen.dart
│   │       └── state/
│   │           ├── moderation_provider.dart
│   │           └── stt_provider.dart
│   │
│   ├── profile/                 # 👤 User Profile Feature
│   │   └── presentation/
│   │       └── screens/
│   │           ├── profile_screen.dart
│   │           └── settings_screen.dart
│   │
│   ├── subscription/            # 💳 Payment/Subscription Feature
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── subscription_model.dart
│   │   │   └── repositories/
│   │   │       └── payment_repository.dart
│   │   ├── domain/
│   │   │   └── usecases/
│   │   │       └── subscribe_premium.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── payment_screen.dart
│   │       │   └── premium_info_screen.dart
│   │       └── state/
│   │           └── payment_provider.dart
│   │
│   └── home/                    # 🏠 Home Feature
│       └── presentation/
│           ├── screens/
│           │   ├── home_screen.dart
│           │   └── splash_screen.dart
│           └── widgets/
│               └── frequency_list_widget.dart
│
└── shared/                      # 🔧 Shared Resources (Used across features)
    │
    ├── config/                  # ⚙️ App Configuration
    │   ├── app_config.dart      # App configuration settings
    │   └── env.dart             # Environment variables
    │
    ├── constants/               # 📌 App-wide Constants
    │   ├── api_endpoints.dart   # API endpoint URLs
    │   ├── app_colors.dart      # Color palette
    │   ├── app_icons.dart       # Icon constants
    │   └── app_strings.dart     # String constants
    │
    ├── data/                    # 💾 Shared Data Layer
    │   ├── models/
    │   │   └── api_response.dart
    │   ├── network/
    │   │   ├── api_client.dart
    │   │   ├── dio_interceptors.dart
    │   │   └── websocket_client.dart
    │   └── local/
    │       ├── db_helper.dart
    │       └── preferences.dart
    │
    ├── services/                # 🛠️ Shared Services
    │   ├── audio_service.dart
    │   ├── communication_service.dart
    │   ├── dialer_service.dart
    │   ├── http_client.dart
    │   ├── logger_service.dart
    │   ├── navigation_service.dart
    │   ├── notification_service.dart
    │   ├── permission_service.dart
    │   └── storage_service.dart
    │
    ├── theme/                   # 🎨 App Theme
    │   ├── app_theme.dart
    │   └── text_styles.dart
    │
    ├── utils/                   # 🧰 Utility Functions
    │   ├── extensions.dart
    │   ├── formatters.dart
    │   ├── helpers.dart
    │   └── validators.dart
    │
    └── widgets/                 # 🧩 Reusable Widgets
        ├── audio_wave_visualizer.dart
        ├── custom_button.dart
        ├── custom_input_field.dart
        ├── environment_banner.dart
        ├── flag_badge.dart
        └── user_avatar.dart
```

---

## 📖 Folder Descriptions

### 🎯 Features Folder
Har feature apni complete functionality ke sath:
- **data/** - Models, repositories, API calls
- **domain/** - Business logic, entities, use cases
- **presentation/** - UI screens, widgets, state management

### 🔧 Shared Folder
Wo sab cheezein jo multiple features mein use hoti hain:
- **config/** - App configuration aur environment settings
- **constants/** - App-wide constants (colors, strings, endpoints)
- **data/** - Shared data models, network aur local storage
- **services/** - Reusable services (HTTP, audio, navigation)
- **theme/** - App theme aur text styles
- **utils/** - Helper functions aur utilities
- **widgets/** - Reusable UI components

---

## ✅ Benefits of This Structure

### 1. **Feature Discovery** 🔍
- Koi bhi feature ke liye code quickly mil jata hai
- Example: Authentication chahiye? → `features/auth/` mein dekho

### 2. **Clear Separation** 🎯
- Data layer alag, UI layer alag, business logic alag
- Aasaan testing aur maintenance

### 3. **Scalability** 📈
- Naye features easily add kar sakte ho
- Ek feature ko modify karne se dusra affect nahi hota

### 4. **Team Collaboration** 👥
- Alag alag developers alag features pe kaam kar sakte hain
- Minimal merge conflicts

### 5. **Code Reusability** ♻️
- Shared folder mein common code
- Duplication avoid hoti hai

---

## 🚀 How to Navigate

### Agar aapko chahiye:
- **Login/Signup UI** → `features/auth/presentation/screens/`
- **Authentication API** → `features/auth/data/repositories/`
- **Radio Screen** → `features/radio/presentation/screens/`
- **WebSocket Connection** → `shared/data/network/websocket_client.dart`
- **App Colors** → `shared/constants/app_colors.dart`
- **Reusable Button** → `shared/widgets/custom_button.dart`

---

## 📝 Import Guidelines

### Absolute Package Imports (Recommended)
```dart
import 'package:harborleaf_radio_app/features/auth/presentation/screens/login_screen.dart';
import 'package:harborleaf_radio_app/shared/widgets/custom_button.dart';
```

### Within Same Feature (Relative Imports OK)
```dart
// Inside features/auth/presentation/screens/
import '../state/auth_bloc.dart';
import '../../data/models/user.dart';
```

---

## 🎓 Development Tips

1. **New Feature Add Karna?**
   - `features/` folder mein nayi folder banao
   - Structure follow karo: `data/`, `domain/`, `presentation/`

2. **Shared Component Banana?**
   - Check karo pehle `shared/widgets/` mein
   - Nahi hai toh wahan banao

3. **API Call Karna?**
   - Feature ke `data/repositories/` mein method banao
   - Shared `http_client.dart` use karo

4. **State Management?**
   - Feature ke `presentation/state/` mein BLoC/Provider banao
   - `injection.dart` mein register karo

---

## 🔄 Migration Completed

### ✅ Kya kiya gaya:
- ✅ Old flat structure se feature-first structure mein convert
- ✅ All files properly organized
- ✅ Import paths updated
- ✅ Empty files aur folders removed
- ✅ Clean, maintainable structure

### ⚠️ Note:
- Functionality same hai, sirf organization change hua hai
- UI aur features mein koi change nahi
- Imports check kar lena agar koi error aaye

---

## 📞 Contact Structure Help

Agar koi confusion ho folder structure ke baare mein:
1. Yeh document padhiye
2. Similar feature ko reference ke liye dekho
3. Feature-first principle follow karo

---

**Happy Coding! 🚀**

*Last Updated: November 2025*
