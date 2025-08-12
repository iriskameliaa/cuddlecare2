import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

export const telegramWebhookSimple = onRequest(async (request, response) => {
  try {
    // Only allow POST requests
    if (request.method !== "POST") {
      response.status(405).send("Method Not Allowed");
      return;
    }

    const webhookData = request.body;
    logger.info("Received Telegram webhook:", webhookData);

    // Extract message from webhook data
    const message = webhookData.message;
    if (!message) {
      response.status(200).json({
        status: "no_message",
        message: "No message in webhook data"
      });
      return;
    }

    const chatId = message.chat.id.toString();
    const text = message.text || "";
    const from = message.from;

    let result;

    // Handle different commands
    if (text.startsWith("/start")) {
      result = await handleStartCommand(chatId, from);
    } else if (text.startsWith("/link")) {
      result = await handleLinkCommand(chatId, text);
    } else if (text.startsWith("/unlink")) {
      result = await handleUnlinkCommand(chatId);
    } else if (text.startsWith("/mybookings")) {
      result = await handleMyBookingsCommand(chatId);
    } else if (text.startsWith("/mypets")) {
      result = await handleMyPetsCommand(chatId);
    } else {
      result = await handleUnknownCommand(chatId, text);
    }

    response.status(200).json(result);
  } catch (error) {
    logger.error("Error processing Telegram webhook:", error);
    response.status(500).json({
      status: "error",
      message: "Internal server error"
    });
  }
});

// Handle /start command
async function handleStartCommand(chatId: string, from: any) {
  try {
    const userFirstName = from?.first_name || "User";
    
    const message = `🐾 <b>Welcome to CuddleCare, ${userFirstName}!</b>

Your trusted pet care companion is here to help!

To get started, please link your CuddleCare account:
/link your.email@example.com

Example: /link john.doe@example.com

Once linked, you can:
• View your bookings with /mybookings
• Check your pets with /mypets
• Get personalized recommendations
• Receive booking notifications

Need help? Contact support through the CuddleCare app.
`;

    // Send the message via Telegram API
    await sendTelegramMessage(chatId, message);

    return {
      status: "success",
      command: "start",
      message: "Instructions sent"
    };
  } catch (error) {
    logger.error("Error handling start command:", error);
    return {
      status: "error",
      command: "start",
      message: "Failed to process start command"
    };
  }
}

// Handle /link command
async function handleLinkCommand(chatId: string, text: string) {
  try {
    const parts = text.split(" ");
    if (parts.length < 2) {
      const message = `🔗 <b>Link Your Account</b>

Please provide your CuddleCare email:
/link email@example.com

Example: /link john.doe@example.com
`;

      await sendTelegramMessage(chatId, message);
      return {
        status: "error",
        command: "link",
        message: "Missing email"
      };
    }

    const email = parts[1].trim();
    const user = await getUserByEmail(email);

    if (!user) {
      const message = `❌ <b>Account Not Found</b>

No CuddleCare account found with email: ${email}

Please check your email or create an account in the CuddleCare app first.

If you need help, contact support through the app.
`;

      await sendTelegramMessage(chatId, message);
      return {
        status: "error",
        command: "link",
        message: "Account not found"
      };
    }

    // Link the account
    await linkTelegramAccount(user.uid, chatId);

    const message = `✅ <b>Account Linked Successfully!</b>

Welcome back, ${(user as any).name || "User"}!
Your Telegram account has been linked to your CuddleCare account.

You can now:
• View your real bookings with /mybookings
• Check your pets with /mypets
• Get personalized recommendations
• Receive booking notifications

Try /mybookings to see your upcoming bookings!
`;

    await sendTelegramMessage(chatId, message);

    return {
      status: "success",
      command: "link",
      message: "Account linked successfully"
    };
  } catch (error) {
    logger.error("Error handling link command:", error);
    return {
      status: "error",
      command: "link",
      message: "Failed to link account"
    };
  }
}

