# SwingAnalyzer ⛳

<div align="center">

<p align="center">
  <img src="SwingAnalyzerr/Assets.xcassets/AppIcon.appiconset/AppIcon~ios-marketing.png" width="200" alt="SwingAnalyzerr Logo">
</p>

**Advanced Golf Swing Analysis using Apple Watch & Machine Learning**

[![Swift](https://img.shields.io/badge/Swift-5.9-orange?style=flat-square&logo=swift)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17.0+-blue?style=flat-square&logo=apple)](https://developer.apple.com/ios/)
[![watchOS](https://img.shields.io/badge/watchOS-10.0+-red?style=flat-square&logo=apple)](https://developer.apple.com/watchos/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-purple?style=flat-square&logo=swift)](https://developer.apple.com/xcode/swiftui/)
[![Core Data](https://img.shields.io/badge/Core%20Data-Enabled-yellow?style=flat-square)](https://developer.apple.com/documentation/coredata)
[![Watch Connectivity](https://img.shields.io/badge/Watch%20Connectivity-Synced-teal?style=flat-square)](https://developer.apple.com/documentation/watchconnectivity)

*Transform your golf game with precision motion analysis, real-time feedback, and intelligent coaching insights.*

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [Architecture](#-architecture) • [Contributing](#-contributing)

</div>

---

## 🏌️ Overview

SwingAnalyzer is a cutting-edge iOS and watchOS application that leverages Apple Watch sensors and machine learning to provide comprehensive golf swing analysis. Get real-time feedback, track your progress, and receive personalized coaching insights to improve your game.

### 🎯 What Makes SwingAnalyzer Special

- **🔬 Precision Analysis**: Advanced motion sensor data processing with 50+ data points per swing
- **🤖 AI-Powered Insights**: Machine learning models trained on professional swing data
- **📱 Seamless Sync**: Real-time data synchronization between Apple Watch and iPhone
- **📊 Comprehensive Metrics**: Distance calculation, swing speed, launch angle, and more
- **🎨 Elegant Design**: Beautiful, minimal interface following Apple's Human Interface Guidelines

---

## ✨ Features

### 🏌️ Core Swing Analysis
- **Real-time Motion Capture** - Precise sensor data collection during swings
- **ML-Powered Rating System** - Intelligent swing quality assessment (Excellent/Good/Average)
- **Distance Calculation** - Physics-based distance estimation with multiple club types
- **Swing Metrics** - Max acceleration, swing speed, attack angle, tempo analysis
- **Impact Detection** - Automatic swing start/stop with impact point identification

### 📱 Cross-Platform Experience
- **Apple Watch App** - Primary swing recording and immediate results
- **iPhone Companion** - Detailed analysis, history, and data management
- **Real-time Sync** - Instant data transfer using Watch Connectivity framework
- **Offline Capable** - Works without internet connection

### 📊 Data & Analytics
- **Swing History** - Complete record of all swings with filtering and search
- **Progress Tracking** - Performance trends and improvement metrics
- **Club-Specific Analysis** - Tailored insights for Driver, 7-Iron, 9-Iron, and more
- **Export Capabilities** - Share data and analysis reports

### ⚙️ Customization
- **Units Support** - Imperial (yards/mph) and Metric (meters/km/h) units
- **Hand Selection** - Left/right hand optimization for accurate readings
- **Club Selection** - Multiple golf club types with specific calculations
- **Haptic Feedback** - Customizable vibration alerts

---

## 📱 Screenshots

<div align="center">

### iPhone App
<img src="screenshots/iphone-dashboard.png" width="200" alt="iPhone Dashboard"> <img src="screenshots/iphone-history.png" width="200" alt="iPhone History"> <img src="screenshots/iphone-analytics.png" width="200" alt="iPhone Analytics">

### Apple Watch App
<img src="screenshots/watch-recording.png" width="150" alt="Watch Recording"> <img src="screenshots/watch-results.png" width="150" alt="Watch Results"> <img src="screenshots/watch-settings.png" width="150" alt="Watch Settings">

</div>

---

## 🚀 Installation

### Prerequisites
- **Xcode 16.0+**
- **iOS 18.0+** / **watchOS 11.0+**
- **Apple Watch Series 6+** (for motion sensors)
- **Apple Developer Account** (for device testing)

### Setup Instructions

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/SwingAnalyzer.git
   cd SwingAnalyzer
   ```

2. **Open in Xcode**
   ```bash
   open SwingAnalyzer.xcodeproj
   ```

3. **Configure Signing**
   - Select your development team in project settings
   - Update bundle identifiers for both iOS and watchOS targets

4. **Build and Run**
   - Select your iPhone as the destination
   - Build and run (⌘+R)
   - The watch app will automatically install

### Required Permissions
- **Motion & Fitness** - For accessing accelerometer and gyroscope data
- **Watch Connectivity** - For syncing data between devices

---

## 🎮 Usage

### Getting Started

1. **Pair Your Apple Watch**
   - Ensure your Apple Watch is paired and connected
   - Open SwingAnalyzer on both devices

2. **Configure Settings**
   - Select your preferred units (Imperial/Metric)
   - Choose your watch hand (Left/Right)
   - Pick your golf club type

3. **Record Your First Swing**
   - Open the watch app
   - Tap "Start" and make your swing
   - View instant results on your watch
   - Check detailed analysis on your iPhone

### Advanced Features

#### 📊 Analyzing Your Data
- **Dashboard**: Overview of your progress and recent activity
- **History**: Browse all swings with filtering options
- **Analytics**: Detailed performance trends and insights

#### ⚙️ Customization
- **Units**: Switch between yards/meters and mph/km/h
- **Clubs**: Select from Driver, 7-Iron, 9-Iron for accurate calculations
- **Sync**: Manual sync options and connection status

#### 🔄 Data Management
- **Export**: Share swing data and analysis
- **Delete**: Remove individual swings (syncs across devices)
- **Backup**: Core Data automatic persistence

---

## 🏗️ Architecture

### Technology Stack
- **Frontend**: SwiftUI with MVVM architecture
- **Backend**: Core Data for local persistence
- **ML**: Core ML for swing analysis
- **Sync**: Watch Connectivity framework
- **Sensors**: Core Motion for accelerometer/gyroscope data

### Project Structure
```
SwingAnalyzer/
├── SwingAnalyzerr/                 # iOS App
│   ├── Views/                      # SwiftUI Views
│   ├── Models/                     # Data Models
│   └── Resources/                  # Assets & ML Models
├── SwingAnalyzerr Watch App/       # watchOS App
│   ├── Views/                      # Watch-optimized Views
│   └── Resources/                  # Watch Assets
├── Shared/                         # Shared Code
│   ├── Models/                     # Core Data Models
│   ├── Managers/                   # Business Logic
│   └── Extensions/                 # Utility Extensions
└── SwingAnalyzer.xcdatamodeld     # Core Data Schema
```

### Key Components

#### 🎯 SwingCoordinator
Central coordinator managing the swing analysis workflow:
- Motion data collection
- ML analysis orchestration
- Results processing and storage

#### 📡 WatchConnectivityManager
Handles real-time sync between devices:
- Bidirectional data transfer
- Connection monitoring
- Conflict resolution

#### 🤖 MLSwingAnalyzer
Machine learning integration:
- Swing quality assessment
- Pattern recognition
- Confidence scoring

#### 📊 DistanceCalculator
Physics-based distance calculation:
- Club-specific algorithms
- Launch angle analysis
- Ball speed estimation

---

## 🔧 Configuration

### ML Model Setup
The app includes a pre-trained Core ML model (`golftrain.mlmodel`) for swing analysis. To update or retrain:

1. Prepare training data in the required format
2. Use Create ML or external tools to train your model
3. Replace the model file in the project
4. Update the `MLSwingAnalyzer` class accordingly

### Core Data Schema
The app uses Core Data for persistence with the following entities:
- **SwingSession**: Main swing record
- **SwingAnalysis**: ML analysis results
- **SensorReading**: Raw motion data

### Watch Connectivity
Sync configuration in `WatchConnectivityManager`:
- Message types for different data
- Transfer methods (immediate vs. queued)
- Error handling and retry logic

---

## 🧪 Testing

### Unit Tests
```bash
# Run unit tests
xcodebuild test -scheme SwingAnalyzer -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Device Testing
1. **Apple Watch Required**: Motion sensors only work on physical devices
2. **Pairing**: Ensure watch is properly paired and connected
3. **Permissions**: Grant motion and fitness permissions when prompted

### Debug Features
- Console logging for motion data and sync status
- Debug views for sensor readings
- Performance metrics for ML analysis

---

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

### Development Setup
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Follow Swift style guidelines
4. Add tests for new functionality
5. Update documentation as needed

### Pull Request Process
1. Ensure all tests pass
2. Update README if needed
3. Add screenshots for UI changes
4. Submit PR with detailed description

### Code Style
- Follow Swift API Design Guidelines
- Use SwiftUI best practices
- Comment complex algorithms
- Maintain MVVM architecture

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Apple** - For the incredible Core Motion and Watch Connectivity frameworks
- **Golf Community** - For feedback and testing
- **Open Source Contributors** - For inspiration and code examples

---

## 📞 Support

### Issues & Bugs
- [GitHub Issues](https://github.com/yourusername/SwingAnalyzer/issues)
- Include device model, iOS version, and steps to reproduce

### Feature Requests
- [GitHub Discussions](https://github.com/yourusername/SwingAnalyzer/discussions)
- Describe your use case and expected behavior

---

<div align="center">

**Made with ❤️ for golfers who love technology**

⭐ **Star this repo if you found it helpful!** ⭐

[⬆ Back to Top](#swinganalyzer-)

</div>
