-- Mise en forme des textes, position des images et taille du logo
-- À exécuter une seule fois dans Supabase > SQL Editor > Run
alter table textes add column if not exists style text;
