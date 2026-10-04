-- Inscription à la newsletter : à exécuter une seule fois dans Supabase > SQL Editor > Run
-- (supabase-membres.sql doit avoir été exécuté avant : il crée la fonction is_admin)

create table if not exists abonnes (
  id bigint generated always as identity primary key,
  email text not null,
  langue text default 'fr',
  created_at timestamptz default now()
);
create unique index if not exists abonnes_email_uniq on abonnes (lower(email));

alter table abonnes enable row level security;
drop policy if exists "inscription publique" on abonnes;
drop policy if exists "admin lit abonnes" on abonnes;
drop policy if exists "admin supprime abonnes" on abonnes;
create policy "inscription publique" on abonnes for insert to anon, authenticated
  with check (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$' and length(email) <= 254);
create policy "admin lit abonnes" on abonnes for select using (is_admin());
create policy "admin supprime abonnes" on abonnes for delete using (is_admin());

-- Désinscription par le visiteur lui-même (depuis le lien « Se désabonner » du pied de page)
create or replace function public.desabonner(p_email text) returns void
language sql security definer set search_path = public
as $$ delete from abonnes where lower(email) = lower(p_email) $$;
grant execute on function public.desabonner(text) to anon, authenticated;
