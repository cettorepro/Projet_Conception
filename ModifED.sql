-------------------------------------------------------------------------------
-- (FR) 0) Nettoyage idempotent : ne supprimer que l'objet à recréer (HISTORISER)
-------------------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE HISTORISER CASCADE CONSTRAINTS PURGE';
EXCEPTION
  WHEN OTHERS THEN
    -- ORA-00942 : table ou vue inexistante → on ignore
    IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

-------------------------------------------------------------------------------
-- (FR) 1) Création de HISTORISER
--      Convention : *#CodeG (PK + FK→GAMME), *Annee_Gamme (PK, pas de FK)
-------------------------------------------------------------------------------
CREATE TABLE HISTORISER (
  CodeG        NUMBER(10)   NOT NULL,      -- *#CodeG → GAMME(CodeG)
  Annee_Gamme  NUMBER(4)    NOT NULL,      -- *Annee_Gamme (clé de l'année, pas de FK)
  PrixKM       NUMBER(10,4) NOT NULL,
  PrixJour     NUMBER(10,2) NOT NULL,
  PrixBase     NUMBER(10,2) NOT NULL,
  CONSTRAINT PK_HISTORISER PRIMARY KEY (CodeG, Annee_Gamme),
  CONSTRAINT FK_HISTORISER_GAMME FOREIGN KEY (CodeG) REFERENCES GAMME(CodeG),
  CONSTRAINT CK_HISTORISER_ANNEE CHECK (Annee_Gamme BETWEEN 1900 AND 2100)
);

-------------------------------------------------------------------------------
-- (FR) 2) Migration des tarifs depuis GAMME vers HISTORISER
--      Par défaut, insertion pour 2023 ET 2024 (mêmes valeurs).
--      Si vous ne voulez qu'une année, commentez l'autre INSERT.
-------------------------------------------------------------------------------
INSERT INTO HISTORISER (CodeG, Annee_Gamme, PrixKM, PrixJour, PrixBase)
SELECT g.CodeG, 2023, g.PrixKM, g.PrixJour, g.PrixBase
  FROM GAMME g;

INSERT INTO HISTORISER (CodeG, Annee_Gamme, PrixKM, PrixJour, PrixBase)
SELECT g.CodeG, 2024, g.PrixKM, g.PrixJour, g.PrixBase
  FROM GAMME g;

COMMIT;

-------------------------------------------------------------------------------
-- (FR) 3) Suppression des colonnes de prix dans GAMME (structure cible = CodeG, NomG)
--      Bloques exception pour permettre les ré-exécutions (si déjà supprimées).
-------------------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE GAMME DROP COLUMN PrixKM';
EXCEPTION WHEN OTHERS THEN
  -- ORA-00904 : colonne inexistante → on ignore
  IF SQLCODE != -904 AND SQLCODE != -904 THEN NULL; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE GAMME DROP COLUMN PrixJour';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -904 THEN NULL; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE GAMME DROP COLUMN PrixBase';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -904 THEN NULL; END IF;
END;
/

-------------------------------------------------------------------------------
-- (FR) 4) RESERVERSOC : ajout et remplissage déterministe de NbReserver (1..3)
--      Méthode 100% reproductible : hachage déterministe des clés métier.
-------------------------------------------------------------------------------
-- 4.1 Ajouter la colonne (si elle n'existe pas déjà)
BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE RESERVERSOC ADD (NbReserver NUMBER(1))';
EXCEPTION
  WHEN OTHERS THEN
    -- ORA-01430 : la colonne existe déjà → on ignore
    IF SQLCODE != -1430 THEN RAISE; END IF;
END;
/

-- 4.2 Remplissage déterministe (stable à chaque exécution)
UPDATE RESERVERSOC
   SET NbReserver = 1
                    + MOD(
                        ORA_HASH(
                          TO_CHAR(CodeSoc)
                          || TO_CHAR(DateDebSoc, ''YYYYMMDD'')
                          || TO_CHAR(CodeG)
                        ),
                        3
                      );
COMMIT;

-- 4.3 Contraintes (rendre NOT NULL et borner à 1..3) ; ignorer si déjà en place
BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE RESERVERSOC MODIFY (NbReserver NOT NULL)';
EXCEPTION
  WHEN OTHERS THEN
    -- ORA-01442 : déjà NOT NULL → on ignore
    IF SQLCODE != -1442 THEN RAISE; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE
    'ALTER TABLE RESERVERSOC ADD CONSTRAINT CK_RS_NBRES CHECK (NbReserver BETWEEN 1 AND 3)';
EXCEPTION
  WHEN OTHERS THEN
    -- Nom de contrainte déjà utilisé / contrainte déjà existante → on ignore
    NULL;
END;
/

-------------------------------------------------------------------------------
-- (FR) 5) Vérifications (facultatif) : décommentez pour contrôler les volumes
-------------------------------------------------------------------------------
-- SELECT CodeG, Annee_Gamme, COUNT(*) AS n
--   FROM HISTORISER GROUP BY CodeG, Annee_Gamme ORDER BY CodeG, Annee_Gamme;
-- SELECT COUNT(*) FROM HISTORISER;                 -- attendu : nb(GAMME) × nb(années insérées)
-- SELECT MIN(NbReserver), MAX(NbReserver) FROM RESERVERSOC;  -- attendu : 1 et 3
