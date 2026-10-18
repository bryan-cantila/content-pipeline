-- ============================================================
-- Content Pipeline — DEMO seed data (optional)
-- Replace 'YOUR_USER_UUID' with your auth user id (dashboard Settings
-- shows it after you sign in), then run in the SQL editor.
-- Delete these rows whenever you like; the app works fine empty.
-- ============================================================

-- demo topics
insert into public.topics (user_id, title, source, trend_score, status) values
  ('YOUR_USER_UUID', 'Why short-form video beats long-form in 2026', 'demo', 30, 'approved'),
  ('YOUR_USER_UUID', 'The 3-second hook formula creators swear by', 'demo', 25, 'new'),
  ('YOUR_USER_UUID', 'Posting times that actually matter', 'demo', 12, 'rejected');

-- demo draft on the approved topic
insert into public.drafts (topic_id, user_id, hook, script_text, caption, hashtags, status)
select id, 'YOUR_USER_UUID',
  'Stop posting long videos.',
  'HOOK: Stop posting long videos.\n\nBEAT 1: Short-form now earns the first impression — viewers decide in 3 seconds.\n\nBEAT 2: One idea per video beats one video per idea.\n\nBEAT 3: Post daily; the algorithm rewards reps.\n\nCTA: Follow for one creator tip every day.',
  'Short-form is winning the attention game. Here is the 3-beat structure I use for every video.',
  '#contentcreator #videotips #socialmedia',
  'approved'
from public.topics
where user_id = 'YOUR_USER_UUID' and title like 'Why short-form%';

-- demo publishing target template (fill config with your real channel/page ids)
insert into public.publishing_targets (user_id, type, label, config, is_active) values
  ('YOUR_USER_UUID', 'youtube', 'Demo channel', '{"channel_id": "YOUR_CHANNEL_ID"}', false);
