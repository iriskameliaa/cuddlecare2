# CuddleCare2

CuddleCare2 is a Flutter-based application designed to streamline pet care services, including bookings, reminders, and communication with pet sitters.

## Features

- **User-Friendly Interface**: Easy navigation for users and pet sitters.
- **Booking Management**: View, create, and manage pet care bookings.
- **Smart Reminders**: Automated reminders for upcoming bookings.
- **Telegram Bot Integration**: Seamless communication via Telegram.
- **Admin Dashboard**: Tools for managing services, users, and bookings.

## Getting Started

### Prerequisites

- Flutter SDK: [Install Flutter](https://docs.flutter.dev/get-started/install)
- Dart: Included with Flutter installation.
- Firebase Account: Required for backend services.

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/your-username/cuddlecare2.git
   cd cuddlecare2
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) files to the respective directories.

4. Run the app:

   ```bash
   flutter run
   ```

## API Key Configuration

This project requires API keys to function correctly. To ensure security, the actual API keys have been replaced with placeholders like `"YOUR_API_KEY"` in the code.

### Steps to Set Up API Keys

1. **Environment Variables**:
   - Set the required API keys as environment variables on your system.
   - Example for Dart:
     ```dart
     String apiKey = Platform.environment['API_KEY'] ?? 'YOUR_API_KEY';
     ```

2. **Configuration File**:
   - Create a file (e.g., `.env`) to store your API keys.
   - Use a library like `dotenv` to load the keys into your application.

3. **Update the Code**:
   - Replace `"YOUR_API_KEY"` in the code with the actual key or fetch it dynamically from the environment or configuration file.

### Important Notes

- Do not hardcode sensitive keys directly in the code.
- Ensure `.env` and other sensitive files are added to `.gitignore`.

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a new branch:

   ```bash
   git checkout -b feature-name
   ```

3. Commit your changes:

   ```bash
   git commit -m "Add feature-name"
   ```

4. Push to your branch:

   ```bash
   git push origin feature-name
   ```

5. Open a pull request.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

## Acknowledgments

- [Flutter](https://flutter.dev/)
- [Firebase](https://firebase.google.com/)
- [Telegram Bot API](https://core.telegram.org/bots/api)
