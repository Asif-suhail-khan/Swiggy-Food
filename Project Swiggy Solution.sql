use swiggy
select * from swiggy_data

-- CHAPTER 1: Data validation & Cleaning
-- Step 1 : Null check

select * from swiggy_data
select
    sum(case when State is null then 1 else 0 end) as null_state,
    sum(case when City is null then 1 else 0 end) as null_city,
    sum(case when Order_Date is null then 1 else 0 end) as null_order_date,
    sum(case when Restaurant_Name is null then 1 else 0 end) as null_restaurant,
    sum(case when Location is null then 1 else 0 end) as null_location,
    sum(case when Category is null then 1 else 0 end) as null_category,
    sum(case when Dish_Name is null then 1 else 0 end) as null_dish,
    sum(case when Price_INR is null then 1 else 0 end) as null_price,
    sum(case when Rating is null then 1 else 0 end) as null_rating,
    sum(case when Rating_Count is null then 1 else 0 end) as null_rating_count
from swiggy_data;

-- STEP 2 : Check blank or Empty Strings
select * from swiggy_data
where State = '' or Restaurant_Name = '' or Location = '' or Category='' or Dish_Name=''

-- STEP 3 : Duplicate Detection
select
    state, city, order_date, restaurant_name , location , category, dish_Name , price_INR ,
    rating ,rating_count, count(*) as cnt
from swiggy_data
group by
    State, City, Order_Date, Restaurant_Name , Location , Category, Dish_Name , Price_INR ,
    Rating ,Rating_Count
Having Count(*)>1

-- STEP 4 : Delete Duplication
with cte as(
    select *, row_number() over
        (partition by State, City, Order_Date, Restaurant_Name , Location , Category, Dish_Name , Price_INR , Rating ,Rating_Count
        order by (select null)) as rn
        from swiggy_data
)
delete from cte where rn>1

-- CHAPTER 2 --
-- creating tables
-- dimension tables
-- date tables

create table dim_date (
    date_id int identity(1,1) primary key,
    full_date Date,
    year int,
    month int,
    month_name varchar(20),
    quarter int,
    day int,
    week int
)

create table dim_location (
    location_id int identity(1,1) primary key,
    state varchar(100),
    city varchar(100),
    location varchar(200)
)

-- STEP 3 : Dim restaurant
create table dim_restaurant (
    restaurant_id int identity(1,1) primary key,
    restaurant_Name varchar(200)
)

-- STEP 4 : dim_categroy
create table dim_category(
    category_id int identity(1,1) primary key,
    category varchar (200)
)

-- STEP 5 ; dim_dish
create table dim_dish (
    dish_id   int identity (1,1) primary key,
    dish_name varchar(200)
)

CREATE TABLE fact_swiggy_orders (
    order_id INT IDENTITY(1,1) PRIMARY KEY,

    date_id INT,
    Price_INR DECIMAL(10,2),
    Rating DECIMAL(4,2),
    Rating_Count INT,

    location_id INT,
    restaurant_id INT,
    category_id INT,
    dish_id INT,

    FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (location_id) REFERENCES dim_location(location_id),
    FOREIGN KEY (restaurant_id) REFERENCES dim_restaurant(restaurant_id),
    FOREIGN KEY (category_id) REFERENCES dim_category(category_id),
    FOREIGN KEY (dish_id) REFERENCES dim_dish(dish_id)
);

select * from swiggy_data

-- CHAPTER 3 : insert data in tables

insert into dim_date ( full_date, year , month , month_name , quarter , day , week )
select distinct
    order_date,
    year(order_date),
    month(order_date),
    datename(month,order_date),
    datepart(quarter, order_date),
    day(order_date),
    datepart(week, order_date)
from swiggy_data


insert dim_location (state,city,location)
select distinct
    state,
    city,
    location
from swiggy_data

insert dim_restaurant (restaurant_name)
select distinct
    restaurant_name
from swiggy_data

insert dim_category (category)
select distinct
    category
from swiggy_data

-- STEP :
insert dim_dish (dish_name)
select distinct
    dish_name
from swiggy_data

-- STEP : fact_table

insert into fact_swiggy_orders
(
    date_id,
    Price_INR,
    Rating,
    Rating_Count,
    Location_id,
    restaurant_id,
    category_id,
    dish_id
)
select dd.date_id,
       s.price_inr,
       s.rating,
       s.rating_count,
       dl.location_id,
       dr.restaurant_id,
       dc.category_id,
       dsh.dish_id
from swiggy_data as s

join dim_date as dd
    on dd.full_Date = s.order_date

join dim_location as dl
    on dl.state = s.state
    and dl.city=s.city
    and dl.location = s.location

join dim_restaurant as dr
    on dr.restaurant_name = s.restaurant_name

join dim_category as dc
    on dc.category = s.category

join dim_dish as dsh
    on dsh.dish_name = s.dish_name


select * from fact_swiggy_orders as f
inner join dim_date as d on f.date_id = d.date_id
inner join dim_location as l on f.location_id = l.location_id
inner join dim_category as c on f.category_id = c.category_id
inner join dim_dish as di on f.dish_id = di.dish_id

