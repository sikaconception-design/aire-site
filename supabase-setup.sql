-- À exécuter une seule fois : Supabase > SQL Editor > New query > Run

create table actualites (
  id bigint generated always as identity primary key,
  categorie text not null,
  date_pub date not null default current_date,
  titre text not null,
  texte text,
  image_url text,
  created_at timestamptz default now()
);
create table documents (
  id bigint generated always as identity primary key,
  titre text not null,
  fichier_url text not null,
  taille text,
  created_at timestamptz default now()
);
create table admins (user_id uuid primary key references auth.users(id) on delete cascade);

alter table actualites enable row level security;
alter table documents  enable row level security;
alter table admins     enable row level security;

create policy "lecture publique actualites" on actualites for select using (true);
create policy "lecture publique documents"  on documents  for select using (true);
create policy "admin ecrit actualites" on actualites for all
  using (exists (select 1 from admins where user_id = auth.uid()))
  with check (exists (select 1 from admins where user_id = auth.uid()));
create policy "admin ecrit documents" on documents for all
  using (exists (select 1 from admins where user_id = auth.uid()))
  with check (exists (select 1 from admins where user_id = auth.uid()));
create policy "un admin voit sa ligne" on admins for select using (user_id = auth.uid());

-- Stockage des PDF
insert into storage.buckets (id, name, public) values ('documents', 'documents', true) on conflict do nothing;
create policy "lecture publique pdf" on storage.objects for select using (bucket_id = 'documents');
create policy "admin envoie pdf" on storage.objects for insert
  with check (bucket_id = 'documents' and exists (select 1 from admins where user_id = auth.uid()));
create policy "admin supprime pdf" on storage.objects for delete
  using (bucket_id = 'documents' and exists (select 1 from admins where user_id = auth.uid()));

-- APRÈS avoir créé l'utilisateur administrateur (Authentication > Users > Add user),
-- remplacez l'adresse ci-dessous par la sienne et exécutez cette ligne :
-- insert into admins (user_id) select id from auth.users where email = 'ADMIN@EXEMPLE.CI';
