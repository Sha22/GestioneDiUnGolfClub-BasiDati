CREATE TABLE ERRORI(
Errore VARCHAR(100) NOT NULL ,
Codice TINYINT NOT NULL AUTO_INCREMENT PRIMARY KEY);
 
CREATE TABLE PERSONE(
NumeroTessera SMALLINT NOT NULL PRIMARY KEY,
Nome VARCHAR(30) NOT NULL,
Cognome VARCHAR(30) NOT NULL,
Età TINYINT NOT NULL,
CF CHAR(20) NOT NULL UNIQUE,
Telefono VARCHAR(20) NOT NULL, 
Tipo VARCHAR(9) NOT NULL CHECK (Tipo IN ('Socio','Non Socio')),
Handicap TINYINT,
CartaID CHAR(10),
QuotaSociale SMALLINT
);
CREATE TABLE GARA(
NomeGara VARCHAR(30) NOT NULL PRIMARY KEY,
Sponsor VARCHAR(30) REFERENCES SPONSOR(Azienda),
NumeroIscritti NUMERIC(2),
Data DATE NOT NULL,
Sede TINYINT NOT NULL REFERENCES SEDE(Codice)
);
CREATE TABLE ISCRIZIONE(
Persona SMALLINT NOT NULL REFERENCES PERSONE(NumeroTessera),
Gara VARCHAR(30) NOT NULL REFERENCES GARA(NomeGara),
PRIMARY KEY (Persona, Gara)
);
CREATE TABLE SPONSOR(
Azienda VARCHAR(30) NOT NULL PRIMARY KEY,
Sede VARCHAR(30) ,
Referente VARCHAR(30),
Telefono VARCHAR(20) NOT NULL
);
CREATE TABLE SEDE(
Codice TINYINT NOT NULL PRIMARY KEY,
Indirizzo VARCHAR(30) NOT NULL,
Telefono VARCHAR(20) NOT NULL,
Email VARCHAR(30)
);
CREATE TABLE BUCHE(
Numero TINYINT NOT NULL,
Sede TINYINT NOT NULL REFERENCES SEDE(Codice),
Bunker TINYINT DEFAULT 0,
Ostacoliacqua TINYINT DEFAULT 0,
Lunghezza TINYINT NOT NULL,
Par TINYINT NOT NULL,
PRIMARY KEY (Numero, Sede)
);
CREATE TABLE PRENOTAZIONE(
Nominativo SMALLINT NOT NULL REFERENCES PERSONE(NumeroTessera),
Sede TINYINT NOT NULL REFERENCES SEDE(Codice),
Datapr DATE NOT NULL,
Orapr TIME(1) NOT NULL,
Greenfee TINYINT DEFAULT 10,
PRIMARY KEY(Datapr,Orapr,Sede)
);
CREATE TABLE DISPONIBILE(
ID  SMALLINT NOT NULL,
Categoria VARCHAR(30) NOT NULL REFERENCES CATEGORIA(Tipo),
Sede TINYINT NOT NULL REFERENCES SEDE(Codice),
PRIMARY KEY (ID, Categoria)
);
CREATE TABLE NONDISPONIBILE(
ID SMALLINT NOT NULL,
Categoria VARCHAR(30) NOT NULL REFERENCES CATEGORIA(Tipo),
Sede TINYINT NOT NULL  REFERENCES SEDE(Codice),
PRIMARY KEY (ID, Categoria)
);
CREATE TABLE CATEGORIA(
Tipo VARCHAR(30) NOT NULL PRIMARY KEY,
Tariffa SMALLINT NOT NULL,
Quantità TINYINT DEFAULT 0
);
CREATE TABLE NOLEGGIO(
Oggetto SMALLINT NOT NULL REFERENCES NONDISPONIBILE(ID),
Categoria VARCHAR(30) NOT NULL  REFERENCES CATEGORIA(Tipo),
Nominativo SMALLINT NOT NULL REFERENCES PERSONE(NumeroTessera),
Datanol DATE NOT NULL,
Oranol TIME(1) NOT NULL,
PRIMARY KEY (Oggetto, Categoria, Datanol, Oranol)
);