-- CHAPTER 4 --
-- KPI's
-- 1. Total Orders
select count(*)  as total_orders  from fact_swiggy_orders

-- 2. Total Revenue (INR Million)
select
    format(sum(convert(Float,price_inr)) /100000,'N2') + ' INR Million'
    as total_revenue
from fact_swiggy_orders

-- 3 . Average Dish Price
select
    format(avg(convert(Float,price_inr)),'N2') + ' INR'
        as Avg_order_value
from fact_swiggy_orders

-- 4. Avg Rating
select avg(rating) as Avg_rating from fact_swiggy_orders

-- 5. Granular Requirments
-- Deep Dive Business Analysis

-- 6. Monthly order Trend
select d.year , d.month, d.month_name ,count(*) as total_orders
from fact_swiggy_orders as f
join dim_date  as d on f.date_id = d.date_id
group by d.year,d.month ,d.month_name

-- 7. Monthly Revenue
select d.year , d.month, d.month_name ,sum(price_inr) as total_orders
from fact_swiggy_orders as f
join dim_date  as d on f.date_id = d.date_id
group by d.year,d.month ,d.month_name
order by sum(price_inr) desc

-- STEP 6. Monthly order Trend
select d.year , d.quarter , count(*) as total_orders
from fact_swiggy_orders as f
join dim_date as d on f.date_id = d.date_id
group by d.year,d.quarter
order by count(*) desc

-- STEP 7. Yearly Trends
select d.year , count(*) as total_orders
from fact_swiggy_orders as f
join dim_date as d on f.date_id = d.date_id
group by d.year
order by count(*) desc

-- STEP 8. Orders by day of week (Mon-Sun)

select
    datename(weekday,d.full_date) as day_name,
    count(*) as total_order
from fact_swiggy_orders  as f
join dim_date  as d on f.date_id = d.date_id
group by
datename(weekday,d.full_date), datepart(weekday,d.full_date)
order by datepart(weekday,d.full_date)

-- STEP 9. Top 10 Cities by order volume
select top 10 l.city,count(*) as total_orders from fact_swiggy_orders f
join dim_location as l on l.location_id = f.location_id
group by l.city
order by count(*) desc

-- STEP 9. Top 10 Cities by  revenue

select top 10 l.city,sum(f.price_inr) as total_revenue from fact_swiggy_orders f
join dim_location as l on l.location_id = f.location_id
group by l.city
order by total_revenue desc

-- STEP 10. Revenue contribution by states
select top 10 l.state,sum(f.price_inr) as total_revenue from fact_swiggy_orders f
join dim_location as l on l.location_id = f.location_id
group by l.state
order by total_revenue desc

-- STEP 10. Top 10 . Restaurant by orders
select top 10 r.restaurant_name ,sum(f.price_inr) as total_revenue
from fact_swiggy_orders f
join dim_restaurant r on r.restaurant_id= f.restaurant_id
group by r.restaurant_name
order by total_revenue desc

-- STEP 11 . Top categories by order volume
select
c.category,
count(*) as total_orders
from fact_swiggy_orders as f
join dim_category as c on f.category_id = c.category_id
group by c.category
order by total_orders desc

-- STEP 12 . Most ordered Dishes
select
d.dish_name,
count(*) as order_count
from dim_dish as d inner join fact_swiggy_orders as f
on
f.dish_id = d.dish_id
group by d.dish_name
order by order_count desc

-- STEP 13. Cuisine Performance (Orders + Avg Rating)
select
    c.category,
    count(*) as total_orders,
    round(avg(convert(float,f.rating)),2) as avg_rating
from  fact_swiggy_orders f
join dim_category as c on f.category_id  = c.category_id
group by c.category
order by total_orders desc

-- CHAPTER 5 --
-- STEP 1 : Bucket of each person spend
SELECT
    CASE
        WHEN CONVERT(FLOAT, price_inr) < 100 THEN 'Under 100'
        WHEN CONVERT(FLOAT, price_inr) BETWEEN 100 AND 199 THEN '100 - 199'
        WHEN CONVERT(FLOAT, price_inr) BETWEEN 200 AND 299 THEN '200 - 299'
        WHEN CONVERT(FLOAT, price_inr) BETWEEN 300 AND 499 THEN '300 - 499'
        ELSE '500+'
    END AS price_range,
    COUNT(*) AS total_orders
FROM fact_swiggy_orders
GROUP BY
    CASE
        WHEN CONVERT(FLOAT, price_inr) < 100 THEN 'Under 100'
        WHEN CONVERT(FLOAT, price_inr) BETWEEN 100 AND 199 THEN '100 - 199'
        WHEN CONVERT(FLOAT, price_inr) BETWEEN 200 AND 299 THEN '200 - 299'
        WHEN CONVERT(FLOAT, price_inr) BETWEEN 300 AND 499 THEN '300 - 499'
        ELSE '500+'
    END
ORDER BY total_orders DESC;

-- STEP 2 : Rating Count Distribution
select
    rating,
    count(*) as rating_count
from fact_swiggy_orders
group by rating
order by rating