# 📻 Harborleaf Radio App

A professional Flutter application for live radio broadcasting and communication with clean architecture.

## ✨ Features

- 🔐 **Authentication** - User login/signup with OTP
- 📻 **Live Radio** - Real-time audio broadcasting
- 💬 **Communication** - In-app messaging
- 📞 **Dialer** - Call functionality
- 🛡️ **Moderation** - Content moderation with AI
- 👤 **User Profile** - Profile management
- 💳 **Subscription** - Premium features
- 🏠 **Home Dashboard** - Main navigation

## 🏗️ Architecture

This project follows **Clean Architecture** with **Feature-First Organization**:

```
lib/
├── features/      # Feature-wise modules (auth, radio, etc.)
└── shared/        # Shared resources (widgets, services, utils)
```

For detailed structure, see: [`FOLDER_STRUCTURE.md`](FOLDER_STRUCTURE.md)

## 📁 Project Structure

```
✅ Feature-First Organization
✅ Clean Architecture (Data → Domain → Presentation)
✅ Shared Resources for Reusability
✅ Clear Separation of Concerns
```

**Visual Tree:** See [`PROJECT_TREE.md`](PROJECT_TREE.md)  
**Structure Guide:** See [`FOLDER_STRUCTURE.md`](FOLDER_STRUCTURE.md)  
**Restructuring Info:** See [`RESTRUCTURING_SUMMARY.md`](RESTRUCTURING_SUMMARY.md)

## 🚀 Getting Started

### Prerequisites
- Flutter SDK: ^3.0.0
- Dart: ^3.0.0

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd harborleaf_radio_app
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the app
```bash
flutter run
```

## 📦 Key Dependencies

- `flutter_bloc` - State management
- `get_it` - Dependency injection
- `dio` - HTTP client
- `socket_io_client` - WebSocket connection
- `audioplayers` - Audio playback
- `record` - Audio recording
- `shared_preferences` - Local storage

## 🎯 Features by Module

### 🔐 Auth (`features/auth/`)
- Login with OTP
- User registration
- Profile management
- Authentication state management

### 📻 Radio (`features/radio/`)
- Live broadcasting
- Join frequency
- Private channels
- Audio streaming

### 💬 Communication (`features/communication/`)
- Real-time messaging
- Group chat
- WebSocket connection

### 🛡️ Moderation (`features/moderation/`)
- Content moderation
- Toxicity detection
- User reporting
- Evidence storage

### 💳 Subscription (`features/subscription/`)
- Premium features
- Payment integration
- Subscription management

## 🔧 Development

### Project Structure
The project uses a **feature-first** approach where each feature contains:
- `data/` - Models, repositories, API calls
- `domain/` - Entities, use cases, business logic
- `presentation/` - UI screens, widgets, state management

### Shared Resources
Common functionality is in the `shared/` folder:
- `widgets/` - Reusable UI components
- `services/` - Shared services (HTTP, audio, etc.)
- `constants/` - App-wide constants
- `utils/` - Helper functions
- `theme/` - App theming

### Adding a New Feature
1. Create folder in `features/`
2. Add `data/`, `domain/`, `presentation/` subfolders
3. Implement following the existing pattern
4. Register dependencies in `injection.dart`

## 📖 Documentation

- **[FOLDER_STRUCTURE.md](FOLDER_STRUCTURE.md)** - Complete folder structure guide
- **[PROJECT_TREE.md](PROJECT_TREE.md)** - Visual project tree
- **[RESTRUCTURING_SUMMARY.md](RESTRUCTURING_SUMMARY.md)** - Restructuring details
- **[QUICK_START.md](QUICK_START.md)** - Quick start guide
- **[API_INTEGRATION_STATUS.md](API_INTEGRATION_STATUS.md)** - API integration status

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/auth_test.dart
```

## 🤝 Contributing

1. Fork the project
2. Create your feature branch
3. Follow the existing structure pattern
4. Commit your changes
5. Push to the branch
6. Open a pull request

## 📝 License

This project is licensed under the MIT License.

## 📞 Contact

For questions about the project structure or architecture, refer to the documentation files listed above.

---

**Built with ❤️ using Flutter**

*Last Updated: November 2025*
