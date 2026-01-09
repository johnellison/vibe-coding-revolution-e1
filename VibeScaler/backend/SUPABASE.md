# Supabase Setup Guide for VibeScaler

## 1. Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign in
2. Click "New Project"
3. Configure:
   - **Name:** `vibescaler`
   - **Database Password:** Generate a strong password (save it!)
   - **Region:** Choose closest to your users (e.g., `us-west-1`)
4. Click "Create new project" and wait ~2 minutes

## 2. Get Your Credentials

After project creation:

1. Go to **Settings → API**
2. Copy these values:

```
Project URL:     https://xxxxxxxxxxxx.supabase.co
anon public key: eyJhbGc...xxxxx
service_role:    eyJhbGc...xxxxx (keep secret!)
```

3. Go to **Settings → Database**
4. Copy the connection string for migrations:

```
postgresql://postgres:[PASSWORD]@db.xxxxxxxxxxxx.supabase.co:5432/postgres
```

## 3. Run Initial Schema

### Option A: Supabase Dashboard (Quick)

1. Go to **SQL Editor** in Supabase dashboard
2. Click "New query"
3. Copy contents of `supabase-schema.sql`
4. Click "Run"

### Option B: Supabase CLI (Recommended for ongoing work)

See Section 5 below for CLI setup.

## 4. Configure Environment Variables

### For Cloudflare Workers

```bash
cd Backend

# Set secrets
wrangler secret put SUPABASE_URL
# Paste: https://xxxxxxxxxxxx.supabase.co

wrangler secret put SUPABASE_ANON_KEY
# Paste: eyJhbGc...your-anon-key
```

### For Local Development

Create `Backend/.dev.vars`:

```env
SUPABASE_URL=https://xxxxxxxxxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...your-anon-key
FAL_API_KEY=your-fal-api-key
```

> ⚠️ Add `.dev.vars` to `.gitignore`!

## 5. Supabase CLI Setup

### Install CLI

```bash
# macOS
brew install supabase/tap/supabase

# Or via npm
npm install -g supabase
```

### Initialize Project

```bash
cd VibeScaler/Backend

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref xxxxxxxxxxxx
# (project-ref is the ID from your project URL)
```

### Create Migration Directory

```bash
mkdir -p supabase/migrations
```

### Pull Existing Schema (if you ran it manually first)

```bash
supabase db pull
```

## 6. Migration Workflow

### Create New Migration

```bash
# Create a new migration file
supabase migration new add_feature_name
```

This creates: `supabase/migrations/20260109123456_add_feature_name.sql`

Edit the file with your SQL changes.

### Apply Migrations

```bash
# Apply to remote (production)
supabase db push

# Or reset and reapply all (dev only!)
supabase db reset
```

### Check Migration Status

```bash
supabase migration list
```

## 7. MCP Server Configuration

To use Supabase with Claude Code via MCP, add this to your Claude config.

### Find Config Location

```bash
# macOS
cat ~/.claude/claude_desktop_config.json
```

### Add Supabase MCP Server

Edit `~/.claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "supabase": {
      "command": "npx",
      "args": [
        "-y",
        "@supabase/mcp-server",
        "--supabase-url",
        "https://xxxxxxxxxxxx.supabase.co",
        "--supabase-key",
        "your-service-role-key"
      ]
    }
  }
}
```

> ⚠️ Use the **service_role** key for MCP (not anon key) to have full access.

### Restart Claude Code

After updating config, restart Claude Code for MCP to take effect.

### Using MCP

Once configured, you can ask Claude:
- "Show me all users in Supabase"
- "Run this migration on Supabase"
- "Check the transactions table"

## 8. Common Commands Reference

```bash
# --- Supabase CLI ---
supabase login                    # Authenticate
supabase link --project-ref xxx   # Link to project
supabase db push                  # Apply migrations
supabase db pull                  # Pull remote schema
supabase migration new NAME       # Create migration
supabase migration list           # List migrations
supabase db reset                 # Reset local DB
supabase start                    # Start local Supabase
supabase stop                     # Stop local Supabase

# --- Useful Queries ---
# Check users
supabase db execute --sql "SELECT * FROM users LIMIT 10;"

# Check credit balances
supabase db execute --sql "SELECT id, email, image_credits, video_seconds FROM users;"

# View recent transactions
supabase db execute --sql "SELECT * FROM transactions ORDER BY created_at DESC LIMIT 20;"
```

## 9. Database Schema Overview

```
┌─────────────────────────────────────────┐
│                 users                    │
├─────────────────────────────────────────┤
│ id              UUID (PK)               │
│ apple_id        TEXT (unique)           │
│ email           TEXT                    │
│ image_credits   INTEGER (default: 5)    │
│ video_seconds   INTEGER (default: 30)   │
│ is_pro          BOOLEAN                 │
│ subscription_expiry TIMESTAMPTZ         │
│ created_at      TIMESTAMPTZ             │
│ updated_at      TIMESTAMPTZ             │
└─────────────────────────────────────────┘
              │
              │ user_id (FK)
              ▼
┌─────────────────────────────────────────┐
│             transactions                 │
├─────────────────────────────────────────┤
│ id              UUID (PK)               │
│ user_id         UUID (FK → users)       │
│ type            TEXT                    │
│ product_id      TEXT                    │
│ credits_used    INTEGER                 │
│ credits_added   INTEGER                 │
│ video_seconds_used    INTEGER           │
│ video_seconds_added   INTEGER           │
│ model           TEXT                    │
│ metadata        JSONB                   │
│ created_at      TIMESTAMPTZ             │
└─────────────────────────────────────────┘
```

## 10. Troubleshooting

### "Permission denied" errors

Check Row Level Security policies in Supabase dashboard.

### Migration conflicts

```bash
# Pull remote state first
supabase db pull

# Then try push again
supabase db push
```

### Can't connect from Workers

1. Verify URL doesn't have trailing slash
2. Check anon key is correct
3. Ensure project is not paused (free tier pauses after 7 days inactivity)

### MCP not connecting

1. Verify config JSON is valid
2. Use service_role key (not anon)
3. Restart Claude Code after config changes

---

## Quick Start Checklist

- [ ] Create Supabase project
- [ ] Copy Project URL and keys
- [ ] Run `supabase-schema.sql` in SQL Editor
- [ ] Install Supabase CLI: `brew install supabase/tap/supabase`
- [ ] Link project: `supabase link --project-ref xxx`
- [ ] Set Cloudflare secrets: `wrangler secret put SUPABASE_URL`
- [ ] (Optional) Configure MCP server for Claude integration
