-- THIX RÉSEAU PRO (Social) - tables + RLS + triggers
-- Compatible Supabase Postgres

create extension if not exists pgcrypto;

-- Updated_at helper
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Profiles (scoped to social module)
create table if not exists public.social_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  headline text not null default '',
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_social_profiles_updated_at on public.social_profiles;
create trigger trg_social_profiles_updated_at
before update on public.social_profiles
for each row execute function public.set_updated_at();

-- Posts
create table if not exists public.social_posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references auth.users(id) on delete cascade,
  author_name text not null,
  author_role text not null,
  author_avatar_url text,
  author_is_verified boolean not null default false,
  author_mutual_connections int not null default 0,
  content text not null,
  kind text not null default 'text',
  visibility text not null default 'public',
  community_name text,
  media_urls text[] not null default '{}'::text[],
  hashtags text[] not null default '{}'::text[],
  mentions text[] not null default '{}'::text[],
  quote text,
  poll jsonb,
  challenge jsonb,
  repost_of_post_id uuid references public.social_posts(id) on delete set null,
  repost_author_name text,
  like_count int not null default 0,
  comment_count int not null default 0,
  share_count int not null default 0,
  view_count int not null default 0,
  is_pinned boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_social_posts_created_at on public.social_posts(created_at desc);
create index if not exists idx_social_posts_author_id on public.social_posts(author_id);

drop trigger if exists trg_social_posts_updated_at on public.social_posts;
create trigger trg_social_posts_updated_at
before update on public.social_posts
for each row execute function public.set_updated_at();

