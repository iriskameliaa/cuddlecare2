# 🤖 Telegram Bot Troubleshooting Guide

## 🚨 Bot Not Responding? Here's How to Fix It!

### **Quick Diagnostic Steps:**

#### **1. Check Bot Status**
- Open your CuddleCare app
- Go to **Admin Dashboard** → **Bot Test** tab
- Check if "Bot is running and listening for commands" is green
- If red, click **"Start Polling"**

#### **2. Test Bot Connection**
- In the Bot Test screen, enter your Chat ID
- Click **"Send Test"**
- Check if you receive a test message

#### **3. Check Console for Errors**
- Open browser developer tools (F12)
- Look for error messages in the console
- Common errors will be listed below

---

## 🔍 **Common Issues & Solutions**

### **Issue 1: Bot Token Problems**

**Symptoms:**
- Bot not responding to any commands
- Console shows "Bot token not configured"
- Test messages fail to send

**Solutions:**
```dart
// Check your bot token in lib/services/bot_config_service.dart
static const String _fallbackToken = 'YOUR_ACTUAL_BOT_TOKEN';
```

**Steps:**
1. Go to @BotFather on Telegram
2. Send `/mybots`
3. Select your bot
4. Copy the token
5. Update the fallback token in the code

### **Issue 2: Polling Not Active**

**Symptoms:**
- Bot status shows "Bot is not running"
- No response to commands
- Test screen shows red status

**Solutions:**
1. Go to **Admin Dashboard** → **Bot Test**
2. Click **"Start Polling"**
3. Wait for green status
4. Try sending `/start` to the bot

### **Issue 3: Network/API Issues**

**Symptoms:**
- Console shows HTTP errors
- "Error polling updates" messages
- Bot was working before but stopped

**Solutions:**
1. Check internet connection
2. Verify Telegram API is accessible
3. Restart the app
4. Clear browser cache

### **Issue 4: Bot Token Expired/Invalid**

**Symptoms:**
- "Unauthorized" errors in console
- Bot responds with error messages
- Test connection fails

**Solutions:**
1. Generate new bot token from @BotFather
2. Update the token in your code
3. Restart the app
4. Test connection again

---

## 🛠️ **Emergency Fixes**

### **Fix 1: Restart Everything**
```bash
# 1. Stop the app
# 2. Clear browser cache
# 3. Restart the app
# 4. Go to Admin Dashboard → Bot Test
# 5. Click "Start Polling"
```

### **Fix 2: Reset Bot Configuration**
```dart
// In lib/services/bot_config_service.dart
// Update the fallback token with your actual token
static const String _fallbackToken = 'YOUR_NEW_BOT_TOKEN';
```

### **Fix 3: Check Bot Permissions**
1. Go to @BotFather
2. Send `/mybots`
3. Select your bot
4. Check if bot is active
5. Verify privacy mode settings

### **Fix 4: Test Bot Manually**
1. Open Telegram
2. Search for your bot (@CuddleCare_app1_bot)
3. Send `/start`
4. Check if bot responds
5. If not, the bot token might be wrong

---

## 🔧 **Technical Debugging**

### **Check Console Logs**
Look for these messages:
```
✅ "Starting Telegram bot polling..."
✅ "Bot polling started successfully"
❌ "Error polling updates: 401" (Unauthorized)
❌ "Bot token not configured"
❌ "Error in polling: ..."
```

### **Test Bot API Directly**
```dart
// Add this to test bot connection
final botInfo = await BotConfigService.getBotInfo();
if (botInfo != null) {
  print('Bot is working: ${botInfo['username']}');
} else {
  print('Bot connection failed');
}
```

### **Verify Token Format**
```dart
// Token should look like this:
// "1234567890:ABCdefGHIjklMNOpqrsTUVwxyz"
// Numbers:Colon:RandomString
```

---

## 📱 **Step-by-Step Recovery**

### **Step 1: Verify Bot Exists**
1. Open Telegram
2. Search for @CuddleCare_app1_bot
3. If not found, create new bot with @BotFather

### **Step 2: Get New Token**
1. Message @BotFather
2. Send `/newbot` (if creating new) or `/mybots` (if existing)
3. Copy the token
4. Update in your code

### **Step 3: Test Connection**
1. Open your app
2. Go to Admin Dashboard → Bot Test
3. Enter your Chat ID
4. Click "Send Test"
5. Check if message arrives

### **Step 4: Start Polling**
1. In Bot Test screen
2. Click "Start Polling"
3. Wait for green status
4. Try sending `/start` to bot

### **Step 5: Test Commands**
Send these to your bot:
- `/start` - Should get welcome message
- `/help` - Should get command list
- `/mybookings` - Should get bookings (or demo)

---

## 🎯 **Prevention Tips**

### **1. Keep Token Secure**
- Don't share your bot token
- Use environment variables in production
- Regularly rotate tokens

### **2. Monitor Bot Status**
- Check Bot Test screen regularly
- Look for error messages in console
- Test bot functionality periodically

### **3. Handle Errors Gracefully**
- Bot should show demo data if real data fails
- Provide clear error messages
- Have fallback mechanisms

### **4. Regular Testing**
- Test bot commands weekly
- Verify polling is active
- Check token validity monthly

---

## 🆘 **Still Not Working?**

### **Last Resort Steps:**
1. **Create New Bot**
   - Go to @BotFather
   - Send `/newbot`
   - Follow instructions
   - Update token in code

2. **Check Firestore Rules**
   - Ensure bot can read user data
   - Verify permissions are correct

3. **Test with Demo Data**
   - Bot should work even without real data
   - Shows demo bookings and pets

4. **Contact Support**
   - Check console for specific errors
   - Note down error messages
   - Provide steps to reproduce

---

## ✅ **Success Checklist**

After fixing, verify:
- [ ] Bot responds to `/start`
- [ ] Bot shows green status in test screen
- [ ] Test message sends successfully
- [ ] Commands like `/mybookings` work
- [ ] No errors in console
- [ ] Polling is active

---

**Remember: The bot should work even with demo data! If it's not responding at all, it's likely a token or polling issue.** 🐾 