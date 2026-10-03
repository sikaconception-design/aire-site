-- Espace membre : à exécuter une seule fois dans Supabase > SQL Editor > Run
-- (supabase-setup.sql et supabase-admin-complet.sql doivent avoir été exécutés avant)

create table if not exists membres (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text, nom text, telephone text, organisation text, fonction text,
  statut text not null default 'en_attente',   -- en_attente | actif | suspendu
  created_at timestamptz default now()
);
create table if not exists docs_membres (
  id bigint generated always as identity primary key,
  titre text not null, fichier_path text not null, taille text,
  created_at timestamptz default now()
);
create table if not exists annonces_membres (
  id bigint generated always as identity primary key,
  titre text not null, texte text, date_pub date default current_date
);

-- Fonctions de contrôle des droits
create or replace function public.is_admin() returns boolean
language sql security definer set search_path = public stable
as $$ select exists (select 1 from admins where user_id = auth.uid()) $$;

create or replace function public.is_member() returns boolean
language sql security definer set search_path = public stable
as $$ select exists (select 1 from membres where user_id = auth.uid() and statut = 'actif') $$;

create or replace function public.my_statut() returns text
language sql security definer set search_path = public stable
as $$ select statut from membres where user_id = auth.uid() $$;

alter table membres           enable row level security;
alter table docs_membres      enable row level security;
alter table annonces_membres  enable row level security;

drop policy if exists "membre voit son profil" on membres;
drop policy if exists "membre modifie son profil" on membres;
drop policy if exists "admin gere membres" on membres;
create policy "membre voit son profil" on membres for select using (user_id = auth.uid() or is_admin());
create policy "membre modifie son profil" on membres for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid() and statut = my_statut());      -- un membre ne peut pas changer son statut
create policy "admin gere membres" on membres for all using (is_admin()) with check (is_admin());

drop policy if exists "membres lisent docs" on docs_membres;
drop policy if exists "admin gere docs membres" on docs_membres;
create policy "membres lisent docs" on docs_membres for select using (is_member() or is_admin());
create policy "admin gere docs membres" on docs_membres for all using (is_admin()) with check (is_admin());

drop policy if exists "membres lisent annonces" on annonces_membres;
drop policy if exists "admin gere annonces membres" on annonces_membres;
create policy "membres lisent annonces" on annonces_membres for select using (is_member() or is_admin());
create policy "admin gere annonces membres" on annonces_membres for all using (is_admin()) with check (is_admin());

-- Création automatique du profil à chaque inscription
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public
as $$ begin
  insert into membres (user_id, email, nom, telephone, organisation)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'nom',''), new.raw_user_meta_data->>'tel', new.raw_user_meta_data->>'org')
  on conflict do nothing;
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- Comptes déjà existants (dont l'administrateur) : profil actif
insert into membres (user_id, email, nom, statut)
select u.id, u.email, coalesce(u.raw_user_meta_data->>'nom', 'Administrateur'), 'actif'
from auth.users u where not exists (select 1 from membres m where m.user_id = u.id);

-- Stockage privé des documents réservés (accès par lien temporaire)
insert into storage.buckets (id, name, public) values ('membres', 'membres', false) on conflict do nothing;
drop policy if exists "membres lisent pdf" on storage.objects;
drop policy if exists "admin envoie pdf membres" on storage.objects;
drop policy if exists "admin supprime pdf membres" on storage.objects;
create policy "membres lisent pdf" on storage.objects for select
  using (bucket_id = 'membres' and (is_member() or is_admin()));
create policy "admin envoie pdf membres" on storage.objects for insert
  with check (bucket_id = 'membres' and is_admin());
create policy "admin supprime pdf membres" on storage.objects for delete
  using (bucket_id = 'membres' and is_admin());
