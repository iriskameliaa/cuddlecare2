# 4.2 Back-End Process

## 4.2.1 Backend Architecture Overview

The CuddleCare application utilizes a modern, cloud-based backend architecture built on Google Firebase platform. The backend is designed to provide scalable, secure, and real-time services for pet care booking and management.

### 4.2.1.1 Technology Stack
- **Primary Platform**: Google Firebase
- **Database**: Cloud Firestore (NoSQL)
- **Authentication**: Firebase Authentication
- **File Storage**: Firebase Storage
- **Serverless Functions**: Firebase Cloud Functions
- **Hosting**: Firebase Hosting
- **Security**: Firestore Security Rules

### 4.2.1.2 Architecture Components
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │    │  Telegram Bot   │    │  Admin Panel    │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────┴─────────────┐
                    │      Firebase Platform     │
                    │  ┌─────────────────────┐   │
                    │  │   Authentication    │   │
                    │  └─────────────────────┘   │
                    │  ┌─────────────────────┐   │
                    │  │    Cloud Firestore  │   │
                    │  └─────────────────────┘   │
                    │  ┌─────────────────────┐   │
                    │  │   Cloud Functions   │   │
                    │  └─────────────────────┘   │
                    │  ┌─────────────────────┐   │
                    │  │   Firebase Storage  │   │
                    │  └─────────────────────┘   │
                    └─────────────────────────────┘