DROP FUNCTION IF  EXISTS Totale; 
DELIMITER |
CREATE FUNCTION Totale (NumeroTessera SMALLINT) RETURNS SMALLINT
BEGIN                                                                
DECLARE Imp SMALLINT;
DECLARE Tar SMALLINT;   
SELECT  SUM(p.Greenfee) into Imp FROM PRENOTAZIONE p WHERE p.Nominativo=NumeroTessera;                                  
SELECT SUM(c.Tariffa) into Tar FROM NOLEGGIO n JOIN CATEGORIA c ON n.Categoria=c.Tipo WHERE n.Nominativo=NumeroTessera;                        
RETURN Tar + Imp;
END | 
DELIMITER ;




DROP FUNCTION IF EXISTS Lungh; 
DELIMITER | 
CREATE FUNCTION Lungh (Sede TINYINT) RETURNS SMALLINT 
BEGIN
DECLARE TotLung SMALLINT; 
SELECT SUM(b.Lunghezza) INTO TotLung FROM SEDE s JOIN BUCHE b ON s.Codice=b.Sede WHERE s.Codice=Sede; RETURN TotLung; 
END| 
DELIMITER ;
DROP FUNCTION IF EXISTS OggettiRimasti;
DELIMITER |
CREATE FUNCTION OggettiRimasti (Sede TINYINT, Categoria VARCHAR(30) )  RETURNS SMALLINT
BEGIN
DECLARE Conto SMALLINT;
SELECT COUNT(d.ID) INTO Conto FROM DISPONIBILE d WHERE  d.Categoria=Categoria && d.Sede=Sede;
RETURN Conto;
END|
DELIMITER ;




DROP TRIGGER IF EXISTS Nominorenni;
DELIMITER |
CREATE TRIGGER Nominorenni
BEFORE INSERT ON PERSONE
FOR EACH ROW
BEGIN
IF(NEW.Tipo='Socio' AND NEW.Età<18)
THEN INSERT INTO ERRORI (Errore)
VALUE ('Non si può registrare un minorenne come socio');
SET NEW.Tipo='Non Socio';
END IF;
END |
DELIMITER ;




DROP TRIGGER IF EXISTS Aggiornamentoiscritti;
DELIMITER |
CREATE TRIGGER Aggiornamentoiscritti AFTER INSERT ON ISCRIZIONE
FOR EACH ROW
BEGIN
UPDATE GARA g SET g.NumeroIscritti=g.NumeroIscritti+1 WHERE g.NomeGara=NEW.Gara;
END |
DELIMITER ;




DROP TRIGGER IF EXISTS NoGreenFeeDieciMin;
DELIMITER |
CREATE TRIGGER NoGreenFeeDieciMin
BEFORE INSERT ON PRENOTAZIONE
FOR EACH ROW
BEGIN
DECLARE Age TINYINT;
DECLARE TipoCliente VARCHAR(9);
        DECLARE Time TIME(1);
SELECT p.Età INTO Age FROM  PERSONE p WHERE p.NumeroTessera=NEW.Nominativo; 
SELECT  g.Tipo into TipoCliente FROM  PERSONE g WHERE g.NumeroTessera=NEW.Nominativo; 
IF (Age<18 OR TipoCliente='Socio')
THEN
set NEW.Greenfee=0;
END IF;
          SELECT MAX(Orapr) INTO Time
FROM PRENOTAZIONE WHERE NEW.Sede=Sede;
IF (TIMEDIFF(Time, NEW.Orapr) < 10)
THEN
INSERT INTO ERRORI (Errore)
VALUES ('Troppo vicino: bisogna aspettare che siano passati 10 minuti dal cliente precedente');
END IF;
END | 
DELIMITER ; 