-- Likes
create table if not exists public.social_post_likes (
  post_id uuid not null references public.social_posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create index if not exists idx_social_post_likes_user on public.social_post_likes(user_id);

-- Bookmarks
create table if not exists public.social_post_bookmarks (
  post_id uuid not null references public.social_posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create index if not exists idx_social_post_bookmarks_user on public.social_post_bookmarks(user_id);

-- Comments
create table if not exists public.social_post_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.social_posts(id) on delete cascade,
  author_id uuid not null references auth.users(id) on delete cascade,
  author_name text not null,
  author_role text not null,
  author_avatar_url text,
  text text not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_social_post_comments_post_id on public.social_post_comments(post_id, created_at desc);

-- Stories
create table if not exists public.social_stories (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references auth.users(id) on delete cascade,
  author_name text not null,
  author_role text not null,
  author_avatar_url text,
  media_url text,
  is_video boolean not null default false,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null
);

create index if not exists idx_social_stories_expires_at on public.social_stories(expires_at desc);

create table if not exists public.social_story_views (
  story_id uuid not null references public.social_stories(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (story_id, user_id)
);

-- Connections
create table if not exists public.social_connections (
  requester_id uuid not null references auth.users(id) on delete cascade,
  addressee_id uuid not null references auth.users(id) on delete cascade,
  status text not null check (status in ('requested', 'accepted', 'blocked')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (requester_id, addressee_id)
);

create index if not exists idx_social_connections_addressee on public.social_connections(addressee_id);

drop trigger if exists trg_social_connections_updated_at on public.social_connections;
create trigger trg_social_connections_updated_at
before update on public.social_connections
for each row execute function public.set_updated_at();

-- Counts triggers
create or replace function public.social_recalc_like_count()
returns trigger
language plpgsql
as $$
begin
  update public.social_posts
  set like_count = (select count(*) from public.social_post_likes where post_id = coalesce(new.post_id, old.post_id))
  where id = coalesce(new.post_id, old.post_id);
  return null;
end;
$$;

drop trigger if exists trg_social_post_likes_count_ins on public.social_post_likes;
drop trigger if exists trg_social_post_likes_count_del on public.social_post_likes;
create trigger trg_social_post_likes_count_ins after insert on public.social_post_likes for each row execute function public.social_recalc_like_count();
create trigger trg_social_post_likes_count_del after delete on public.social_post_likes for each row execute function public.social_recalc_like_count();

create or replace function public.social_recalc_comment_count()
returns trigger
language plpgsql
as $$
begin
  update public.social_posts
  set comment_count = (select count(*) from public.social_post_comments where post_id = coalesce(new.post_id, old.post_id))
  where id = coalesce(new.post_id, old.post_id);
  return null;
end;
$$;

drop trigger if exists trg_social_post_comments_count_ins on public.social_post_comments;
drop trigger if exists trg_social_post_comments_count_del on public.social_post_comments;
create trigger trg_social_post_comments_count_ins after insert on public.social_post_comments for each row execute function public.social_recalc_comment_count();
create trigger trg_social_post_comments_count_del after delete on public.social_post_comments for each row execute function public.social_recalc_comment_count();

-- RLS
alter table public.social_profiles enable row level security;
alter table public.social_posts enable row level security;
alter table public.social_post_likes enable row level security;
alter table public.social_post_bookmarks enable row level security;
alter table public.social_post_comments enable row level security;
alter table public.social_stories enable row level security;
alter table public.social_story_views enable row level security;
alter table public.social_connections enable row level security;

-- social_profiles policies
drop policy if exists "social_profiles_read" on public.social_profiles;
create policy "social_profiles_read" on public.social_profiles
for select to authenticated
using (true);

drop policy if exists "social_profiles_insert" on public.social_profiles;
create policy "social_profiles_insert" on public.social_profiles
for insert to authenticated
with check (user_id = auth.uid());

drop policy if exists "social_profiles_update" on public.social_profiles;
create policy "social_profiles_update" on public.social_profiles
for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- social_posts policies
drop policy if exists "social_posts_read" on public.social_posts;
create policy "social_posts_read" on public.social_posts
for select to authenticated
using (true);

drop policy if exists "social_posts_insert" on public.social_posts;
create policy "social_posts_insert" on public.social_posts
for insert to authenticated
with check (author_id = auth.uid());

drop policy if exists "social_posts_update" on public.social_posts;
create policy "social_posts_update" on public.social_posts
for update to authenticated
using (author_id = auth.uid())
with check (author_id = auth.uid());

drop policy if exists "social_posts_delete" on public.social_posts;
create policy "social_posts_delete" on public.social_posts
for delete to authenticated
using (author_id = auth.uid());

-- likes policies
drop policy if exists "social_likes_read" on public.social_post_likes;
create policy "social_likes_read" on public.social_post_likes
for select to authenticated
using (true);

drop policy if exists "social_likes_write" on public.social_post_likes;
create policy "social_likes_write" on public.social_post_likes
for all to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- bookmarks policies
drop policy if exists "social_bookmarks_read" on public.social_post_bookmarks;
create policy "social_bookmarks_read" on public.social_post_bookmarks
for select to authenticated
using (user_id = auth.uid());

drop policy if exists "social_bookmarks_write" on public.social_post_bookmarks;
create policy "social_bookmarks_write" on public.social_post_bookmarks
for all to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- comments policies
drop policy if exists "social_comments_read" on public.social_post_comments;
create policy "social_comments_read" on public.social_post_comments
for select to authenticated
using (true);

drop policy if exists "social_comments_insert" on public.social_post_comments;
create policy "social_comments_insert" on public.social_post_comments
for insert to authenticated
with check (author_id = auth.uid());

drop policy if exists "social_comments_delete" on public.social_post_comments;
create policy "social_comments_delete" on public.social_post_comments
for delete to authenticated
using (author_id = auth.uid());

-- stories policies
drop policy if exists "social_stories_read" on public.social_stories;
create policy "social_stories_read" on public.social_stories
for select to authenticated
using (expires_at > now());

drop policy if exists "social_stories_write" on public.social_stories;
create policy "social_stories_write" on public.social_stories
for all to authenticated
using (author_id = auth.uid())
with check (author_id = auth.uid());

-- story views policies
drop policy if exists "social_story_views_read" on public.social_story_views;
create policy "social_story_views_read" on public.social_story_views
for select to authenticated
using (user_id = auth.uid());

drop policy if exists "social_story_views_write" on public.social_story_views;
create policy "social_story_views_write" on public.social_story_views
for all to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- connections policies
drop policy if exists "social_connections_read" on public.social_connections;
create policy "social_connections_read" on public.social_connections
for select to authenticated
using (requester_id = auth.uid() or addressee_id = auth.uid());

drop policy if exists "social_connections_insert" on public.social_connections;
create policy "social_connections_insert" on public.social_connections
for insert to authenticated
with check (requester_id = auth.uid());

drop policy if exists "social_connections_update" on public.social_connections;
create policy "social_connections_update" on public.social_connections
for update to authenticated
using (requester_id = auth.uid() or addressee_id = auth.uid())
with check (requester_id = auth.uid() or addressee_id = auth.uid());
