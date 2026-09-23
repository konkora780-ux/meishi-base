-- 名刺ベース（meishi-base）セットアップSQL
-- Supabase の SQL Editor に貼り付けて実行してください（再実行しても安全）。
-- 「クラウド共有」モードを使うときだけ必要です。ローカルモードだけなら不要。
-- 既存の他アプリと同じSupabaseプロジェクトに相乗りしてOK（テーブル名は meishi_ 始まりで衝突しません）。

-- ============ 名刺テーブル ============
create table if not exists public.meishi_cards (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  owner_name text default '',
  name text not null,
  kana text default '',
  company text default '',
  dept text default '',
  title text default '',
  phone text default '',
  mobile text default '',
  email text default '',
  address text default '',
  web text default '',
  tags text[] default '{}',
  memo text default '',
  metdate date,
  metevent text default '',
  follow boolean default false,
  follow_done boolean default false,
  photo text,                       -- base64データURL（小さめ推奨）
  is_shared boolean default false,  -- true=みんなに共有 / false=自分だけ
  created_at timestamptz not null default now()
);

-- 後から列を足しても安全に
alter table public.meishi_cards add column if not exists owner_name text default '';
alter table public.meishi_cards add column if not exists follow_done boolean default false;

-- 検索・並び順を速く
create index if not exists meishi_cards_owner_idx on public.meishi_cards(owner_id);
create index if not exists meishi_cards_shared_idx on public.meishi_cards(is_shared);
create index if not exists meishi_cards_created_idx on public.meishi_cards(created_at desc);

-- ============ アクセス制御（RLS）============
alter table public.meishi_cards enable row level security;

-- 再実行を安全にするため既存ポリシーを消してから作り直す
drop policy if exists meishi_select on public.meishi_cards;
drop policy if exists meishi_insert on public.meishi_cards;
drop policy if exists meishi_update on public.meishi_cards;
drop policy if exists meishi_delete on public.meishi_cards;

-- 閲覧：自分の名刺 または 共有された名刺（ログイン済みユーザー全員が見られる）
create policy meishi_select on public.meishi_cards
  for select to authenticated
  using ( owner_id = auth.uid() or is_shared = true );

-- 追加：自分の名刺としてのみ追加できる
create policy meishi_insert on public.meishi_cards
  for insert to authenticated
  with check ( owner_id = auth.uid() );

-- 編集：自分が登録した名刺だけ
create policy meishi_update on public.meishi_cards
  for update to authenticated
  using ( owner_id = auth.uid() )
  with check ( owner_id = auth.uid() );

-- 削除：自分が登録した名刺だけ
create policy meishi_delete on public.meishi_cards
  for delete to authenticated
  using ( owner_id = auth.uid() );

-- ============ 完了 ============
-- ・共有は「同じSupabaseプロジェクトにログインしたユーザーどうしでOK」という単純な全体共有です。
-- ・後から「グループ別共有」にしたくなったら meishi_groups / meishi_group_members を足して
--   is_shared を group_id 参照に変える拡張が可能です（相談してください）。
