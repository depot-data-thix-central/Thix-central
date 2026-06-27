begin;

create extension if not exists "pgcrypto";

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.social_posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references auth.users(id) on delete cascade,
  author_name text not null,
  author_role text,
  author_avatar_url text,
  author_is_verified boolean not null default false,
  author_mutual_connections integer not null default 0,
  content text not null,
  kind text not null default 'text',
  visibility text not null default 'public',
  community_name text,
  quote text,
  media_urls text[] not null default '{}',
  hashtags text[] not null default '{}',
  mentions text[] not null default '{}',
  poll jsonb,
  challenge jsonb,
  repost_of_post_id uuid references public.social_posts(id) on delete set null,
  repost_author_name text,
  like_count integer not null default 0,
  comment_count integer not null default 0,
  share_count integer not null default 0,
  view_count integer not null default 0,
  is_pinned boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_social_posts_created on public.social_posts (created_at desc);
create index if not exists idx_social_posts_kind on public.social_posts (kind, created_at desc);
create index if not exists idx_social_posts_tags on public.social_posts using gin (hashtags);
create index if not exists idx_social_posts_mentions on public.social_posts using gin (mentions);

drop trigger if exists trg_social_posts_updated_at on public.social_posts;
create trigger trg_social_posts_updated_at
before update on public.social_posts
for each row execute function public.set_updated_at();

alter table public.social_posts enable row level security;

drop policy if exists "social_posts_read_all" on public.social_posts;
create policy "social_posts_read_all" on public.social_posts
for select using (true);

drop policy if exists "social_posts_insert_own" on public.social_posts;
create policy "social_posts_insert_own" on public.social_posts
for insert with check (auth.uid() = author_id);

drop policy if exists "social_posts_update_own" on public.social_posts;
create policy "social_posts_update_own" on public.social_posts
for update using (auth.uid() = author_id) with check (auth.uid() = author_id);

create table if not exists public.social_post_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.social_posts(id) on delete cascade,
  author_id uuid not null references auth.users(id) on delete cascade,
  author_name text not null,
  author_role text,
  author_avatar_url text,
  text text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_social_post_comments_post on public.social_post_comments (post_id, created_at asc);

drop trigger if exists trg_social_post_comments_updated_at on public.social_post_comments;
create trigger trg_social_post_comments_updated_at
before update on public.social_post_comments
for each row execute function public.set_updated_at();

alter table public.social_post_comments enable row level security;

drop policy if exists "social_comments_read_all" on public.social_post_comments;
create policy "social_comments_read_all" on public.social_post_comments
for select using (true);

drop policy if exists "social_comments_insert_own" on public.social_post_comments;
create policy "social_comments_insert_own" on public.social_post_comments
for insert with check (auth.uid() = author_id);

drop policy if exists "social_comments_update_own" on public.social_post_comments;
create policy "social_comments_update_own" on public.social_post_comments
for update using (auth.uid() = author_id) with check (auth.uid() = author_id);

create table if not exists public.social_post_bookmarks (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.social_posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (post_id, user_id)
);

alter table public.social_post_bookmarks enable row level security;

drop policy if exists "social_bookmarks_read_own" on public.social_post_bookmarks;
create policy "social_bookmarks_read_own" on public.social_post_bookmarks
for select using (auth.uid() = user_id);

drop policy if exists "social_bookmarks_insert_own" on public.social_post_bookmarks;
create policy "social_bookmarks_insert_own" on public.social_post_bookmarks
for insert with check (auth.uid() = user_id);

drop policy if exists "social_bookmarks_delete_own" on public.social_post_bookmarks;
create policy "social_bookmarks_delete_own" on public.social_post_bookmarks
for delete using (auth.uid() = user_id);

create table if not exists public.social_post_likes (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.social_posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (post_id, user_id)
);

alter table public.social_post_likes enable row level security;

drop policy if exists "social_likes_read_all" on public.social_post_likes;
create policy "social_likes_read_all" on public.social_post_likes
for select using (true);

drop policy if exists "social_likes_insert_own" on public.social_post_likes;
create policy "social_likes_insert_own" on public.social_post_likes
for insert with check (auth.uid() = user_id);

drop policy if exists "social_likes_delete_own" on public.social_post_likes;
create policy "social_likes_delete_own" on public.social_post_likes
for delete using (auth.uid() = user_id);

create table if not exists public.social_stories (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references auth.users(id) on delete cascade,
  author_name text not null,
  media_url text,
  is_video boolean not null default false,
  view_count integer not null default 0,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '24 hours')
);

create table if not exists public.social_story_views (
  id uuid primary key default gen_random_uuid(),
  story_id uuid not null references public.social_stories(id) on delete cascade,
  viewer_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (story_id, viewer_id)
);

alter table public.social_stories enable row level security;
alter table public.social_story_views enable row level security;

drop policy if exists "social_stories_read_active" on public.social_stories;
create policy "social_stories_read_active" on public.social_stories
for select using (expires_at > now());

