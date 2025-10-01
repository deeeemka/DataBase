CREATE DATABASE advanced_lab;

CREATE TABLE employees(
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50),
    salary INT,
    hire_date date,
    status VARCHAR(50) DEFAULT 'Active'
)

CREATE TABLE departments(
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(50),
    budget INT,
    manager_id INT
)

CREATE TABLE projects(
    project_id  SERIAL PRIMARY KEY,
    project_name VARCHAR(50),
    dept_id INT,
    start_date date,
    end_date date,
    budget INT
)

INSERT INTO employees (emp_id, first_name,last_name, department)
VALUES ('1','Dimon','Baitaliyev','HR');

INSERT INTO employees (first_name,last_name, department, salary, hire_date)
VALUES ('Demka','Krut','Software Enginiring',DEFAULT, '2005-03-29');

INSERT INTO departments (dept_name, budget, manager_id)
VALUES
('HR', 10000, 1),
('MEDICAL', 20000, 2),
('MANAGEMENT', 30000, 3);

INSERT INTO employees(first_name,last_name, department, salary, hire_date)
VALUES ('Damir', 'Garipzhanov', 'IT', 50000*1.1, CURRENT_DATE);

CREATE TEMPORARY TABLE temp_employees AS
SELECT * FROM employees WHERE department = 'IT';



UPDATE employees set salary = salary * 1.1;

UPDATE employees SET status = 'Senior'
WHERE salary > 60000 AND  hire_date < '2020-01-01';

UPDATE employees 
SET department = CASE
    WHEN salary > 80000 THEN 'Management'
    WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
    ELSE 'Junior'
END;

UPDATE employees SET department = DEFAULT
WHERE status = 'Inactive';

UPDATE department SET budget = (
    SELECT AVG(employess.budget)*1.2
    FROM employees WHERE employees.department = department.deparment_name
);

UPDATE employees SET salary = salary * 1.15, status = 'Promoted'
WHERE department = 'Sales';


DELETE FROM employees WHERE status = 'Terminated';

DELETE FROM employees WHERE salary < 40000 AND hire_date > '2023-01-01' AND department IS NULL;

DELETE FROM departments 
WHERE dept_id NOT IN(
    SELECT DISTINCT dept_id 
    FROM employees 
    JOIN employees.department = department.dept_name
    where department IS NOT NULL
);

DELETE FROM projects
WHERE end_date<'2023-01-01'
RETURNING *;


INSERT INTO employees (first_name,last_name, department, salary, hire_date)
VALUES ('Yeraly','Bibossynov',NULL, NULL, '2006-01-15');

UPDATE employees SET department = 'Unassigned'
WHERE department IS NULL;

DELETE FROM employees WHERE salary IS NULL OR department IS NULL;



INSERT INTO employees (first_name,last_name, department, salary, hire_date)
VALUES ('Adilseit','Tuyebay','Videmaking', 30, '2006-08-10')
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

UPDATE employees SET salary = salary + 5000 WHERE department = 'IT'
RETURNING emp_id, salary - 5000 AS old_salary, salary AS news_salary;

DELETE FROM employees WHERE hire_date < '2020-01-01'
RETURNING *;


INSERT INTO employees (first_name,last_name, department, salary, hire_date)
VALUES ('Baltabay','Zhanibek','CS',DEFAULT, '2005-09-28')
WHERE NOT EXISTS(
    SELECT 1 FROM employees WHERE first_name = 'Baltabay' AND last_name = 'Zhanibek'
);

UPDATE employees SET salary = salary * CASE
    WHEN (SELECT budget FROM departments WHERE department.dept_name = employees.department) > 100000 THEN 1.10
    ELSE 1.05
END;

INSERT INTO employees (first_name,last_name, department, salary, hire_date)
VALUES 
('NAME1', 'LASTNAME1', 'DEP1', 10, CURRENT_DATE),
('NAME2', 'LASTNAME2', 'DEP2', 20, CURRENT_DATE),
('NAME3', 'LASTNAME3', 'DEP3', 30, CURRENT_DATE),
('NAME4', 'LASTNAME4', 'DEP4', 40, CURRENT_DATE),
('NAME5', 'LASTNAME5', 'DEP5', 50, CURRENT_DATE);

UPDATE employees SET salary = salary * 1.1
WHERE first_name IN ('NAME1','NAME2','NAME3','NAME4','NAME5');

CREATE TABLE employee_archive(
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50),
    salary INT,
    hire_date date,
    status VARCHAR(50) DEFAULT 'Active'
)

INSERT INTO employee_archive 
SELECT * FROM employees WHERE status = 'Inactive';

DELETE FROM employees WHERE status = 'Inactive';

UPDATE projects SET end_date = end_date + INTERVAL '30 days'
WHERE budget > 50000
AND (SELECT COUNT(*) FROM employees WHERE employees.department = projects.dept_id)>3;