// Handle /unlink command
async function handleUnlinkCommand(chatId: string) {
  try {
    // Check if user is currently linked
    const user = await getUserByChatId(chatId);

    if (!user) {
      const message = `❌ <b>Account Not Linked</b>

Your Telegram account is not currently linked to any CuddleCare account.

To link an account, use:
/link your.email@example.com
`;

      await sendTelegramMessage(chatId, message);
      return {
        status: "error",
        command: "unlink",
        message: "Account not linked"
      };
    }

    // Unlink the account by removing the telegramChatId
    await unlinkTelegramAccount(user.uid, chatId);

    const message = `✅ <b>Account Unlinked Successfully</b>

Your Telegram account has been disconnected from CuddleCare.

You will no longer receive:
• Booking notifications
• Status updates
• Personalized recommendations

To link again in the future, use:
/link your.email@example.com

Thank you for using CuddleCare! 🐾
`;

    await sendTelegramMessage(chatId, message);

    return {
      status: "success",
      command: "unlink",
      message: "Account unlinked successfully"
    };
  } catch (error) {
    logger.error("Error handling unlink command:", error);
    return {
      status: "error",
      command: "unlink",
      message: "Failed to unlink account"
    };
  }
}

// Handle /mybookings command
async function handleMyBookingsCommand(chatId: string) {
  try {
    // Check if user is linked
    const user = await getUserByChatId(chatId);

    if (!user) {
      const message = `❌ <b>Account Not Linked</b>

Please link your CuddleCare account first:
/link your.email@example.com
`;

      await sendTelegramMessage(chatId, message);
      return {
        status: "error",
        command: "mybookings",
        message: "Account not linked"
      };
    }

    // Get user's bookings
    const bookings = await getUserBookings(user.uid);

    if (!bookings || bookings.length === 0) {
      const message = `� <b>Your Bookings</b>

You don't have any upcoming bookings.

Book a pet sitter through the CuddleCare app to see your bookings here!
`;

      await sendTelegramMessage(chatId, message);
      return {
        status: "success",
        command: "mybookings",
        message: "No bookings found"
      };
    }

    // Build bookings message
    let message = `📅 <b>Your Upcoming Bookings (${bookings.length})</b>\n\n`;

    bookings.forEach((booking: any, index: number) => {
      message += `${index + 1}. 🐾 <b>${booking.service || 'Pet Care'}</b>\n`;
      message += `   📅 Date: ${booking.date || 'TBD'}\n`;

      // Handle multiple pets or single pet
      if (booking.petNames && Array.isArray(booking.petNames) && booking.petNames.length > 1) {
        message += `   🐕 Pets: ${booking.petNames.join(', ')}\n`;
        message += `   📊 Pet Count: ${booking.petCount || booking.petNames.length}\n`;
      } else {
        message += `   🐕 Pet: ${booking.petName || booking.petNames?.[0] || 'Unknown'}\n`;
      }

      message += `   👩‍⚕️ Provider: ${booking.providerName || 'TBD'}\n`;
      message += `   📊 Status: ${booking.status || 'pending'}\n`;
      message += `\n`;
    });

    message += `📱 View full details in the CuddleCare app!`;

    await sendTelegramMessage(chatId, message);

    return {
      status: "success",
      command: "mybookings",
      message: `Found ${bookings.length} bookings`
    };
  } catch (error) {
    console.error("Error handling mybookings command:", error);

    const message = `❌ <b>Error</b>

Sorry, there was an error retrieving your bookings. Please try again later.
`;

    await sendTelegramMessage(chatId, message);

    return {
      status: "error",
      command: "mybookings",
      message: "Failed to get bookings"
    };
  }
}

