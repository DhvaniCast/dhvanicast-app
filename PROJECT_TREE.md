# 🌳 Project Structure Visualization

```
harborleaf_radio_app/
│
├── 📱 lib/                                    # Main source code
│   │
│   ├── 🚀 main.dart                          # App entry point
│   ├── 💉 injection.dart                     # Dependency injection
│   │
│   ├── 🎯 features/                          # FEATURE-FIRST ORGANIZATION
│   │   │
│   │   ├── 🔐 auth/                          # Authentication Feature
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   ├── user.dart
│   │   │   │   │   └── user_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── auth_repository.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── user_entity.dart
│   │   │   │   └── usecases/
│   │   │   │       └── login_user.dart
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── login_screen.dart
│   │   │       │   └── signup_screen.dart
│   │   │       └── state/
│   │   │           ├── auth_bloc.dart
│   │   │           ├── auth_event.dart
│   │   │           ├── auth_state.dart
│   │   │           └── auth_provider.dart
│   │   │
│   │   ├── 📻 radio/                         # Live Radio Feature
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   ├── frequency_model.dart
│   │   │   │   │   └── group_model.dart
│   │   │   │   └── repositories/
│   │   │   │       ├── frequency_repository.dart
│   │   │   │       └── group_repository.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── frequency_entity.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── join_frequency.dart
│   │   │   │       └── stream_audio.dart
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── live_radio_screen.dart
│   │   │       │   ├── private_frequency_screen.dart
│   │   │       │   └── radio_controls.dart
│   │   │       └── state/
│   │   │           └── radio_provider.dart
│   │   │
│   │   ├── 💬 communication/                 # Chat/Communication Feature
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   └── message_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── communication_repository.dart
│   │   │   └── presentation/
│   │   │       └── screens/
│   │   │           ├── communication_screen.dart
│   │   │           └── communication_screen_api.dart
│   │   │
│   │   ├── 📞 dialer/                        # Dialer Feature
│   │   │   └── presentation/
│   │   │       └── screens/
│   │   │           └── dialer_screen.dart
│   │   │
│   │   ├── 🛡️ moderation/                    # Content Moderation Feature
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   ├── moderation_model.dart
│   │   │   │   │   └── transcript_model.dart
│   │   │   │   └── repositories/
│   │   │   │       ├── moderation_repository.dart
│   │   │   │       └── stt_repository.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── transcript_entity.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── detect_toxicity.dart
│   │   │   │       ├── moderate_user.dart
│   │   │   │       └── store_evidence.dart
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── moderator_dashboard.dart
│   │   │       │   ├── transcript_viewer.dart
│   │   │       │   └── user_flag_screen.dart
│   │   │       └── state/
│   │   │           ├── moderation_provider.dart
│   │   │           └── stt_provider.dart
│   │   │
│   │   ├── 👤 profile/                       # User Profile Feature
│   │   │   └── presentation/
│   │   │       └── screens/
│   │   │           ├── profile_screen.dart
│   │   │           └── settings_screen.dart
│   │   │
│   │   ├── 💳 subscription/                  # Payment/Premium Feature
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   └── subscription_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── payment_repository.dart
│   │   │   ├── domain/
│   │   │   │   └── usecases/
│   │   │   │       └── subscribe_premium.dart
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── payment_screen.dart
│   │   │       │   └── premium_info_screen.dart
│   │   │       └── state/
│   │   │           └── payment_provider.dart
│   │   │
│   │   └── 🏠 home/                          # Home Feature
│   │       └── presentation/
│   │           ├── screens/
│   │           │   ├── home_screen.dart
│   │           │   └── splash_screen.dart
│   │           └── widgets/
│   │               └── frequency_list_widget.dart
│   │
│   └── 🔧 shared/                            # SHARED RESOURCES
│       │
│       ├── ⚙️ config/                        # Configuration
│       │   ├── app_config.dart
│       │   └── env.dart
│       │
│       ├── 📌 constants/                     # Constants
│       │   ├── api_endpoints.dart
│       │   ├── app_colors.dart
│       │   ├── app_icons.dart
│       │   └── app_strings.dart
│       │
│       ├── 💾 data/                          # Shared Data Layer
│       │   ├── models/
│       │   │   └── api_response.dart
│       │   ├── network/
│       │   │   ├── api_client.dart
│       │   │   ├── dio_interceptors.dart
│       │   │   └── websocket_client.dart
│       │   └── local/
│       │       ├── db_helper.dart
│       │       └── preferences.dart
│       │
│       ├── 🛠️ services/                      # Services
│       │   ├── audio_service.dart
│       │   ├── communication_service.dart
│       │   ├── dialer_service.dart
│       │   ├── http_client.dart
│       │   ├── logger_service.dart
│       │   ├── navigation_service.dart
│       │   ├── notification_service.dart
│       │   ├── permission_service.dart
│       │   └── storage_service.dart
│       │
│       ├── 🎨 theme/                         # Theme
│       │   ├── app_theme.dart
│       │   └── text_styles.dart
│       │
│       ├── 🧰 utils/                         # Utilities
│       │   ├── extensions.dart
│       │   ├── formatters.dart
│       │   ├── helpers.dart
│       │   └── validators.dart
│       │
│       └── 🧩 widgets/                       # Reusable Widgets
│           ├── audio_wave_visualizer.dart
│           ├── custom_button.dart
│           ├── custom_input_field.dart
│           ├── environment_banner.dart
│           ├── flag_badge.dart
│           └── user_avatar.dart
│
├── 📦 assets/                                # Static Assets
│   ├── fonts/
│   ├── icons/
│   ├── images/
│   └── sounds/
│
├── 🤖 android/                               # Android Platform
├── 🍎 ios/                                   # iOS Platform
├── 🪟 windows/                               # Windows Platform
├── 🐧 linux/                                 # Linux Platform
├── 🍏 macos/                                 # macOS Platform
├── 🌐 web/                                   # Web Platform
│
├── 🧪 test/                                  # Tests
│   ├── widget_test.dart
│   ├── integration/
│   ├── unit/
│   └── widget/
│
├── 📄 pubspec.yaml                           # Dependencies
├── 📋 README.md                              # Project readme
├── 📁 FOLDER_STRUCTURE.md                    # Structure documentation (DETAILED)
├── 📝 RESTRUCTURING_SUMMARY.md               # Summary of changes
└── ⚙️ analysis_options.yaml                  # Linter rules
```