INSERT INTO PERSONE(NumeroTessera,Nome,Cognome,Età,CF,Telefono,Tipo,Handicap,CartaID,QuotaSociale) VALUES (15, 'Paolo', 'Biancotti', 21, 'BNCPLA94B13F163D', '0498215126', 'Socio', 32, 'AV2987346', 450), (102, 'Chiara', 'Panozzo', 40, 'PNZCHR75C23J018Q', '0498232054', 'Non Socio', 40, NULL, NULL), (120, 'Pietro', 'Meneghello', 45, 'MNGPTR70T98B287S', '0498287121', 'Socio', 14, 'AV8421656', 450),(90, 'Giuseppe', 'Torquato', 16, 'TRQGSP99M14P513Z', '0493425019305', 'Non Socio', NULL, NULL, NULL), (237, 'Anna', 'Rizzotto', 15, 'RZZNNA00N66L091X', '0493420523124', 'Non Socio', NULL, NULL, NULL),(135, 'Carlo', 'Torrente', 32, 'TRRCRL83R36V229F', '0498236687', 'Socio', 33, 'AV0217532', 450);




INSERT INTO GARA (NomeGara,Sponsor,NumeroIscritti,Data,Sede)
VALUES ('Batti il record 2015', 'CoppaBlu', 32, "2015-03-12", 01),('Pallabianca', 'Golf Veneto', 44, "2015-03-13", 02), ('Campi da sogno', 'Golfpertutti', 40, "2015-03-19",03),('Sportlibero', 'Passione golf', 38, "2015-03-05", 02), ('Coppayoung', 'CoppaBlu', 22, "2015-03-04", 01), ('Tuttiinpalla', 'Coppablu', 15, "2015-03-20", 01);




INSERT INTO SPONSOR (Azienda,Sede,Referente,Telefono)
VALUES ('CoppaBlu', 'Porta Nuova 3', 'Felice Frosin', '0493429862258'), ('Golf Veneto', 'XV Novembre 7', 'Rosa Polga', '049858520'),('Golfpertutti', 'Bonaventura 16', 'Maria Viviani', '0498284413'),('Passione golf', 'Portorico 34', 'Alessandro Mastroianni', '0498296019');




INSERT INTO SEDE (Codice,Indirizzo,Telefono,Email)
VALUES (01, 'Pallanza 3', '0498225192', 'golfPallanza@gmail.com'),
(02, 'Novena 16', '0498283348', 'golfNovena@gmail.com'), (03, 'Luigi XV 2', '0498222522', 'golfLuigiXV@gmail.com'), (04, 'Torinesi 16', '0498284413', 'golfLuigiXV@gmail.com'),(05, 'Borsellino 5', '0498237949', 'golfBorsellino@gmail.com');




INSERT INTO BUCHE (Numero,Sede,Bunker,Ostacoliacqua,Lunghezza,Par)
VALUES (1, 01, 0, 0, 10, 3),(2, 01, 1, 0, 11, 4), (3, 01, 0, 0, 15, 5), (4, 01, 0, 1, 15, 3), (5, 01, 0, 0, 10, 3),(6, 01, 0, 0, 14, 4), (7, 01, 0, 0, 20, 5), (8, 01, 1, 0, 16, 3), (9, 01, 0, 0, 15, 5), (10, 01, 0, 0, 23, 3),(11, 01, 0, 0, 12, 5), (12, 01, 0, 0, 18, 3),(13, 01, 2, 0, 16, 4), (14, 01, 0, 0, 21, 3),(15, 01, 0, 0, 11, 3),(16, 01, 0, 0, 28, 4),(17, 01, 1, 1, 22, 5),(18, 01, 0, 1, 16, 3), (1, 02, 0, 0, 12, 4),(2, 02, 0, 0, 10, 3),(3, 02, 0, 1, 14, 5), (4, 02, 0, 1, 16, 5), (5, 02, 0, 1, 10, 4),(6, 02, 0, 0, 14, 4), (7, 02, 0, 0, 22, 3),(8, 02, 3, 0, 16, 5), (9, 02, 0, 0, 21, 4), (10, 02, 0, 1, 20, 3),(11, 02, 1, 1, 12, 4), (12, 02, 0, 0, 23, 4),(13, 02, 0, 0, 21, 3),(14, 02, 0, 1, 12, 3), (15, 02, 0, 0, 22, 4), (16, 02, 2, 0, 20, 5), (17, 02, 1, 1, 30, 3),(18, 02, 0, 0, 32, 3), (1, 03, 0, 0, 15, 5), (2, 03, 1, 1, 11, 5), (3, 03, 0, 0, 16, 5), (4, 03, 0, 0, 18, 4), (5, 03, 0, 0, 17, 5), (6, 03, 1, 1, 12, 3),(7, 03, 0, 1, 22, 4), (8, 03, 0, 0, 15, 5), (9, 03, 0, 0, 17, 3), (10, 03, 1, 0, 22, 5), (11, 03, 1, 0, 20, 4), (12, 03, 0, 0, 17, 5), (13, 03, 1, 0, 18, 3), (14, 03, 0, 0, 15, 5), (15, 03, 0, 0, 13, 4),(16, 03, 0, 0, 23, 3), (17, 03, 0, 0, 19, 4), (18, 03, 0, 0, 16, 5),(1, 04, 2, 0, 22, 3), (1, 05, 0, 0, 12, 4);




