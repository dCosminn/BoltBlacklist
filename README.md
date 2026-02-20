# 📱 BoltBlacklist (iOS)

An iOS app that allows you to manually OCR license plates from screenshots or photos and maintain a local blacklist of Bolt and Uber drivers.

The app extracts plate numbers from ride screenshots and stores them locally for future reference.

---

## 🔐 First-Time Setup

On first launch:

1. Grant **full access to your Photos library**.
2. Position the red rectangle over the area where the **license plate number** appears in your screenshots.

The selected rectangle will be reused for future OCR scans.

📄 All detected plate numbers (with optional notes) are stored locally in: Documents/ocr_results.txt


No external servers. No cloud sync. Everything stays on your device.

---

## 🚗 Uber Workflow

1. Take a screenshot inside the **Uber** app.
2. Open **BoltBlacklist**.
3. The latest screenshot loads automatically.
4. The red OCR rectangle is already positioned.
5. Tap **"OCR Uber"**.
6. If the plate number is not yet stored:
   - A flyout appears.
   - Tap the flyout to store the plate.
   - Or swipe to dismiss.

---

## 🚙 Bolt Workflow

1. Take a screenshot inside the **Bolt** app.
2. Share the screenshot to **BoltBlacklist**.
3. The app will:
   - Auto-load the image  
   - Automatically run **Bolt OCR**
4. If the plate number is not yet stored:
   - A flyout appears.
   - Tap to store.
   - Or swipe to dismiss.

---

## 🗂 Data Storage

- Stored locally in `Documents/ocr_results.txt`
- Optional notes can be saved alongside plate numbers
- No backend
- No tracking
- No data sharing

---

## ⚠️ Disclaimer

This app is for personal use only.  
Make sure you comply with local laws and platform terms of service when using screenshots and storing vehicle information.
