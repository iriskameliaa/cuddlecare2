# CuddleCare Onboarding Illustrations

This folder contains illustrations for the CuddleCare app's onboarding screens.

## Current Implementation

The app currently uses **custom Flutter-drawn illustrations** that match the app's orange and white color scheme. These are defined in `lib/widgets/onboarding_illustrations.dart`.

## Free Illustration Alternatives

If you'd like to use professional vector illustrations instead, here are some free options:

### Screen 1: Welcome to CuddleCare
**Pet owner with cat and dog in park**

**Option 1: Storyset (Free)**
- URL: https://storyset.com/illustration/pet-care/amico
- Style: Flat vector, customizable colors
- License: Free for commercial use
- Download as SVG and place in this folder as `welcome.svg`

**Option 2: unDraw (Free)**
- URL: https://undraw.co/illustrations/pet-care
- Style: Clean, modern vector
- License: MIT License
- Download as SVG and place in this folder as `welcome.svg`

### Screen 2: Choose a Service
**Pet service icons (grooming, sitting, training)**

**Option 1: Storyset (Free)**
- URL: https://storyset.com/illustration/pet-services/amico
- Style: Flat vector, service-focused
- License: Free for commercial use
- Download as SVG and place in this folder as `services.svg`

**Option 2: IconScout (Free)**
- Search for "pet services" or "veterinary services"
- Style: Various styles available
- License: Check individual license
- Download as SVG and place in this folder as `services.svg`

### Screen 3: Book Appointments
**Calendar and booking illustration**

**Option 1: Storyset (Free)**
- URL: https://storyset.com/illustration/calendar/amico
- Style: Flat vector, calendar-focused
- License: Free for commercial use
- Download as SVG and place in this folder as `booking.svg`

**Option 2: unDraw (Free)**
- URL: https://undraw.co/illustrations/calendar
- Style: Clean, modern vector
- License: MIT License
- Download as SVG and place in this folder as `booking.svg`

## How to Use External Illustrations

1. **Download the SVG files** from the provided links
2. **Place them in this folder** with the following names:
   - `welcome.svg`
   - `services.svg`
   - `booking.svg`

3. **Add flutter_svg dependency** to `pubspec.yaml`:
```yaml
dependencies:
  flutter_svg: ^2.0.9
```

4. **Update the welcome screen** to use SVG images:
```dart
import 'package:flutter_svg/flutter_svg.dart';

// Replace the custom illustration with:
SvgPicture.asset(
  'assets/images/onboarding/welcome.svg',
  width: 200,
  height: 200,
  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
)
```

## Color Customization

Most of these illustrations allow you to customize colors. For CuddleCare, use:
- **Primary**: Orange (#FFA500)
- **Secondary**: Green (#4CAF50)
- **Background**: White (#FFFFFF)

## Current Custom Illustrations

The current custom illustrations include:
- **Welcome**: Person sitting with cat and dog in a park setting
- **Services**: Five service icons arranged in a circle (grooming, sitting, training, walking, vet)
- **Booking**: Calendar with highlighted date and person with phone

These illustrations are:
- ✅ **Perfectly matched** to your app's color scheme
- ✅ **No external dependencies** required
- ✅ **Fully customizable** and scalable
- ✅ **Optimized for performance**

## Recommendation

The current custom illustrations are well-designed and perfectly match your app's aesthetic. However, if you prefer more professional vector illustrations, the Storyset options would be the best choice as they offer:
- High-quality vector graphics
- Consistent style across all illustrations
- Easy color customization
- Free commercial license 