---

## 🎯 Key Features of This Structure

### ✨ Feature-First Benefits:
```
✅ Ek jagah feature ka complete code
✅ Easy to locate any functionality
✅ Independent features - no interdependency
✅ Team can work on different features simultaneously
✅ Easy to add/remove features
```

### 🔧 Shared Resources Benefits:
```
✅ No code duplication
✅ Reusable components
✅ Consistent styling
✅ Centralized configuration
✅ Common utilities available everywhere
```

---

## 📊 Statistics

```
📁 Total Features:      8
📄 Dart Files:         60+
🧩 Shared Widgets:     6
🛠️ Shared Services:    9
📌 Constants Files:    4
🎨 Theme Files:        2
```

---

## 🚀 Quick Reference

### Import Patterns:
```dart
// Feature imports
import 'package:harborleaf_radio_app/features/auth/...';
import 'package:harborleaf_radio_app/features/radio/...';

// Shared imports
import 'package:harborleaf_radio_app/shared/widgets/...';
import 'package:harborleaf_radio_app/shared/services/...';

// Main imports
import 'package:harborleaf_radio_app/injection.dart';
```

---

## 📖 More Information

- **Complete Guide:** See `FOLDER_STRUCTURE.md`
- **Changes Made:** See `RESTRUCTURING_SUMMARY.md`
- **Development:** Follow the feature-first pattern

---

**🎉 Clean, Professional, Maintainable Structure!**

*Created: November 5, 2025*
