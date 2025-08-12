# 🤖 Telegram Bot Testing Guide

## 📋 Overview

This guide will help you test the Telegram bot with your current Firestore data. The bot can work with both real data and demo data, making it perfect for testing and demonstration.

## 🚀 Quick Start

### Step 1: Access the Test Screen
1. Open your CuddleCare app
2. Go to **Admin Dashboard** (login as admin if needed)
3. Navigate to the **"Bot Test"** tab (last tab)
4. You'll see the Telegram Bot Testing screen

### Step 2: Start the Bot
1. Click **"Start Polling"** button
2. You should see "Bot is running and listening for commands"
3. The bot is now active and ready to receive commands

### Step 3: Connect Your Telegram Account
1. Open **Telegram** on your phone
2. Search for **@CuddleCare_app1_bot**
3. Send **/start** to the bot
4. Use **@userinfobot** to get your Chat ID
5. Enter your Chat ID in the test screen and click **"Send Test"**

## 🧪 Testing Commands

Once connected, try these commands in Telegram:

### Basic Commands
- `/start` - Welcome message and bot info
- `/help` - Show available commands
- `/mybookings` - View your bookings
- `/mypets` - View your pets
- `/weather` - Check weather for your area
- `/recommend` - Get personalized recommendations

### Expected Responses

#### `/start` Response:
```
🤖 Welcome to CuddleCare Bot!

I'm here to help you with your pet care services.

Available commands:
/start - Show this welcome message
/help - Show help information
/mybookings - View your bookings
/mypets - View your pets
/weather - Check weather
/recommend - Get recommendations

For support, contact us through the CuddleCare app.
```

#### `/mybookings` Response:
If you have real bookings:
```
📅 Your Upcoming Bookings

🔸 Dog Walking for Buddy
   📅 Date: [Today's date]
   ⏰ Time: 09:00 AM
   📍 Location: Central Park
   💰 Price: $25.00
   📊 Status: confirmed

🔸 Pet Sitting for Fluffy
   📅 Date: [Today's date]
   ⏰ Time: 02:00 PM
   📍 Location: Home
   💰 Price: $35.00
   📊 Status: confirmed
```

If no real bookings (demo mode):
```
📅 Your Upcoming Bookings

🔸 Dog Walking for Buddy
   📅 Date: Today
   ⏰ Time: 09:00 AM
   📍 Location: Central Park
   💰 Price: $25.00
   📊 Status: confirmed

🔸 Pet Sitting for Fluffy
   📅 Date: Today
   ⏰ Time: 02:00 PM
   📍 Location: Home
   💰 Price: $35.00
   📊 Status: confirmed

💡 Demo Mode: This is demo data. To see your real bookings, link your account in the CuddleCare app.
```

## 📊 Current Data Status

The test screen shows you:

### Users with Telegram Chat IDs
- Shows how many users have connected their Telegram accounts
- Lists user names and their Chat IDs

### Recent Bookings
- Shows your most recent bookings from Firestore
- Displays service type and pet name

### Recent Pets
- Shows pets stored in your Firestore
- Displays pet name and breed

## 🔧 Testing with Real Data

To test with your real Firestore data:

### 1. Add Telegram Chat ID to User Profile
```dart
// In your user profile document, add:
{
  "telegramChatId": "123456789"  // Your actual Chat ID
}
```

### 2. Ensure You Have Real Data
- **Bookings**: Create bookings in the `bookings` collection
- **Pets**: Add pets to the `pets` collection
- **Users**: Make sure users have `telegramChatId` field

### 3. Test Commands
- Send `/mybookings` - Should show your real bookings
- Send `/mypets` - Should show your real pets
- Send `/weather` - Should show weather for your location

## 🎯 Demo Mode

If you don't have real data or haven't linked your account:

1. **Bot still works** - It shows demo data
2. **All commands work** - You get realistic responses
3. **Perfect for demos** - Shows the full functionality

Demo data includes:
- Sample bookings (Dog Walking, Pet Sitting, Pet Grooming)
- Sample pets (Buddy, Fluffy, Max)
- Weather information
- Personalized recommendations

## 🐛 Troubleshooting

### Bot Not Responding
1. Check if polling is started in the test screen
2. Verify the bot token is configured correctly
3. Check console for error messages

### Commands Not Working
1. Make sure you sent `/start` first
2. Check that your Chat ID is correct
3. Verify the bot is running (green status in test screen)

### No Real Data Showing
1. Check if your user profile has `telegramChatId`
2. Verify you have bookings in Firestore
3. Ensure pets are in the `pets` collection

### Test Message Not Sending
1. Verify your Chat ID is correct
2. Check bot token configuration
3. Try restarting the polling

## 📱 Admin Dashboard Integration

The bot testing is integrated into your admin dashboard:

1. **Admin Dashboard** → **Bot Test** tab
2. **Start/Stop Polling** controls
3. **Quick test message** sending
4. **Current data overview**
5. **Step-by-step instructions**

## 🎓 Final Year Project Demo

For your final year project demonstration:

### Setup (5 minutes)
1. Start the app
2. Login as admin
3. Go to Bot Test tab
4. Start polling
5. Connect your Telegram account

### Demo Flow (10 minutes)
1. **Show bot connection** - Send test message
2. **Demonstrate commands** - Try each command
3. **Show real data** - If you have real bookings/pets
4. **Show demo mode** - If no real data
5. **Explain features** - Weather, recommendations, etc.

### Key Features to Highlight
- ✅ **Real-time notifications**
- ✅ **Personalized responses**
- ✅ **Weather integration**
- ✅ **Smart recommendations**
- ✅ **Demo mode for testing**
- ✅ **Admin controls**
- ✅ **User-friendly interface**

## 🔗 Quick Links

- **Bot Username**: @CuddleCare_app1_bot
- **Chat ID Helper**: @userinfobot
- **Raw Data Bot**: @RawDataBot
- **Admin Email**: admin@cuddlecare.com
- **Admin Password**: admin123456

## 📞 Support

If you encounter issues:
1. Check the console for error messages
2. Verify all configuration steps
3. Test with demo data first
4. Ensure Firestore permissions are correct

---

**Happy Testing! 🐾** 