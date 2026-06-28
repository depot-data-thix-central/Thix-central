begin;

-- Adds optional caption field for stories (used by Flutter UI).
alter table public.social_stories add column if not exists caption text;

commit;
