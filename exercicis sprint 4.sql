#					*****Nivell 1*****
#Descàrrega els arxius CSV, estudia'ls i dissenya una base de dades amb un esquema d'estrella que contingui,
# almenys 4 taules de les quals puguis realitzar les següents consultes:

-- Creamos la base de datos
CREATE DATABASE IF NOT EXISTS transactions_s4;
USE transactions_s4;

    -- Creamos las tablas
#companies
CREATE TABLE IF NOT EXISTS companies (
	id VARCHAR(15) PRIMARY KEY,
	company_name VARCHAR(255),
	phone VARCHAR(15),
	email VARCHAR(100),
	country VARCHAR(100),
	website VARCHAR(255)
);

# transactions
CREATE TABLE IF NOT EXISTS transactions (
	id VARCHAR(255) PRIMARY KEY,
	card_id VARCHAR(15) REFERENCES credit_card(id),
	business_id VARCHAR(15) REFERENCES companies(id), 
    timestamp TIMESTAMP,
	amount DECIMAL(10,2),
	declined BOOLEAN,
	product_ids VARCHAR(25),
	user_id VARCHAR(5) REFERENCES users(id),
	lat FLOAT,
	longitude FLOAT
    );

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

#products
CREATE TABLE IF NOT EXISTS products (
	id VARCHAR(20) PRIMARY KEY,
	product_name TEXT NOT NULL ,
	price FLOAT NOT NULL ,
    colour VARCHAR(20),
    weight VARCHAR(20),
	warehouse_id VARCHAR(20) NOT NULL 
);

#users
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


SHOW VARIABLES LIKE 'secure_file_priv';

#cargar archivos csv. 
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, product_name, @price_raw, colour, weight, warehouse_id)
SET price = REPLACE(@price_raw, '$', '');

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/companies.csv'
INTO TABLE companies
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS ;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/credit_cards.csv'
INTO TABLE credit_cards
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/transactions.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ';' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

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

CREATE INDEX idx_companies
	ON transactions(business_id);
    
CREATE INDEX idx_credit_cards
	ON transactions(card_id);
    
CREATE INDEX idx_users
	ON transactions(user_id);
    

 
#Exercici 1: #Realitza una subconsulta que mostri tots els usuaris amb més de 30 transaccions
#utilitzant almenys 2 taules.

SELECT 
    users.id, users.name, users.surname,
    COUNT(transactions.id) AS num_transacciones
FROM users
JOIN transactions 
    ON users.id = transactions.user_id
GROUP BY users.id, users.name, users.surname
HAVING num_transacciones > 30;

#Exercici 2: Mostra la mitjana d'amount per IBAN de les targetes de crèdit a la companyia Donec Ltd, 
#utilitza almenys 2 taules.

SELECT credit_cards.iban,companies.company_name,
   ROUND(AVG(amount),2)AS average_amount
   FROM credit_cards 
JOIN transactions 
	ON credit_cards.id = transactions.card_id
JOIN companies
	ON transactions.business_id = companies.id
WHERE companies.company_name = 'Donec Ltd'
GROUP BY credit_cards.iban;


#					*****Nivell 2*****
#Exercici 1: Crea una nova taula que reflecteixi l'estat de les targetes de crèdit 
#basat en si les últimes tres transaccions van ser declinades i genera la següent consulta:
#Quantes targetes estan actives?

CREATE TABLE credit_card_status (
    card_id VARCHAR(15) PRIMARY KEY,
    status VARCHAR(15) NOT NULL
);

INSERT INTO credit_card_status (card_id, status)
SELECT 
    transactions.card_id,
    CASE 
        WHEN SUM(CASE WHEN transactions.declined THEN 1 ELSE 0 END) = 3 THEN 'Inactiva'
        ELSE 'Activa'
    END AS status
FROM (
    SELECT card_id, declined
    FROM transactions
    ORDER BY timestamp DESC
    LIMIT 3
) transactions
GROUP BY transactions.card_id;

#				*****Nivell 3*****
#Exercici 1: Necessitem conèixer el nombre de vegades que s'ha venut cada producte.
CREATE TABLE bridge_products (
	transactions_id VARCHAR(100) PRIMARY KEY,
	products_id VARCHAR(100) NOT NULL,
    FOREIGN KEY (transactions_id) REFERENCES transactions(id),
    FOREIGN KEY (products_id) REFERENCES products(id)
);
