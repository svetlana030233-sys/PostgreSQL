--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите для каждого покупателя его адрес проживания, город и страну проживания.
--В результирующей таблице должны быть следующие столбцы: Имя пользователя, фамилия пользователя, адрес, город, страна.

select 
	c.first_name, 
	c.last_name, 
	a.address, 
	c2.city, 
	c3.country 
from customer c 
join address a on c.address_id = a.address_id 
join city c2 on a.city_id = c2.city_id
join country c3 on c2.country_id = c3.country_id;

--ЗАДАНИЕ №2
--С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.
--В результирующей таблице должны быть следующие столбцы: Идентификатор магазина, количество прикрепленных пользователей.

select 
	s.store_id, 
	count(c.customer_id) 
from customer c 
join store s on c.store_id = s.store_id 
group by s.store_id;

--Доработайте запрос и выведите только те магазины, 
--у которых количество покупателей больше 300-от.
--Для решения используйте фильтрацию по сгруппированным строкам с использованием функции агрегации.
--В результирующей таблице должны быть следующие столбцы: Идентификатор магазина, количество прикрепленных пользователей.

select 
	s.store_id, 
	count(c.customer_id) 
from customer c 
join store s on c.store_id = s.store_id 
group by s.store_id
having count(c.customer_id) > 300;

-- Доработайте запрос, добавив в него информацию о городе магазина, 
--а также фамилию и имя продавца, который работает в этом магазине.
--В результирующей таблице должны быть следующие столбцы: Фамилия и имя сотрудника в виде одного значения, идентификатор магазина, 
--город нахождения магазина, количество прикрепленных пользователей.

select 
	st.first_name||' '||st.last_name as full_name, 
	c2.city,
	store_info.id,
	store_info.customer_count
from staff st
join store s on st.store_id = s.store_id
join address a on s.address_id = a.address_id
join city c2 on a.city_id = c2.city_id
join (
	select 
		s.store_id as id, 
		count(c.customer_id) as customer_count
	from customer c 
	join store s on c.store_id = s.store_id 
	group by s.store_id
	having count(c.customer_id) > 300
) as store_info on s.store_id = store_info.id;


--ЗАДАНИЕ №3
--Выведите ТОП-5 покупателей, которые взяли в аренду за всё время наибольшее количество фильмов
--В результирующей таблице должны быть следующие столбцы: 
--Фамилия и имя пользователя в виде одного значения, количество арендованных фильмов.

select 
	c.first_name||' '||c.last_name as full_name, 
	r.rental_count
from customer c
join(
	select 
		customer_id, 
		count(rental_id) as rental_count
	from rental
	group by customer_id
) r on c.customer_id = r.customer_id
order by r.rental_count desc
limit 5;

--ЗАДАНИЕ №4
--Посчитайте для каждого покупателя 4 аналитических показателя:
--  1. количество фильмов, которые он взял в аренду
--  2. общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа)
--  3. минимальное значение платежа за аренду фильма
--  4. максимальное значение платежа за аренду фильма
--В результирующей таблице должны быть следующие столбцы: 
--Фамилия и имя пользователя в виде одного значения, 
--количество арендованных фильмов, округленная сумма платежей, минимальный и максимальный платеж.

select 
	c.first_name||' '||c.last_name as full_name, 
	info.rental_count, 
	info.summa, 
	info.minimum, 
	info.maximum
from customer c
join(
	select 
		p.customer_id,
		count(r.rental_id) as rental_count,
		round(sum(p.amount),0) as summa, 
		min(p.amount) as minimum, 
		max(p.amount) as maximum
	from payment p
	join rental r on p.rental_id = r.rental_id
	group by p.customer_id
) info on  c.customer_id = info.customer_id;

--ЗАДАНИЕ №5
--Используя данные из таблицы городов, составьте все возможные пары городов так, чтобы 
--в результате не было пар с одинаковыми названиями городов. Решение должно быть через Декартово произведение.
--В результирующей таблице должны быть следующие столбцы: два столбца с названиями городов.

