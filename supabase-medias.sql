-- Photos et vidéos : à exécuter une seule fois dans Supabase > SQL Editor > Run

alter table equipe       add column if not exists photo_url text;
alter table partenaires  add column if not exists logo_url  text;
alter table activites    add column if not exists image_url text;

insert into storage.buckets (id, name, public) values ('medias', 'medias', true) on conflict do nothing;

drop policy if exists "lecture publique medias" on storage.objects;
drop policy if exists "admin envoie medias" on storage.objects;
drop policy if exists "admin supprime medias" on storage.objects;
create policy "lecture publique medias" on storage.objects for select using (bucket_id = 'medias');
create policy "admin envoie medias" on storage.objects for insert
  with check (bucket_id = 'medias' and exists (select 1 from admins where user_id = auth.uid()));
create policy "admin supprime medias" on storage.objects for delete
  using (bucket_id = 'medias' and exists (select 1 from admins where user_id = auth.uid()));
