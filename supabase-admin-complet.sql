-- Administration complète : à exécuter une seule fois dans Supabase > SQL Editor > Run
-- (le script supabase-setup.sql doit avoir été exécuté avant)

create table if not exists projets (id bigint generated always as identity primary key, titre text not null, description text, equipe text, duree text, statut text default 'En cours', image_url text, ordre int default 0);
create table if not exists equipe (id bigint generated always as identity primary key, role text, nom text not null, description text, ordre int default 0);
create table if not exists partenaires (id bigint generated always as identity primary key, icone text, nom text not null, ordre int default 0);
create table if not exists publications (id bigint generated always as identity primary key, titre text not null, image_url text, fichier_url text, ordre int default 0);
create table if not exists activites (id bigint generated always as identity primary key, icone text, titre text not null, texte text, page text default 'activites', ordre int default 0);
create table if not exists textes (cle text primary key, fr text, en text);

do $$ declare t text; begin
foreach t in array array['projets','equipe','partenaires','publications','activites','textes'] loop
  execute format('alter table %I enable row level security', t);
  execute format('drop policy if exists "lecture publique" on %I', t);
  execute format('drop policy if exists "admin ecrit" on %I', t);
  execute format('create policy "lecture publique" on %I for select using (true)', t);
  execute format('create policy "admin ecrit" on %I for all using (exists (select 1 from admins where user_id = auth.uid())) with check (exists (select 1 from admins where user_id = auth.uid()))', t);
end loop; end $$;

-- Contenu de départ (inséré seulement si la table est vide)
insert into actualites (categorie,date_pub,titre,texte,image_url)
select categorie,date_pub::date,titre,texte,image_url from (values
  ('Événements','2025-03-12','Colloque sur la recherche en éducation : défis et perspectives en Côte d’Ivoire','L’AIRE a réuni chercheurs et décideurs autour des enjeux de l’école ivoirienne.','1524178232363-1fb2b075b655'),
  ('Publications','2025-03-05','Nouvelle publication de l’AIRE : les politiques éducatives en Afrique','Une analyse comparée des dispositifs éducatifs en Afrique de l’Ouest.','1497633762265-9d179a990aa6'),
  ('Projets','2025-02-20','Lancement du projet « Éducation et inclusion » dans la région du Gbêkê','Un projet pour mieux comprendre la scolarisation des élèves vulnérables.','1522202176988-66273c2fd55f'),
  ('Interviews','2025-02-10','Interview : Dr Koné M. sur l’éducation inclusive','Regards d’un chercheur sur les pratiques inclusives dans les écoles.','1544717305-2782549b5136'),
  ('Événements','2025-01-28','Appel à contributions pour le prochain numéro','Les chercheurs sont invités à soumettre leurs articles avant la date limite.','1531482615713-2afd69097998')
) v(categorie,date_pub,titre,texte,image_url)
where not exists (select 1 from actualites);
insert into documents (titre,fichier_url,taille)
select * from (values
  ('Rapport : État de l’éducation en CI (2024)','rapport-etat-education-ci-2024.pdf','PDF'),
  ('Guide méthodologique pour la recherche en éducation','guide-methodologique-recherche.pdf','PDF'),
  ('Revue AIRE – N°12 (2024)','revue-aire-n12-2024.pdf','PDF'),
  ('Modèle de projet de recherche','modele-projet-recherche.pdf','PDF'),
  ('L’inclusion scolaire : enjeux et perspectives','inclusion-scolaire-enjeux-perspectives.pdf','PDF')
) v(titre,fichier_url,taille)
where not exists (select 1 from documents);
insert into projets (titre,description,equipe,duree,statut,image_url,ordre)
select * from (values
  ('Évaluation des politiques éducatives en Côte d’Ivoire','Analyse des dispositifs et de leur impact sur la qualité de l’enseignement.','Dr Koffi A. et al.','2024 - 2026','En cours','1531482615713-2afd69097998',1),
  ('Inclusion et équité dans l’éducation','Étude sur l’accès et la rétention des élèves vulnérables.','Dr Koné M. et al.','2024 - 2026','En cours','1544717305-2782549b5136',2),
  ('Éducation numérique et innovation pédagogique','Impact des technologies numériques sur les pratiques pédagogiques.','M. Diana S. et al.','2025 - 2027','À venir','1532094349884-543bc11b234d',3)
) v(titre,description,equipe,duree,statut,image_url,ordre)
where not exists (select 1 from projets);
insert into equipe (role,nom,description,ordre)
select * from (values
  ('Président','Dr Koffi A.','Chercheur en sciences de l’éducation',1),
  ('Vice-présidente','Dr Koné M.','Enseignante-chercheuse',2),
  ('Secrétaire général','M. Diana S.','Spécialiste en politiques éducatives',3),
  ('Trésorière','Mme Bamba L.','Gestionnaire de projets',4)
) v(role,nom,description,ordre)
where not exists (select 1 from equipe);
insert into partenaires (icone,nom,ordre)
select * from (values
  ('🎓','Université Félix Houphouët-Boigny',1),
  ('🏛','Ministère de l’Éducation Nationale',2),
  ('🌍','UNESCO',3),
  ('🏦','Banque Mondiale',4),
  ('🤝','ONG & institutions internationales',5)
) v(icone,nom,ordre)
where not exists (select 1 from partenaires);
insert into publications (titre,image_url,fichier_url,ordre)
select * from (values
  ('Les politiques éducatives en Afrique','1497633762265-9d179a990aa6','politiques-educatives-afrique.pdf',1),
  ('Évaluation des apprentissages en Côte d’Ivoire','1524178232363-1fb2b075b655','evaluation-apprentissages-ci.pdf',2),
  ('La pédagogie active en contexte africain','1522202176988-66273c2fd55f','pedagogie-active-contexte-africain.pdf',3)
) v(titre,image_url,fichier_url,ordre)
where not exists (select 1 from publications);
insert into activites (icone,titre,texte,page,ordre)
select * from (values
  ('🔬','Recherche','Projets de recherche sur les politiques éducatives, les pratiques pédagogiques et l’enseignement.','activites',1),
  ('📖','Publications','Diffusion de revues, rapports et articles scientifiques pour une meilleure valorisation des connaissances.','ressources',2),
  ('🤝','Partenariats','Collaboration avec les universités, institutions publiques, ONG et partenaires internationaux.','apropos',3)
) v(icone,titre,texte,page,ordre)
where not exists (select 1 from activites);