// Handle /mypets command
async function handleMyPetsCommand(chatId: string) {
  try {
    // Check if user is linked
    const user = await getUserByChatId(chatId);

    if (!user) {
      const message = `❌ <b>Account Not Linked</b>

Please link your CuddleCare account first:
/link your.email@example.com
`;

      await sendTelegramMessage(chatId, message);
      return {
        status: "error",
        command: "mypets",
        message: "Account not linked"
      };
    }

    // Get user's pets
    const pets = await getUserPets(user.uid);

    if (!pets || pets.length === 0) {
      const message = `🐕 <b>Your Pets</b>

You don't have any pets registered.

Add your pets through the CuddleCare app to see them here!
`;

      await sendTelegramMessage(chatId, message);
      return {
        status: "success",
        command: "mypets",
        message: "No pets found"
      };
    }

    // Build pets message
    let message = `🐕 <b>Your Pets (${pets.length})</b>\n\n`;

    pets.forEach((pet, index) => {
      message += `${index + 1}. 🐾 <b>${pet.name || 'Unnamed Pet'}</b>\n`;
      message += `   🏷️ Breed: ${pet.breed || 'Unknown'}\n`;
      message += `   🎂 Age: ${pet.age || 'Unknown'}\n`;
      if (pet.specialNeeds) {
        message += `   ⚠️ Special Needs: ${pet.specialNeeds}\n`;
      }
      message += `\n`;
    });

    message += `📱 Manage your pets in the CuddleCare app!`;

    await sendTelegramMessage(chatId, message);

    return {
      status: "success",
      command: "mypets",
      message: "Pets list sent"
    };
  } catch (error) {
    console.error("Error handling mypets command:", error);

    const message = `❌ <b>Error Loading Pets</b>

Sorry, there was an error loading your pets. Please try again later or use the CuddleCare mobile app.
`;

    await sendTelegramMessage(chatId, message);

    return {
      status: "error",
      command: "mypets",
      message: "Failed to load pets"
    };
  }
}

// Handle unknown commands
async function handleUnknownCommand(chatId: string, text: string) {
  const message = `❓ <b>Unknown Command</b>

I don't understand "${text}".

Available commands:
• /start - Get started and link your account
• /link email@example.com - Link your CuddleCare account
• /unlink - Disconnect your Telegram account
• /mybookings - View your upcoming bookings
• /mypets - View your pets

Need help? Contact support through the CuddleCare app.
`;

  await sendTelegramMessage(chatId, message);

  return {
    status: "success",
    command: "unknown",
    message: "Help sent"
  };
}

// Helper function to get user by email
async function getUserByEmail(email: string) {
  try {
    const userSnapshot = await db.collection("users")
      .where("email", "==", email)
      .limit(1)
      .get();

    if (!userSnapshot.empty) {
      const doc = userSnapshot.docs[0];
      return {uid: doc.id, ...doc.data()};
    }
    return null;
  } catch (error) {
    logger.error("Error getting user by email:", error);
    return null;
  }
}

async function getUserByChatId(chatId: string) {
  try {
    const userSnapshot = await db.collection("users")
      .where("telegramChatId", "==", chatId)
      .limit(1)
      .get();

    if (!userSnapshot.empty) {
      const doc = userSnapshot.docs[0];
      return {uid: doc.id, ...doc.data()};
    }
    return null;
  } catch (error) {
    logger.error("Error getting user by chat ID:", error);
    return null;
  }
}