INSERT INTO CATEGORIA (Tipo,Tariffa,Quantità) VALUES ( 'mazza', 8, 30), ( 'golf car', 80, 6), ( 'carrello manuale', 12, 70), ( 'set palline', 5, 200); 








INSERT INTO DISPONIBILE (ID,Categoria,Sede)
VALUES (1, 'mazza', 01), (2, 'mazza', 01), (4, 'mazza', 01),(5, 'mazza', 01), (6, 'mazza', 02), (7, 'mazza', 02), (8, 'mazza', 02), (9, 'mazza', 02),(10, 'mazza', 02),(12, 'mazza', 03),(13, 'mazza', 03), (14, 'mazza', 03),(15, 'mazza', 03),(16, 'mazza', 04), (17, 'mazza', 04),(18, 'mazza', 04),(19, 'mazza', 04), (20, 'mazza', 04), (21, 'mazza', 05), (22, 'mazza', 05), (23, 'mazza', 05), (25, 'mazza', 05), (1, 'carrello manuale', 01), (2, 'carrello manuale', 01), (3, 'carrello manuale', 01),(4, 'carrello manuale', 01),(5, 'carrello manuale', 01),(6, 'carrello manuale', 02), (7, 'carrello manuale', 02),(9, 'carrello manuale', 02), (10, 'carrello manuale', 02), (11, 'carrello manuale', 03),(12, 'carrello manuale', 03), (13, 'carrello manuale', 03), (14, 'carrello manuale', 03),(16, 'carrello manuale', 04), (17, 'carrello manuale', 04), (18, 'carrello manuale', 04),(19, 'carrello manuale', 04), (20, 'carrello manuale', 04),(21, 'carrello manuale', 05), (22, 'carrello manuale', 05), (23, 'carrello manuale', 05), (24, 'carrello manuale', 05),(25, 'carrello manuale', 05), (2, 'golf car', 01), (3, 'golf car', 01), (4, 'golf car', 01),(5, 'golf car', 01), (6, 'golf car', 02), (7, 'golf car', 02), (8, 'golf car', 02),(9, 'golf car', 02),(10, 'golf car', 02), (11, 'golf car', 03), (12, 'golf car', 03), (13, 'golf car', 03),(14, 'golf car', 03), (15, 'golf car', 03), (16, 'golf car', 04), (17, 'golf car', 04), (18, 'golf car', 04), (19, 'golf car', 04), (20, 'golf car', 04),(22, 'golf car', 05),(23, 'golf car', 05), (24, 'golf car', 05), (25, 'golf car', 05), (1, 'set palline', 01), (4, 'set palline', 01), (5, 'set palline', 01),(6, 'set palline', 02), (7, 'set palline', 02),(8, 'set palline', 02), (9, 'set palline', 02), (10, 'set palline', 02), (12, 'set palline', 03),(13, 'set palline', 03),(15, 'set palline', 03),(16, 'set palline', 04),(17, 'set palline', 04), (18, 'set palline', 04), (19, 'set palline', 04), (20, 'set palline', 04), (21, 'set palline', 05), (22, 'set palline', 05),(23, 'set palline', 05), (24, 'set palline', 05),(25, 'set palline', 05);




