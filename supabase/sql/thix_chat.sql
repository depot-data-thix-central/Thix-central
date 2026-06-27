-- THIX CHAT Module — Complete Database Schema
-- Comprehensive messaging system with all features
-- Run in Supabase Dashboard → SQL Editor

begin;

-- Ensure pgcrypto is available
create extension if not exists "pgcrypto";

-- =============================================================================
-- Helper Functions
-- =============================================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- =============================================================================
-- 1. Conversations (1-to-1 and Groups)
-- =============================================================================

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  name text,
  is_group boolean not null default false,
  description text,
  avatar_url text,
  created_by uuid not null references public.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_conversations_created_by on public.conversations(created_by);
drop trigger if exists trg_conversations_updated_at on public.conversations;
create trigger trg_conversations_updated_at before update on public.conversations for each row execute function public.set_updated_at();

-- =============================================================================
-- 2. Conversation Participants
-- =============================================================================

create table if not exists public.conversation_participants (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  role text not null default 'member', -- 'admin', 'moderator', 'member'
  joined_at timestamptz not null default now(),
  archived_at timestamptz,
  muted_until timestamptz, -- For "Do Not Disturb" feature
  custom_name text, -- Optional custom name for this user in this conversation
  unique(conversation_id, user_id)
);

create index if not exists idx_conv_participants_conversation on public.conversation_participants(conversation_id);
create index if not exists idx_conv_participants_user on public.conversation_participants(user_id);

-- =============================================================================
-- 3. Messages (Core)
-- =============================================================================

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.users(id) on delete cascade,
  content text,
  message_type text not null default 'text', -- 'text', 'voice', 'video', 'image', 'document', 'contact'
  file_url text, -- For media messages
  file_name text,
  file_size integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz, -- Soft delete
  is_edited boolean default false,
  reply_to_id uuid references public.messages(id) on delete set null -- For threaded replies
);

create index if not exists idx_messages_conversation on public.messages(conversation_id);
create index if not exists idx_messages_sender on public.messages(sender_id);
create index if not exists idx_messages_created_at on public.messages(created_at);
create index if not exists idx_messages_reply_to on public.messages(reply_to_id);
drop trigger if exists trg_messages_updated_at on public.messages;
create trigger trg_messages_updated_at before update on public.messages for each row execute function public.set_updated_at();

-- =============================================================================
-- 4. Read Receipts (Sent → Delivered → Read)
-- =============================================================================

create table if not exists public.read_receipts (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  status text not null default 'sent', -- 'sent', 'delivered', 'read'
  delivered_at timestamptz,
  read_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(message_id, user_id)
);

create index if not exists idx_read_receipts_message on public.read_receipts(message_id);
create index if not exists idx_read_receipts_user on public.read_receipts(user_id);
drop trigger if exists trg_read_receipts_updated_at on public.read_receipts;
create trigger trg_read_receipts_updated_at before update on public.read_receipts for each row execute function public.set_updated_at();

-- =============================================================================
-- 5. Typing Indicators (Real-time)
-- =============================================================================

create table if not exists public.typing_indicators (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  started_at timestamptz not null default now(),
  unique(conversation_id, user_id)
);

create index if not exists idx_typing_indicators_conversation on public.typing_indicators(conversation_id);

-- =============================================================================
-- 6. User Presence (Online/Offline + Last Seen)
-- =============================================================================

