import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WebhookInstructionsScreen extends StatelessWidget {
  const WebhookInstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Webhook Setup Instructions'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success Message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Webhook Setup Complete!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your Telegram bot is now configured to use webhooks and should respond to commands.',
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Test Instructions
            _buildInstructionCard(
              'Test Your Bot',
              Icons.chat,
              Colors.blue,
              [
                '1. Open Telegram on your phone or computer',
                '2. Search for your bot (check Bot Control screen for username)',
                '3. Start a chat with your bot',
                '4. Send the command: /start',
                '5. You should receive a welcome message!',
              ],
            ),

            const SizedBox(height: 16),

            // Link Account Instructions
            _buildInstructionCard(
              'Link Your Account',
              Icons.link,
              Colors.purple,
              [
                '1. After receiving the welcome message',
                '2. Use the /link command with your email:',
                '   /link your.email@example.com',
                '3. Replace with your actual CuddleCare account email',
                '4. Once linked, you can use other commands like:',
                '   • /mybookings - View your bookings',
                '   • /mypets - View your pets',
              ],
            ),

            const SizedBox(height: 16),

            // Troubleshooting
            _buildInstructionCard(
              'Troubleshooting',
              Icons.help_outline,
              Colors.orange,
              [
                'If the bot doesn\'t respond:',
                '• Wait 1-2 minutes after setup',
                '• Check Bot Diagnostics screen',
                '• Make sure you\'re messaging the correct bot',
                '• Try the /start command again',
                '',
                'If you see "Bot not found":',
                '• Check the bot username in Bot Control',
                '• Make sure the bot token is correct',
              ],
            ),

            const SizedBox(height: 16),

            // Technical Details
            _buildInstructionCard(
              'Technical Details',
              Icons.info_outline,
              Colors.grey,
              [
                'Webhook URL:',
                'https://us-central1-cuddlecare2-dd913.cloudfunctions.net/telegramWebhookSimple',
                '',
                'This webhook is hosted on Firebase Functions and processes all incoming messages from Telegram.',
              ],
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(
                        text: 'https://us-central1-cuddlecare2-dd913.cloudfunctions.net/telegramWebhookSimple'
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Webhook URL copied to clipboard'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Webhook URL'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check),
                    label: const Text('Done'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionCard(
    String title,
    IconData icon,
    Color color,
    List<String> instructions,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...instructions.map((instruction) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                instruction,
                style: TextStyle(
                  fontSize: 14,
                  color: instruction.startsWith('•') || instruction.startsWith('   ') 
                    ? Colors.grey.shade600 
                    : Colors.black87,
                  fontFamily: instruction.contains('http') || instruction.contains('/') 
                    ? 'monospace' 
                    : null,
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
