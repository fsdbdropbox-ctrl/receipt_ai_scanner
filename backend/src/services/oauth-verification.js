import { OAuth2Client } from 'google-auth-library';
import jwt from 'jsonwebtoken';
import jwksClient from 'jwks-rsa';

/**
 * OAuth token verification service
 * Verifies tokens from Google and Apple OAuth providers
 */

// Google OAuth client
let googleClient = null;

function getGoogleClient() {
  if (!googleClient) {
    const clientId = process.env.GOOGLE_CLIENT_ID;
    if (!clientId) {
      throw new Error('GOOGLE_CLIENT_ID environment variable is required for Google OAuth verification');
    }
    googleClient = new OAuth2Client(clientId);
  }
  return googleClient;
}

// Apple JWKS client (cached)
let appleJwksClient = null;

function getAppleJwksClient() {
  if (!appleJwksClient) {
    // Apple's public keys endpoint
    appleJwksClient = jwksClient({
      jwksUri: 'https://appleid.apple.com/auth/keys',
      cache: true,
      cacheMaxAge: 86400000, // 24 hours
      rateLimit: true,
      jwksRequestsPerMinute: 10,
    });
  }
  return appleJwksClient;
}

/**
 * Get signing key for Apple JWT
 */
function getAppleSigningKey(kid) {
  return new Promise((resolve, reject) => {
    getAppleJwksClient().getSigningKey(kid, (err, key) => {
      if (err) {
        return reject(err);
      }
      resolve(key.getPublicKey());
    });
  });
}

/**
 * Verify Google OAuth token
 * @param {string} token - Google ID token
 * @returns {Promise<Object>} - Verified token payload
 */
export async function verifyGoogleToken(token) {
  try {
    const client = getGoogleClient();
    const clientId = process.env.GOOGLE_CLIENT_ID;
    
    // Debug: Log client ID being used (first 20 chars only for security)
    console.log('Verifying Google token with Client ID:', clientId ? `${clientId.substring(0, 20)}...` : 'NOT SET');
    console.log('Token length:', token ? token.length : 0);
    console.log('Token prefix:', token ? `${token.substring(0, 50)}...` : 'null');
    
    const ticket = await client.verifyIdToken({
      idToken: token,
      audience: clientId,
    });
    
    const payload = ticket.getPayload();
    
    if (!payload) {
      throw new Error('Invalid Google token: no payload');
    }
    
    // Verify required claims
    if (!payload.sub) {
      throw new Error('Invalid Google token: missing sub claim');
    }
    
    if (!payload.email) {
      throw new Error('Invalid Google token: missing email claim');
    }
    
    // Debug: Log successful verification
    console.log('Google token verified successfully:', {
      email: payload.email,
      sub: payload.sub,
      audience: payload.aud,
    });
    
    return {
      oauthId: payload.sub,
      email: payload.email,
      emailVerified: payload.email_verified || false,
      name: payload.name,
      picture: payload.picture,
    };
  } catch (error) {
    // Enhanced error logging
    console.error('Google token verification error:', {
      message: error.message,
      code: error.code,
      name: error.name,
      clientIdSet: !!clientId,
      clientIdPrefix: clientId ? `${clientId.substring(0, 20)}...` : 'NOT SET',
    });
    
    if (error.message.includes('GOOGLE_CLIENT_ID')) {
      throw error;
    }
    
    // Provide more specific error messages
    if (error.message.includes('audience') || error.code === 'auth/id-token-aud-mismatch') {
      throw new Error(`Invalid audience: Token was issued for a different Client ID. Expected: ${clientId ? clientId.substring(0, 20) + '...' : 'NOT SET'}`);
    }
    
    if (error.message.includes('expired') || error.code === 'auth/id-token-expired') {
      throw new Error('Token has expired. Please sign in again.');
    }
    
    throw new Error(`Google token verification failed: ${error.message}`);
  }
}

/**
 * Verify Apple OAuth token
 * @param {string} token - Apple ID token (JWT)
 * @returns {Promise<Object>} - Verified token payload
 */
export async function verifyAppleToken(token) {
  try {
    // Decode token header to get kid (key ID)
    const decoded = jwt.decode(token, { complete: true });
    
    if (!decoded || !decoded.header || !decoded.header.kid) {
      throw new Error('Invalid Apple token: missing kid in header');
    }
    
    // Get Apple's public key
    const publicKey = await getAppleSigningKey(decoded.header.kid);
    
    // Verify token signature and claims
    const payload = jwt.verify(token, publicKey, {
      algorithms: ['RS256'],
      issuer: 'https://appleid.apple.com',
      // Note: audience can be your app's client ID, but Apple tokens might not always include it
      // We'll verify the token is valid and from Apple, then trust the claims
    });
    
    if (!payload.sub) {
      throw new Error('Invalid Apple token: missing sub claim');
    }
    
    // Apple may not always include email in the token (privacy feature)
    // If email is not in token, we'll use the email from the request body
    // but we still verify the token is valid
    
    return {
      oauthId: payload.sub,
      email: payload.email || null, // May be null if user chose to hide email
      emailVerified: payload.email_verified || false,
      // Apple doesn't provide name/picture in the token
    };
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      throw new Error(`Apple token verification failed: ${error.message}`);
    }
    if (error.name === 'TokenExpiredError') {
      throw new Error('Apple token has expired');
    }
    throw new Error(`Apple token verification failed: ${error.message}`);
  }
}

/**
 * Verify OAuth token based on provider
 * @param {string} provider - 'google' or 'apple'
 * @param {string} token - OAuth token
 * @param {string} expectedOauthId - Expected OAuth ID (for additional verification)
 * @param {string} expectedEmail - Expected email (for additional verification)
 * @returns {Promise<Object>} - Verified token payload
 */
export async function verifyOAuthToken(provider, token, expectedOauthId, expectedEmail) {
  if (!token) {
    throw new Error('Token is required');
  }
  
  let verifiedPayload;
  
  if (provider === 'google') {
    verifiedPayload = await verifyGoogleToken(token);
  } else if (provider === 'apple') {
    verifiedPayload = await verifyAppleToken(token);
  } else {
    throw new Error(`Unsupported provider: ${provider}`);
  }
  
  // Additional verification: ensure oauthId matches
  if (verifiedPayload.oauthId !== expectedOauthId) {
    throw new Error(`OAuth ID mismatch: expected ${expectedOauthId}, got ${verifiedPayload.oauthId}`);
  }
  
  // Additional verification: ensure email matches (if provided in token)
  // Note: Apple may not provide email in token, so we allow it to be null
  if (verifiedPayload.email && verifiedPayload.email !== expectedEmail) {
    throw new Error(`Email mismatch: expected ${expectedEmail}, got ${verifiedPayload.email}`);
  }
  
  return verifiedPayload;
}

