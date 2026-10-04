-- Position des logos partenaires et des photos de l'équipe
-- À exécuter une seule fois dans Supabase > SQL Editor > Run
alter table partenaires add column if not exists logo_x    int default 50;
alter table partenaires add column if not exists logo_y    int default 50;
alter table partenaires add column if not exists logo_zoom int default 100;
alter table equipe      add column if not exists photo_x   int default 50;
alter table equipe      add column if not exists photo_y   int default 50;
