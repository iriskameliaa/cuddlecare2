// Simple script to create sample data directly via Firebase REST API
const https = require('https');

const projectId = 'cuddlecare2-dd913';
const baseUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents`;

// Sample verification data
const verificationData = {
  'provider_001': {
    fields: {
      providerId: { stringValue: 'provider_001' },
      status: { stringValue: 'pending' },
      backgroundCheckStatus: { stringValue: 'notStarted' },
      verifiedCertificates: { arrayValue: { values: [] } },
      pendingCertificates: { 
        arrayValue: { 
          values: [
            { stringValue: 'cert_001.pdf' },
            { stringValue: 'cert_002.pdf' }
          ] 
        } 
      },
      trustScore: { doubleValue: 0.0 },
      verificationData: {
        mapValue: {
          fields: {
            name: { stringValue: 'Sarah Johnson' },
            email: { stringValue: 'sarah.johnson@example.com' },
            phone: { stringValue: '+1234567890' },
            experience: { stringValue: 'intermediate' }
          }
        }
      },
      createdAt: { stringValue: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString() },
      updatedAt: { stringValue: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString() }
    }
  },
  'provider_002': {
    fields: {
      providerId: { stringValue: 'provider_002' },
      status: { stringValue: 'verified' },
      backgroundCheckStatus: { stringValue: 'passed' },
      verifiedCertificates: { 
        arrayValue: { 
          values: [
            { stringValue: 'cert_003.pdf' },
            { stringValue: 'cert_004.pdf' }
          ] 
        } 
      },
      pendingCertificates: { arrayValue: { values: [] } },
      trustScore: { doubleValue: 85.5 },
      verifiedAt: { stringValue: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString() },
      verifiedBy: { stringValue: 'admin' },
      verificationData: {
        mapValue: {
          fields: {
            name: { stringValue: 'Michael Chen' },
            email: { stringValue: 'michael.chen@example.com' },
            phone: { stringValue: '+1234567891' },
            experience: { stringValue: 'expert' }
          }
        }
      },
      createdAt: { stringValue: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString() },
      updatedAt: { stringValue: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString() }
    }
  }
};

// Provider data
const providerData = {
  'provider_001': {
    fields: {
      providerId: { stringValue: 'provider_001' },
      name: { stringValue: 'Sarah Johnson' },
      email: { stringValue: 'sarah.johnson@example.com' },
      phone: { stringValue: '+1234567890' },
      experience: { stringValue: 'intermediate' },
      rating: { doubleValue: 4.2 },
      completedBookings: { integerValue: '15' },
      trustScore: { doubleValue: 0.0 },
      verificationStatus: { stringValue: 'pending' },
      trustLevel: { stringValue: 'New Provider' }
    }
  },
  'provider_002': {
    fields: {
      providerId: { stringValue: 'provider_002' },
      name: { stringValue: 'Michael Chen' },
      email: { stringValue: 'michael.chen@example.com' },
      phone: { stringValue: '+1234567891' },
      experience: { stringValue: 'expert' },
      rating: { doubleValue: 4.8 },
      completedBookings: { integerValue: '45' },
      trustScore: { doubleValue: 85.5 },
      verificationStatus: { stringValue: 'verified' },
      trustLevel: { stringValue: 'Highly Trusted' }
    }
  }
};

async function createDocument(collection, docId, data) {
  return new Promise((resolve, reject) => {
    const url = `${baseUrl}/${collection}?documentId=${docId}`;
    const postData = JSON.stringify(data);
    
    const options = {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };
    
    const req = https.request(url, options, (res) => {
      let responseData = '';
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          console.log(`✅ Created ${collection}/${docId}`);
          resolve(responseData);
        } else {
          console.error(`❌ Failed to create ${collection}/${docId}: ${res.statusCode}`);
          console.error(responseData);
          reject(new Error(`HTTP ${res.statusCode}: ${responseData}`));
        }
      });
    });
    
    req.on('error', (error) => {
      console.error(`❌ Request error for ${collection}/${docId}:`, error);
      reject(error);
    });
    
    req.write(postData);
    req.end();
  });
}

async function createAllData() {
  try {
    console.log('🚀 Creating sample verification data...');
    
    // Create verification documents
    for (const [docId, data] of Object.entries(verificationData)) {
      await createDocument('provider_verifications', docId, data);
    }
    
    // Create provider documents
    for (const [docId, data] of Object.entries(providerData)) {
      await createDocument('providers', docId, data);
    }
    
    console.log('✅ All sample data created successfully!');
    
  } catch (error) {
    console.error('❌ Error creating sample data:', error);
  }
}

createAllData();
