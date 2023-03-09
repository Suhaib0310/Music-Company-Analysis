-- Total invoices per country

SELECT billing_country, COUNT(*) AS number_of_invoice FROM invoice
GROUP BY billing_country
ORDER BY 2 DESC;


-- top 3 values of invoices

SELECT total AS amount FROM invoice
ORDER BY total DESC
LIMIT 3;


-- Top 3 Cities with highest invoice total

SELECT billing_city, SUM(total) AS amount FROM invoice
GROUP BY billing_city
ORDER BY 2 DESC
LIMIT 3;


-- Customer who has spent the most money

SELECT invoice.customer_id, CONCAT(first_name, ' ', last_name)AS customer , SUM(total) AS amount FROM invoice
JOIN customer
on invoice.customer_id = customer.customer_id
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 1;


-- customer's name, email who listen to Rock genre

SELECT first_name, last_name, email FROM customer
JOIN invoice
ON customer.customer_id = invoice.customer_id
JOIN invoice_line
ON invoice.invoice_id = invoice_line_id
JOIN track
ON track.track_id = invoice_line.invoice_line_id
JOIN genre
ON track.genre_id = genre.genre_id
WHERE genre.name = 'Rock'
ORDER BY 3 ;


-- Top 10 artists with most Rock songs

SELECT artist.name AS artist, COUNT(genre.genre_id) AS number_of_rock_songs FROM artist
JOIN album1
ON artist.artist_id = album1.artist_id
JOIN track
ON album1.album_id = track.album_id
JOIN genre
ON track.genre_id = genre.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;


-- Songs that are longer than the avg song lenght

SELECT name, milliseconds FROM track
WHERE milliseconds > (SELECT avg(milliseconds) FROM track)
ORDER BY 2;


-- break through by customer of highest selling artist using CTE

WITH best_selling_artist AS (

SELECT ar.artist_id, ar.name AS artist_name, SUM(il.unit_price*il.quantity) AS amount FROM invoice_line il
JOIN track t
ON il.track_id = t.track_id
JOIN album1 a
ON a.album_id = t.album_id
JOIN artist ar
ON a.artist_id = ar.artist_id
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 1)
SELECT c.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer, bsa.artist_name,  SUM(il.unit_price*quantity) AS amount_spend FROM invoice i
JOIN customer c
ON c.customer_id = i.customer_id
JOIN invoice_line il
ON i.invoice_id = il.invoice_line_id
JOIN track t
ON il.track_id = t.track_id
JOIN album1 a
ON t.album_id = a.album_id
JOIN best_selling_artist bsa
ON a.artist_id = bsa.artist_id
GROUP BY 1,2,3
ORDER BY 4 DESC;


-- Most popular genre in each country using CTE


WITH popular_genre AS (

SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id, ROW_NUMBER() OVER(PARTITION BY customer.country
ORDER BY COUNT(invoice_line.quantity) DESC) AS row_no
FROM invoice_line
JOIN invoice
ON invoice_line.invoice_line_id = invoice.invoice_id
JOIN customer
ON invoice.customer_id = customer.customer_id
JOIN track
ON invoice_line.track_id = track.track_id
JOIN genre 
ON track.track_id = genre.genre_id
GROUP BY 2,3,4
ORDER BY 2, 1 DESC)
SELECT purchases, country, name, genre_id FROM popular_genre
WHERE row_no = 1;


-- customer who has spend the most from each country using recursive

WITH RECURSIVE

customer_from_country AS (
SELECT c.customer_id, c.first_name, c.last_name, billing_country, SUM(total) AS total_spending FROM customer c
JOIN invoice i
ON c.customer_id = i.customer_id
GROUP BY 1,2,3,4
ORDER BY 1),

country_max_spending AS (
SELECT billing_country, MAX(total_spending) AS max_spending FROM customer_from_country
GROUP BY 1)

SELECT cc.billing_country AS country, cc.customer_id, CONCAT(cc.first_name, ' ', cc.last_name) AS customer, ms.max_spending FROM customer_from_country as cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;


-- country with maximum sales by employee

WITH emp_max_sale_country AS (

SELECT i.billing_country, emp.employee_id, CONCAT(emp.first_name, ' ', emp.last_name) AS employee, COUNT(i.invoice_id) AS number_of_sales,
ROW_NUMBER() OVER(PARTITION BY i.billing_country ORDER BY COUNT(i.invoice_id) DESC) AS row_no FROM employee emp
JOIN customer c 
ON emp.employee_id = c.support_rep_id
JOIN invoice i
ON c.customer_id = i.customer_id
GROUP BY 3, 1,2)
SELECT billing_country, employee_id, employee, number_of_sales FROM emp_max_sale_country
WHERE row_no= 1
ORDER BY billing_country;
