
-- 1. Необхідно створити процедуру додавання нового співробітника, з потрібним переліком вхідних параметрів.
-- Після успішної роботи Дані процедури повинні потрапити
-- в таблиці employees, dept_emp, salaries и titles
-- Обчислення emp_no, обчислюємо по формулою max(emp_no) +1.
-- Якщо передана не існуюча посада, тоді показати помилку з необхідним текстом. Якщо передано зарплату менше 30000, 
-- тоді показати помилку з необхідним текстом.

DROP PROCEDURE  IF EXISTS new_employee;
 
 DELIMITER //
Create PROCEDURE new_employee (
                              IN  p_birth_date date, IN p_first_name varchar(50), IN p_last_name varchar(50), 
                              IN p_gender varchar(5),
                              IN p_dept_no varchar(10),
                              IN p_salary decimal,
                              IN p_title varchar(50)
                              )
       BEGIN
       
         DECLARE NEW_EMP_NO INT;
         SET NEW_EMP_NO = (SELECT MAX(e.emp_no)+1 FROM employees e);
	
		 IF P_title NOT IN (SELECT distinct t.title from titles t)
	       THEN
		   SIGNAL SQLSTATE '45000' -- returns general purpose error
		   SET MESSAGE_TEXT = 'Title does not exist';
		 END IF;
          
		 IF P_salary< 30000
	       THEN
		   SIGNAL SQLSTATE '45000' -- returns general purpose error
		   SET MESSAGE_TEXT = 'Salary less then 30000';
		  END IF;
          
	START transaction;
    
       insert into employees (emp_no, birth_date, first_name, last_name, gender, hire_date) 
              values (NEW_EMP_NO, p_birth_date, p_first_name, p_last_name, p_gender, now());
	   insert into dept_emp (emp_no, dept_no, from_date, to_date)
              values (NEW_EMP_NO, p_dept_no, now(), '9999-01-01');
	   insert into  salaries ( emp_no, salary, from_date, to_date)
              values (NEW_EMP_NO, p_salary, now(), '9999-01-01');
	   insert into titles (emp_no, title, from_date, to_date)
              values (NEW_EMP_NO, p_title, now(), '9999-01-01');
	COMMIT;	
     END //

CALL new_employee ('1999-01-01','Raman','Bangalore', 'M', 'd004', 29000, 'Senior Staff');
               --   Error Code: 1644. Salary less then 30000
CALL new_employee ('1999-01-01','Raman','Bangalore', 'M', 'd004', 35000, 'Staff2');
               --   Error Code: 1644. Title does not exist

CALL new_employee ('1999-01-01','Raman','Bangalore', 'M', 'd004', 35000, 'Senior Staff');

Select * from employees;
Select * from dept_emp;
Select * from salaries; 
Select * from titles;


-- 2. Створити процедуру оновлення зарплати по співробітнику. При оновленні зарплати
-- потрібно закрити останню активну зарплату поточною датою, і створити новий
-- історичний запис поточною датою. Якщо переданий не існуючий співробітник, тоді
-- показати помилку із потрібним текстом.

 DROP PROCEDURE  IF EXISTS modify_salary;
 
 DELIMITER //
	CREATE PROCEDURE modify_salary (IN p_emp_no INT, IN p_salary bigint)	
		BEGIN
            IF p_emp_no NOT IN (SELECT s.emp_no FROM salaries s WHERE s.to_date > NOW())
				THEN
					    SIGNAL SQLSTATE '45000'
						SET MESSAGE_TEXT = 'There are no active employees who have such ID. Please, use ID of an active employee.';
                END IF;
            
            START TRANSACTION;
		
			UPDATE salaries
               SET to_date = NOW()
			 WHERE emp_no = p_emp_no
               AND to_date > NOW()
			 ORDER BY from_date DESC LIMIT 1;
		            
            INSERT INTO salaries (emp_no, salary, from_date, to_date)
				VALUES(p_emp_no, p_salary, NOW(), '9999-01-01');
			COMMIT;
        END //

CALL modify_salary (01, 3000);
Error Code: 1644. There are no active employees who have such ID. Please, use ID of an active employee.

CALL modify_salary (10016, 3000);

select *
from salaries
where emp_no=10016;


-- 3. Створити процедуру для звільнення працівника, закриття історичних записів у таблицях dept_emp, salaries та titles. 
-- Якщо передано неіснуючий номер співробітника, тоді показати
-- помилку з потрібним текстом

DROP PROCEDURE  IF EXISTS retire_employee;
 
 DELIMITER //
	CREATE PROCEDURE retire_employee (IN p_emp_no INT)	
		
        BEGIN
            IF p_emp_no NOT IN (SELECT s.emp_no FROM salaries s WHERE s.to_date > NOW())
				THEN
					    SIGNAL SQLSTATE '45000'
						SET MESSAGE_TEXT = 'There are no active employees who have such ID. Please, use ID of an active employee.';
                END IF;
            
            START TRANSACTION;
		
        UPDATE dept_emp as dm
               SET dm.to_date = NOW()
			 WHERE dm.emp_no = p_emp_no
               AND dm.to_date > NOW()
			 ORDER BY dm.from_date DESC LIMIT 1;
             
             UPDATE salaries as sal
               SET sal.to_date = NOW()
			 WHERE sal.emp_no = p_emp_no
               AND sal.to_date > NOW()
			 ORDER BY sal.from_date DESC LIMIT 1;
             
             
			UPDATE titles as t
               SET t.to_date = NOW()
			 WHERE t.emp_no = p_emp_no
               AND t.to_date > NOW()
			 ORDER BY t.from_date DESC LIMIT 1;
             
			COMMIT;
        END //

CALL retire_employee (16);
Error Code: 1644. There are no active employees who have such ID. Please, use ID of an active employee.

CALL retire_employee (10016);

select *
from salaries
where emp_no=10016;

select *
from dept_emp
where emp_no=10016;

select *
from titles
where emp_no=10016;


-- 4. Створити функцію, яка виводила б поточну зарплату по співробітнику.

DROP FUNCTION IF EXISTS GET_SALARY_BY_EMP;

DELIMITER // 
	CREATE FUNCTION GET_SALARY_BY_EMP ( P_EMP_NO INT ) 
		RETURNS bigint DETERMINISTIC -- NOT DETERMINISTIC
		  BEGIN 
			 DECLARE V_SALARY bigint;
			
             SELECT sal.salary
             INTO V_SALARY
             FROM salaries as sal
             WHERE sal.TO_DATE > CURRENT_DATE() 
             AND sal.EMP_NO = P_EMP_NO;
            RETURN V_SALARY;
		 END; //

SELECT GET_SALARY_BY_EMP  (10001);
