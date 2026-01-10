/**
 * VibeScaler API - Cloudflare Workers Backend
 *
 * Handles:
 * - Apple Sign-In authentication
 * - Credit management
 * - Fal.ai API proxy
 * - Purchase verification
 */

import { createClient } from '@supabase/supabase-js';

interface Env {
  FAL_API_KEY: string;
  SUPABASE_URL: string;
  SUPABASE_ANON_KEY: string;
  APPLE_TEAM_ID: string;
  ENVIRONMENT: string;
}

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    const url = new URL(request.url);
    const path = url.pathname;

    try {
      // Route requests
      if (path === '/api/auth/apple') {
        return handleAppleAuth(request, env);
      }

      if (path === '/api/user/credits') {
        return handleGetCredits(request, env);
      }

      if (path === '/api/upscale/image') {
        return handleUpscaleImage(request, env);
      }

      if (path.startsWith('/api/upscale/status/')) {
        const jobId = path.split('/').pop();
        return handleGetStatus(jobId!, env);
      }

      if (path === '/api/purchase/verify') {
        return handleVerifyPurchase(request, env);
      }

      if (path === '/api/remove-background') {
        return handleRemoveBackground(request, env);
      }

      // Health check
      if (path === '/health') {
        return json({ status: 'ok', environment: env.ENVIRONMENT });
      }

      return json({ error: 'Not found' }, 404);
    } catch (error) {
      console.error('API Error:', error);
      return json({ error: 'Internal server error' }, 500);
    }
  },
};

// ============================================================
// AUTH HANDLERS
// ============================================================

async function handleAppleAuth(request: Request, env: Env): Promise<Response> {
  const { identityToken, userId, email } = await request.json();

  // TODO: Verify Apple identity token with Apple's servers
  // For now, trust the token (implement proper verification for production)

  const supabase = createClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY);

  // Check if user exists
  const { data: existingUser } = await supabase
    .from('users')
    .select('*')
    .eq('apple_id', userId)
    .single();

  let user;

  if (existingUser) {
    user = existingUser;
  } else {
    // Create new user with initial credits
    const { data: newUser, error } = await supabase
      .from('users')
      .insert({
        apple_id: userId,
        email: email || null,
        image_credits: 5, // Free credits with app
        video_seconds: 30,
        is_pro: false,
      })
      .select()
      .single();

    if (error) {
      return json({ error: 'Failed to create user' }, 500);
    }

    user = newUser;
  }

  // Generate session token (simple JWT-like for demo)
  const sessionToken = btoa(
    JSON.stringify({
      userId: user.id,
      appleId: userId,
      exp: Date.now() + 7 * 24 * 60 * 60 * 1000, // 7 days
    })
  );

  return json({
    sessionToken,
    user: {
      id: user.id,
      email: user.email,
      appleId: user.apple_id,
      imageCredits: user.image_credits,
      videoSeconds: user.video_seconds,
      isPro: user.is_pro,
      createdAt: user.created_at,
    },
  });
}

// ============================================================
// CREDIT HANDLERS
// ============================================================

async function handleGetCredits(request: Request, env: Env): Promise<Response> {
  const userId = await validateAuth(request);
  if (!userId) {
    return json({ error: 'Unauthorized' }, 401);
  }

  const supabase = createClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY);

  const { data: user, error } = await supabase
    .from('users')
    .select('image_credits, video_seconds')
    .eq('id', userId)
    .single();

  if (error || !user) {
    return json({ error: 'User not found' }, 404);
  }

  return json({
    imageCredits: user.image_credits,
    videoSeconds: user.video_seconds,
  });
}

// ============================================================
// UPSCALE HANDLERS
// ============================================================

interface UpscaleRequest {
  image: string; // base64 data URL
  model: string;
  scale: number;
}

