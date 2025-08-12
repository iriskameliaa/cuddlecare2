const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('./cuddlecare2-dd913-firebase-adminsdk-ixqhj-b8b8b8b8b8.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function createSampleData() {
  try {
    console.log('Creating sample provider verification data...');

    // Sample provider verification data
    const sampleVerifications = [
      {
        providerId: 'provider_001',
        status: 'pending',
        backgroundCheckStatus: 'notStarted',
        verifiedCertificates: [],
        pendingCertificates: ['cert_001.pdf', 'cert_002.pdf'],
        trustScore: 0.0,
        verificationData: {
          name: 'Sarah Johnson',
          email: 'sarah.johnson@example.com',
          phone: '+1234567890',
          experience: 'intermediate',
        },
        createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
        updatedAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
      },
      {
        providerId: 'provider_002',
        status: 'verified',
        backgroundCheckStatus: 'passed',
        verifiedCertificates: ['cert_003.pdf', 'cert_004.pdf'],
        pendingCertificates: [],
        trustScore: 85.5,
        verifiedAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
        verifiedBy: 'admin',
        verificationData: {
          name: 'Michael Chen',
          email: 'michael.chen@example.com',
          phone: '+1234567891',
          experience: 'expert',
        },
        createdAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString(),
        updatedAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
      },
      {
        providerId: 'provider_003',
        status: 'pending',
        backgroundCheckStatus: 'inProgress',
        verifiedCertificates: [],
        pendingCertificates: ['cert_005.pdf'],
        trustScore: 0.0,
        verificationData: {
          name: 'Emily Rodriguez',
          email: 'emily.rodriguez@example.com',
          phone: '+1234567892',
          experience: 'beginner',
        },
        createdAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
        updatedAt: new Date(Date.now() - 6 * 60 * 60 * 1000).toISOString(),
      },
      {
        providerId: 'provider_004',
        status: 'verified',
        backgroundCheckStatus: 'passed',
        verifiedCertificates: ['cert_006.pdf', 'cert_007.pdf', 'cert_008.pdf'],
        pendingCertificates: [],
        trustScore: 92.3,
        verifiedAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
        verifiedBy: 'admin',
        verificationData: {
          name: 'David Thompson',
          email: 'david.thompson@example.com',
          phone: '+1234567893',
          experience: 'expert',
        },
        createdAt: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000).toISOString(),
        updatedAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
      },
      {
        providerId: 'provider_005',
        status: 'rejected',
        backgroundCheckStatus: 'failed',
        verifiedCertificates: [],
        pendingCertificates: [],
        trustScore: 0.0,
        rejectionReason: 'Failed background check - criminal record found',
        verificationData: {
          name: 'John Smith',
          email: 'john.smith@example.com',
          phone: '+1234567894',
          experience: 'intermediate',
        },
        createdAt: new Date(Date.now() - 8 * 24 * 60 * 60 * 1000).toISOString(),
        updatedAt: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000).toISOString(),
      },
    ];

    // Create verification documents
    for (const verification of sampleVerifications) {
      await db.collection('provider_verifications').doc(verification.providerId).set(verification);
      console.log(`Created verification for ${verification.providerId}`);
    }

    // Sample provider data
    const sampleProviders = [
      {
        providerId: 'provider_001',
        name: 'Sarah Johnson',
        email: 'sarah.johnson@example.com',
        phone: '+1234567890',
        experience: 'intermediate',
        rating: 4.2,
        completedBookings: 15,
        trustScore: 0.0,
        verificationStatus: 'pending',
        trustLevel: 'New Provider',
      },
      {
        providerId: 'provider_002',
        name: 'Michael Chen',
        email: 'michael.chen@example.com',
        phone: '+1234567891',
        experience: 'expert',
        rating: 4.8,
        completedBookings: 45,
        trustScore: 85.5,
        verificationStatus: 'verified',
        trustLevel: 'Highly Trusted',
      },
      {
        providerId: 'provider_003',
        name: 'Emily Rodriguez',
        email: 'emily.rodriguez@example.com',
        phone: '+1234567892',
        experience: 'beginner',
        rating: 4.0,
        completedBookings: 8,
        trustScore: 0.0,
        verificationStatus: 'pending',
        trustLevel: 'New Provider',
      },
      {
        providerId: 'provider_004',
        name: 'David Thompson',
        email: 'david.thompson@example.com',
        phone: '+1234567893',
        experience: 'expert',
        rating: 4.9,
        completedBookings: 67,
        trustScore: 92.3,
        verificationStatus: 'verified',
        trustLevel: 'Premium Trusted',
      },
      {
        providerId: 'provider_005',
        name: 'John Smith',
        email: 'john.smith@example.com',
        phone: '+1234567894',
        experience: 'intermediate',
        rating: 3.5,
        completedBookings: 12,
        trustScore: 0.0,
        verificationStatus: 'rejected',
        trustLevel: 'New Provider',
      },
    ];

    // Create provider documents
    for (const provider of sampleProviders) {
      await db.collection('providers').doc(provider.providerId).set(provider);
      console.log(`Created provider ${provider.providerId}`);
    }

    console.log('✅ Sample data created successfully!');
    console.log('📊 Created 5 provider verifications and 5 provider profiles');
    
  } catch (error) {
    console.error('❌ Error creating sample data:', error);
  } finally {
    process.exit(0);
  }
}

createSampleData();
