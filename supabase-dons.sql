-- Dons : à exécuter une seule fois dans Supabase > SQL Editor > Run
-- (supabase-membres.sql doit avoir été exécuté avant : il crée la fonction is_admin)

create table if not exists dons (
  id bigint generated always as identity primary key,
  nom text not null,
  email text not null,
  telephone text,
  montant int not null,
  moyen text,
  statut text not null default 'promesse',   -- promesse | recu
  created_at timestamptz default now()
);
alter table dons enable row level security;
drop policy if exists "don public" on dons;
drop policy if exists "admin lit dons" on dons;
drop policy if exists "admin modifie dons" on dons;
drop policy if exists "admin supprime dons" on dons;
create policy "don public" on dons for insert to anon, authenticated
  with check (statut = 'promesse' and montant between 500 and 100000000
              and email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$');
create policy "admin lit dons"      on dons for select using (is_admin());
create policy "admin modifie dons"  on dons for update using (is_admin()) with check (is_admin());
create policy "admin supprime dons" on dons for delete using (is_admin());
