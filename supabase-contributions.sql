-- Contributions des membres, charte et exclusion de membres
-- À exécuter une seule fois dans Supabase > SQL Editor > Run
-- (après supabase-membres.sql et supabase-medias.sql)

-- 1. Contributions (articles, colloques, activités, informations)
create table if not exists contributions (
  id bigint generated always as identity primary key,
  auteur_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  auteur_nom text,
  type text not null default 'Article',      -- Article | Colloque | Activité | Information
  titre text not null,
  texte text,
  date_evt date,
  lieu text,
  media_url text,
  created_at timestamptz default now()
);
alter table contributions enable row level security;
drop policy if exists "lecture publique contributions" on contributions;
drop policy if exists "membre publie" on contributions;
drop policy if exists "membre modifie les siennes" on contributions;
drop policy if exists "membre supprime les siennes" on contributions;
drop policy if exists "admin gere contributions" on contributions;
create policy "lecture publique contributions" on contributions for select using (true);
create policy "membre publie" on contributions for insert with check (auteur_id = auth.uid() and is_member());
create policy "membre modifie les siennes" on contributions for update
  using (auteur_id = auth.uid() and is_member()) with check (auteur_id = auth.uid() and is_member());
create policy "membre supprime les siennes" on contributions for delete using (auteur_id = auth.uid() and is_member());
create policy "admin gere contributions" on contributions for all using (is_admin()) with check (is_admin());

-- 2. Les membres validés peuvent téléverser photos et vidéos (images/vidéos uniquement, 50 Mo max)
update storage.buckets set file_size_limit = 52428800, allowed_mime_types = array['image/*','video/*'] where id = 'medias';
drop policy if exists "admin envoie medias" on storage.objects;
drop policy if exists "membre envoie medias" on storage.objects;
create policy "membre envoie medias" on storage.objects for insert
  with check (bucket_id = 'medias' and (is_member() or is_admin()));

-- 3. Acceptation de la charte à l'inscription
alter table membres add column if not exists charte_ok timestamptz;
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public
as $$ begin
  insert into membres (user_id, email, nom, telephone, organisation, charte_ok)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'nom',''), new.raw_user_meta_data->>'tel',
          new.raw_user_meta_data->>'org', case when new.raw_user_meta_data->>'charte' = 'oui' then now() end)
  on conflict do nothing;
  return new;
end $$;

-- 4. Exclusion d'un membre (réservée à l'administrateur) : supprime le compte et ses contributions
create or replace function public.supprimer_membre(uid uuid) returns void
language plpgsql security definer set search_path = public
as $$ begin
  if not is_admin() then raise exception 'Réservé à l''administrateur'; end if;
  if uid = auth.uid() or exists (select 1 from admins where user_id = uid) then
    raise exception 'Impossible de supprimer un administrateur';
  end if;
  delete from auth.users where id = uid;
end $$;
revoke all on function public.supprimer_membre(uuid) from public;
grant execute on function public.supprimer_membre(uuid) to authenticated;
