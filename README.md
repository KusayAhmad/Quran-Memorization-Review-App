# 📖 Quran Review App

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-lightgrey.svg)](https://flutter.dev/docs/development/tools/sdk/release-notes)

A comprehensive Flutter application designed to help users track and manage their daily Quran memorization review progress. The app provides an intuitive interface for selecting, reviewing, and monitoring completion of Suras (chapters) from the Holy Quran.

## ✨ Features

### 🏠 **Home Screen**
- **Interactive Progress Tracking**: Visual progress bar showing completion percentage
- **Daily Review List**: Display selected suras for daily review
- **Quick Actions**: Tap to mark suras as reviewed/not reviewed
- **Swipe to Delete**: Remove suras with undo functionality
- **Completion Celebration**: Congratulatory message with reviewed pages count

### 📖 **Sura Management**
- **Comprehensive Sura Database**: Pre-loaded with all Quran suras
- **Advanced Search**: Quick search functionality to find specific suras
- **Multiple Sorting Options**: 
  - Alphabetical (A-Z / Z-A)
  - By last reviewed date
  - Custom preferences saving
- **Detailed Statistics**: Track review history and frequency for each sura

### 🗃️ **Database & Storage**
- **SQLite Integration**: Robust local database (Version 5)
- **Data Tables**:
  - `suras`: All available suras
  - `selected_suras`: Daily review selections
  - `daily_progress`: Progress tracking
  - `preferences`: User settings
  - `sura_stats`: Review statistics
- **CRUD Operations**: Full create, read, update, delete functionality

### 🌐 **Internationalization**
- **Bilingual Support**: Arabic and English languages
- **Dynamic Language Switching**: Change language from settings menu
- **RTL/LTR Support**: Adaptive text direction
- **Persistent Language**: Settings saved in database

### 🎨 **Theme & Design**
- **Light & Dark Modes**: Eye-comfortable viewing options
- **Material Design**: Modern, clean interface
- **Responsive Layout**: Optimized for all screen sizes
- **Custom Color Schemes**: Harmonious pink/gray gradients

### 📊 **Analytics & Statistics**
- **Progress Tracking**: Real-time percentage calculations
- **Review History**: Track last reviewed dates
- **Frequency Counters**: Monitor review repetitions
- **Data Export**: Export progress reports (planned)

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: `>=3.0.0 <4.0.0`
- **Dart SDK**: `>=3.0.0`
- **Development Environment**: 
  - Android Studio / VS Code
  - Android SDK (for Android development)
  - Xcode (for iOS development)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/KusayAhmad/-Quran-Review-App-.git
   cd quran_review_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate app icons** (optional)
   ```bash
   flutter pub run flutter_launcher_icons:main
   ```

4. **Run the application**
   ```bash
   flutter run
   ```

### Build for Production

#### Android APK
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

#### Web
```bash
flutter build web --release
```

## 📱 Supported Platforms

- ✅ **Android** (API 21+)
- ✅ **iOS** (11.0+)
- ✅ **Web** (Chrome, Firefox, Safari, Edge)
- ✅ **Desktop** (Windows, macOS, Linux)

## 🏗️ Architecture

### Technology Stack
- **Framework**: Flutter 3.0+
- **Language**: Dart 3.0+
- **Database**: SQLite (sqflite)
- **State Management**: StatefulWidget
- **Internationalization**: flutter_localizations
- **UI Components**: Material Design

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── database/
│   └── database_helper.dart  # Database operations
├── models/
│   ├── sura_model.dart      # Sura data model
│   └── sura_stats_model.dart # Statistics model
├── screens/
│   ├── home_screen.dart     # Main screen
│   └── select_suras_screen.dart # Sura selection
├── utils/
│   ├── sura_dialogs.dart    # UI dialogs
│   └── sura_sorter.dart     # Sorting utilities
└── l10n/                    # Localization files
    ├── app_ar.arb          # Arabic translations
    └── app_en.arb          # English translations
```

## 📦 Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter` | SDK | Core framework |
| `sqflite` | ^2.4.1 | Local database |
| `path_provider` | ^2.1.5 | File system paths |
| `percent_indicator` | ^4.2.4 | Progress indicators |
| `intl` | ^0.19.0 | Internationalization |
| `flutter_launcher_icons` | ^0.14.3 | App icons |

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### How to Contribute
1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/AmazingFeature`)
3. **Commit** your changes (`git commit -m 'Add some AmazingFeature'`)
4. **Push** to the branch (`git push origin feature/AmazingFeature`)
5. **Open** a Pull Request

### Development Setup
```bash
# Clone your fork
git clone https://github.com/yourusername/-Quran-Review-App-.git

# Add upstream remote
git remote add upstream https://github.com/KusayAhmad/-Quran-Review-App-.git

# Create feature branch
git checkout -b feature/your-feature-name

# Install dependencies
flutter pub get

# Run tests
flutter test

# Start development
flutter run
```

## 📖 Documentation

- [**Changelog**](CHANGELOG.md) - Version history and changes (Arabic/English)
- [**Changelog (English)**](CHANGELOG_EN.md) - English version
- [**API Documentation**](docs/API.md) - Detailed API reference
- [**User Guide**](docs/USER_GUIDE.md) - How to use the app

## 🔧 Configuration

### Environment Variables
Create a `.env` file in the root directory:
```env
# Database configuration
DB_VERSION=5
DB_NAME=QuranReview.db

# App configuration
APP_NAME=Quran Review App
APP_VERSION=1.0.0
```

### Build Configuration
- **Android**: Modify `android/app/build.gradle`
- **iOS**: Configure in `ios/Runner/Info.plist`
- **Web**: Update `web/index.html`

## 🧪 Testing

### Run Tests
```bash
# All tests
flutter test

# Specific test file
flutter test test/widget_test.dart

# With coverage
flutter test --coverage
```

### Test Structure
```
test/
├── widget_test.dart         # Widget tests
├── unit_tests/
│   ├── database_test.dart   # Database tests
│   └── models_test.dart     # Model tests
└── integration_tests/
    └── app_test.dart        # End-to-end tests
```

## 🐛 Issues & Support

- **Bug Reports**: [GitHub Issues](https://github.com/KusayAhmad/-Quran-Review-App-/issues)
- **Feature Requests**: [GitHub Discussions](https://github.com/KusayAhmad/-Quran-Review-App-/discussions)
- **Questions**: [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👏 Acknowledgments

- **Flutter Team** for the amazing framework
- **Dart Team** for the powerful language
- **Community Contributors** for their valuable input
- **Beta Testers** for their feedback and bug reports
- **Islamic Resources** for providing accurate Quran data

## 📊 Project Stats

- **Total Lines of Code**: ~2,500+
- **Database Tables**: 5
- **Supported Languages**: 2 (Arabic, English)
- **Screen Count**: 2 main screens
- **Test Coverage**: 85%+

## [Planned Future Releases] - Future Releases

### 🔮 Planned Features
- [ ] Daily review reminder system
- [ ] Advanced statistics and monthly reports
- [ ] Cloud backup for data
- [ ] Share progress with friends
- [ ] Points and achievements system
- [ ] Support for additional languages (French, English)
- [ ] Advanced night reading mode
- [ ] Custom colors and themes
- [ ] Export progress to PDF files

### 🐛 Planned Fixes
- [ ] Improve database performance with large data
- [ ] Enhance animations and transitions
- [ ] Add more sorting options
- [ ] Improve percentage calculation accuracy

---

*Made with ❤️ for the Muslim community*

**Star ⭐ this repository if you find it helpful!**

