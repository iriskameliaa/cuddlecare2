# Rating Functionality Testing Guide

## Overview

This guide explains how to test the provider rating functionality in the CuddleCare mockup app. Since this is a mockup, you need to manually simulate the booking completion process to test the rating system.

## How Rating Works

### Normal Flow (Real App)
1. User books a service with a provider
2. Provider accepts the booking
3. Provider completes the service
4. User receives notification to rate the provider
5. User can rate the provider (1-5 stars + comments)
6. Rating is saved and displayed on provider profile

### Mockup Testing Flow
1. Create a booking (pending status)
2. Provider accepts booking (confirmed status)
3. **Manually mark booking as completed** (for testing)
4. User can now rate the provider
5. Test the rating interface and functionality

## Testing Methods

### Method 1: Admin Dashboard (Recommended)

1. **Login as Admin**
   - Use admin credentials: `admin@cuddlecare.com` / `admin123456`
   - Navigate to Admin Dashboard

2. **Access Test Screen**
   - In Admin Dashboard, go to "Quick Actions"
   - Click "Test Booking Completion" chip
   - This opens the booking completion test screen

3. **Mark Bookings as Completed**
   - View all pending/confirmed bookings
   - Click "Mark as Completed" for individual bookings
   - Or use "Mark All Completed" to complete all at once
   - Success message confirms completion

4. **Test Rating**
   - Switch to user account
   - Go to "View Bookings" screen
   - Find completed bookings
   - Click "Rate Provider" button
   - Test the rating interface

### Method 2: Provider Dashboard

1. **Login as Provider**
   - Use any provider account
   - Navigate to Provider Home Screen

2. **Complete Bookings**
   - View confirmed bookings
   - Click "Mark as Completed" button
   - Booking status changes to completed

3. **Test Rating**
   - Switch to user account
   - Follow steps from Method 1, step 4

### Method 3: Direct Database Update

1. **Access Firestore Console**
   - Go to Firebase Console
   - Navigate to Firestore Database
   - Find the `bookings` collection

2. **Update Booking Status**
   - Find a booking document
   - Change `status` field to `"completed"`
   - Add `reviewed: false` field
   - Save the document

3. **Test Rating**
   - Follow steps from Method 1, step 4

## Rating Interface Features

### Star Rating System
- 1-5 star selection
- Visual feedback with filled/empty stars
- Rating text display (e.g., "3 stars")

### Quick Rating Options
- Excellent (5 stars)
- Great (4 stars)
- Good (3 stars)
- Fair (2 stars)
- Poor (1 star)

### Comment Section
- Optional text field
- Multi-line input
- Character limit (if implemented)

### Review Submission
- Validation (rating required)
- Loading state during submission
- Success/error feedback
- Booking marked as reviewed

## Testing Scenarios

### Scenario 1: Basic Rating
1. Mark a booking as completed
2. Rate provider with 5 stars
3. Add a positive comment
4. Submit review
5. Verify rating appears on provider profile

### Scenario 2: Different Ratings
1. Test all rating levels (1-5 stars)
2. Test with and without comments
3. Verify average rating calculation

### Scenario 3: Multiple Reviews
1. Complete multiple bookings with same provider
2. Rate each booking differently
3. Verify average rating updates correctly
4. Check review count increases

### Scenario 4: Edge Cases
1. Try submitting without rating (should show error)
2. Test with very long comments
3. Test network error scenarios
4. Verify reviewed bookings don't show rating button

## Expected Results

### After Marking Booking as Completed
- Booking status: `"completed"`
- `reviewed` field: `false`
- "Rate Provider" button appears in user's booking list

### After Submitting Review
- Booking `reviewed` field: `true`
- `reviewedAt` timestamp added
- Review saved to `reviews` collection
- Provider's average rating updated
- Provider's review count incremented
- "Rate Provider" button disappears
- "Reviewed" status shown instead

### Provider Profile Updates
- Average rating displayed with stars
- Review count shown
- Individual reviews accessible via "View Reviews"
- Trust score recalculated (if implemented)

## Troubleshooting

### No "Rate Provider" Button
- Check booking status is "completed"
- Verify `reviewed` field is `false`
- Ensure you're logged in as the booking user

### Rating Not Saving
- Check Firebase permissions
- Verify network connection
- Check console for error messages

### Provider Rating Not Updating
- Verify review was saved to `reviews` collection
- Check provider document in both `users` and `providers` collections
- Ensure average rating calculation is working

### Admin Test Screen Not Working
- Verify admin login credentials
- Check Firebase configuration
- Ensure proper imports in admin dashboard

## Files Involved

### Core Rating Files
- `lib/screens/rate_provider_screen.dart` - Rating interface
- `lib/services/review_service.dart` - Review data management
- `lib/models/review.dart` - Review data model

### Testing Files
- `lib/scripts/mark_booking_completed.dart` - Booking completion utilities
- `lib/screens/test_booking_completion_screen.dart` - Admin test interface

### Related Files
- `lib/screens/view_bookings_screen.dart` - User booking management
- `lib/screens/pet_sitter_home_screen.dart` - Provider booking management
- `lib/screens/provider_reviews_screen.dart` - Review display
- `lib/screens/admin_dashboard.dart` - Admin access to test tools

## Quick Test Checklist

- [ ] Create a booking as user
- [ ] Accept booking as provider
- [ ] Mark booking as completed (admin or provider)
- [ ] Switch to user account
- [ ] Navigate to View Bookings
- [ ] Verify "Rate Provider" button appears
- [ ] Click "Rate Provider" button
- [ ] Test star rating selection
- [ ] Add optional comment
- [ ] Submit review
- [ ] Verify success message
- [ ] Check provider profile for updated rating
- [ ] Verify "Rate Provider" button is gone
- [ ] Check "Reviewed" status appears

This testing approach allows you to fully test the rating functionality in your mockup app without waiting for actual service completion. 