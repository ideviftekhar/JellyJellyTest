
# JellyJellyTest

A sample iOS application built as part of a test task assignment. The app simulates a TikTok-style video feed, dual-camera recording interface, and local camera roll management.

## 🚀 Project Overview

This project includes a three-tab interface:

1. **Feed** – A scrollable video feed  
2. **Camera** – Dual-screen front and back camera recording  
3. **Camera Roll** – Saved videos list/grid

Built with **Xcode 14** and supports **iOS 17.2+**.

---

## ✅ Completed Tasks

### 📺 Tab 1 – Feed
- Scraped and displayed a **hardcoded video feed** using predefined HTTP URLs.
- Implemented a **TikTok-style** scrolling video UI.
- Autoplay with mute and smooth transitions.

### 🎥 Tab 2 – Camera
- Developed a **dual-screen recording interface** (front and back camera).
- Records **synchronized 15-second videos**.
- Auto-navigation to Camera Roll on recording completion.

### 🧾 Tab 3 – Camera Roll
- Displays recorded videos in a **list/grid** format.

---

## ❌ Incomplete / Known Limitations

### 🔗 Tab 2 – Camera
- Video is **not uploaded to persistent storage** (e.g., Firebase/Supabase).
- Currently stored only in **local temporary variables**.

### 📱 Tab 3 – Camera Roll
- Video **playback is not yet implemented** (inline or fullscreen).

---

## 🐞 Known Bugs

- **Button Flash During Flip:** "Save" and "Discard" buttons briefly flash when switching cameras mid-recording.
- **Camera Reuse Issue:** Previously recorded preview appears unintentionally after navigating between tabs.
- **Share Post Layout:** Missing constraints causing layout issues on smaller screens.

---

## 📽 Demo Video

Check out the working demo:  

👉 [https://drive.google.com/file/d/1k_y7EzSlasv5ozv8mLX-WxFsRFZzqKL-/view](https://drive.google.com/file/d/1k_y7EzSlasv5ozv8mLX-WxFsRFZzqKL-/view)

---

## 📦 Installation Guide

1. Clone the repo:
   ```bash
   git clone https://github.com/ideviftekhar/JellyJellyTest.git
   ```

2. Open in **Xcode 14 or later**

3. Make sure your device is running **iOS 17.2 or higher**

4. Build & Run on a physical device (Camera features don’t work on the simulator)

---
