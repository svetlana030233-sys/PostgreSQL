--====== МОДУЛЬ 6. POSTGRESQL =======================================
--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Напишите SQL-запрос, который выводит всю информацию о фильмах со специальным атрибутом "Behind the Scenes".
--В результирующей таблице должны быть следующие столбцы: Название фильма, столбец со специальными атрибутами.

explain analyze -- 100.5 / 0.34
select 
	title,
	special_features
from film 
where 'Behind the Scenes' = any (special_features);

--ЗАДАНИЕ №2
--Напишите еще 2 варианта поиска фильмов с атрибутом "Behind the Scenes",
--используя другие функции или операторы языка SQL для поиска значения в массиве.
--В результирующей таблице должны быть следующие столбцы: Название фильма, столбец со специальными атрибутами.

explain analyze --140.50 /0.77
select title, unnest
from(
	select title, unnest(special_features)
	from film)
where unnest = 'Behind the Scenes';

explain analyze --100.5 / 0.39
select 
	title, 
	special_features
from film
where special_features @> array['Behind the Scenes'];

explain analyze --100.5 / 0.37
select 
	title, 
	special_features
from film
where array_position(special_features, 'Behind the Scenes') is not null;

--ЗАДАНИЕ №3
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов 
--со специальным атрибутом "Behind the Scenes.
--Обязательное условие для выполнения задания: используйте запрос из задания 1, 
--помещенный в CTE. CTE необходимо использовать для решения задания.
--В результирующей таблице должны быть следующие столбцы: Фамилия и имя пользователя в виде одного значения, 
--количество арендованных фильмов.

explain analyze --792.37 / 11.79
with cte as(
	select
		film_id
	from film
	where special_features @> array['Behind the Scenes'])
select 
	c.first_name || ' ' || c.last_name as full_name,
	count(r.rental_id)
from customer c
join rental r on c.customer_id = r.customer_id 
join inventory i on r.inventory_id = i.inventory_id 
join cte on i.film_id = cte.film_id
group by c.customer_id, full_name
order by full_name;

--ЗАДАНИЕ №4
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов
-- со специальным атрибутом "Behind the Scenes".
--Обязательное условие для выполнения задания: используйте запрос из задания 1,
--помещенный в подзапрос, который необходимо использовать для решения задания.
--В результирующей таблице должны быть следующие столбцы: Фамилия и имя пользователя в виде одного значения, 
--количество арендованных фильмов.

explain analyze --792.37 / 11.67
select 
	c.first_name || ' ' || c.last_name as full_name,
	count(r.rental_id)
from customer c
join rental r on c.customer_id = r.customer_id 
join inventory i on r.inventory_id = i.inventory_id 
join (select
		film_id
	  from film
	  where special_features @> array['Behind the Scenes']) as f on i.film_id = f.film_id
group by c.customer_id, full_name;

--ЗАДАНИЕ №5
--Создайте материализованное представление с запросом из предыдущего задания
--и напишите запрос для обновления материализованного представления

create materialized view cust_rental as
	select 
		c.first_name || ' ' || c.last_name as full_name,
		count(r.rental_id)
	from customer c
	join rental r on c.customer_id = r.customer_id 
	join inventory i on r.inventory_id = i.inventory_id 
	join (select
			film_id
		  from film
		  where special_features @> array['Behind the Scenes']) as f on i.film_id = f.film_id
	group by c.customer_id, full_name;

refresh materialized view cust_rental;


--ЗАДАНИЕ №6
--С помощью explain analyze проведите анализ стоимости выполнения запросов из предыдущих заданий и ответьте на вопросы:
--1. с каким оператором или функцией языка SQL, используемыми при выполнении домашнего задания: 
--поиск значения в массиве затрачивает меньше ресурсов системы;
--2. какой вариант вычислений затрачивает меньше ресурсов системы: 
--с использованием CTE или с использованием подзапроса.

1. примерно одинаковое количество ресурсов затрачивают:
any() 100.5 / 0.34
функция array_position 100.5 / 0.37
оператор @>  100.5 / 0.39

самым оптимальным по времени выполнения является конструкция any() 0.34

наиболее энергозатратным вариантом является функция unnest с подзапросом 140.50 / 0.711

2. СТЕ и подзапрос используют примерно одинаковое количество ресурсов 792.37 / 11.79 и 792.37 / 11.67 соответственно, 
но подзапрос все же немного быстрее по времени

