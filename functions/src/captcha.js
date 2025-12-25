/**
 * CAPTCHA Verification Cloud Functions
 * Verifies Google reCAPTCHA v3 tokens server-side
 */

const axios = require('axios');

// reCAPTCHA configuration
const RECAPTCHA_SECRET_KEY = process.env.RECAPTCHA_SECRET_KEY || '';
const RECAPTCHA_VERIFY_URL = 'https://www.google.com/recaptcha/api/siteverify';
const SCORE_THRESHOLD = 0.5;
const ENABLED = true; // Kill switch

/**
 * Verify a reCAPTCHA token
 * @param {string} token - reCAPTCHA token from client
 * @param {string} remoteip - User's IP address (optional)
 * @returns {Promise<Object>} Verification result
 */
async function verifyRecaptchaToken(token, remoteip = null) {
  if (!ENABLED) {
    console.log('CAPTCHA verification disabled');
    return {
      success: true,
      score: 1.0,
      action: 'signup',
    };
  }

  if (!RECAPTCHA_SECRET_KEY) {
    console.error('RECAPTCHA_SECRET_KEY not configured');
    // Fail open - don't block users if not configured
    return {
      success: true,
      score: 0.5,
      action: 'unknown',
    };
  }

  try {
    const params = new URLSearchParams({
      secret: RECAPTCHA_SECRET_KEY,
      response: token,
    });

    if (remoteip) {
      params.append('remoteip', remoteip);
    }

    const response = await axios.post(RECAPTCHA_VERIFY_URL, params, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      timeout: 5000, // 5 second timeout
    });

    const result = response.data;

    console.log('reCAPTCHA verification result:', {
      success: result.success,
      score: result.score,
      action: result.action,
      challengeTs: result.challenge_ts,
      hostname: result.hostname,
    });

    return {
      success: result.success,
      score: result.score || 0.0,
      action: result.action || 'unknown',
      challenge_ts: result.challenge_ts,
      hostname: result.hostname,
      'error-codes': result['error-codes'] || [],
    };
  } catch (error) {
    console.error('reCAPTCHA verification error:', error.message);
    // Fail open - don't block users if verification service fails
    return {
      success: true,
      score: 0.5,
      action: 'unknown',
      'error-codes': ['network-error'],
    };
  }
}

/**
 * Check if a verification result passes the threshold
 * @param {Object} result - Verification result
 * @param {number} threshold - Minimum score (default 0.5)
 * @returns {boolean} True if passes
 */
function passesThreshold(result, threshold = SCORE_THRESHOLD) {
  return result.success && result.score >= threshold;
}

/**
 * Verify signup CAPTCHA
 * Higher threshold for signups to prevent bot accounts
 */
async function verifySignupCaptcha(token, remoteip = null) {
  const result = await verifyRecaptchaToken(token, remoteip);

  // Stricter threshold for signup (0.7)
  const passes = passesThreshold(result, 0.7);

  if (!passes) {
    console.warn('Signup CAPTCHA failed:', {
      score: result.score,
      action: result.action,
      errors: result['error-codes'],
    });
  }

  return {
    ...result,
    passes,
    threshold: 0.7,
  };
}

/**
 * Verify login CAPTCHA
 * Lower threshold for login (0.3) - only block obvious bots
 */
async function verifyLoginCaptcha(token, remoteip = null) {
  const result = await verifyRecaptchaToken(token, remoteip);

  // Lenient threshold for login (0.3)
  const passes = passesThreshold(result, 0.3);

  if (!passes) {
    console.warn('Login CAPTCHA failed:', {
      score: result.score,
      action: result.action,
      errors: result['error-codes'],
    });
  }

  return {
    ...result,
    passes,
    threshold: 0.3,
  };
}

/**
 * Verify message send CAPTCHA
 * Moderate threshold (0.5)
 */
async function verifyMessageCaptcha(token, remoteip = null) {
  const result = await verifyRecaptchaToken(token, remoteip);

  const passes = passesThreshold(result, 0.5);

  if (!passes) {
    console.warn('Message CAPTCHA failed:', {
      score: result.score,
      action: result.action,
      errors: result['error-codes'],
    });
  }

  return {
    ...result,
    passes,
    threshold: 0.5,
  };
}

/**
 * Callable function to verify reCAPTCHA from client
 */
async function verifyRecaptchaCallable(data, context) {
  // Check authentication for sensitive operations
  if (!context.auth && data.action !== 'signup') {
    throw new Error('UNAUTHENTICATED');
  }

  const {token, action} = data;

  if (!token) {
    throw new Error('CAPTCHA token is required');
  }

  // Get remote IP if available
  const remoteip = context.rawRequest?.ip || null;

  let result;
  switch (action) {
    case 'signup':
      result = await verifySignupCaptcha(token, remoteip);
      break;
    case 'login':
      result = await verifyLoginCaptcha(token, remoteip);
      break;
    case 'send_message':
      result = await verifyMessageCaptcha(token, remoteip);
      break;
    default:
      result = await verifyRecaptchaToken(token, remoteip);
      result.passes = passesThreshold(result);
      result.threshold = SCORE_THRESHOLD;
  }

  return result;
}

module.exports = {
  verifyRecaptchaToken,
  verifySignupCaptcha,
  verifyLoginCaptcha,
  verifyMessageCaptcha,
  verifyRecaptchaCallable,
  passesThreshold,
};
