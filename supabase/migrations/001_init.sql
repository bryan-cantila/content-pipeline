-- ============================================================
-- Content Pipeline — initial schema (Supabase / PostgreSQL)
-- Run this in the Supabase SQL editor (one paste, top to bottom).
-- ============================================================

-- ---------- tables ----------

create table public.topics (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id) on delete cascade not null,
  title       text not null,
  source      text,
  trend_score int not null default 0,
  status      text not null default 'new' check (status in ('new','approved','rejected')),
  created_at  timestamptz not null default now()
);
create index topics_user_status_idx on public.topics (user_id, status);

create table public.drafts (
  id          uuid primary key default gen_random_uuid(),
  topic_id    uuid references public.topics(id) on delete cascade not null,
  user_id     uuid references auth.users(id) on delete cascade not null,
  hook        text,
  script_text text,
  caption     text,
  hashtags    text,
  media_url   text, -- URL of the finished video file to publish (set by the creator)
  status      text not null default 'draft' check (status in ('draft','approved','published')),
  created_at  timestamptz not null default now()
);
create index drafts_topic_idx on public.drafts (topic_id);

create table public.publishing_targets (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid references auth.users(id) on delete cascade not null,
  type       text not null check (type in ('youtube','facebook','instagram','tiktok')),
  label      text not null,
  config     jsonb not null default '{}'::jsonb,
  is_active  boolean not null default true,
  created_at timestamptz not null default now()
);
-- config shapes (never store secrets anywhere else):
--   youtube:   {"channel_id": "..."}        (OAuth credential lives in n8n)
--   facebook:  {"page_id": "..."}           (OAuth credential lives in n8n)
--   instagram: {"account_id": "..."}        (OAuth credential lives in n8n)
--   tiktok:    {"open_id": "..."}            (OAuth credential lives in n8n)

create table public.scheduled_posts (
  id           uuid primary key default gen_random_uuid(),
  draft_id     uuid references public.drafts(id) on delete cascade not null,
  target_id    uuid references public.publishing_targets(id) on delete cascade not null,
  scheduled_at timestamptz not null,
  status       text not null default 'queued' check (status in ('queued','posted','failed')),
  posted_url   text,
  error        text,
  created_at   timestamptz not null default now()
);
create index scheduled_posts_due_idx on public.scheduled_posts (scheduled_at, status);

-- ---------- row level security ----------
-- NOTE: n8n talks to Supabase with the service_role key, which BYPASSES
-- RLS entirely. These policies only constrain the anon/authenticated keys
-- used by the dashboard, so each user sees only their own rows.

alter table public.topics             enable row level security;
alter table public.drafts             enable row level security;
alter table public.publishing_targets enable row level security;
alter table public.scheduled_posts    enable row level security;

-- topics: owners manage their own
create policy topics_owner_all on public.topics
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- drafts: ownership flows through the parent topic
create policy drafts_owner_all on public.drafts
  for all to authenticated
  using (exists (
    select 1 from public.topics t
    where t.id = drafts.topic_id and t.user_id = auth.uid()
  ))
  with check (exists (
    select 1 from public.topics t
    where t.id = drafts.topic_id and t.user_id = auth.uid()
  ));

-- publishing targets: owners manage their own
create policy publishing_targets_owner_all on public.publishing_targets
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- scheduled posts: ownership flows through the draft -> topic chain
create policy scheduled_posts_owner_all on public.scheduled_posts
  for all to authenticated
  using (exists (
    select 1 from public.drafts d
    join public.topics t on t.id = d.topic_id
    where d.id = scheduled_posts.draft_id and t.user_id = auth.uid()
  ))
  with check (exists (
    select 1 from public.drafts d
    join public.topics t on t.id = d.topic_id
    where d.id = scheduled_posts.draft_id and t.user_id = auth.uid()
  ));

-- ---------- realtime ----------
alter publication supabase_realtime add table public.topics;
alter publication supabase_realtime add table public.drafts;
alter publication supabase_realtime add table public.scheduled_posts;
