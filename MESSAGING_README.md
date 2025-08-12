# CuddleCare Messaging System & Telegram Bot Integration

## 📱 Messaging System

### Features
- **Real-time chat** between users and providers
- **Image sharing** support
- **Message status** (read/unread)
- **Chat room management**
- **Booking-linked conversations**

### Architecture

#### Models
- `Message` - Individual chat messages
- `ChatRoom` - Conversation containers
- `MessagingService` - Business logic

#### Collections
```
chat_rooms/
├── {chatRoomId}/
│   ├── userId: string
│   ├── providerId: string
│   ├── bookingId: string (optional)
│   ├── createdAt: timestamp
│   ├── lastMessageTime: timestamp
│   ├── lastMessage: string
│   ├── lastMessageSenderId: string
│   ├── unreadCount: number
│   └── isActive: boolean
│   └── messages/
│       ├── {messageId}/
│       │   ├── id: string
│       │   ├── senderId: string
│       │   ├── receiverId: string
│       │   ├── content: string
│       │   ├── timestamp: timestamp
│       │   ├── imageUrl: string (optional)
│       │   ├── isRead: boolean
│       │   └── messageType: string
```

### Usage

#### Starting a Chat
```dart
final messagingService = MessagingService();
final chatRoomId = await messagingService.createOrGetChatRoom(
  userId,
  providerId,
  bookingId: bookingId, // optional
);
```

#### Sending Messages
```dart
await messagingService.sendMessage(chatRoomId, "Hello!");
```

#### Listening to Messages
```dart
StreamBuilder<List<Message>>(
  stream: messagingService.getMessages(chatRoomId),
  builder: (context, snapshot) {
    // Handle messages
  },
)
```

## 🤖 Telegram Bot Integration

### Features
- **Booking notifications** to providers
- **Status updates** to customers
- **Service reminders**
- **Completion notifications**
- **Command handling** (/start, /help, /status)

### Setup

1. **Create a Telegram Bot**
   ```bash
   # Message @BotFather on Telegram
   /newbot
   # Follow instructions to create bot
   # Save the bot token
   ```

2. **Configure Bot Token**
   ```dart
   // In lib/services/telegram_bot_service.dart
   static const String _botToken = 'YOUR_BOT_TOKEN';
   ```

3. **Set Webhook** (for production)
   ```dart
   await TelegramBotService.setWebhook('https://your-domain.com/webhook');
   ```

### API Endpoints

#### Send Notification
```dart
await TelegramBotService.sendNotification(
  chatId: '123456789',
  message: 'Hello from CuddleCare!',
);
```

#### Booking Notifications
```dart
await TelegramBotService.sendBookingNotification(
  providerChatId: 'provider_chat_id',
  customerName: 'John Doe',
  service: 'Pet Sitting',
  date: '2024-01-15',
  petName: 'Buddy',
  bookingId: 'booking_123',
);
```

#### Status Updates
```dart
await TelegramBotService.sendStatusUpdate(
  chatId: 'user_chat_id',
  bookingId: 'booking_123',
  status: 'confirmed',
  providerName: 'Jane Smith',
);
```

### Bot Commands

- `/start` - Welcome message and bot info
- `/help` - Show available commands
- `/status [booking_id]` - Check booking status

### Integration Points

#### 1. Booking Creation
```dart
// After successful booking
await TelegramBotService.sendBookingNotification(
  providerChatId: provider.telegramChatId,
  customerName: user.name,
  service: booking.service,
  date: booking.date,
  petName: booking.petName,
  bookingId: booking.id,
);
```

#### 2. Booking Status Changes
```dart
// When provider accepts/declines booking
await TelegramBotService.sendStatusUpdate(
  chatId: customer.telegramChatId,
  bookingId: booking.id,
  status: 'confirmed',
  providerName: provider.name,
);
```

#### 3. Service Reminders
```dart
// Scheduled reminder (implement with cron jobs)
await TelegramBotService.sendReminder(
  chatId: customer.telegramChatId,
  bookingId: booking.id,
  service: booking.service,
  date: booking.date,
  time: booking.time,
);
```