INSERT INTO NONDISPONIBILE (ID,Categoria,Sede) 
VALUES (11, 'mazza', 03), (3, 'mazza', 01), (24, 'mazza', 05), (8, 'carrello manuale', 02), (15, 'carrello manuale', 03), (1, 'golf car', 01), (21, 'golf car', 05), (2, 'set palline', 01), (3, 'set palline', 01), (11, 'set palline', 03), (14, 'set palline', 03);




INSERT INTO ISCRIZIONE (Persona,Gara)
VALUES (102, 'Pallabianca'),(90, 'Campi da sogno'),(90, 'Batti il record 2015'), (135, 'Pallabianca'), (237, 'Campi da sogno');




INSERT INTO PRENOTAZIONE (Nominativo,Sede,Datapr,Orapr,Greenfee)VALUES (15 ,01, "2015-03-07",'08:25:00', 10),(90 ,01, "2015-03-07",'09:10:00', 10), (102 ,02, "2015-03-07",'09:30:00', 10), (135 ,03, "2015-03-07",'09:10:00', 10), (120 ,03, "2015-03-07",'09:35:00', 10), (237 ,05, "2015-03-07",'10:15:00', 10);


INSERT INTO NOLEGGIO (Oggetto,Categoria,Nominativo,Datanol,Oranol)
VALUES (3, 'mazza', 15, "2015-03-07",'08:25:00'), (2, 'set palline', 15, "2015-03-07",'08:25:00'), (3, 'set palline', 15, "2015-03-07",'08:25:00'), (1, 'golf car', 90, "2015-03-07",'09:10:00'), (8, 'carrello manuale', 102, "2015-03-07",'09:20:00'), (11, 'set palline', 135, "2015-03-07",'09:10:00'),(14, 'set palline', 135, "2015-03-07",'09:10:00'), (11, 'mazza', 120, "2015-03-07",'09:35:00'), (15, 'carrello manuale', 120, "2015-03-07",'09:35:00'),(24, 'mazza', 237, "2015-03-07",'10:15:00'),(21, 'golf car', 237, "2015-03-07",'10:15:00');




SELECT d.ID FROM SEDE s JOIN DISPONIBILE d ON d.Sede=s.Codice  WHERE d.Categoria='Golf car' && s.Indirizzo='Pallanza 3'; 




SELECT * FROM BUCHE WHERE Sede=1 ORDER BY Numero ;  




SELECT g.NumeroIscritti, s.Azienda, s.Sede, s.Referente, s.Telefono                        FROM GARA g JOIN SPONSOR s ON g.Sponsor=s.Azienda WHERE g.NomeGara=         'Pallabianca';




SELECT pe.Nome, pe.Cognome, pe.Telefono, pr.Sede, COUNT(*) AS NumVolte from  PERSONE pe JOIN PRENOTAZIONE pr ON pe.NumeroTessera=pr.Nominativo GROUP BY NumeroTessera; 




CREATE VIEW NumGarSpons (Sponsorizzazione, Quantità) AS SELECT g.Sponsor, count(*) FROM GARA g GROUP BY g.Sponsor; SELECT Sponsorizzazione, Quantità  FROM NumGarSpons WHERE Quantità= (SELECT MAX(Quantità) FROM NumGarSpons); 




SELECT NumeroTessera,Nome,Cognome,Tipo FROM PERSONE WHERE NumeroTessera NOT IN (SELECT Persona FROM ISCRIZIONE) UNION SELECT NumeroTessera,Nome,Cognome,Tipo FROM PERSONE WHERE NumeroTessera NOT IN (SELECT Nominativo FROM PRENOTAZIONE);