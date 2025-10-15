--1.1--
CREATE TABLE employees(
    employee_id SERIAL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    age int CHECK(age BETWEEN 18 AND 65),
    salary NUMERIC(10,2) CHECK(salary > 0)
);

--1.2--
CREATE TABLE products_catalog(
    product_id SERIAL,
    product_name VARCHAR(50),
    regular_price NUMERIC(10,2),
    discount_price NUMERIC(10,2),
    CONSTRAINT valid_discounts CHECK(regular_price > 0 AND discount_price > 0 AND discount_price < regular_price)
);

--1.3--
CREATE TABLE bookings(
    booking_id SERIAL,
    check_in_date date,
    check_out_date date CHECK(check_out_date > check_in_date),
    num_guests INT CHECK(num_guests BETWEEN 1 AND 10)
);

--1.4--
INSERT INTO employees VALUES
(1,'DEMKA','BAITALIYEV',20,250.00),
(2,'DAMIR','GARIPZHANOV',23,260.00);

--INVALID INSERD USING age and salary CHECK CONSTRAINT--
INSERT INTO employees VALUES
(3,'DIMKA','KRUT',10,-250.00),
(4,'DAMKA','CHORT',3,-260.00);

INSERT INTO products_catalog VALUES
(1,'MILK',20.00,18.00),
(2,'BREAD',10.00,8.00);

--INVALID INSERD USING  valid_discount CHECK CONSTRAINT--
INSERT INTO products_catalog VALUES
(3,'MEAT',-20.00,18.00),
(4,'EGGS',10.00,-8.00),
(5,'OIL',10.00,12.00);

INSERT INTO bookings VALUES
(1,'2020-01-01','2021-01-01',3),
(2,'2010-01-01','2011-01-01',4);

--INVALID INSERD USING  valid_discount CHECK CONSTRAINT--
INSERT INTO bookings VALUES
(3,'2021-01-01','2020-01-01',5),
(4,'2012-01-01','2013-01-01',-4);

--2.1--
CREATE TABLE customers(
    customer_id SERIAL NOT NULL,
    email VARCHAR(50) NOT NULL,
    phone VARCHAR(50),
    registration_date date NOT NULL
);

--2.2--
CREATE TABLE inventory(
    item_id SERIAL NOT NULL,
    item_name VARCHAR(50) NOT NULL,
    quantity INT NOT NULL CHECK(quantity>=0),
    unit_price NUMERIC(10,2) NOT NULL CHECK(unit_price>=0),
    last_updated TIMESTAMP, NOT NULL
);

--2.3--
INSERT INTO customers VALUES
(1,'GUEST1@gmail.com','11111111111','2020-01-01'),
(2,'GUEST2@gmail.com','22222222222','2021-01-01'),

--INVALID INSERD USING NOT NULL CONSTRAINT--
INSERT INTO customers VALUES
(2,NULL,'11111111111' NULL),
(2,'GUEST2@gmail.com', NULL,'2021-01-01'),

INSERT INTO inventory VALUES
(1,'STICK1',3,20.00,'2020-01-01'),
(2,'STICK2',4,23.00,'2021-01-01');

--INVALID INSERD USING NOT NULL CONSTRAINT--
INSERT INTO inventory VALUES
(NULL,'STICK3',1,20.00,'2020-01-01'),
(2,'STICK5','7',222.00,NULL);


--3.1--
CREATE TABLE users(
    user_id SERIAL,
    username VARCHAR(50) UNIQUE,
    email VARCHAR(50) UNIQUE,
    created_at TIMESTAMP
);

--3.2--
CREATE TABLE course_enrollments(
    enrollment_id SERIAL,
    student_id INT,
    course_code VARCHAR(50),
    semester VARCHAR(50),
    UNIQUE(student_id,course_code,semester)
);

--3.3--
ALTER TABLE users
ADD CONSTRAINT unique_username UNIQUE(username);

ALTER TABLE users
ADD CONSTRAINT unique_email UNIQUE(email);

INSERT INTO users VALUES
(1, 'DEMKA', 'student1@gmail.com','2020-01-01'),
(1, 'DEMKA', 'student1@gmail.com','2020-01-01');

--4.1--
CREATE TABLE departments(
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(50) NOT NULL,
    location VARCHAR(50)
);

INSERT INTO departments VALUES
(1,'IT', 'TARAZ'),
(2,'MED', 'ALMATY'),
(3,'INGENIRING', 'ASTANA');

INSERT INTO departments VALUES
(1,'ECONOMY', 'ASTANA'),
(NULL,'ECONOMY', 'ASTANA');

--4.2--
CREATE TABLE student_courses(
    student_id SERIAL,
    course_id INT,
    enrollment_date DATE,
    grade VARCHAR(50),
    PRIMARY KEY(student_id, course_id)
);

--4.3--

--difference between UNIQUE and PRIMARY KEY
--both of them make the value where its assigned unique, however PRIMARY KEY are mostly 
--used for data relation, main identifier od the table and it can not be null, whereas columns 
--assigned with UNIQUE can. Also table can have many UNIQUE, but only one PRIMARY KEY

--when to use single or composite primary key
--sinlge column is used when there is only one column that can be assigned as identifier
--wheres we use composite key when our identifier consist of not only one column


--Why a table can have only one PRIMARY KEY but multiple UNIQUE constraints
--because table has only one identifier column and unique, while other columns only unique

--5.1
CREATE TABLE employees_dept(
    emp_id SERIAL PRIMARY KEY,
    emp_name VARCHAR(50) NOT NULL,
    dept_id INT REFERENCES departments,
    hire_date date
);

