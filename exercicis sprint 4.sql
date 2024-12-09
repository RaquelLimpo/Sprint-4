#					*****Nivell 1*****
#Descàrrega els arxius CSV, estudia'ls i dissenya una base de dades amb un esquema d'estrella que contingui,
# almenys 4 taules de les quals puguis realitzar les següents consultes:

-- Creamos la base de datos
CREATE DATABASE IF NOT EXISTS transactions_s4;
USE transactions_s4;
-- buscamos la carpeta donde colocar los archivos csv
SHOW VARIABLES LIKE 'secure_file_priv';

    -- Creamos la tabla companies y la cargamos 
#companies
CREATE TABLE IF NOT EXISTS companies (
	company_id VARCHAR(15) PRIMARY KEY,
	company_name VARCHAR(255),
	phone VARCHAR(15),
	email VARCHAR(100),
	country VARCHAR(100),
	website VARCHAR(255)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/companies.csv'
INTO TABLE companies
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS ;

#comprobamos que se ha cargado la tabla
SELECT * FROM transactions_s4.companies;

    -- Creamos la tabla credit_cards y la cargamos 
#credit_cards
CREATE TABLE credit_cards (
	id VARCHAR(20) PRIMARY KEY,
	user_id VARCHAR(20) NOT NULL,
	iban VARCHAR(50) NOT NULL,
	pan VARCHAR(50) NOT NULL,
	pin VARCHAR(4) NOT NULL,
	cvv SMALLINT NOT NULL,
	track1 VARCHAR(255),
	track2 VARCHAR(255),
	expiring_date VARCHAR(20) NOT NULL
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/credit_cards.csv'
INTO TABLE credit_cards
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

#comprobamos que se ha cargado la tabla
SELECT * FROM transactions_s4.credit_cards;

   -- Creamos la tabla products y la cargamos
CREATE TABLE IF NOT EXISTS products (
	id VARCHAR(20) PRIMARY KEY,
	product_name VARCHAR(255),
	price DECIMAL (10,2),
    	colour VARCHAR(20),
   	 weight VARCHAR(20),
	warehouse_id VARCHAR(20)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, product_name, @price_raw, colour, weight, warehouse_id)
SET price = REPLACE(@price_raw, '$', '');

#comprobamos que se ha cargado la tabla
SELECT * FROM transactions_s4.products;

   -- Creamos la tabla users y la cargamos 
CREATE TABLE IF NOT EXISTS users (
	id VARCHAR(20) PRIMARY KEY,
	name VARCHAR(100),
	surname VARCHAR(100),
	phone VARCHAR(150),
	email VARCHAR(150),
	birth_date VARCHAR(100),
	country VARCHAR(150),
	city VARCHAR(150),
	postal_code VARCHAR(100),
	address VARCHAR(255)
    );
    
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_ca.csv'
INTO TABLE users
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_uk.csv'
INTO TABLE users
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_usa.csv'
INTO TABLE users
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;
#comprobamos que se ha cargado la tabla unificada users
SELECT * FROM transactions_s4.users;

   -- Creamos la tabla transactions y la cargamos 
CREATE TABLE IF NOT EXISTS transactions (
	id VARCHAR(255) PRIMARY KEY,
	card_id VARCHAR(15) ,
	business_id VARCHAR(15), 
    	timestamp TIMESTAMP,
	amount DECIMAL(10,2),
	declined BOOLEAN,
	product_ids VARCHAR(25),
	user_id VARCHAR(5),
	lat FLOAT,
	longitude FLOAT,
	FOREIGN KEY (business_id) REFERENCES companies(company_id), 
	FOREIGN KEY (card_id) REFERENCES credit_cards(id),
	FOREIGN KEY (user_id) REFERENCES users(id)
    );
    
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/transactions.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ';' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
#comprobamos que se ha cargado la tabla
SELECT * FROM transactions_s4.transactions;

#Creamos los indices: 
CREATE INDEX idx_companies
	ON transactions(business_id);
    
CREATE INDEX idx_credit_cards
	ON transactions(card_id);
    
CREATE INDEX idx_users
	ON transactions(user_id);
    
#Exercici 1: #Realitza una subconsulta que mostri tots els usuaris amb més de 30 transaccions
#utilitzant almenys 2 taules.

SELECT users.id, name, surname
FROM users
WHERE id IN (SELECT user_id 
             FROM transactions
             GROUP BY user_id
             HAVING COUNT(id)>30)
ORDER BY users.id ASC; 

#opcion join
SELECT 
    users.id, name, surname,
    COUNT(transactions.id) AS num_transacciones
FROM users
JOIN transactions 
    ON users.id = user_id
GROUP BY users.id, name, surname
HAVING num_transacciones > 30;

#Exercici 2: Mostra la mitjana d'amount per IBAN de les targetes de crèdit a la companyia Donec Ltd, 
#utilitza almenys 2 taules.

SELECT iban,company_name,
   ROUND(AVG(amount),2)AS average_amount
   FROM credit_cards 
JOIN transactions 
	ON credit_cards.id = card_id
JOIN companies
	ON business_id = company_id
WHERE company_name = 'Donec Ltd'
GROUP BY iban;


#					*****Nivell 2*****
#Exercici 1: Crea una nova taula que reflecteixi l'estat de les targetes de crèdit 
#basat en si les últimes tres transaccions van ser declinades i genera la següent consulta:
#Quantes targetes estan actives?

CREATE TABLE credit_card_status (
    card_id VARCHAR(15) PRIMARY KEY,
    status VARCHAR(15) NOT NULL
);
ALTER TABLE credit_cards
ADD FOREIGN KEY (id) REFERENCES credit_card_status (card_id);


INSERT INTO credit_card_status (card_id, status)
SELECT 
    transactions.card_id,
    CASE 
        WHEN SUM(CASE WHEN declined THEN 1 ELSE 0 END) = 3 THEN 'Inactiva'
        ELSE 'Activa'
    END AS status
FROM (
    SELECT card_id, declined
    FROM transactions
    ORDER BY timestamp DESC
) transactions
GROUP BY card_id;

SELECT * FROM transactions_s4.credit_card_status;

SELECT COUNT(*) AS active_cards
FROM credit_card_status
WHERE status = 'activa';


#				*****Nivell 3*****
#Exercici 1: Necessitem conèixer el nombre de vegades que s'ha venut cada producte.
CREATE TABLE bridge_products (
	transactions_id VARCHAR(100),
	products_id VARCHAR(100),
	FOREIGN KEY (transactions_id) REFERENCES transactions(id),
    	FOREIGN KEY (products_id) REFERENCES products(id),
    	primary key(transactions_id, products_id));

INSERT INTO bridge_products (transactions_id, products_id) 
SELECT transactions.id AS transactions_id, products.id AS products_id
FROM transactions
JOIN products
ON FIND_IN_SET(products.id, REPLACE(transactions.product_ids, ' ', '')) > 0;

SELECT products_id, COUNT(*) AS num_ventas
FROM bridge_products
GROUP BY products_id;

SELECT products_id, COUNT(*) AS num_ventas
FROM bridge_products
JOIN transactions ON transactions_id = transactions.id
WHERE declined = 0
GROUP BY products_id
ORDER BY num_ventas DESC;