## 🔧 Implementation Steps

### 1. Add Telegram Chat IDs to User Profiles
```dart
// In user profile
Map<String, dynamic> userData = {
  'uid': user.uid,
  'name': user.name,
  'telegramChatId': '123456789', // Add this field
  // ... other fields
};
```

### 2. Update Booking Flow
```dart
// In booking creation
if (provider.telegramChatId != null) {
  await TelegramBotService.sendBookingNotification(
    providerChatId: provider.telegramChatId,
    customerName: user.name,
    service: selectedService,
    date: selectedDate,
    petName: selectedPet.name,
    bookingId: bookingId,
  );
}
```

### 3. Add Chat Integration to UI
```dart
// In booking success page
ElevatedButton(
  onPressed: () async {
    final chatRoomId = await messagingService.createOrGetChatRoom(
      userId,
      providerId,
      bookingId: bookingId,
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatRoomId: chatRoomId,
          otherUserName: providerName,
          bookingId: bookingId,
        ),
      ),
    );
  },
  child: Text('Start Chat'),
)
```

## 🔒 Security Considerations

### Firestore Rules
```javascript
// Chat rooms
match /chat_rooms/{chatRoomId} {
  allow read, write: if isAuthenticated() && 
    (resource.data.userId == request.auth.uid || 
     resource.data.providerId == request.auth.uid);
  
  // Messages subcollection
  match /messages/{messageId} {
    allow read, write: if isAuthenticated() && 
      (get(/databases/$(database)/documents/chat_rooms/$(chatRoomId)).data.userId == request.auth.uid || 
       get(/databases/$(database)/documents/chat_rooms/$(chatRoomId)).data.providerId == request.auth.uid);
  }
}
```

### Telegram Bot Security
- Store bot token securely (use environment variables)
- Validate incoming webhook requests
- Rate limit message sending
- Implement user authentication for bot commands

## 🚀 Future Enhancements

### Messaging System
- [ ] **Voice messages** support
- [ ] **File sharing** (documents, videos)
- [ ] **Message reactions** (like, heart, etc.)
- [ ] **Typing indicators**
- [ ] **Message search** functionality
- [ ] **Chat backup** and export

### Telegram Bot
- [ ] **Payment integration** via Telegram Payments
- [ ] **Location sharing** for service coordination
- [ ] **Photo sharing** for pet updates
- [ ] **Automated scheduling** via bot commands
- [ ] **Multi-language** support
- [ ] **Analytics dashboard** for bot usage

### Smart Features
- [ ] **AI-powered** message suggestions
- [ ] **Auto-translation** for international users
- [ ] **Smart reminders** based on user behavior
- [ ] **Integration** with calendar apps
- [ ] **Voice commands** for hands-free operation

## 📊 Monitoring & Analytics

### Key Metrics
- **Message delivery rate**
- **Response times**
- **User engagement**
- **Bot command usage**
- **Error rates**

### Logging
```dart
// Add logging to messaging service
print('Message sent: ${message.id}');
print('Chat room created: ${chatRoom.id}');
print('Telegram notification sent: ${success}');
```

## 🛠 Troubleshooting

### Common Issues

1. **Messages not sending**
   - Check Firestore rules
   - Verify user authentication
   - Check network connectivity

2. **Telegram notifications not working**
   - Verify bot token
   - Check chat ID format
   - Ensure bot has permission to send messages

3. **Real-time updates not working**
   - Check Firestore connection
   - Verify stream listeners
   - Check for error handling

### Debug Commands
```dart
// Test messaging service
await messagingService.sendMessage(chatRoomId, 'Test message');

// Test Telegram bot
await TelegramBotService.getBotInfo();
await TelegramBotService.sendNotification(
  chatId: 'your_chat_id',
  message: 'Test notification',
);
```

---

**Note:** This messaging system provides a solid foundation for user-provider communication. The Telegram bot integration adds an extra layer of convenience and automation for service management. 