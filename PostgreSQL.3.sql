--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Сделайте запрос к таблице payment и с помощью оконных функций добавьте вычисляемые колонки согласно условиям:
--1.1 Пронумеруйте все платежи от 1 до N по дате платежа
--1.2 Пронумеруйте платежи для каждого покупателя, сортировка платежей должна быть по дате платежа
--1.3 Посчитайте нарастающим итогом сумму всех платежей для каждого покупателя, сортировка должна быть 
--сперва по дате платежа, а затем по размеру платежа от наименьшей к большей
--1.4 Пронумеруйте платежи для каждого покупателя по размеру платежа от наибольшего к меньшему так, 
--чтобы платежи с одинаковым значением имели одинаковое значение номера.
--В результирующей таблице должны быть следующие столбцы: Идентификатор платежа, дата платежа, 
--идентификатор пользователя, размер платежа, 4 столбца с результатами оконных функций.


select
	payment_id,
	payment_date,
	customer_id,
	amount,
	row_number() over (order by payment_date),
	row_number() over (partition by customer_id order by payment_date),
	sum(amount) over (partition by customer_id order by payment_date, amount),
	dense_rank() over (partition by customer_id order by amount desc)
from payment;


--ЗАДАНИЕ №2
--С помощью оконной функции выведите для каждого покупателя стоимость платежа и стоимость 
--платежа из предыдущей строки со значением по умолчанию 0.0 с сортировкой по дате платежа.
--В результирующей таблице должны быть следующие столбцы: Идентификатор платежа, дата платежа, 
--идентификатор пользователя, текущий размер платежа, размер платежа из предыдущей строки.

select
	payment_id,
	payment_date,
	customer_id,
	amount,
	lag(amount,1,0.0) over (partition by customer_id order by payment_date)
from payment;


--ЗАДАНИЕ №3
--С помощью оконной функции определите, на сколько каждый следующий платеж покупателя больше или меньше текущего.
--В результирующей таблице должны быть следующие столбцы: Идентификатор платежа, дата платежа, идентификатор пользователя, 
--текущий размер платежа, следующий размер платежа, разница между текущим и следующим платежами.

select 
	payment_id,
	payment_date,
	customer_id,
	amount,
	lead(amount,1,0.0) over (partition by customer_id order by payment_date),
	amount - lead(amount,1,0.0) over (partition by customer_id order by payment_date)
from payment;

--ЗАДАНИЕ №4
--С помощью оконной функции для каждого покупателя выведите данные о его последней оплате аренды.
--В результирующей таблице должны быть следующие столбцы: Все столбцы из таблицы с платежами.

select *
from(
	select *,
		last_value(payment_id) over (partition by customer_id order by payment_date
		rows between unbounded preceding and unbounded following)
	from payment) 
where payment_id = last_value;


--можно сделать c обратной сортировкой
select *
from(
	select *,
		row_number () over (partition by customer_id order by payment_date desc)
	from payment)
where row_number = 1;

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--С помощью оконной функции выведите для каждого сотрудника сумму продаж за август 2005 года 
--с нарастающим итогом по каждому сотруднику и по каждой дате продажи (без учёта времени) 
--с сортировкой по дате.
--В результирующей таблице должны быть следующие столбцы: Фамилия и имя сотрудника в виде 
--одного значения, сумма продаж на каждый день, накопительный итог.

with sales as (
	select 
		s.staff_id,
		s.first_name || ' ' || s.last_name as full_name,
		p.payment_date::date as sales_date,
		sum(p.amount) as sales_sum
	from staff s
	join payment p on s.staff_id = p.staff_id
	where payment_date::date between '2005-08-01' and '2005-08-31'
	group by s.staff_id, sales_date)
select
	full_name,
	sales_date,
	sales_sum,
	sum(sales_sum) over (partition by full_name order by sales_date) as total_sales
from sales;

--ЗАДАНИЕ №2
--20 августа 2005 года в магазинах проходила акция: покупатель каждого сотого платежа получал
--дополнительную скидку на следующую аренду. С помощью оконной функции выведите всех покупателей,
--которые в день проведения акции получили скидку
--В результирующей таблице должны быть следующие столбцы: Идентификатор пользователя, 
--фамилия и имя пользователя в виде одного значения.

with sales as (
	select 
		c.customer_id,
		c.first_name || ' ' || c.last_name as full_name,
		row_number() over (order by p.payment_id) 
	from customer c
	join payment p on c.customer_id = p.customer_id
	where p.payment_date::date = '2005-08-20')
select 
	customer_id,
	full_name
from sales
where row_number % 100 = 0;

--ЗАДАНИЕ №3
--Для каждой страны определите и выведите одним SQL-запросом покупателей, которые попадают под условия:
-- 1. покупатель, арендовавший наибольшее количество фильмов
-- 2. покупатель, арендовавший фильмов на самую большую сумму
-- 3. покупатель, который последним арендовал фильм
--В результирующей таблице должны быть следующие столбцы: Название страны, фамилия и имя пользователя в 
--виде одного значения лучшего по количеству, фамилия и имя пользователя в виде одного значения лучшего 
--по сумме платежей, фамилия и имя пользователя в виде одного значения последним арендовавшим фильм.
--Есть два варианта решения: получать одного случайного, если в топ 1 попадает несколько пользователей, 
--выводить всех пользователей, попавших в топ 1. Выбор варианта остается за вами.

with stats as (
	select 
		ctr.country_id,
		ctr.country,
		c.customer_id,
		c.first_name || ' ' || c.last_name as full_name,
		count(r.rental_id) as rental_count,
		sum(p.amount) as sum_amount,
		max(r.rental_date) as last_rent_date,
		dense_rank() over (partition by ctr.country_id order by count(r.rental_id) desc) as rental_rank,
		dense_rank() over (partition by ctr.country_id order by sum(p.amount) desc) as amount_rank,
		dense_rank() over (partition by ctr.country_id order by max(r.rental_date) desc) as last_rent_rank
	from country ctr
	join city ci on ctr.country_id = ci.country_id 
	join address a on ci.city_id = a.city_id 
	join customer c on a.address_id = c.address_id 
	join rental r on c.customer_id = r.customer_id 
	join payment p on r.rental_id = p.rental_id 
	group by ctr.country_id, ctr.country, c.customer_id, c.first_name || ' ' || c.last_name)
select
	country,
	string_agg(distinct case when rental_rank = 1 then full_name end, ', ') as Best_of_rental,
	string_agg(distinct case when amount_rank = 1 then full_name end, ', ') as Best_of_amount,
	string_agg(distinct case when last_rent_rank = 1 then full_name end, ', ') as Last_rental
from stats
group by country_id, country;


	
	