async function linkTelegramAccount(userId: string, chatId: string) {
  try {
    await db.collection("users").doc(userId).update({
      telegramChatId: chatId,
      telegramLinkedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    logger.info(`Linked Telegram chat ID ${chatId} to user ${userId}`);
  } catch (error) {
    logger.error("Error linking Telegram account:", error);
    throw error;
  }
}

async function unlinkTelegramAccount(userId: string, chatId: string) {
  try {
    await db.collection("users").doc(userId).update({
      telegramChatId: admin.firestore.FieldValue.delete(),
      telegramUnlinkedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    logger.info(`Unlinked Telegram chat ID ${chatId} from user ${userId}`);
  } catch (error) {
    logger.error("Error unlinking Telegram account:", error);
    throw error;
  }
}

async function getUserPets(userId: string) {
  try {
    const petsSnapshot = await db.collection("users")
      .doc(userId)
      .collection("pets")
      .get();

    const pets: any[] = [];
    petsSnapshot.forEach((doc) => {
      pets.push({id: doc.id, ...doc.data()});
    });

    return pets;
  } catch (error) {
    logger.error("Error getting user pets:", error);
    return [];
  }
}

async function getUserBookings(userId: string) {
  try {
    const bookingsSnapshot = await db.collection("bookings")
      .where("userId", "==", userId)
      .get();

    const bookings: any[] = [];
    bookingsSnapshot.forEach((doc) => {
      bookings.push({id: doc.id, ...doc.data()});
    });

    // Filter future bookings
    const now = new Date();
    return bookings.filter((booking: any) => {
      if (booking.date) {
        const bookingDate = new Date(booking.date);
        return bookingDate >= now;
      }
      return false;
    }).sort((a: any, b: any) => {
      return new Date(a.date).getTime() - new Date(b.date).getTime();
    });
  } catch (error) {
    logger.error("Error getting user bookings:", error);
    return [];
  }
}

async function sendTelegramMessage(chatId: string, message: string) {
  try {
    const botToken = process.env.TELEGRAM_BOT_TOKEN || "YOUR_BOT_TOKEN";
    const baseUrl = `https://api.telegram.org/bot${botToken}`;

    const response = await fetch(`${baseUrl}/sendMessage`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        chat_id: chatId,
        text: message,
        parse_mode: "HTML",
      }),
    });

    if (!response.ok) {
      throw new Error(`Telegram API error: ${response.status}`);
    }

    const data = await response.json();
    return data.ok;
  } catch (error) {
    logger.error("Error sending Telegram message:", error);
    return false;
  }
}

// 🔔 Smart Notifications for Pet Owners
export const sendBookingNotification = onRequest(async (request, response) => {
  try {
    const {type, userId, data} = request.body;

    // Get user's Telegram chat ID
    const user = await db.collection("users").doc(userId).get();
    if (!user.exists || !user.data()?.telegramChatId) {
      response.status(200).json({status: "no_telegram_link"});
      return;
    }

    const chatId = user.data()?.telegramChatId;
    let message = "";

    switch (type) {
      case "booking_confirmed":
        message = `✅ <b>Booking Confirmed!</b>

Your pet sitting appointment is confirmed for <b>${data.date}</b> at <b>${data.time}</b>

🐾 Pet: ${data.petName}
👩‍⚕️ Provider: ${data.providerName}
📍 Location: ${data.location}
💰 Cost: $${data.cost}

Your provider will arrive 15 minutes early for setup.
You'll receive updates when they're on their way!`;
        break;

      case "provider_arriving":
        message = `🚗 <b>Provider On The Way!</b>

${data.providerName} is on their way to your location.

⏰ ETA: <b>${data.eta} minutes</b>
📍 Current location: ${data.currentLocation}
📞 Contact: ${data.phone}

Your pet ${data.petName} will be in great hands! 🐾`;
        break;

      case "service_completed":
        message = `✅ <b>Service Completed!</b>

Pet grooming session completed! 📸

🐾 Pet: ${data.petName}
👩‍⚕️ Provider: ${data.providerName}
⏰ Duration: ${data.duration}
💰 Total: $${data.cost}

${data.photos ? "📸 Photos have been uploaded to your account!" : ""}
${data.notes ? `📝 Notes: ${data.notes}` : ""}

Rate your experience in the CuddleCare app!`;
        break;

      case "emergency_alert":
        message = `🚨 <b>URGENT: Pet Health Alert</b>

Your pet sitter reports ${data.petName} seems unwell.

⚠️ Issue: ${data.issue}
📞 Please call immediately: ${data.providerPhone}
🏥 Nearest vet: ${data.nearestVet}

Your pet sitter is monitoring the situation.`;
        break;

      case "reminder":
        message = `⏰ <b>Reminder</b>

Don't forget: ${data.service} scheduled in <b>${data.timeUntil}</b>

🐾 Pet: ${data.petName}
👩‍⚕️ Provider: ${data.providerName}
📍 Location: ${data.location}

Make sure ${data.petName} is ready! 🐕`;
        break;

      default:
        message = `📱 <b>CuddleCare Update</b>

You have a new update regarding your pet care service.
Check the CuddleCare app for details.`;
    }

    await sendTelegramMessage(chatId, message);

    response.status(200).json({
      status: "success",
      message: "Notification sent"
    });
  } catch (error) {
    logger.error("Error sending booking notification:", error);
    response.status(500).json({
      status: "error",
      message: "Failed to send notification"
    });
  }
});
