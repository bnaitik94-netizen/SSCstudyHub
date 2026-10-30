# 🚀 SSC Study Hub Pro — Next-Gen Hybrid EdTech Classroom

[![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Hosting%20%26%20Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Live Web Portal](https://img.shields.io/badge/Live%20Web-sscstudyhub.web.app-brightgreen?logo=google-chrome&logoColor=white)](https://sscstudyhub.web.app)
[![Admin Studio](https://img.shields.io/badge/Admin%20Studio-Cyber%20Executive-purple?logo=shield&logoColor=white)](https://sscstudyhub.web.app/admin)

An enterprise-grade, real-time live lecture and study hub platform engineered for both **Web (PC & Mobile)** and **Android**. Features an Error-153 immune cinematic video engine, zero-hover YouTube pointer interception, proprietary floating emoji physics, AI-powered real-time doubt solver, and a cyber-themed administrative broadcast studio.

---

## 🌐 Live Production Deployments

* **Student Web Portal**: [https://sscstudyhub.web.app](https://sscstudyhub.web.app)
* **Secondary Production Mirror**: [https://naitik-live-class.web.app](https://naitik-live-class.web.app)
* **Teacher Executive Studio**: [https://sscstudyhub.web.app/admin](https://sscstudyhub.web.app/admin)

---

## ⚡ Core Feature Highlights

### 1. 🛡️ Cinematic Video Engine & Pointer Interceptor
* **Zero YouTube Hover Artifacts**: The player wraps YouTube's embedded stream in a multi-layered pointer interceptor. Mouse movement across the video never triggers YouTube's native controls, watermarks, or title banners.
* **Proprietary Touch & Control Overlay**:
  * Clean arrow pointer across the video stage (`cursor: default`), cleanly hiding after 3.5 seconds of inactivity.
  * Direct postMessage hardware playback bridge: instant Play/Pause and Mute/Unmute toggle.
  * True native Fullscreen with zero browser gesture rejection across desktop and mobile browsers.
  * Adaptive edge detection that smoothly auto-hides controls when the cursor is parked at screen edges.

### 2. 🎈 Real-Time Live Floating Emoji Reactions
* Real-time floating emoji bubbles (❤️, 🔥, 👏, 💡, 🚀, 🙋‍♂️) rising smoothly along the right edge of the screen, inspired by YouTube Live and Instagram Live.
* Dual-engine rendering: GPU-accelerated CSS keyframe animations on Web and 60fps particle physics on Android.
* Ultra-low-latency (<80ms) multi-client broadcast via Firebase Firestore.

### 3. 💬 Real-Time Live Chat & Private Question Modes
* Public classroom chat with administrative moderation badges.
* Teacher locking and private Q&A modes.
* Full keyboard space-bar support and uninterrupted typing across all desktop and mobile browsers.

### 4. 🧠 Instant AI Doubts Solver
* Embedded Google Gemini AI engine answering student questions in real-time during live lectures.
* State-preserving drawer panels that maintain context across orientation and layout changes.

### 5. 🎛️ Cyber Executive Admin Studio (`/admin`)
* Real-time broadcast management (Enter video ID, schedule upcoming classes, pin announcements).
* One-click student attendance and active viewer tracking.
* Dynamic question paper and quiz builder with automated GitHub syllabus synchronization.
* Live reaction pulse trigger for teacher interaction.

---

## 🏗️ Architecture & Technology Stack

| Layer | Technologies |
| :--- | :--- |
| **Frontend Framework** | Flutter 3.24+ (Web, Android, Desktop) |
| **Language** | Dart 3.5+ / HTML5 / CSS3 / JavaScript |
| **Backend & Realtime** | Firebase Firestore, Firebase Hosting, Firebase Messaging (FCM) |
| **Streaming Engine** | YouTube Embedded IFrame API with `youtube-nocookie.com` |
| **AI Doubt Clearing** | Google Gemini Generative AI API |
| **PDF & Syllabus Engine** | Syncfusion Flutter PDF / GitHub Contents API |
| **State & Lifecycle** | AutomaticKeepAliveClientMixin, Persistent GlobalKeys, ValueNotifiers |

---

## 🎨 Material Design 3 UI System & Low-End Architecture

The entire user interface has been overhauled to a production-ready Material Design 3 design system strictly optimized for median hardware (2GB RAM, weak Adreno/Mali GPUs) while providing a premium, minimalist experience (Linear/Notion/Google Keep M3 aesthetics).

### 1. Theme Tokens (`lib/core/theme/`)
* **`AppColors`**: Centralized semantic token architecture.
  * **Brand Seed**: `#4F46E5` (Slate Indigo) generating harmonious M3 tonal palettes.
  * **Surfaces**: Multi-tier Slate surfaces for Light (`#F8FAFC` to `#CBD5E1`) and Neutral-Dark (`#0F1117` to `#384055`), avoiding pure `#000000` to prevent OLED smearing and visual harshness.
  * **Functional Tokens**: WCAG AA compliant colors for `success` (`#10B981`), `warning` (`#F59E0B`), `error` (`#EF4444`), and `info` (`#3B82F6`) paired with high-contrast surfaces.
* **`AppSpacing`**: Predictable geometric scale (`xs: 4`, `sm: 8`, `md: 12`, `lg: 16`, `xl: 24`, `xxl: 32`, `xxxl: 48`) and rounded corner radii (`radiusSm: 8` to `radiusFull: 999`).
* **`AppTypography`**: Full Material 3 scale built on `GoogleFonts.inter` with strict weight constraints (two body weights: 400 & 500; display weight: 700).
* **`AppComponentTheme`**: Centralized styling for Cards, Buttons (Filled, Outlined, Text), Inputs, Badges, NavigationBar, Dialogs, and Bottom Sheets.
* **`AppTheme`**: Provides `AppTheme.light()` and `AppTheme.dark()` fully wired to Flutter's `MaterialApp`.

### 2. Production Reusable Widget Library (`lib/core/widgets/`)
All widgets are 100% complete with no stubs, TODOs, or placeholders:
* **`AppCard`**: Zero elevation, subtle 1px border, smooth ripple feedback, and low GPU overhead.
* **`AppButton`**: 3 variants (`.filled`, `.outlined`, `.text`) with integrated adaptive loading indicators and minimum 48x48dp touch targets.
* **`AppTextField`**: Material 3 filled/outlined input with animated label and inline validation errors.
* **`AppAvatar`**: Memory-cached network image avatar with deterministic color initials fallback.
* **`AppBadge`**: Semantic pill badges for status feedback (`LIVE`, `SCHEDULED`, `SSC 2026`).
* **`AppEmptyState`**: Minimalist empty and standby state presentation with optional recovery actions.
* **`AppLoadingShimmer`**: Low-overhead GPU shimmer placeholder for list and card loading.
* **`AppDivider`**: Ultra-thin 0.5dp divider with optional center label support.
* **`AppSectionHeader`**: Standardized section header with title and action button.
* **`AppBottomSheet`**: Modal sheet with top drag handle and `DraggableScrollableSheet` support.

### 3. Low-End Hardware Optimization Rules (Applied System-Wide)
* **Zero Runtime Blurs**: Eliminated all `BackdropFilter` and runtime Gaussian blurs, replacing them with single-pass tonal surface colors.
* **Memory-Bound Images**: Enforced `memCacheWidth` and `memCacheHeight` on all network image requests to prevent bitmap memory spikes.
* **Repaint Boundary Isolation**: Dynamic widgets (live streaming badges, bottom navigation bar, reactive lists) are isolated inside `RepaintBoundary` to prevent unnecessary root repaints.
* **Minimal Startup**: Non-critical services (notifications sync, background music prewarm) are dispatched post-first-frame to ensure instant app launch.

---

## 📱 Mobile Android APKs

The project is configured with ABI splitting to produce lightweight, highly optimized Android APK packages:

* **ARM 64-bit (`app-arm64-v8a-release.apk`)**: ~28.8 MB (Optimized for modern Android devices)
* **ARM 32-bit (`app-armeabi-v7a-release.apk`)**: ~27.0 MB (Optimized for budget & older devices)
* **x86_64 (`app-x86_64-release.apk`)**: ~30.2 MB (Optimized for ChromeOS & emulators)

---

## 🚀 Local Development Setup

### Prerequisites
* Flutter SDK (3.22.0 or higher)
* Dart SDK (3.5.0 or higher)
* Android SDK & Android Studio (for native Android builds)
* Firebase CLI (`npm install -g firebase-tools`)

### 1. Clone the Repository
```bash
git clone https://github.com/bnaitik94-netizen/SSCstudyHub.git
cd SSCstudyHub
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run Locally (Chrome Web)
```bash
flutter run -d chrome
```

### 4. Build for Production Web
```bash
flutter build web --release
```

### 5. Build Android Release APKs
```bash
flutter build apk --release --split-per-abi
```

### 6. Deploy to Firebase Hosting
```bash
firebase deploy --only hosting
```

---

## 👨‍💻 Author & Maintainer

* **Developer**: Naitik ([@bnaitik94-netizen](https://github.com/bnaitik94-netizen))
* **Project**: SSC Study Hub Pro
* **Website**: [sscstudyhub.web.app](https://sscstudyhub.web.app)

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
