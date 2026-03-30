-- Migration: Add public competitions and subscription tracking
-- Date: 2026-03-29

-- Add is_public flag to competitions table
ALTER TABLE public.competitions ADD COLUMN is_public boolean DEFAULT false NOT NULL;

-- Add subscription tracking columns to users table
ALTER TABLE public.users ADD COLUMN apple_original_transaction_id text;
ALTER TABLE public.users ADD COLUMN subscription_expires_date timestamp;
