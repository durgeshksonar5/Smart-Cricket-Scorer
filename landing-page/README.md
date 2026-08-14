# 🏏 Smart Cricket Scorer – Official APK Download Landing Page

This folder contains the official landing page for promoting and distributing the Android APK for **Smart Cricket Scorer** (Version 1.2.0).

It is completely independent of the main Flutter application codebase in `lib/`, `android/`, `ios/`, etc.

---

## 📁 Directory Structure

```text
landing-page/
├── index.html                  # Main responsive HTML5 landing page (v1.2.0)
├── css/
│   └── style.css               # Theme matching Flutter AppTheme (#0A1612, #00E676, #FFD700)
├── js/
│   └── script.js               # Download toast, interactive mockup tabs, 3D coin flip
├── assets/
│   ├── logo/                   # App icons and brand logos
│   ├── screenshots/            # App screenshots and UI previews
│   └── images/                 # Supporting visual assets
├── apk/
│   └── app-release.apk         # Compiled release APK binary (51.3 MB)
└── README.md                   # Setup, maintenance, and deployment guide
```

---

## ✨ Features Highlighted in v1.2.0

- 📜 **Permanent Match History**: Persistent local match database with zero data loss.
- 🔍 **Search & Multi-Filters**: Filter by `ALL`, `LIVE`, `COMPLETED`, `EDITABLE`, `LOCKED`, or search by team, player, venue, date.
- 🔄 **Quick Team Reuse & Rematch**: Reuse saved rosters with custom overs (1-50) and player counts (2-15) starting at 0/0 score.
- 📊 **3-Tab Detailed Match Viewer**: Summary overview, complete Batting & Bowling tables with extras breakdown, and over-by-over ball timelines.
- ⏱️ **2-Hour Edit Window Protection**: Live countdown timer for match score corrections before automatic permanent lock.
- 🪙 **3D Coin Toss Simulation**: Interactive physics-based coin flip for pre-match toss decisions.
- 💾 **Crash & Low-Battery Recovery**: Auto-saves every ball to resume matches anytime.

---

## 🚀 How to Run Locally

### Option 1: Double-Click or Open directly
Open `index.html` directly in any web browser (Chrome, Firefox, Edge, Safari).

### Option 2: Local HTTP Server (Python)
Run inside the `landing-page` directory:
```bash
cd landing-page
python -m http.server 8080
```
Then visit `http://localhost:8080` in your browser.

---

## 📦 How to Update the APK

Whenever you build a new release APK in Flutter:
1. Compile the APK:
   ```bash
   flutter build apk --release
   ```
2. Copy the newly generated APK into `landing-page/apk/`:
   ```bash
   cp build/app/outputs/flutter-apk/app-release.apk landing-page/apk/app-release.apk
   ```

---

## 🌐 Deployment Instructions

### 1. Netlify
- Drag and drop the `landing-page` folder into Netlify Drop (`app.netlify.com/drop`).
- **Important**: Only deploy the `landing-page` directory, not the entire Flutter root.

### 2. Vercel
- Deploy via Vercel CLI or Dashboard by setting `Root Directory` to `landing-page`.

### 3. GitHub Pages
- Create a `gh-pages` branch or publish the `landing-page/` subfolder using `gh-pages`:
  ```bash
  git subtree push --prefix landing-page origin gh-pages
  ```

### 4. cPanel / Hostinger / Nginx / Apache
- Upload all contents inside `landing-page/` into your domain's `public_html/` folder via FTP or File Manager.
- Relative links (`apk/app-release.apk`) will automatically work out-of-the-box.

---

## ✍️ Credits

- **Developer**: Durgesh Sonar
- **App Version**: 1.2.0
