CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
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
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


  --What is the total amount each customer spent at the restaurant?

  SELECT s.customer_id, sum(m.price) from sales s
  join menu m 
  on s.product_id = m.product_id
  group by customer_id

 
  ------ How many days has each customer visited the restaurant?

    SELECT customer_id, count(distinct order_date) as visted from sales 
  group by customer_id


  ---What was the first item from the menu purchased by each customer?

WITH ct AS
  (SELECT customer_id, order_date, product_name,
 DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rank_num
   FROM sales AS s
   JOIN menu AS m ON s.product_id = m.product_id)
SELECT customer_id, product_name FROM ct
WHERE rank_num = 1
GROUP BY customer_id,product_name;


---4. What is the most purchased item on the menu and how many times was it purchased by all customers?


select top 1 (count(s.product_id)) as most , m.product_name 
from sales s 
join menu m 
on s.product_id = m.product_id
group by s.product_id, product_name
order by s.product_id desc

---5. Which item was the most popular for each customer?

with ct as(SELECT s.customer_id, m.product_name, COUNT(m.product_id) AS order_count, DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.customer_id) DESC) AS rank
FROM menu AS m
JOIN sales AS s
ON m.product_id = s.product_id
GROUP BY s.customer_id, m.product_name)
select customer_id, product_name, order_count from ct
where rank = 1
group by customer_id, product_name,order_count


---Which item was purchased first by the customer after they became a member?---

 
 with ct as (SELECT s.customer_id, m.join_date, s.order_date,  s.product_id,  DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rank
FROM sales AS s
 JOIN members AS m
 ON s.customer_id = m.customer_id
 WHERE s.order_date >= m.join_date)

SELECT s.customer_id, s.order_date, m2.product_name  FROM ct AS s
JOIN menu AS m2
ON s.product_id = m2.product_id
WHERE rank = 1;

---7. Which item was purchased just before the customer became a member?

with ct as (SELECT s.customer_id, m.join_date, s.order_date,  s.product_id,  DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rank
FROM sales AS s
 JOIN members AS m
 ON s.customer_id = m.customer_id
 WHERE s.order_date < m.join_date)
 SELECT s.customer_id, s.order_date, m2.product_name  FROM ct AS s
JOIN menu AS m2
ON s.product_id = m2.product_id
WHERE rank = 1;

---What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id, COUNT(DISTINCT s.product_id) AS tota_item, CONCAT('$', SUM(mm. price)) AS amount_spent  FROM sales AS s
JOIN members AS m
ON s.customer_id = m.customer_id
JOIN menu AS mm
ON s.product_id = mm.product_id
WHERE s.order_date < m.join_date
GROUP BY s.customer_id;

  --9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with ct as
(SELECT *, CASE WHEN product_id = 1 THEN price * 20 ELSE price * 10 END AS points FROM menu)
SELECT s.customer_id, SUM(p.points) AS total_points FROM ct AS p
JOIN sales AS s 
ON p.product_id = s.product_id
GROUP BY s.customer_id

--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi — how many points do customer A and B have at the end of January?



----join all
SELECT s.customer_id, s.order_date, m.product_name, m.price,
CASE
 WHEN mm.join_date > s.order_date THEN 'N'
 WHEN mm.join_date <= s.order_date THEN 'Y'
 ELSE 'N'
 END AS member
FROM sales AS s
LEFT JOIN menu AS m
ON s.product_id = m.product_id
LEFT JOIN members AS mm
ON s.customer_id = mm.customer_id;

-----new ranking all


WITH summary_cte AS 
(SELECT s.customer_id, s.order_date, m.product_name, m.price,
  CASE
  WHEN mm.join_date > s.order_date THEN 'N'
  WHEN mm.join_date <= s.order_date THEN 'Y'
  ELSE 'N' END AS member
 FROM sales AS s
 LEFT JOIN menu AS m
  ON s.product_id = m.product_id
 LEFT JOIN members AS mm
  ON s.customer_id = mm.customer_id)
SELECT *, CASE WHEN member = 'N' then NULL ELSE RANK () OVER(PARTITION BY customer_id, member ORDER BY order_date) END AS ranking
FROM summary_cte;


  select * from sales 
  select * from menu
  select * from members