-- Запросы
-- 1. Покажите среднюю зарплату сотрудников за каждый год (средняя заработная плата
-- среди тех, кто работал в отчетный период - статистика с начала до 2005 года).

Select extract(year from from_date) as year, round(avg(salary)) as avg_salary
 from employees.salaries
 group by extract(year from from_date);

-- 2. Покажите среднюю зарплату сотрудников по каждому отделу. Примечание: принять в
-- расчет только текущие отделы и текущую заработную плату.

select depem.dept_no, round(avg(sal.salary)) as avg_salary
from dept_emp as depem
join salaries as sal on depem.emp_no=sal.emp_no and depem.to_date>curdate() and sal.to_date>curdate()
group by depem.dept_no;

-- 3. Покажите среднюю зарплату сотрудников по каждому отделу за каждый год.
-- Примечание: для средней зарплаты отдела X в году Y нам нужно взять среднее
-- значение всех зарплат в году Y сотрудников, которые были в отделе X в году Y.

select depem.dept_no, extract(year from sal.from_date) as year, avg(sal.salary) as avg_sal
from salaries as sal
join dept_emp as depem on depem.emp_no=sal.emp_no
group by depem.dept_no, extract(year from sal.from_date);

-- 4. Покажите для каждого года самый крупный отдел (по количеству сотрудников) в этом
-- году и его среднюю зарплату.

with 
table1 as
      (SELECT  
             tab.year as year, 
			 MAX(tab.quant) as q1
        from  (select 
                    extract(year from sal1.from_date) as year, 
                    depem1.dept_no,
	                count(sal1.emp_no) as quant
		        from salaries as sal1
		        join dept_emp as depem1 on depem1.emp_no=sal1.emp_no
	         group by depem1.dept_no, extract(year from sal1.from_date))  as tab 
	group by tab.year),
table2 as 
      (select 
			extract(year from sal2.from_date) as year, 
			depem2.dept_no,
			count(sal2.emp_no) as quant,
			avg(sal2.salary) as avgsal
		from salaries as sal2
		join dept_emp as depem2 on depem2.emp_no=sal2.emp_no
	   group by depem2.dept_no, extract(year from sal2.from_date))
       
select t1.year, t2.dept_no, t2.avgsal 
from table1 as t1
join table2 as t2 on t1.q1=t2.quant;

-- 5. Покажите подробную информацию о менеджере, который дольше всех исполняет свои
-- обязанности на данный момент


SELECT 
       dm.emp_no, ee.birth_date, ee.first_name, ee.last_name, ee.gender, ee. hire_date, datediff(curdate(), dm.from_date)
  FROM dept_manager as dm
  join employees as ee on ee.emp_no=dm.emp_no
 where datediff(dm.to_date, dm.from_date)=( 
                                          SELECT MAX(countdays) 
                                            FROM (
                                                  SELECT dm2.emp_no, datediff(dm2.to_date, dm2.from_date) countdays
                                                    FROM dept_manager as dm2
                                                    where dm2.to_date>curdate()) as tab);

-- 6. Покажите топ-10 нынешних сотрудников компании с наибольшей разницей между их
-- зарплатой и текущей средней зарплатой в их отделе.

with 
avarege_sal as (
                select depem.dept_no, avg(sal.salary) as avgsal
                 from salaries as sal
				 join dept_emp as depem on sal.emp_no=depem.emp_no
					  and sal.to_date>curdate() and depem.to_date> curdate()
             group by depem.dept_no)
select sal.emp_no, depem.dept_no, sal.salary, aversal.avgsal, ABS(sal.salary-aversal.avgsal) as saldif
from salaries as sal
join dept_emp as depem on sal.emp_no=depem.emp_no
join avarege_sal as aversal on aversal.dept_no=depem.dept_no
where sal.to_date>curdate() and depem.to_date>curdate()
order by saldif desc
limit 10;

-- 7. Из-за кризиса на одно подразделение на своевременную выплату зарплаты выделяется
-- всего 500 тысяч долларов. Правление решило, что низкооплачиваемые сотрудники
-- будут первыми получать зарплату. Показать список всех сотрудников, которые будут
-- вовремя получать зарплату (обратите внимание, что мы должны платить зарплату за
-- один месяц, но в базе данных мы храним годовые суммы).

with totalsum as (
                 select emp_no, salary/12 as monthsal,
	                    SUM(salary/12) OVER(ORDER BY salary/12 asc) as total_sum	
                   from salaries
                  where to_date>curdate()
                  order by monthsal asc
                 )
 select emp_no, monthsal, total_sum
   from totalsum 
   where total_sum<500000;
                 
 

-- Дизайн базы данных:
-- 1. Разработайте базу данных для управления курсами. База данных содержит
-- следующие сущности:
-- a. students: student_no, teacher_no, course_no, student_name, email, birth_date.
-- b. teachers: teacher_no, teacher_name, phone_no
-- c. courses: course_no, course_name, start_date, end_date.
-- ● Секционировать по годам, таблицу students по полю birth_date с помощью механизма range
-- ● В таблице students сделать первичный ключ в сочетании двух полей student_no и birth_date
-- ● Создать индекс по полю students.email
-- ● Создать уникальный индекс по полю teachers.phone_no

