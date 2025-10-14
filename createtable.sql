-- Drop tables if they exist (dropping in order of dependencies)
DROP TABLE Louer CASCADE CONSTRAINTS;
DROP TABLE ReserverPrive CASCADE CONSTRAINTS;
DROP TABLE ReserverSoc CASCADE CONSTRAINTS;
DROP TABLE Vehicule CASCADE CONSTRAINTS;
DROP TABLE Client CASCADE CONSTRAINTS;
DROP TABLE Societe CASCADE CONSTRAINTS;
DROP TABLE Marque CASCADE CONSTRAINTS;
DROP TABLE Gamme CASCADE CONSTRAINTS;

-- Create tables with specified schema
CREATE TABLE MARQUE (
    CodeMA    NUMBER(3)    PRIMARY KEY,
    NomMA     VARCHAR2(50),
    PaysMA    VARCHAR2(50),
    DateCreationMA DATE
);

CREATE TABLE GAMME (
    CodeG     NUMBER(2)    PRIMARY KEY,
    NomG      VARCHAR2(50),
    PrixKM    NUMBER(6,2),
    PrixJour  NUMBER(6,2),
    PrixBase  NUMBER(6,2)
);

CREATE TABLE SOCIETE (
    CodeSoc   NUMBER(4)    PRIMARY KEY,
    NomSoc    VARCHAR2(100),
    RueSoc    VARCHAR2(100),
    CPSoc     VARCHAR2(5),
    VilleSoc  VARCHAR2(50)
);

CREATE TABLE CLIENT (
    CodeC     NUMBER(5)    PRIMARY KEY,
    NomC      VARCHAR2(50),
    PrenomC   VARCHAR2(50),
    RueC      VARCHAR2(100),
    CPC       VARCHAR2(5),
    VilleC    VARCHAR2(50),
    RegionC   VARCHAR2(50),
    CodeSoc   NUMBER(4),
    CONSTRAINT FK_Client_Soc FOREIGN KEY(CodeSoc) REFERENCES SOCIETE(CodeSoc)
);

CREATE TABLE VEHICULE (
    NoImmat   VARCHAR2(10) PRIMARY KEY,
    Modele    VARCHAR2(50),
    DateAchat DATE,
    CodeG     NUMBER(2)   NOT NULL,
    CodeMA    NUMBER(3)   NOT NULL,
    CONSTRAINT FK_Vehicule_Gamme FOREIGN KEY(CodeG) REFERENCES GAMME(CodeG),
    CONSTRAINT FK_Vehicule_Marque FOREIGN KEY(CodeMA) REFERENCES MARQUE(CodeMA)
);

CREATE TABLE RESERVERPRIVE (
    CodeC       NUMBER(5),
    DateDebClt  DATE,
    CodeG       NUMBER(2),
    DateFinClt  DATE,
    DateResa    DATE,
    CONSTRAINT PK_ResPrive PRIMARY KEY(CodeC, DateDebClt, CodeG),
    CONSTRAINT FK_ResPrive_Client FOREIGN KEY(CodeC) REFERENCES CLIENT(CodeC),
    CONSTRAINT FK_ResPrive_Gamme FOREIGN KEY(CodeG) REFERENCES GAMME(CodeG)
);

CREATE TABLE RESERVERSOC (
    CodeSoc     NUMBER(4),
    DateDebSoc  DATE,
    CodeG       NUMBER(2),
    DateFinSoc  DATE,
    DateResaSoc DATE,
    CONSTRAINT PK_ResSoc PRIMARY KEY(CodeSoc, DateDebSoc, CodeG),
    CONSTRAINT FK_ResSoc_Soc FOREIGN KEY(CodeSoc) REFERENCES SOCIETE(CodeSoc),
    CONSTRAINT FK_ResSoc_Gamme FOREIGN KEY(CodeG) REFERENCES GAMME(CodeG)
);

CREATE TABLE LOUER (
    CodeC      NUMBER(5),
    NoImmat    VARCHAR2(10),
    DateDebLoc DATE,
    DateFinLoc DATE,
    KmDeb      NUMBER(6),
    KmFin      NUMBER(6),
    CONSTRAINT PK_Louer PRIMARY KEY(CodeC, NoImmat, DateDebLoc),
    CONSTRAINT FK_Louer_Client FOREIGN KEY(CodeC) REFERENCES CLIENT(CodeC),
    CONSTRAINT FK_Louer_Vehicule FOREIGN KEY(NoImmat) REFERENCES VEHICULE(NoImmat)
);