```

## 4.2.2 Database Design and Structure

### 4.2.2.1 Firestore Collections

The application uses the following main collections in Cloud Firestore:

#### Users Collection (`users/{userId}`)
```javascript
{
  uid: "string",
  email: "string",
  name: "string",
  phoneNumber: "string",
  role: "user|provider|admin",
  isPetSitter: boolean,
  profilePicUrl: "string",
  bio: "string",
  location: {
    lat: number,
    lng: number
  },
  services: ["string"],
  petTypes: ["string"],
  rate: number,
  experience: "Beginner|Intermediate|Expert",
  reliabilityScore: number,
  verificationStatus: "pending|verified|rejected",
  createdAt: timestamp,
  updatedAt: timestamp
}
```

#### Providers Collection (`providers/{providerId}`)
```javascript
{
  name: "string",
  bio: "string",
  rate: number,
  experience: "string",
  services: ["string"],
  petTypes: ["string"],
  profilePicUrl: "string",
  idDocumentUrl: "string",
  phoneNumber: "string",
  address: "string",
  isPetSitter: boolean,
  role: "provider",
  setupCompleted: boolean,
  reliabilityScore: number,
  reliabilityLevel: "string",
  verificationStatus: "string",
  completedBookings: number,
  rating: number,
  reviewCount: number
}
```

#### Bookings Collection (`bookings/{bookingId}`)
```javascript
{
  userId: "string",
  userName: "string",
  providerId: "string",
  providerName: "string",
  petName: "string",
  service: "string",
  date: "string",
  status: "pending|confirmed|completed|rejected",
  notes: "string",
  customerGeo: GeoPoint,
  reminderSent: boolean,
  arrivalFeedbackSent: boolean,
  reviewRequestSent: boolean,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

#### Provider Verifications Collection (`provider_verifications/{verificationId}`)
```javascript
{
  providerId: "string",
  status: "pending|verified|rejected|suspended",
  backgroundCheckStatus: "notStarted|inProgress|passed|failed",
  verifiedCertificates: ["string"],
  pendingCertificates: ["string"],
  trustScore: number,
  verifiedAt: timestamp,
  verifiedBy: "string",
  rejectionReason: "string",
  createdAt: timestamp,
  updatedAt: timestamp
}
```

#### Chat Rooms Collection (`chat_rooms/{chatRoomId}`)
```javascript
{
  userId: "string",
  providerId: "string",
  bookingId: "string",
  lastMessage: "string",
  lastMessageTime: timestamp,
  lastMessageSenderId: "string",
  createdAt: timestamp
}
```

#### Messages Subcollection (`chat_rooms/{chatRoomId}/messages/{messageId}`)
```javascript
{
  senderId: "string",
  content: "string",
  imageUrl: "string",
  timestamp: timestamp,
  isRead: boolean
}
```

### 4.2.2.2 Data Relationships
- **One-to-Many**: User → Pets (subcollection)
- **One-to-Many**: User → Favorites (subcollection)
- **One-to-Many**: User → Bookings
- **One-to-One**: User → Provider Verification
- **Many-to-Many**: Users ↔ Chat Rooms (through messages)

## 4.2.3 Authentication and Authorization

### 4.2.3.1 Firebase Authentication
The application uses Firebase Authentication for user management with the following features:

- **Email/Password Authentication**: Primary authentication method
- **Role-Based Access Control**: User, Provider, and Admin roles
- **Session Management**: Automatic token refresh
- **Security**: Encrypted password storage

### 4.2.3.2 Security Rules Implementation
Firestore security rules ensure data protection and access control:

```javascript
// User authentication check
function isAuthenticated() {
  return request.auth != null;
}

// Admin role check
function isAdmin() {
  return isAuthenticated() && 
    (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin' ||
     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.email == 'admin@cuddlecare.com');
}

// Pet sitter role check
function isPetSitter() {
  return isAuthenticated() && 
    (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'provider' ||
     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isPetSitter == true);
}
```

### 4.2.3.3 Access Control Matrix

| Resource | User | Provider | Admin |
|----------|------|----------|-------|
| Own Profile | Read/Write | Read/Write | Read/Write |
| Other Profiles | Read | Read | Read/Write |
| Own Bookings | Read/Write | Read/Write | Read/Write |
| All Bookings | - | - | Read/Write |
| Provider Verifications | Read | Read/Write | Read/Write |
| Chat Messages | Own chats | Own chats | All chats |

## 4.2.4 Backend Services

### 4.2.4.1 Core Services

#### FirestoreService
```dart
class FirestoreService {
  // User data management
  Future<Map<String, dynamic>?> getUserData()
  Future<void> saveUserData({required String uid, required String email, required String name})
  Future<void> updateUserData({required String uid, required Map<String, dynamic> data})
  Future<void> deleteUserData(String uid)
}
```

#### ProfileService
```dart
class ProfileService {
  // Profile management
  Future<UserProfile?> getUserProfile(String uid)
  Future<List<UserProfile>> getPetSitters()
  Future<void> saveUserProfile(UserProfile profile)
  Future<List<UserProfile>> getProfilesByIds(List<String> userIds)
}
```

#### VerificationService
```dart
class VerificationService {
  // Provider verification
  Future<void> initializeVerification(String providerId)
  Future<ProviderVerification?> getVerification(String providerId)
  Future<void> updateVerificationStatus(String providerId, VerificationStatus status)
  Future<void> updateTrustScore(String providerId)
  Future<List<ProviderVerification>> getVerifiedProviders()
}
```

#### MessagingService
```dart
class MessagingService {
  // Real-time messaging
  Future<String> createOrGetChatRoom(String userId, String providerId)
  Future<void> sendMessage(String chatRoomId, String content)
  Stream<List<Message>> getMessages(String chatRoomId)
  Stream<List<ChatRoom>> getUserChatRooms()
}
```

#### FavoritesService
```dart
class FavoritesService {
  // Favorites management
  Future<void> addFavorite(String providerId)
  Future<void> removeFavorite(String providerId)
  Future<bool> isFavorite(String providerId)
  Stream<List<String>> getFavoriteProviderIds()
}
```

### 4.2.4.2 Smart Services

#### Smart Booking Reminders
Automated system for booking management:

```typescript
export const smartBookingReminders = functions.pubsub
  .schedule('every 15 minutes')
  .onRun(async (context) => {
    // Check upcoming bookings
    // Send reminders via Telegram
    // Request feedback and reviews
  });
```

#### Telegram Integration
Real-time communication through Telegram bot:

```dart
class TelegramBotService {
  // Bot commands
  Future<void> handleStartCommand(String chatId)
  Future<void> handleMyBookingsCommand(String chatId)
  Future<void> handleMyPetsCommand(String chatId)
  Future<void> handleWeatherCommand(String chatId, String location)
  Future<void> handleRecommendCommand(String chatId)
}
```

## 4.2.5 Cloud Functions

### 4.2.5.1 Scheduled Functions

#### Smart Booking Reminders (Every 15 minutes)
- **Purpose**: Automated booking management
- **Triggers**: Upcoming bookings within 24 hours
- **Actions**: 
  - Send reminder notifications
  - Request arrival feedback
  - Request post-service reviews

#### Provider Migration Function
- **Purpose**: Data migration and cleanup
- **Triggers**: Manual execution
- **Actions**: Migrate user data to provider collection

### 4.2.5.2 HTTP Functions

#### Admin Functions
```typescript
// Provider migration
export const migrateProvidersFunction = onRequest(migrateProviders);

// Smart booking management
export {smartBookingReminders, onBookingStatusChange};
```

## 4.2.6 File Storage and Media Management

### 4.2.6.1 Firebase Storage Structure
```
firebase-storage/
├── users/
│   └── {userId}/
│       ├── profile_image.jpg
│       ├── certificates/
│       │   └── certificate_1.pdf
│       └── identity/
│           └── id_document.pdf
└── pets/
    └── {petId}/
        └── pet_image.jpg
```

### 4.2.6.2 Storage Security Rules
```javascript
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 4.2.7 Real-time Features

### 4.2.7.1 Live Data Synchronization
- **Chat Messages**: Real-time messaging between users and providers
- **Booking Status**: Live updates on booking confirmations and changes
- **Provider Availability**: Real-time availability updates
- **Notifications**: Instant push notifications for important events

### 4.2.7.2 Stream-Based Architecture
```dart
// Real-time booking updates
Stream<QuerySnapshot> getBookingsStream() {
  return FirebaseFirestore.instance
      .collection('bookings')
      .where('providerId', isEqualTo: currentUserId)
      .snapshots();
}

// Real-time chat messages
Stream<List<Message>> getMessagesStream(String chatRoomId) {
  return FirebaseFirestore.instance
      .collection('chat_rooms')
      .doc(chatRoomId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Message.fromMap(doc.data()))
          .toList());
}
```

## 4.2.8 Data Processing and Analytics

### 4.2.8.1 Reliability Scoring System
Automated calculation of provider reliability:

```dart
double calculateTrustScore({
  required double rating,
  required int reviewCount,
  required int completedBookings,
  required int verifiedCertificates,
  required bool backgroundCheckPassed,
  required int experienceYears,
}) {
  double score = 0.0;
  
  // Rating contribution (40% of total)
  score += (rating / 5.0) * 40;
  
  // Review count contribution (20% of total)
  score += (reviewCount / 50.0).clamp(0.0, 1.0) * 20;
  
  // Completed bookings contribution (15% of total)
  score += (completedBookings / 20.0).clamp(0.0, 1.0) * 15;
  
  // Verified certificates contribution (15% of total)
  score += (verifiedCertificates / 5.0).clamp(0.0, 1.0) * 15;
  
  // Background check contribution (10% of total)
  score += backgroundCheckPassed ? 10 : 0;
  
  return score.clamp(0.0, 100.0);
}
```

### 4.2.8.2 Analytics and Reporting
- **Provider Performance Metrics**: Booking completion rates, ratings, reliability scores
- **User Engagement Analytics**: App usage patterns, feature adoption
- **Business Intelligence**: Revenue tracking, service popularity analysis
- **Quality Assurance**: Verification rates, trust level distribution

## 4.2.9 Security and Compliance

### 4.2.9.1 Data Protection
- **Encryption**: All data encrypted in transit and at rest
- **Access Control**: Role-based permissions and authentication
- **Audit Logging**: Comprehensive activity tracking
- **Data Retention**: Configurable data retention policies

### 4.2.9.2 Privacy Compliance
- **GDPR Compliance**: User data protection and right to deletion
- **Data Minimization**: Only collect necessary information
- **Consent Management**: Clear user consent for data processing
- **Transparency**: Clear privacy policies and data usage

### 4.2.9.3 Security Measures
- **Input Validation**: Server-side validation of all user inputs
- **SQL Injection Prevention**: Parameterized queries and input sanitization
- **XSS Protection**: Content Security Policy implementation
- **Rate Limiting**: API rate limiting to prevent abuse

## 4.2.10 Performance Optimization

### 4.2.10.1 Database Optimization
- **Indexing Strategy**: Optimized Firestore indexes for common queries
- **Query Optimization**: Efficient query patterns and pagination
- **Caching**: Client-side caching for frequently accessed data
- **Data Denormalization**: Strategic data duplication for performance

### 4.2.10.2 Scalability Features
- **Horizontal Scaling**: Automatic scaling with Firebase
- **Load Balancing**: Distributed load across multiple instances
- **CDN Integration**: Global content delivery for static assets
- **Database Sharding**: Efficient data distribution strategies

## 4.2.11 Error Handling and Monitoring

### 4.2.11.1 Error Management
```dart
// Comprehensive error handling
try {
  await saveUserData(userData);
} catch (e) {
  if (e is FirebaseException) {
    switch (e.code) {
      case 'permission-denied':
        handlePermissionError();
        break;
      case 'not-found':
        handleNotFoundError();
        break;
      default:
        handleGenericError(e);
    }
  }
}
```

### 4.2.11.2 Monitoring and Logging
- **Firebase Analytics**: User behavior and app performance tracking
- **Crashlytics**: Real-time crash reporting and analysis
- **Performance Monitoring**: App performance metrics and optimization
- **Custom Logging**: Structured logging for debugging and analysis

## 4.2.12 Backup and Recovery

### 4.2.12.1 Data Backup Strategy
- **Automated Backups**: Daily automated Firestore backups
- **Point-in-Time Recovery**: Ability to restore to specific timestamps
- **Cross-Region Replication**: Data replication across multiple regions
- **Disaster Recovery**: Comprehensive disaster recovery procedures

### 4.2.12.2 Recovery Procedures
- **Data Restoration**: Step-by-step data recovery processes
- **Service Continuity**: Minimal downtime during recovery
- **Testing**: Regular backup and recovery testing
- **Documentation**: Comprehensive recovery documentation

## 4.2.13 Integration and APIs

### 4.2.13.1 External Service Integrations
- **Telegram Bot API**: Real-time messaging and notifications
- **Weather API**: Weather information for outdoor services
- **Google Maps API**: Location services and route optimization
- **Payment Gateway**: Secure payment processing (future implementation)

### 4.2.13.2 API Design Principles
- **RESTful Design**: Standard REST API patterns
- **Versioning**: API versioning for backward compatibility
- **Documentation**: Comprehensive API documentation
- **Rate Limiting**: API rate limiting and throttling

## 4.2.14 Deployment and DevOps

### 4.2.14.1 Deployment Pipeline
- **Continuous Integration**: Automated testing and building
- **Continuous Deployment**: Automated deployment to Firebase
- **Environment Management**: Separate development, staging, and production environments
- **Rollback Procedures**: Quick rollback capabilities for issues

### 4.2.14.2 Configuration Management
- **Environment Variables**: Secure configuration management
- **Feature Flags**: Dynamic feature enabling/disabling
- **Remote Config**: Firebase Remote Config for dynamic settings
- **Secrets Management**: Secure handling of sensitive configuration

This comprehensive backend architecture ensures the CuddleCare application provides reliable, scalable, and secure services for pet care booking and management, addressing the core problem of limited accessibility to reliable pet sitters through robust backend processes and systems. 