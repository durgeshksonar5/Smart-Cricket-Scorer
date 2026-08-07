# 🏏 Cricket Score App - APK Download Landing Page

This folder contains the official landing page for promoting and distributing the Android APK for **Cricket Score Counter**.

It is completely independent of the main Flutter application codebase in `lib/`, `android/`, `ios/`, etc.

---

## 📁 Directory Structure

```text
landing-page/
├── index.html                  # Main responsive HTML5 landing page
├── css/
│   └── style.css               # Theme matching Flutter AppTheme (#0A1612, #00E676, #FFD700)
├── js/
│   └── script.js               # Download tracking toast, 3D coin flip, mobile nav toggle
├── assets/
│   ├── logo/                   # App icons and brand logos
│   ├── screenshots/            # App screenshots and UI previews
│   └── images/                 # Supporting visual assets
├── apk/
│   └── app-release.apk         # Compiled release APK binary (~49.6 MB)
└── README.md                   # Setup, maintenance, and deployment guide
```

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

## 🏷️ Customization & SEO

- **SEO Tags**: Edit `<title>`, `<meta name="description">`, and `<meta name="keywords">` in `index.html`.
- **App Name / Branding**: Change text inside `.nav-title` and `.hero-title`.
- **Colors**: Modify CSS variables inside `css/style.css` (`--primary-emerald`, `--coin-gold`, `--bg-dark`).

---

## ✍️ Credits

- **Developer**: Durgesh Sonar
- **App Version**: 1.0.1+2