USE COURSES;
CREATE TABLE IF NOT EXISTS students
(student_no INT NOT NULL,
teacher_no INT NOT NULL,
course_no INT NOT NULL,
student_name VARCHAR (255) NOT NULL,
email VARCHAR (255) NOT NULL,
birth_date DATE NOT NULL)
PARTITION BY RANGE  (YEAR(birth_date))
    (PARTITION p2000 VALUES LESS THAN (2001),
    PARTITION p2001 VALUES LESS THAN (2002),
    PARTITION p2002 VALUES LESS THAN (2003),
    PARTITION p2003 VALUES LESS THAN (2004),
    PARTITION p2004 VALUES LESS THAN (2005),
    PARTITION p2005 VALUES LESS THAN (2006),
    PARTITION p2006 VALUES LESS THAN (2007),
    PARTITION p2007 VALUES LESS THAN (2008),
    PARTITION p2008 VALUES LESS THAN (2009),
    PARTITION p2009 VALUES LESS THAN (2010),
    PARTITION p2010 VALUES LESS THAN (2011),
    PARTITION pother VALUES LESS THAN MAXVALUE);


ALTER TABLE students
ADD PRIMARY KEY(student_no,birth_date);

CREATE INDEX ind_email ON courses.students(email ASC) USING BTREE;


CREATE TABLE IF NOT EXISTS teachers
(teacher_no INT AUTO_INCREMENT PRIMARY KEY,
teacher_name VARCHAR (255) NOT NULL,
phone_no INT NOT NULL)
ENGINE=INNODB;


CREATE UNIQUE INDEX index_phone_no ON teachers (phone_no);

CREATE TABLE IF NOT EXISTS courses
(course_no INT AUTO_INCREMENT PRIMARY KEY,
course_name VARCHAR (255) NOT NULL,
start_date DATE NOT NULL,
end_date DATE NOT NULL)
ENGINE=INNODB;


-- 2. На свое усмотрение добавить тестовые данные (7-10 строк) в наши три таблицы.

INSERT INTO students (student_no, teacher_no, course_no, email, student_name,  birth_date) 
            values (1, 1, 1, 'aaaa@aaaa.com', 'Alex', '2001-01-02'),
				   (2, 1, 1, 'bbbb@aaaa.com', 'Helen', '2002-01-02'),
                   (3, 2, 3, 'cccc@aaaa.com', 'Peter', '2003-01-02'),
                   (4, 2, 1, 'dddd@aaaa.com', 'Fibi', '2004-01-02'),
                   (5, 3, 1, 'eeee@aaaa.com', 'Cris', '2005-01-02'),
                   (6, 3, 2, 'ffff@aaaa.com', 'Cristin', '2006-01-02'),
                   (7, 4, 3, 'gggg@aaaa.com', 'Jasper', '2007-01-02'),
                   (8, 4, 3, 'hhhh@aaaa.com', 'July', '2001-01-02');
                   
INSERT INTO teachers (teacher_name, phone_no)
			  values ('July', 111111111), 
                     ('Jasper', 221111111),
                     ('Cris', 44444444),
                     ('Eles', 8888888);

INSERT INTO courses (course_name, start_date, end_date)
			  values ('SQL', '2022-09-01', '2023-12-31'),
                     ('Python', '2023-01-10', '2023-03-31'),
                     ('Power BI', '2023-04-10', '2023-05-31');
				


-- 3. Отобразить данные за любой год из таблицы students и зафиксировать в виду
-- комментария план выполнения запроса, где будет видно что запрос будет выполняться по
-- конкретной секции.

Explain
select *
from students
where birth_date='2005-01-02';

-- '1','SIMPLE','students','p2005','ALL',NULL,NULL,NULL,NULL,'1','100.00','Using where'


-- 4. Отобразить данные учителя, по любому одному номеру телефона и зафиксировать план
-- выполнения запроса, где будет видно, что запрос будет выполняться по индексу, а не
-- методом ALL. Далее индекс из поля teachers.phone_no сделать невидимым и
-- зафиксировать план выполнения запроса, где ожидаемый результат - метод ALL. В итоге
-- индекс оставить в статусе - видимый.

Explain
select *
from teachers
where phone_no=44444444;

-- '1','SIMPLE','teachers',NULL,'const','index_phone_no','index_phone_no','4','const','1','100.00',NULL
-- '1','SIMPLE','teachers',NULL,'const','index_phone_no','index_phone_no','ALL','const','1','100.00',NULL


-- 5. Специально сделаем 3 дубляжа в таблице students (добавим еще 3 одинаковые строки).
INSERT INTO students (student_no, teacher_no, course_no, email, student_name,  birth_date) 
            values (9, 1, 1, 'aaaa@aaaa.com', 'Alex', '2001-01-02'),
                   (10, 1, 1, 'aaaa@aaaa.com', 'Alex', '2001-01-02'), 
                   (11, 1, 1, 'aaaa@aaaa.com', 'Alex', '2001-01-02');
                   
-- 6. Написать запрос, который выводит строки с дубляжами

select teacher_no, course_no, student_name, email, birth_date, count(*)
from students
group by teacher_no, course_no, student_name, email, birth_date
having count(*)>1;

