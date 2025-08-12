import 'package:flutter/material.dart';
import 'package:cuddlecare2/services/bot_config_service.dart';
import 'package:cuddlecare2/services/telegram_polling_service.dart';
import 'package:cuddlecare2/services/webhook_setup_service.dart';
import 'bot_diagnostics_screen.dart';
import 'webhook_instructions_screen.dart';

class BotControlScreen extends StatefulWidget {
  const BotControlScreen({super.key});

  @override
  State<BotControlScreen> createState() => _BotControlScreenState();
}

class _BotControlScreenState extends State<BotControlScreen> {
  bool _isBotRunning = false;
  bool _isLoading = false;
  String _botStatus = 'Unknown';
  String _lastMessage = '';

  @override
  void initState() {
    super.initState();
    _checkBotStatus();
  }

  Future<void> _checkBotStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final botInfo = await BotConfigService.getBotInfo();
      if (botInfo != null) {
        setState(() {
          _isBotRunning = true;
          _botStatus = 'Connected to @${botInfo['username']}';
        });
      } else {
        setState(() {
          _isBotRunning = false;
          _botStatus = 'Not connected';
        });
      }
    } catch (e) {
      setState(() {
        _isBotRunning = false;
        _botStatus = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startBot() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await TelegramPollingService.startPolling();
      setState(() {
        _isBotRunning = true;
        _botStatus = 'Bot is running and listening for commands';
        _lastMessage = 'Bot started successfully!';
      });
    } catch (e) {
      setState(() {
        _botStatus = 'Error starting bot: $e';
        _lastMessage = 'Failed to start bot';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _stopBot() async {
    setState(() {
      _isLoading = true;
    });

    try {
      TelegramPollingService.stopPolling();
      setState(() {
        _isBotRunning = false;
        _botStatus = 'Bot stopped';
        _lastMessage = 'Bot stopped successfully!';
      });
    } catch (e) {
      setState(() {
        _botStatus = 'Error stopping bot: $e';
        _lastMessage = 'Failed to stop bot';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendTestMessage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // You can replace this with your actual chat ID
      const testChatId = '123456789'; // Replace with your chat ID
      final success = await BotConfigService.sendTestMessage(testChatId);

      if (success) {
        setState(() {
          _lastMessage = 'Test message sent successfully!';
        });
      } else {
        setState(() {
          _lastMessage = 'Failed to send test message';
        });
      }
    } catch (e) {
      setState(() {
        _lastMessage = 'Error sending test message: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _setupWebhook() async {
    setState(() {
      _isLoading = true;
      _lastMessage = 'Setting up webhook...';
    });

    try {
      final result = await WebhookSetupService.completeWebhookSetup();

      if (result['success']) {
        setState(() {
          _lastMessage =
              'Webhook setup completed! Bot should now respond to /start commands.';
          _isBotRunning = true;
          _botStatus = 'Webhook active - Bot ready';
        });

        // Show instructions screen
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WebhookInstructionsScreen(),
            ),
          );
        }
      } else {
        setState(() {
          _lastMessage = 'Webhook setup failed: ${result['error']}';
        });
      }
    } catch (e) {
      setState(() {
        _lastMessage = 'Error setting up webhook: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bot Control'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bot Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isBotRunning ? Icons.check_circle : Icons.error,
                          color: _isBotRunning ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Bot Status',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _botStatus,
                      style: TextStyle(
                        color: _isBotRunning ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Control Buttons
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton.icon(
                onPressed: _isBotRunning ? null : _startBot,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Bot'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isBotRunning ? _stopBot : null,
                icon: const Icon(Icons.stop),
                label: const Text('Stop Bot'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isBotRunning ? _sendTestMessage : null,
                icon: const Icon(Icons.send),
                label: const Text('Send Test Message'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _setupWebhook,
                icon: const Icon(Icons.webhook),
                label: const Text('Setup Webhook'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BotDiagnosticsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.bug_report),
                label: const Text('Bot Diagnostics'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Last Message
            if (_lastMessage.isNotEmpty)
              Card(
                color: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Action:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(_lastMessage),
                    ],
                  ),
                ),
              ),

            const Spacer(),

            // Instructions
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to Test:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text('1. Start the bot using the button above'),
                    const Text(
                        '2. Open Telegram and find @CuddleCare_app1_bot'),
                    const Text('3. Send /start to test the bot'),
                    const Text(
                        '4. Use /link your-email@example.com to link your account'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
