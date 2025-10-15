-- =====================================================================
-- Section 1: Table Creation
-- =====================================================================

-- Table: Marque (Brands)
-- Stores information about vehicle brands.
CREATE TABLE Marque (
    CodeMA          NUMBER(10)      NOT NULL,
    NomMA           VARCHAR2(20)    NOT NULL,
    PaysMA          VARCHAR2(40),
    DateCreationMA  DATE,
    CONSTRAINT pk_marque PRIMARY KEY (CodeMA)
);

-- Table: Gamme (Vehicle Ranges/Categories)
-- Stores different vehicle categories and their pricing.
CREATE TABLE Gamme (
    CodeG           NUMBER(10)      NOT NULL,
    NomG            VARCHAR2(20)    NOT NULL,
    PrixKM          NUMBER(10, 2)   NOT NULL,
    PrixJour        NUMBER(10, 2)   NOT NULL,
    PrixBase        NUMBER(10, 2)   NOT NULL,
    CONSTRAINT pk_gamme PRIMARY KEY (CodeG)
);

-- Table: Societe (Companies)
-- Stores information about corporate clients.
CREATE TABLE Societe (
    CodeSoc         VARCHAR2(14)    NOT NULL,
    NomSoc          VARCHAR2(50)    NOT NULL,
    RueSoc          VARCHAR2(50),
    CPSoc           VARCHAR2(5),
    VilleSoc        VARCHAR2(50),
    CONSTRAINT pk_societe PRIMARY KEY (CodeSoc)
);

-- Table: Vehicule (Vehicles)
-- Stores details of each individual vehicle in the fleet.
CREATE TABLE Vehicule (
    NoImmat         VARCHAR2(9)     NOT NULL,
    Modele          VARCHAR2(20)    NOT NULL,
    DateAchat       DATE,
    CodeG           NUMBER(10)      NOT NULL,
    CodeMA          NUMBER(10)      NOT NULL,
    CONSTRAINT pk_vehicule PRIMARY KEY (NoImmat)
);

-- Table: Client (Customers)
-- Stores information about individual customers.
CREATE TABLE Client (
    CodeC           NUMBER(10)      NOT NULL,
    NomC            VARCHAR2(50)    NOT NULL,
    PrenomC         VARCHAR2(30),
    RueC            VARCHAR2(50),
    CPC             VARCHAR2(5),
    VilleC          VARCHAR2(50),
    RegionC         VARCHAR2(50),
    CodeSoc         VARCHAR2(14),
    CONSTRAINT pk_client PRIMARY KEY (CodeC)
);

-- Table: Louer (Rentals)
-- Transactional table for actual vehicle rentals.
-- Composite PK ensures a client cannot rent the same car starting on the exact same date.
CREATE TABLE Louer (
    CodeC           NUMBER(10)      NOT NULL,
    NoImmat         VARCHAR2(9)     NOT NULL,
    DateDebLoc      DATE            NOT NULL,
    DateFinLoc      DATE,
    KmDeb           NUMBER(10)      NOT NULL,
    KmFin           NUMBER(10),
    CONSTRAINT pk_louer PRIMARY KEY (CodeC, NoImmat, DateDebLoc)
);

-- Table: ReserverPrive (Private Reservations)
-- Transactional table for reservations made by individual clients.
CREATE TABLE ReserverPrive (
    CodeC           NUMBER(10)      NOT NULL,
    DateDebClt      DATE            NOT NULL,
    CodeG           NUMBER(10)      NOT NULL,
    DateFinClt      DATE,
    DateResa        DATE,
    CONSTRAINT pk_reserverprive PRIMARY KEY (CodeC, DateDebClt, CodeG)
);

-- Table: ReserverSoc (Corporate Reservations)
-- Transactional table for reservations made by companies.
CREATE TABLE ReserverSoc (
    CodeSoc         VARCHAR2(14)    NOT NULL,
    DateDebSoc      DATE            NOT NULL,
    CodeG           NUMBER(10)      NOT NULL,
    DateFinSoc      DATE,
    DateResaSoc     DATE,
    CONSTRAINT pk_reserversoc PRIMARY KEY (CodeSoc, DateDebSoc, CodeG)
);

-- =====================================================================
-- Section 2: Integrity Constraints (Foreign Keys & Checks)
-- =====================================================================

-- Foreign Key Constraints
ALTER TABLE Vehicule 
    ADD CONSTRAINT fk_vehicule_gamme FOREIGN KEY (CodeG) REFERENCES Gamme(CodeG);
ALTER TABLE Vehicule 
    ADD CONSTRAINT fk_vehicule_marque FOREIGN KEY (CodeMA) REFERENCES Marque(CodeMA);
ALTER TABLE Client 
    ADD CONSTRAINT fk_client_societe FOREIGN KEY (CodeSoc) REFERENCES Societe(CodeSoc);
ALTER TABLE Louer 
    ADD CONSTRAINT fk_louer_client FOREIGN KEY (CodeC) REFERENCES Client(CodeC);
ALTER TABLE Louer 
    ADD CONSTRAINT fk_louer_vehicule FOREIGN KEY (NoImmat) REFERENCES Vehicule(NoImmat);
ALTER TABLE ReserverPrive 
    ADD CONSTRAINT fk_reserverprive_client FOREIGN KEY (CodeC) REFERENCES Client(CodeC);
ALTER TABLE ReserverPrive 
    ADD CONSTRAINT fk_reserverprive_gamme FOREIGN KEY (CodeG) REFERENCES Gamme(CodeG);