drop policy if exists "social_stories_insert_own" on public.social_stories;
create policy "social_stories_insert_own" on public.social_stories
for insert with check (auth.uid() = author_id);

drop policy if exists "social_story_views_read_own" on public.social_story_views;
create policy "social_story_views_read_own" on public.social_story_views
for select using (auth.uid() = viewer_id);

drop policy if exists "social_story_views_insert_own" on public.social_story_views;
create policy "social_story_views_insert_own" on public.social_story_views
for insert with check (auth.uid() = viewer_id);

create table if not exists public.social_highlights (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.social_highlight_items (
  id uuid primary key default gen_random_uuid(),
  highlight_id uuid not null references public.social_highlights(id) on delete cascade,
  story_id uuid not null references public.social_stories(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (highlight_id, story_id)
);

alter table public.social_highlights enable row level security;
alter table public.social_highlight_items enable row level security;

drop policy if exists "social_highlights_read_all" on public.social_highlights;
create policy "social_highlights_read_all" on public.social_highlights
for select using (true);

drop policy if exists "social_highlights_insert_own" on public.social_highlights;
create policy "social_highlights_insert_own" on public.social_highlights
for insert with check (auth.uid() = owner_id);

create table if not exists public.social_communities (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  description text,
  is_private boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (name)
);

create table if not exists public.social_community_members (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references public.social_communities(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member',
  status text not null default 'active',
  created_at timestamptz not null default now(),
  unique (community_id, user_id)
);

alter table public.social_communities enable row level security;
alter table public.social_community_members enable row level security;

drop trigger if exists trg_social_communities_updated_at on public.social_communities;
create trigger trg_social_communities_updated_at
before update on public.social_communities
for each row execute function public.set_updated_at();

drop policy if exists "social_communities_read_public_or_member" on public.social_communities;
create policy "social_communities_read_public_or_member" on public.social_communities
for select using (
  not is_private
  or exists (
    select 1 from public.social_community_members m
    where m.community_id = id and m.user_id = auth.uid() and m.status = 'active'
  )
);

drop policy if exists "social_communities_insert_own" on public.social_communities;
create policy "social_communities_insert_own" on public.social_communities
for insert with check (auth.uid() = owner_id);

drop policy if exists "social_members_read_own_or_public" on public.social_community_members;
create policy "social_members_read_own_or_public" on public.social_community_members
for select using (
  auth.uid() = user_id
  or exists (
    select 1 from public.social_communities c
    where c.id = community_id and c.is_private = false
  )
);

drop policy if exists "social_members_insert_own" on public.social_community_members;
create policy "social_members_insert_own" on public.social_community_members
for insert with check (auth.uid() = user_id);

create table if not exists public.social_connections (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references auth.users(id) on delete cascade,
  receiver_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (requester_id, receiver_id),
  check (requester_id <> receiver_id)
);

create table if not exists public.social_blocks (
  id uuid primary key default gen_random_uuid(),
  blocker_id uuid not null references auth.users(id) on delete cascade,
  blocked_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

alter table public.social_connections enable row level security;
alter table public.social_blocks enable row level security;

drop trigger if exists trg_social_connections_updated_at on public.social_connections;
create trigger trg_social_connections_updated_at
before update on public.social_connections
for each row execute function public.set_updated_at();

drop policy if exists "social_connections_read_participants" on public.social_connections;
create policy "social_connections_read_participants" on public.social_connections
for select using (auth.uid() in (requester_id, receiver_id));

drop policy if exists "social_connections_insert_requester" on public.social_connections;
create policy "social_connections_insert_requester" on public.social_connections
for insert with check (auth.uid() = requester_id);

drop policy if exists "social_connections_update_participants" on public.social_connections;
create policy "social_connections_update_participants" on public.social_connections
for update using (auth.uid() in (requester_id, receiver_id)) with check (auth.uid() in (requester_id, receiver_id));

drop policy if exists "social_blocks_read_own" on public.social_blocks;
create policy "social_blocks_read_own" on public.social_blocks
for select using (auth.uid() = blocker_id);

drop policy if exists "social_blocks_insert_own" on public.social_blocks;
create policy "social_blocks_insert_own" on public.social_blocks
for insert with check (auth.uid() = blocker_id);

drop policy if exists "social_blocks_delete_own" on public.social_blocks;
create policy "social_blocks_delete_own" on public.social_blocks
for delete using (auth.uid() = blocker_id);

create table if not exists public.social_conversations (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references auth.users(id) on delete cascade,
  is_group boolean not null default false,
  title text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.social_conversation_members (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.social_conversations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (conversation_id, user_id)
);

create table if not exists public.social_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.social_conversations(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  body text not null,
  attachment_urls text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.social_message_reads (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.social_messages(id) on delete cascade,
  reader_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (message_id, reader_id)
);

alter table public.social_conversations enable row level security;
alter table public.social_conversation_members enable row level security;
alter table public.social_messages enable row level security;
alter table public.social_message_reads enable row level security;

drop trigger if exists trg_social_conversations_updated_at on public.social_conversations;
create trigger trg_social_conversations_updated_at
before update on public.social_conversations
for each row execute function public.set_updated_at();

drop trigger if exists trg_social_messages_updated_at on public.social_messages;
create trigger trg_social_messages_updated_at
before update on public.social_messages
for each row execute function public.set_updated_at();

drop policy if exists "social_conversations_read_members" on public.social_conversations;
create policy "social_conversations_read_members" on public.social_conversations
for select using (
  exists (
    select 1 from public.social_conversation_members m
    where m.conversation_id = id and m.user_id = auth.uid()
  )
);

drop policy if exists "social_conversations_insert_owner" on public.social_conversations;
create policy "social_conversations_insert_owner" on public.social_conversations
for insert with check (auth.uid() = created_by);

drop policy if exists "social_conversation_members_read_members" on public.social_conversation_members;
create policy "social_conversation_members_read_members" on public.social_conversation_members
for select using (auth.uid() = user_id);

drop policy if exists "social_conversation_members_insert_members" on public.social_conversation_members;
create policy "social_conversation_members_insert_members" on public.social_conversation_members
for insert with check (auth.uid() = user_id);

drop policy if exists "social_messages_read_members" on public.social_messages;
create policy "social_messages_read_members" on public.social_messages
for select using (
  exists (
    select 1 from public.social_conversation_members m
    where m.conversation_id = conversation_id and m.user_id = auth.uid()
  )
);

drop policy if exists "social_messages_insert_sender" on public.social_messages;
create policy "social_messages_insert_sender" on public.social_messages
for insert with check (auth.uid() = sender_id);

drop policy if exists "social_message_reads_read_own" on public.social_message_reads;
create policy "social_message_reads_read_own" on public.social_message_reads
for select using (auth.uid() = reader_id);

drop policy if exists "social_message_reads_insert_own" on public.social_message_reads;
create policy "social_message_reads_insert_own" on public.social_message_reads
for insert with check (auth.uid() = reader_id);

create table if not exists public.social_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text not null,
  type text not null default 'general',
  is_unread boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.social_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  post_id uuid references public.social_posts(id) on delete cascade,
  reported_user_id uuid references auth.users(id) on delete set null,
  reason text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.social_profile_visits (
  id uuid primary key default gen_random_uuid(),
  profile_user_id uuid not null references auth.users(id) on delete cascade,
  visitor_user_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

alter table public.social_notifications enable row level security;
alter table public.social_reports enable row level security;
alter table public.social_profile_visits enable row level security;

drop policy if exists "social_notifications_read_own" on public.social_notifications;
create policy "social_notifications_read_own" on public.social_notifications
for select using (auth.uid() = user_id);

drop policy if exists "social_notifications_insert_own" on public.social_notifications;
create policy "social_notifications_insert_own" on public.social_notifications
for insert with check (auth.uid() = user_id);

drop policy if exists "social_notifications_update_own" on public.social_notifications;
create policy "social_notifications_update_own" on public.social_notifications
for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "social_reports_insert_own" on public.social_reports;
create policy "social_reports_insert_own" on public.social_reports
for insert with check (auth.uid() = reporter_id);

drop policy if exists "social_reports_read_own" on public.social_reports;
create policy "social_reports_read_own" on public.social_reports
for select using (auth.uid() = reporter_id);

drop policy if exists "social_profile_visits_read_owner" on public.social_profile_visits;
create policy "social_profile_visits_read_owner" on public.social_profile_visits
for select using (auth.uid() = profile_user_id);

drop policy if exists "social_profile_visits_insert_authenticated" on public.social_profile_visits;
create policy "social_profile_visits_insert_authenticated" on public.social_profile_visits
for insert with check (auth.uid() = visitor_user_id or visitor_user_id is null);

insert into storage.buckets (id, name, public)
values ('social-media', 'social-media', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('story-media', 'story-media', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('profile-media', 'profile-media', true)
on conflict (id) do nothing;

drop policy if exists "social_media_public_read" on storage.objects;
create policy "social_media_public_read" on storage.objects
for select using (bucket_id in ('social-media', 'story-media', 'profile-media'));

drop policy if exists "social_media_auth_upload" on storage.objects;
create policy "social_media_auth_upload" on storage.objects
for insert with check (
  auth.role() = 'authenticated'
  and bucket_id in ('social-media', 'story-media', 'profile-media')
);

drop policy if exists "social_media_owner_update" on storage.objects;
create policy "social_media_owner_update" on storage.objects
for update using (
  auth.uid()::text = owner
  and bucket_id in ('social-media', 'story-media', 'profile-media')
)
with check (
  auth.uid()::text = owner
  and bucket_id in ('social-media', 'story-media', 'profile-media')
);

drop policy if exists "social_media_owner_delete" on storage.objects;
create policy "social_media_owner_delete" on storage.objects
for delete using (
  auth.uid()::text = owner
  and bucket_id in ('social-media', 'story-media', 'profile-media')
);

commit;
