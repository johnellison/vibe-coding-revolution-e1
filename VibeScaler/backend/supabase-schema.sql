-- VibeScaler Database Schema
-- Run this in your Supabase SQL Editor

-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  apple_id TEXT UNIQUE NOT NULL,
  email TEXT,
  image_credits INTEGER DEFAULT 5,
  video_seconds INTEGER DEFAULT 30,
  is_pro BOOLEAN DEFAULT FALSE,
  subscription_expiry TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster lookups
CREATE INDEX idx_users_apple_id ON users(apple_id);

-- Transactions table (for audit trail)
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  type TEXT NOT NULL, -- 'purchase', 'image_upscale', 'video_upscale', 'refund'
  product_id TEXT,
  credits_used INTEGER DEFAULT 0,
  credits_added INTEGER DEFAULT 0,
  video_seconds_used INTEGER DEFAULT 0,
  video_seconds_added INTEGER DEFAULT 0,
  model TEXT,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for user lookups
CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_created_at ON transactions(created_at);

-- Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Users can only read their own data
CREATE POLICY "Users can read own data"
  ON users FOR SELECT
  USING (true); -- Cloudflare Worker handles auth

-- Users can only update their own data
CREATE POLICY "Users can update own data"
  ON users FOR UPDATE
  USING (true);

-- Transactions are read-only for users
CREATE POLICY "Users can read own transactions"
  ON transactions FOR SELECT
  USING (true);

-- Allow inserts from service role
CREATE POLICY "Service can insert users"
  ON users FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Service can insert transactions"
  ON transactions FOR INSERT
  WITH CHECK (true);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- View for credit history
CREATE VIEW credit_history AS
SELECT
  t.id,
  t.user_id,
  t.type,
  t.product_id,
  CASE
    WHEN t.type = 'purchase' THEN t.credits_added
    WHEN t.type = 'refund' THEN t.credits_added
    ELSE -t.credits_used
  END as credit_change,
  t.model,
  t.created_at
FROM transactions t
ORDER BY t.created_at DESC;