ALTER TABLE ReserverSoc 
    ADD CONSTRAINT fk_reserversoc_societe FOREIGN KEY (CodeSoc) REFERENCES Societe(CodeSoc);
ALTER TABLE ReserverSoc 
    ADD CONSTRAINT fk_reserversoc_gamme FOREIGN KEY (CodeG) REFERENCES Gamme(CodeG);

-- Check Constraints (Business Rules Enforcement)

-- Marque Table Constraints
ALTER TABLE Marque 
    ADD CONSTRAINT chk_marque_datecreation CHECK (DateCreationMA <= SYSDATE);
ALTER TABLE Marque 
    ADD CONSTRAINT chk_marque_nomma_enum CHECK (NomMA IN 
        ('Abarth', 'Alfa Romeo', 'Alpine', 'Aston Martin', 'Audi', 'Austin', 'Austin Healey', 
         'Bentley', 'BMW', 'Cadillac', 'Chatenet', 'Chevrolet', 'Chrysler', 'Citroen', 'Cupra', 
         'Dacia', 'Dodge', 'DS', 'Ferrari', 'Fiat', 'Ford', 'G.M.C', 'Honda', 'Ineos', 'Innocenti', 
         'Isuzu', 'Iveco', 'Jaguar', 'Jeep', 'Kia', 'Lada', 'Lamborghini', 'Lancia', 'Land Rover', 
         'Lexus', 'Lincoln', 'Lotus', 'Maserati', 'Mazda', 'McLaren', 'Mercedes', 'MG', 'Mini', 
         'Mitsubishi', 'Morgan', 'Nissan', 'Opel', 'Peugeot', 'Porsche', 'Renault', 'Rolls Royce', 
         'Saab', 'Seat', 'Skoda', 'Smart', 'Subaru', 'Sunbeam', 'Suzuki', 'Tesla', 'Toyota', 'Triumph', 
         'Volkswagen', 'Volvo', 'Xpeng'));

-- Gamme Table Constraints
ALTER TABLE Gamme 
    ADD CONSTRAINT chk_gamme_prixkm CHECK (PrixKM > 0);
ALTER TABLE Gamme 
    ADD CONSTRAINT chk_gamme_prixjour CHECK (PrixJour > 0);
ALTER TABLE Gamme 
    ADD CONSTRAINT chk_gamme_prixbase CHECK (PrixBase > 0);
ALTER TABLE Gamme 
    ADD CONSTRAINT chk_gamme_nomg_enum CHECK (NomG IN 
        ('citadine', 'compacte', 'grande', 'monospace', '3m³', '6m³', '9m³', '12m³', '20m³'));

-- Vehicule Table Constraints
ALTER TABLE Vehicule 
    ADD CONSTRAINT chk_vehicule_dateachat CHECK (DateAchat <= SYSDATE);
ALTER TABLE Vehicule 
    ADD CONSTRAINT chk_vehicule_modele_enum CHECK (Modele IN 
        ('SUV', 'Berline', 'Break', 'Cabriolet', 'Citadine', 'Collection', 'Coupé', 
         'Monospace', 'Pick-Up', 'Utilitaires', 'Voiture de société', 'Voiture sans permis'));
-- Enforces license plate format: LL-NNN-LL (e.g., AB-123-CD)
ALTER TABLE Vehicule 
    ADD CONSTRAINT chk_vehicule_noimmat_format CHECK (REGEXP_LIKE(NoImmat, '^[A-Z]{2}-[0-9]{3}-[A-Z]{2}$'));

-- Client Table Constraints
ALTER TABLE Client 
    ADD CONSTRAINT chk_client_regionc_enum CHECK (RegionC IN 
        ('Auvergne-Rhône-Alpes', 'Bourgogne-Franche-Comté', 'Bretagne', 'Centre-Val de Loire', 
         'Corse', 'Grand Est', 'Hauts-de-France', 'Île-de-France', 'Normandie', 
         'Nouvelle-Aquitaine', 'Occitanie', 'Pays de la Loire', 'Provence-Alpes-Côte d’Azur', 
         'Guadeloupe', 'Martinique', 'Guyane', 'La Réunion', 'Mayotte'));

-- Louer Table Constraints
-- End date must be after or same as start date. Allows NULL for ongoing rentals.
ALTER TABLE Louer 
    ADD CONSTRAINT chk_louer_dates CHECK (DateFinLoc IS NULL OR DateFinLoc >= DateDebLoc);
-- End mileage must be greater than start mileage. Allows NULL for ongoing rentals.
ALTER TABLE Louer 
    ADD CONSTRAINT chk_louer_km CHECK (KmFin IS NULL OR KmFin > KmDeb);
ALTER TABLE Louer 
    ADD CONSTRAINT chk_louer_kmdeb_positif CHECK (KmDeb > 0);

-- ReserverPrive Table Constraints
ALTER TABLE ReserverPrive 
    ADD CONSTRAINT chk_reserverprive_dates_resa CHECK (DateDebClt >= DateResa);
ALTER TABLE ReserverPrive 
    ADD CONSTRAINT chk_reserverprive_dates_loc CHECK (DateFinClt >= DateDebClt);

-- ReserverSoc Table Constraints
ALTER TABLE ReserverSoc 
    ADD CONSTRAINT chk_reserversoc_dates_resa CHECK (DateDebSoc >= DateResaSoc);
ALTER TABLE ReserverSoc 
    ADD CONSTRAINT chk_reserversoc_dates_loc CHECK (DateFinSoc >= DateDebSoc);
