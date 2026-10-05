-- Catégories et rubriques des documents : à exécuter une seule fois dans Supabase > SQL Editor > Run
alter table documents add column if not exists categorie text;
alter table documents add column if not exists type text default 'bibliotheque';   -- bibliotheque | guide

-- Classement des cinq documents d'exemple (modifiable ensuite dans Administration > Documents)
update documents set categorie = 'Rapports et études',       type = 'bibliotheque' where titre = 'Rapport : État de l’éducation en CI (2024)'                 and categorie is null;
update documents set categorie = 'Sciences de l’éducation',  type = 'guide'        where titre = 'Guide méthodologique pour la recherche en éducation'  and categorie is null;
update documents set categorie = 'Sciences de l’éducation',  type = 'bibliotheque' where titre = 'Revue AIRE – N°12 (2024)'                              and categorie is null;
update documents set categorie = 'Sciences de l’éducation',  type = 'guide'        where titre = 'Modèle de projet de recherche'                        and categorie is null;
update documents set categorie = 'Politiques éducatives',    type = 'bibliotheque' where titre = 'L’inclusion scolaire : enjeux et perspectives'          and categorie is null;
