-- JakWypiję: profil użytkownika, zgody i usuwanie konta.
-- Uruchom w Supabase: SQL Editor → New query → wklej → Run.
-- Skrypt można uruchomić ponownie (jest idempotentny).

-- 1. Profil – jeden wiersz na konto ------------------------------------------
create table if not exists public.profiles (
  id                uuid primary key references auth.users (id) on delete cascade,
  display_name      text not null default 'Ty'
                    check (char_length(display_name) between 1 and 24),
  avatar_emoji      text not null default '🍺'
                    check (char_length(avatar_emoji) between 1 and 16),
  user_mode         text check (user_mode in ('tourist', 'local')),
  theme_mode        text check (theme_mode in ('light', 'dark')),
  age_confirmed_at  timestamptz,
  terms_version     integer not null default 0,
  terms_accepted_at timestamptz,
  marketing_consent boolean not null default false,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

comment on table public.profiles is
  'JakWypiję – profil i zgody użytkownika (RODO: usuwany razem z kontem).';

-- 2. Row level security: każdy widzi i zmienia tylko swój profil -------------
alter table public.profiles enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles
  for select to authenticated
  using ((select auth.uid()) = id);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles
  for insert to authenticated
  with check ((select auth.uid()) = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
  for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- Brak polityki DELETE: profil znika tylko razem z kontem (kaskada).

-- 3. updated_at ---------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- 4. Profil tworzony automatycznie przy rejestracji ---------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(
      nullif(left(trim(new.raw_user_meta_data ->> 'display_name'), 24), ''),
      'Ty'
    )
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 5. Usunięcie konta z aplikacji (wymóg Google Play / App Store, art. 17 RODO)
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;
  delete from auth.users where id = uid; -- profil usuwa się kaskadowo
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