INSERT INTO employees_dept VALUES
(1,'demka', 1, '2020-01-01'),
(2,'dimon',2,'2021-01-01'),
(3,'damir',3,'2022-01-01');

INSERT INTO employees_dept VALUES
(4,'demka', 6, '2020-01-01');

--5,2
CREATE TABLE authors(
    author_id SERIAL PRIMARY KEY,
    author_name VARCHAR(50) NOT NULL,
    country VARCHAR(50)
);

CREATE TABLE publishers(
    publisher_id SERIAL PRIMARY KEY,
    publisher_name VARCHAR(50) NOT NULL,
    city VARCHAR(50)
);

CREATE TABLE books(
    book_id SERIAL PRIMARY KEY,
    title VARCHAR(50) NOT NULL,
    author_id INT REFERENCES authors(author_id),
    publisher_id INT REFERENCES publishers(publisher_id),
    publication_year INT,
    isbn VARCHAR(50) UNIQUE
);

INSERT INTO authors VALUES (1, 'Gabriel García Márquez ', ' Colombia');
INSERT INTO authors VALUES (2, 'William Shakespeare', 'England');
INSERT INTO authors VALUES (3, 'Fyodor Dostoevsky', 'Russia');

INSERT INTO publishers VALUES (1, 'Penguin Random House', 'New York City');
INSERT INTO publishers VALUES (2, 'HarperCollins', 'New York City');
INSERT INTO publishers VALUES (3, 'Hachette Book Group', 'Paris');

INSERT INTO books VALUES (1, 'One Hundred Years of Solitude', 1, 1, 2009, '9780451524935');
INSERT INTO books VALUES (2, 'The Complete Works of William Shakespeare (Alexander Text)', 2, 2, 1994, '9780747532699');
INSERT INTO books VALUES (3, 'Crime and Punishment', 3, 3, 2022, '9780684801223');

--5.3
CREATE TABLE categories(
    category_id SERIAL PRIMARY KEY,
    title VARCHAR(50) NOT NULL
);

CREATE TABLE products_fk(
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(50) NOT NULL,
    category_id INT REFERENCES categories(category_id) ON DELETE RESTRICT
);

CREATE TABLE orders(
    order_id SERIAL PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items(
    item_id  SERIAL PRIMARY KEY,
    order_id INT REFERENCES categories(category_id) ON DELETE CASCADE,
    product_id INT REFERENCES products_fk(product_id),
    quantity INT CHECK(quantity>0)
);

INSERT INTO categories VALUES (1, 'ART');
INSERT INTO categories VALUES (2, 'SPORT');

INSERT INTO products_fk VALUES (101, 'canvas', 1);
INSERT INTO products_fk VALUES (102, 'BALL', 2);

INSERT INTO orders VALUES (105, '2001-01-01');

INSERT INTO order_items VALUES (1, 105, 101, 2);
INSERT INTO order_items VALUES (2, 105, 102, 1);


DELETE FROM categories WHERE category_id = 1;

DELETE FROM orders WHERE order_id = 105;

--6.1
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,    
    email VARCHAR(50) UNIQUE NOT NULL, 
    phone VARCHAR(50),
    registration_date TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP 
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY, 
    name VARCHAR(50) NOT NULL,    
    description TEXT,
    price NUMERIC(10, 2) NOT NULL, 
    stock_quantity INT NOT NULL,  
    CHECK (price >= 0),
    CHECK (stock_quantity >= 0)
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,    
    customer_id INT NOT NULL,       
    order_date TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP, 
    total_amount NUMERIC(10, 2) NOT NULL, 
    status VARCHAR(50) NOT NULL,    
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
    CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);

CREATE TABLE order_details (
    order_detail_id SERIAL PRIMARY KEY, 
    order_id INT NOT NULL,              
    product_id INT NOT NULL,            
    quantity INT NOT NULL,              
    unit_price NUMERIC(10, 2) NOT NULL, 
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT,
    UNIQUE (order_id, product_id),
    CHECK (quantity > 0)
);

INSERT INTO customers (name, email, phone) VALUES
('demka', 'demka@gmail.com', '555-1001'),
('damir', 'damir@gmail.com', '555-2002'),
('yeraly', 'yeraly@gmail.com', '555-3003'),
('adilseit', 'adilseit@gmail.com', '555-4004'),
('baltabay', 'baltabay@gmail.com', '555-5005');

INSERT INTO products (name, description, price, stock_quantity) VALUES
('Laptop Pro X', 'High-performance laptop with 16GB RAM.', 1200.00, 50),
('Wireless Mouse M5', 'Ergonomic wireless mouse.', 25.50, 150),
('4K Monitor 27"', '27-inch monitor with UHD resolution.', 350.99, 30),
('USB-C Hub (7-in-1)', 'Multi-port adapter for modern laptops.', 45.00, 200),
('Mechanical Keyboard R1', 'Full-size keyboard with tactile switches.', 99.95, 75);

INSERT INTO orders (customer_id, order_date, total_amount, status) VALUES
(1, '2000-01-01 10:00:00', 1225.50, 'delivered'), 
(2, '2000-01-02 11:30:00', 350.99, 'shipped'),   
(3, '2000-01-03 08:00:00', 90.00, 'processing'),   
(4, '2000-01-04 09:30:00', 99.95, 'pending'),    
(5, '2000-01-05 11:00:00', 0.00, 'cancelled');   

INSERT INTO order_details (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 1200.00), 
(1, 2, 1, 25.50),  
(2, 3, 1, 350.99), 
(3, 4, 2, 45.00),   
(4, 5, 1, 99.95),   
(5, 1, 1, 1200.00), 
(4, 2, 1, 25.50),   
(3, 5, 1, 99.95),   
(2, 4, 3, 45.00);   