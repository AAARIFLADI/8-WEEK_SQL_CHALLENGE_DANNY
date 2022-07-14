
--Data creation

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);
INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');


  CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);
INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12')

  
  CREATE TABLE members (
  customer_id VARCHAR(10),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  

select * from DANNY_CHALLENGE..members
select * from DANNY_CHALLENGE..sales
select * from DANNY_CHALLENGE..menu

---The total amount spent by each customer

select A.customer_id,sum(price) as Amount_by_customer from DANNY_CHALLENGE..sales A
left join DANNY_CHALLENGE..menu B on A.product_id=B.product_id
group by A.customer_id

---How many days has each customer visited the restaurant?
select A.customer_id,count(distinct order_date) as Number_of_days from DANNY_CHALLENGE..sales A
left join DANNY_CHALLENGE..menu B on A.product_id=B.product_id
group by A.customer_id

--What was the first item from the menu purchased by each customer?

with product as  (select A.customer_id as customer,product_name,order_date,rank() over (partition by A.customer_id order by order_date) as rk from DANNY_CHALLENGE..sales A
left join DANNY_CHALLENGE..menu B on A.product_id=B.product_id
--group by A.customer_id
)
select customer, product_name from product where rk=1


--What is the most purchased item on the menu and how many times was it purchased by all customers?
With cte as(select product_name,count(product_name) as number_of_purchase,ROW_NUMBER() over (order by count(product_name) desc) as rk from DANNY_CHALLENGE..sales A
left join DANNY_CHALLENGE..menu B on A.product_id=B.product_id
group by product_name)
select product_name,number_of_purchase from cte where rk=1





--Which item was the most popular for each customer?
With cte as(select customer_id, product_name,count(product_name) as number_of_purchase,ROW_NUMBER() over (partition by customer_id order by count(product_name) desc) as rk from DANNY_CHALLENGE..sales A
left join DANNY_CHALLENGE..menu B on A.product_id=B.product_id
group by product_name,customer_id)
select customer_id,product_name,number_of_purchase from cte where rk=1


--Which item was purchased first by the customer after they became a member?

select  AB.customer_id,product_name from (select A.customer_id,A.product_id,A.order_date,B.join_date,ROW_NUMBER() over (partition by A.customer_id order by order_date desc) as rn from DANNY_CHALLENGE..sales A
left join DANNY_CHALLENGE..members B on A.customer_id=B.customer_id
where A.order_date>=B.join_date
)AB,DANNY_CHALLENGE..menu B 
where AB.product_id=B.product_id
and rn=1

---Which item was purchased just before the customer became a member?
select  AB.customer_id,product_name from (select A.customer_id,A.product_id,A.order_date,B.join_date,ROW_NUMBER() over (partition by A.customer_id order by order_date desc) as rn from DANNY_CHALLENGE..sales A
left join DANNY_CHALLENGE..members B on A.customer_id=B.customer_id
where A.order_date<B.join_date or B.join_date is null
)AB,DANNY_CHALLENGE..menu B 
where AB.product_id=B.product_id
--and rn=1

--What is the total items and amount spent for each member before they became a member?
select  AB.customer_id,SUM(price) as AMOUNT_SPENT_BEFORE_JOIN from (select A.customer_id,A.product_id,A.order_date,B.join_date from DANNY_CHALLENGE..sales A
left join DANNY_CHALLENGE..members B on A.customer_id=B.customer_id
where A.order_date<B.join_date or B.join_date is null
)AB,DANNY_CHALLENGE..menu B 
where AB.product_id=B.product_id
group by AB.customer_id

--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH PT as (select product_id,product_name,price,
CASE
WHEN product_name='sushi' then price*2
Else price
END
as point
from DANNY_CHALLENGE..menu)
select A.customer_id,sum(point) as point_total from DANNY_CHALLENGE..sales A join PT on A.product_id=PT.product_id
group by A.customer_id


--In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


WITH CTE AS(select customer_id,M.product_id,product_name,price,order_date,join_date,
CASE
WHEN DATEPART(WEEK,order_date) between DATEPART(WEEK,join_date) and DATEPART(WEEK,join_date)+1 then price*2
WHEN product_name='sushi' then price*2
Else price
END
as point
from DANNY_CHALLENGE..menu M join (select S.product_id,S.customer_id,S.order_date,MS.join_date from DANNY_CHALLENGE..sales S
join DANNY_CHALLENGE..members MS on S.customer_id=MS.customer_id) V on M.product_id=V.product_id)
select CTE.customer_id,SUM(CTE.point) as point from CTE
where order_date<='2021-01-31'
group by CTE.customer_id



