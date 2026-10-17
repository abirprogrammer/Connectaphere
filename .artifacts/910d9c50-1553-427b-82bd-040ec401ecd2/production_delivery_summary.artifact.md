# ConnectSphere — Production Delivery Summary

ConnectSphere is a complete, production-ready social networking platform inspired by Facebook and Messenger, built with a **Flutter** frontend, **PHP** REST backend, and **MySQL** database.

## 🚀 Key Professional Features

1. **Authentication & User Management**
   - Secure Registration and Login with encrypted passwords (`password_hash` & `password_verify`).
   - Session token management and profile synchronization.

2. **Professional Profile & Customization**
   - Cover photo, avatar image setup, bio, location, and website.
   - Real-time profile picture upload and updating directly from the app.

3. **Facebook-Style Feed & Posts**
   - Rich text posts, photo uploads, and video uploads.
   - Post likes/reactions, comments, and post saving (bookmarking).
   - Pull-to-refresh and smooth pagination.

4. **Stories & Reels**
   - 24-hour disappearing photo/video stories with viewer tracking.
   - Vertical full-screen Reels video playback.

5. **Friends & Messenger Chat**
   - Send, accept, and reject friend requests.
   - Direct messaging and conversation threads.

6. **Modern UI/UX & Theming**
   - Light and Dark theme controller with instant switching.
   - Material 3 design system with responsive layouts.

---

## 📦 Client Delivery Checklist

### 1. Database Setup
- Import `backend/database/schema.sql` into your MySQL 8+ database (e.g. `programm_abir2025`).

### 2. Backend Deployment
- Upload all `.php` files (`registers.php`, `login.php`, `profile.php`, `posts.php`, `stories.php`, `upload.php`, `comments.php`, `reactions.php`, `save_post.php`) and `.htaccess` to your server folder (e.g. `blood_app_api/`).

### 3. Frontend Configuration
- Ensure `ApiConstants.baseUrl` in `lib/core/constants/api_constants.dart` points to your production backend URL:
  ```dart
  static const String baseUrl = 'https://yourdomain.com/blood_app_api';
  ```
- Build the production release APK or web app:
  ```bash
  flutter build apk --release
  ```