create table if not exists public.user_presence (
  user_id uuid primary key references public.users(id) on delete cascade,
  is_online boolean not null default false,
  last_seen_at timestamptz,
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_user_presence_updated_at on public.user_presence;
create trigger trg_user_presence_updated_at before update on public.user_presence for each row execute function public.set_updated_at();

-- =============================================================================
-- 7. Message Reactions (Emoji)
-- =============================================================================

create table if not exists public.message_reactions (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  emoji text not null, -- '👍', '❤️', '😂', etc.
  created_at timestamptz not null default now(),
  unique(message_id, user_id, emoji)
);

create index if not exists idx_message_reactions_message on public.message_reactions(message_id);
create index if not exists idx_message_reactions_user on public.message_reactions(user_id);

-- =============================================================================
-- 8. Ephemeral Messages (Auto-delete after duration)
-- =============================================================================

create table if not exists public.ephemeral_messages (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages(id) on delete cascade,
  duration_seconds integer not null, -- 5, 10, 30, 60, or custom
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  deleted_at timestamptz,
  unique(message_id)
);

create index if not exists idx_ephemeral_messages_expires_at on public.ephemeral_messages(expires_at);

-- =============================================================================
-- 9. Confidential Messages (PIN or Biometric Protected)
-- =============================================================================

create table if not exists public.confidential_messages (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages(id) on delete cascade,
  pin_hash text, -- Hashed PIN (use bcrypt or similar)
  biometric_required boolean default false,
  created_at timestamptz not null default now(),
  accessed_by uuid[], -- Array of user IDs who accessed it
  unique(message_id)
);

create index if not exists idx_confidential_messages_message on public.confidential_messages(message_id);

-- =============================================================================
-- 10. Scheduled Messages (With Recurrence)
-- =============================================================================

create table if not exists public.scheduled_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.users(id) on delete cascade,
  content text,
  message_type text not null default 'text',
  scheduled_for timestamptz not null,
  recurrence text, -- 'once', 'daily', 'weekly', 'monthly'
  recurrence_end_date date,
  is_active boolean default true,
  last_sent_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_scheduled_messages_conversation on public.scheduled_messages(conversation_id);
create index if not exists idx_scheduled_messages_sender on public.scheduled_messages(sender_id);
create index if not exists idx_scheduled_messages_scheduled_for on public.scheduled_messages(scheduled_for);
drop trigger if exists trg_scheduled_messages_updated_at on public.scheduled_messages;
create trigger trg_scheduled_messages_updated_at before update on public.scheduled_messages for each row execute function public.set_updated_at();

-- =============================================================================
-- 11. Message Reminders (Snooze on Message)
-- =============================================================================

create table if not exists public.message_reminders (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  remind_at timestamptz not null,
  is_sent boolean default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_message_reminders_remind_at on public.message_reminders(remind_at);
create index if not exists idx_message_reminders_user on public.message_reminders(user_id);

-- =============================================================================
-- 12. Polls
-- =============================================================================

create table if not exists public.polls (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages(id) on delete cascade,
  question text not null,
  created_by uuid not null references public.users(id) on delete cascade,
  is_anonymous boolean default false,
  allow_multiple boolean default false,
  created_at timestamptz not null default now(),
  closed_at timestamptz,
  unique(message_id)
);

create index if not exists idx_polls_message on public.polls(message_id);
create index if not exists idx_polls_created_by on public.polls(created_by);

-- =============================================================================
-- 13. Poll Options & Votes
-- =============================================================================

create table if not exists public.poll_options (
  id uuid primary key default gen_random_uuid(),
  poll_id uuid not null references public.polls(id) on delete cascade,
  option_text text not null,
  position integer not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_poll_options_poll on public.poll_options(poll_id);

create table if not exists public.poll_votes (
  id uuid primary key default gen_random_uuid(),
  poll_id uuid not null references public.polls(id) on delete cascade,
  option_id uuid not null references public.poll_options(id) on delete cascade,
  voted_by uuid not null references public.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(poll_id, voted_by, option_id)
);

create index if not exists idx_poll_votes_poll on public.poll_votes(poll_id);
create index if not exists idx_poll_votes_voted_by on public.poll_votes(voted_by);

-- =============================================================================
-- 14. Collaborative Tasks
-- =============================================================================

create table if not exists public.collaborative_tasks (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  created_by uuid not null references public.users(id) on delete cascade,
  title text not null,
  description text,
  assigned_to uuid references public.users(id) on delete set null,
  priority text not null default 'medium', -- 'low', 'medium', 'high'
  status text not null default 'pending', -- 'pending', 'in_progress', 'completed'
  due_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz
);

create index if not exists idx_tasks_conversation on public.collaborative_tasks(conversation_id);
create index if not exists idx_tasks_assigned_to on public.collaborative_tasks(assigned_to);
create index if not exists idx_tasks_created_by on public.collaborative_tasks(created_by);
drop trigger if exists trg_tasks_updated_at on public.collaborative_tasks;
create trigger trg_tasks_updated_at before update on public.collaborative_tasks for each row execute function public.set_updated_at();

-- =============================================================================
-- 15. Pinned Messages (Group Admin Feature)
-- =============================================================================

create table if not exists public.pinned_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  message_id uuid not null references public.messages(id) on delete cascade,
  pinned_by uuid not null references public.users(id) on delete cascade,
  pinned_at timestamptz not null default now()
);

create index if not exists idx_pinned_messages_conversation on public.pinned_messages(conversation_id);
create index if not exists idx_pinned_messages_message on public.pinned_messages(message_id);

-- =============================================================================
-- 16. Message Drafts (Auto-save)
-- =============================================================================

create table if not exists public.message_drafts (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  content text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(conversation_id, user_id)
);

create index if not exists idx_message_drafts_conversation on public.message_drafts(conversation_id);
create index if not exists idx_message_drafts_user on public.message_drafts(user_id);
drop trigger if exists trg_message_drafts_updated_at on public.message_drafts;
create trigger trg_message_drafts_updated_at before update on public.message_drafts for each row execute function public.set_updated_at();

-- =============================================================================
-- 17. Blocked Users
-- =============================================================================

create table if not exists public.blocked_users (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  blocked_user_id uuid not null references public.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(user_id, blocked_user_id)
);

create index if not exists idx_blocked_users_user on public.blocked_users(user_id);
create index if not exists idx_blocked_users_blocked on public.blocked_users(blocked_user_id);

-- =============================================================================
-- 18. Reported Content (Moderation)
-- =============================================================================

create table if not exists public.reported_content (
  id uuid primary key default gen_random_uuid(),
  content_type text not null, -- 'message', 'user'
  content_id uuid not null,
  reported_by uuid not null references public.users(id) on delete cascade,
  reason text not null,
  description text,
  status text not null default 'pending', -- 'pending', 'reviewing', 'resolved', 'dismissed'
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_reported_content_created_at on public.reported_content(created_at);
create index if not exists idx_reported_content_status on public.reported_content(status);
drop trigger if exists trg_reported_content_updated_at on public.reported_content;
create trigger trg_reported_content_updated_at before update on public.reported_content for each row execute function public.set_updated_at();

-- =============================================================================
-- 19. Chat Settings (Per User)
-- =============================================================================

create table if not exists public.chat_settings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.users(id) on delete cascade,
  theme text default 'system', -- 'light', 'dark', 'system'
  notification_priority text default 'all', -- 'all', 'mentions_only', 'none'
  silent_hours_start time,
  silent_hours_end time,
  data_saver_enabled boolean default false,
  wifi_only_media boolean default false,
  auto_translate_enabled boolean default false,
  translate_to_language text default 'en',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_chat_settings_user on public.chat_settings(user_id);
drop trigger if exists trg_chat_settings_updated_at on public.chat_settings;
create trigger trg_chat_settings_updated_at before update on public.chat_settings for each row execute function public.set_updated_at();

-- =============================================================================
-- 20. Call History
-- =============================================================================

create table if not exists public.call_history (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  initiated_by uuid not null references public.users(id) on delete cascade,
  call_type text not null, -- 'audio', 'video'
  started_at timestamptz not null,
  ended_at timestamptz,
  duration_seconds integer,
  status text not null default 'missed', -- 'completed', 'missed', 'rejected', 'cancelled'
  created_at timestamptz not null default now()
);

create index if not exists idx_call_history_conversation on public.call_history(conversation_id);
create index if not exists idx_call_history_initiated_by on public.call_history(initiated_by);
create index if not exists idx_call_history_started_at on public.call_history(started_at);

-- =============================================================================
-- 21. Conversation Settings (Per Conversation)
-- =============================================================================

create table if not exists public.conversation_settings (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null unique references public.conversations(id) on delete cascade,
  custom_wallpaper_url text,
  bubble_color text,
  bubble_shape text default 'rounded', -- 'rounded', 'sharp'
  bubble_opacity real default 1.0,
  custom_notification_sound text,
  is_encrypted boolean default false,
  pin_protected boolean default false,
  pin_hash text, -- For conversation-specific PIN
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_conversation_settings_conversation on public.conversation_settings(conversation_id);
drop trigger if exists trg_conversation_settings_updated_at on public.conversation_settings;
create trigger trg_conversation_settings_updated_at before update on public.conversation_settings for each row execute function public.set_updated_at();

-- =============================================================================
-- Row Level Security (RLS)
-- =============================================================================

-- Enable RLS on all tables
alter table public.conversations enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.messages enable row level security;
alter table public.read_receipts enable row level security;
alter table public.typing_indicators enable row level security;
alter table public.user_presence enable row level security;
alter table public.message_reactions enable row level security;
alter table public.ephemeral_messages enable row level security;
alter table public.confidential_messages enable row level security;
alter table public.scheduled_messages enable row level security;
alter table public.message_reminders enable row level security;
alter table public.polls enable row level security;
alter table public.poll_options enable row level security;
alter table public.poll_votes enable row level security;
alter table public.collaborative_tasks enable row level security;
alter table public.pinned_messages enable row level security;
alter table public.message_drafts enable row level security;
alter table public.blocked_users enable row level security;
alter table public.reported_content enable row level security;
alter table public.chat_settings enable row level security;
alter table public.call_history enable row level security;
alter table public.conversation_settings enable row level security;

-- Conversations: Users can view if they're a participant, create groups/1-to-1
drop policy if exists "conversations_select" on public.conversations;
create policy "conversations_select" on public.conversations for select
using (exists(select 1 from public.conversation_participants where conversation_id = id and user_id = auth.uid()));

drop policy if exists "conversations_insert" on public.conversations;
create policy "conversations_insert" on public.conversations for insert
with check (created_by = auth.uid());

-- Conversation Participants: Users can view/manage their own participation
drop policy if exists "conv_participants_select" on public.conversation_participants;
create policy "conv_participants_select" on public.conversation_participants for select
using (user_id = auth.uid() or exists(select 1 from public.conversation_participants cp where cp.conversation_id = conversation_id and cp.user_id = auth.uid() and cp.role in ('admin', 'moderator')));

drop policy if exists "conv_participants_insert" on public.conversation_participants;
create policy "conv_participants_insert" on public.conversation_participants for insert
with check (true); -- Will be validated by Edge Function

-- Messages: Users can view messages in conversations they're part of
drop policy if exists "messages_select" on public.messages;
create policy "messages_select" on public.messages for select
using (exists(select 1 from public.conversation_participants where conversation_id = conversation_id and user_id = auth.uid()) and deleted_at is null);

drop policy if exists "messages_insert" on public.messages;
create policy "messages_insert" on public.messages for insert
with check (sender_id = auth.uid());

drop policy if exists "messages_update" on public.messages;
create policy "messages_update" on public.messages for update
using (sender_id = auth.uid() or exists(select 1 from public.conversation_participants cp join public.conversations c on cp.conversation_id = c.id where c.id = conversation_id and cp.user_id = auth.uid() and cp.role in ('admin', 'moderator')));

-- Read Receipts: Users can manage their own
drop policy if exists "read_receipts_select" on public.read_receipts;
create policy "read_receipts_select" on public.read_receipts for select
using (user_id = auth.uid() or exists(select 1 from public.messages m join public.conversation_participants cp on m.conversation_id = cp.conversation_id where m.id = message_id and cp.user_id = auth.uid()));

drop policy if exists "read_receipts_insert" on public.read_receipts;
create policy "read_receipts_insert" on public.read_receipts for insert
with check (user_id = auth.uid());

-- Message Reactions: Users can manage their own
drop policy if exists "message_reactions_select" on public.message_reactions;
create policy "message_reactions_select" on public.message_reactions for select
using (true); -- Public read

drop policy if exists "message_reactions_insert" on public.message_reactions;
create policy "message_reactions_insert" on public.message_reactions for insert
with check (user_id = auth.uid());

-- Chat Settings: Users can only access their own
drop policy if exists "chat_settings_select" on public.chat_settings;
create policy "chat_settings_select" on public.chat_settings for select
using (user_id = auth.uid());

drop policy if exists "chat_settings_update" on public.chat_settings;
create policy "chat_settings_update" on public.chat_settings for update
using (user_id = auth.uid());

commit;