select c1.city, c2.city 
from city c1
cross join city c2
where c1.city != c2.city;

--ЗАДАНИЕ №6
--Используя данные из таблицы rental о дате выдачи фильма в аренду (поле rental_date) и дате возврата (поле return_date),
--вычислите для каждого покупателя среднее количество дней, за которые он возвращает фильмы, округленное до сотых. 
--В результирующей таблице должны быть следующие столбцы: Фамилия и имя пользователя в виде одного значения, 
--среднее количество дней с учетом округления 

select 
	c.first_name||' '||c.last_name as full_name, 
	r.avg_rent_day
from customer c 
join(
	select customer_id, round(avg(return_date::date - rental_date::date),2) as avg_rent_day
	from rental
	group by customer_id 
) r on c.customer_id = r.customer_id;

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Посчитайте для каждого фильма сколько раз его брали в аренду и значение общей стоимости аренды фильма за всё время.
--В результирующей таблице должны быть следующие столбцы: Название фильма, рейтинг фильма, язык фильма, категория фильма, 
--количество аренд фильма, общий размер платежей по фильму.

select 
	f.title, 
	f.rating, 
	l.name as language, 
	cat.name as category, 
	rental_count.rent_count, 
	rental_count.total_summa
from film f
left join language l on f.language_id = l.language_id
left join (
	select
		fc.film_id,
		string_agg(c.name, ', ') as name
	from film_category fc
	join category c on fc.category_id = c.category_id
	group by fc.film_id
) cat on f.film_id = cat.film_id
left join (
	select 
		i.film_id, 
		count(r.rental_id) as rent_count,
		sum(p.amount) as total_summa
	from inventory i 
	join rental r on i.inventory_id = r.inventory_id
	join payment p on r.rental_id = p.rental_id
	group by i.film_id 
) rental_count on f.film_id = rental_count.film_id
order by f.title;


--ЗАДАНИЕ №2
--Доработайте запрос из предыдущего задания и выведите с помощью него фильмы, которые отсутствуют на dvd дисках.
--В результирующей таблице должны быть следующие столбцы: Название фильма, рейтинг фильма, язык фильма, категория фильма, 
--количество аренд фильма, общий размер платежей по фильму.

select 
	f.title, 
	f.rating, 
	l.name as language, 
	cat.name as category, 
	rental_count.rent_count, 
	rental_count.total_summa
from film f
left join language l on f.language_id = l.language_id
left join (
	select
		fc.film_id,
		string_agg(c.name, ', ') as name
	from film_category fc
	join category c on fc.category_id = c.category_id
	group by fc.film_id
) cat on f.film_id = cat.film_id
left join (
	select 
		i.film_id, 
		count(r.rental_id) as rent_count,
		sum(p.amount) as total_summa
	from inventory i 
	join rental r on i.inventory_id = r.inventory_id
	join payment p on r.rental_id = p.rental_id
	group by i.film_id 
) rental_count on f.film_id = rental_count.film_id
where rental_count.film_id is null
order by f.title;

--ЗАДАНИЕ №3
--Посчитайте количество продаж, выполненных каждым продавцом. Добавьте вычисляемую колонку "Премия".
--Если количество продаж превышает 7300, то значение в колонке будет "Да", иначе должно быть значение "Нет".
--В результирующей таблице должны быть следующие столбцы: Фамилия и имя сотрудника в виде одного значения, 
--количество продаж, столбец с указанием будет премия или нет.

select 
	s.first_name||' '||s.last_name as full_name, 
	count(r.rental_id) as rental_count,
	case
		when count(r.rental_id) > 7300 then 'Да'
		else 'Нет'
	end as "Премия"
from staff s
left join rental r on s.staff_id = r.staff_id
group by s.staff_id;




