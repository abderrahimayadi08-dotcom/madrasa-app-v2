# PROJECT_MAP - المدرسة القرآنية

## TECH_STACK
- Flutter 3.44.4 / Dart 3.12.2
- Firebase Auth (email/password)
- Cloud Firestore (NoSQL)
- Cloudinary (صور)
- image_picker (التقاط الصور)
- intl (تنسيق التواريخ)

## SYSTEM_FLOW
### رحلة العضو:
```
member → login → MyRequestsScreen
  → أزرار الفلتر (الكل / قيد المراجعة / موافق / مرفوض)
  → FAB (+) → CreateRequestScreen
    → اختيار النوع: شراء / صيانة
    → شراء: itemName + image + price + priority → assignedRole: finance_manager
    → صيانة: itemName + image + location + priority → assignedRole: maintenance_manager
  → طلب جديد → Firestore `requests/{id}`
```

### رحلة المدير:
```
manager → login → DashboardScreen
  → Stream: getRequestsByRole(assignedRole)
  → مرتب حسب priority (urgent first) ثم createdAt
  → نقر على طلب → RequestDetailScreen
    → موافقة / رفض / تعليق + ملاحظات اختيارية
    → update: status + comment + reviewedAt
```

## ARCHITECTURE
```
lib/
├── main.dart                          # Firebase init + runApp
├── app.dart                           # MaterialApp + Theme
├── core/
│   ├── models/
│   │   ├── user_model.dart            # User (id, name, email, role)
│   │   └── request_model.dart         # Request (category, priority, status...)
│   ├── services/
│   │   ├── auth_service.dart          # signIn, register, signOut, getCurrentUser
│   │   ├── firestore_service.dart     # createRequest, getRequestsByUser, getRequestsByRole, updateStatus
│   │   ├── cloudinary_service.dart    # init + uploadImage (placeholder)
│   │   └── logger.dart                # info / warning / error
│   └── theme.dart                     # Material 3, green seed
├── features/
│   ├── auth/
│   │   ├── login_screen.dart          # Email + password → navigate by role
│   │   └── register_screen.dart       # Name + email + password + role dropdown
│   ├── requests/
│   │   ├── create_request_screen.dart  # Category chips + fields + image picker + submit
│   │   └── my_requests_screen.dart     # Stream list + filter chips + FAB new request
│   └── dashboard/
│       ├── dashboard_screen.dart       # Stream list sorted by priority + filter chips
│       └── request_detail_screen.dart  # Request info + approve/hold/reject buttons
```

### Firestore Collections
```
users/{userId}
  ├── id: String
  ├── name: String
  ├── email: String
  └── role: "member" | "finance_manager" | "maintenance_manager"

requests/{requestId}
  ├── id: String
  ├── userId: String
  ├── userName: String
  ├── category: "purchase" | "maintenance"
  ├── itemName: String
  ├── imageUrl: String
  ├── estimatedPrice: double
  ├── location: String? (maintenance only)
  ├── priority: "urgent" | "medium" | "low"
  ├── status: "pending" | "approved" | "rejected" | "hold"
  ├── assignedRole: "finance_manager" | "maintenance_manager"
  ├── comment: String?
  ├── createdAt: String (ISO8601)
  └── reviewedAt: String? (ISO8601)
```

## ORPHANS & PENDING
- [ ] **تثبيت Flutter SDK** على جهازك من flutter.dev (الإصدار 3.44.4)
- [ ] **تشغيل `flutter pub get`** في المجلد لتحميل التبعيات
- [ ] **Firebase Console**:
  - إنشاء مشروع جديد
  - تفعيل Authentication → Email/Password
  - إنشاء Firestore Database
  - تنزيل `google-services.json` ووضعه في `android/app/`
- [ ] **Cloudinary**:
  - إنشاء حساب مجاني
  - إنشاء Upload Preset (unsigned)
  - تعبئة `YOUR_CLOUD_NAME` و `YOUR_UPLOAD_PRESET` في `lib/core/services/cloudinary_service.dart`
- [ ] **Firestore Composite Index** (يدوي عبر Firebase Console):
  ```
  collection: requests
  fields: assignedRole (ascending), priority (descending), createdAt (descending)
  ```
- [ ] **Image upload الحقيقي**: استبدال دالة `uploadImage` في `cloudinary_service.dart` برفع حقيقي عبر Cloudinary API
- [ ] **تشغيل `flutter build apk --release`** لبناء APK