async function handleUpscaleImage(request: Request, env: Env): Promise<Response> {
  const userId = await validateAuth(request);
  if (!userId) {
    return json({ error: 'Unauthorized' }, 401);
  }

  const supabase = createClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY);

  // Check credits
  const { data: user } = await supabase
    .from('users')
    .select('image_credits')
    .eq('id', userId)
    .single();

  if (!user || user.image_credits < 1) {
    return json({ error: 'Insufficient credits' }, 402);
  }

  // Deduct credit
  await supabase
    .from('users')
    .update({ image_credits: user.image_credits - 1 })
    .eq('id', userId);

  const body: UpscaleRequest = await request.json();

  try {
    // Call fal.ai
    const falResponse = await fetch('https://queue.fal.run/fal-ai/clarity-upscaler', {
      method: 'POST',
      headers: {
        'Authorization': `Key ${env.FAL_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        image_url: body.image,
        scale: body.scale,
        enable_safety_checker: false,
      }),
    });

    const falResult = await falResponse.json();

    if (!falResponse.ok) {
      // Refund credit on failure
      await supabase
        .from('users')
        .update({ image_credits: user.image_credits })
        .eq('id', userId);

      return json({ error: 'Processing failed', details: falResult }, 500);
    }

    // Log transaction
    await supabase.from('transactions').insert({
      user_id: userId,
      type: 'image_upscale',
      credits_used: 1,
      model: body.model,
    });

    return json({
      jobId: falResult.request_id || 'direct',
      status: falResult.status || 'completed',
      resultUrl: falResult.image?.url || falResult.output?.url,
    });
  } catch (error) {
    // Refund credit on error
    await supabase
      .from('users')
      .update({ image_credits: user.image_credits })
      .eq('id', userId);

    throw error;
  }
}

async function handleGetStatus(jobId: string, env: Env): Promise<Response> {
  // For fal.ai queue jobs, check status
  const statusResponse = await fetch(`https://queue.fal.run/requests/${jobId}/status`, {
    headers: {
      'Authorization': `Key ${env.FAL_API_KEY}`,
    },
  });

  const status = await statusResponse.json();

  return json({
    status: status.status,
    resultUrl: status.response?.image?.url,
    error: status.error,
  });
}

// ============================================================
// BACKGROUND REMOVAL HANDLERS
// ============================================================

interface RemoveBackgroundRequest {
  image: string; // base64 data URL
  model: 'portrait' | 'general' | 'heavy' | 'bria';
}

// Model configurations for background removal
const BG_REMOVAL_MODELS = {
  portrait: {
    endpoint: 'fal-ai/birefnet',
    modelType: 'Portrait',
  },
  general: {
    endpoint: 'fal-ai/birefnet',
    modelType: 'General Use (Light)',
  },
  heavy: {
    endpoint: 'fal-ai/birefnet',
    modelType: 'General Use (Heavy)',
  },
  bria: {
    endpoint: 'fal-ai/bria/background/remove',
    modelType: null,
  },
};

async function handleRemoveBackground(request: Request, env: Env): Promise<Response> {
  const userId = await validateAuth(request);
  if (!userId) {
    return json({ error: 'Unauthorized' }, 401);
  }

  const supabase = createClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY);

  // Check credits
  const { data: user } = await supabase
    .from('users')
    .select('image_credits')
    .eq('id', userId)
    .single();

  if (!user || user.image_credits < 1) {
    return json({ error: 'Insufficient credits' }, 402);
  }

  // Deduct credit
  await supabase
    .from('users')
    .update({ image_credits: user.image_credits - 1 })
    .eq('id', userId);

  const body: RemoveBackgroundRequest = await request.json();
  const modelConfig = BG_REMOVAL_MODELS[body.model] || BG_REMOVAL_MODELS.portrait;

  try {
    // Build request body
    const falBody: Record<string, unknown> = {
      image_url: body.image,
    };

    // Add model type if applicable (BiRefNet)
    if (modelConfig.modelType) {
      falBody.model = modelConfig.modelType;
    }

    // Call fal.ai
    const falResponse = await fetch(`https://queue.fal.run/${modelConfig.endpoint}`, {
      method: 'POST',
      headers: {
        'Authorization': `Key ${env.FAL_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(falBody),
    });

    const falResult = await falResponse.json() as Record<string, unknown>;

    if (!falResponse.ok) {
      // Refund credit on failure
      await supabase
        .from('users')
        .update({ image_credits: user.image_credits })
        .eq('id', userId);

      return json({ error: 'Processing failed', details: falResult }, 500);
    }

    // Log transaction
    await supabase.from('transactions').insert({
      user_id: userId,
      type: 'background_removal',
      credits_used: 1,
      model: body.model,
    });

    // Extract result URL (handle different response structures)
    let resultUrl: string | null = null;
    if (falResult.image && typeof falResult.image === 'object' && 'url' in (falResult.image as object)) {
      resultUrl = (falResult.image as { url: string }).url;
    } else if (falResult.output && typeof falResult.output === 'object' && 'url' in (falResult.output as object)) {
      resultUrl = (falResult.output as { url: string }).url;
    } else if (typeof falResult.output === 'string') {
      resultUrl = falResult.output;
    } else if (typeof falResult.url === 'string') {
      resultUrl = falResult.url;
    }

    return json({
      status: 'completed',
      resultUrl,
    });
  } catch (error) {
    // Refund credit on error
    await supabase
      .from('users')
      .update({ image_credits: user.image_credits })
      .eq('id', userId);

    throw error;
  }
}

// ============================================================
// PURCHASE HANDLERS
// ============================================================

async function handleVerifyPurchase(request: Request, env: Env): Promise<Response> {
  const userId = await validateAuth(request);
  if (!userId) {
    return json({ error: 'Unauthorized' }, 401);
  }

  const { receiptData, productId } = await request.json();

  // TODO: Verify receipt with Apple's servers
  // For now, trust the receipt (implement App Store Server API for production)

  const supabase = createClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY);

  // Get current credits
  const { data: user } = await supabase
    .from('users')
    .select('image_credits, video_seconds')
    .eq('id', userId)
    .single();

  if (!user) {
    return json({ error: 'User not found' }, 404);
  }

  // Add credits based on product
  let creditsToAdd = 0;
  let videoSecondsToAdd = 0;

  switch (productId) {
    case 'com.johnellison.vibescaler.credits.10':
      creditsToAdd = 10;
      break;
    case 'com.johnellison.vibescaler.credits.50':
      creditsToAdd = 50;
      break;
    case 'com.johnellison.vibescaler.credits.100':
      creditsToAdd = 100;
      break;
    case 'com.johnellison.vibescaler.video.2min':
      videoSecondsToAdd = 120;
      break;
    case 'com.johnellison.vibescaler.video.5min':
      videoSecondsToAdd = 300;
      break;
    case 'com.johnellison.vibescaler.video.15min':
      videoSecondsToAdd = 900;
      break;
    case 'com.johnellison.vibescaler.pro.monthly':
      creditsToAdd = 75;
      videoSecondsToAdd = 300;
      break;
    default:
      return json({ error: 'Unknown product' }, 400);
  }

  // Update credits
  await supabase
    .from('users')
    .update({
      image_credits: user.image_credits + creditsToAdd,
      video_seconds: user.video_seconds + videoSecondsToAdd,
    })
    .eq('id', userId);

  // Log transaction
  await supabase.from('transactions').insert({
    user_id: userId,
    type: 'purchase',
    product_id: productId,
    credits_added: creditsToAdd,
    video_seconds_added: videoSecondsToAdd,
  });

  return json({
    success: true,
    creditsAdded: creditsToAdd,
    videoSecondsAdded: videoSecondsToAdd,
  });
}

// ============================================================
// HELPERS
// ============================================================

async function validateAuth(request: Request): Promise<string | null> {
  const authHeader = request.headers.get('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return null;
  }

  const token = authHeader.slice(7);

  try {
    const payload = JSON.parse(atob(token));

    if (payload.exp < Date.now()) {
      return null; // Token expired
    }

    return payload.userId;
  } catch {
    return null;
  }
}

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...corsHeaders,
    },
  });
}
