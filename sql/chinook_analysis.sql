-- Confirm all tables exist
SHOW TABLES;

-- Spot-check row counts
SELECT 'Artist' AS tbl, COUNT(*) FROM Artist
UNION ALL SELECT 'Track', COUNT(*) FROM Track
UNION ALL SELECT 'Customer', COUNT(*) FROM Customer
UNION ALL SELECT 'Invoice', COUNT(*) FROM Invoice
UNION ALL SELECT 'PlaylistTrack', COUNT(*) FROM PlaylistTrack
UNION ALL SELECT 'Genre', COUNT(*) FROM Genre
UNION ALL SELECT 'Playlist', COUNT(*) FROM Playlist
UNION ALL SELECT 'MediaType', COUNT(*) FROM MediaType
UNION ALL SELECT 'Album', COUNT(*) FROM Album
UNION ALL SELECT 'Employee', COUNT(*) FROM Employee
UNION ALL SELECT 'InvoiceLine', COUNT(*) FROM InvoiceLine;


-- Inspecting Columns
SELECT * FROM Genre;
SELECT * FROM Track;
SELECT * FROM MediaType;
SELECT * FROM Artist;
SELECT * FROM Album;
SELECT * FROM Track;
SELECT * FROM Employee;
SELECT * FROM Customer;
SELECT * FROM Invoice;
SELECT * FROM InvoiceLine;
SELECT * FROM Playlist;
SELECT * FROM PlaylistTrack;


-- Explpratory Data Analysis
-- Q1. Which countries do our customers come from, and how many customers are in each?
SELECT Country, COUNT(CustomerId) AS total_customers
FROM customer
GROUP BY Country
ORDER BY total_customers DESC;


-- Q2. What are the top 10 longest tracks in the database?
SELECT Name, (Milliseconds / 60000.0) AS duration_minutes
FROM track
ORDER BY duration_minutes DESC
LIMIT 10;


-- Q3. How many tracks belong to each genre?
SELECT g.Name AS genre, COUNT(t.TrackId) AS track_count
FROM genre g
JOIN track t 
	ON g.GenreId = t.GenreId
GROUP BY g.Name
ORDER BY track_count DESC;


-- Q4. What is the total revenue generated overall?
SELECT ROUND(SUM(Total), 2) AS total_revenue
FROM invoice;


-- Q5. Who are the top 5 customers by total spend?
SELECT 
    c.FirstName, 
    c.LastName, 
    c.Country,
    ROUND(SUM(i.Total), 2) AS total_spent
FROM customer c
JOIN invoice i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId, c.FirstName, c.LastName, c.Country
ORDER BY total_spent DESC
LIMIT 5;


-- Q6. Which artist has the most tracks across all albums?
SELECT 
    ar.Name AS artist,
    COUNT(t.TrackId) AS total_tracks
FROM artist ar
JOIN album al 
	ON ar.ArtistId = al.ArtistId
JOIN track t  
	ON al.AlbumId  = t.AlbumId
GROUP BY ar.ArtistId, ar.Name
ORDER BY total_tracks DESC
LIMIT 1;


-- Q7. What are the monthly revenue trends over time?
SELECT 
    DATE_FORMAT(InvoiceDate, '%Y-%m') AS month,
    ROUND(SUM(Total), 2)              AS monthly_revenue,
    COUNT(InvoiceId)                  AS invoice_count
FROM invoice
GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
ORDER BY month;


-- Q8. Which employee supports the most valuable customers (by total spend)?
SELECT 
    CONCAT(e.FirstName, ' ', e.LastName) AS support_rep,
    COUNT(DISTINCT c.CustomerId)          AS customer_count,
    ROUND(SUM(i.Total), 2)               AS revenue_managed
FROM employee e
JOIN customer c 
	ON e.EmployeeId = c.SupportRepId
JOIN invoice  i 
	ON c.CustomerId  = i.CustomerId
GROUP BY e.EmployeeId, e.FirstName, e.LastName
ORDER BY revenue_managed DESC;


-- Q9. What is each customer's running total spend over time?
SELECT 
    c.FirstName,
    c.LastName,
    i.InvoiceDate,
    i.Total,
    ROUND(SUM(i.Total) OVER (
        PARTITION BY c.CustomerId 
        ORDER BY i.InvoiceDate
    ), 2) AS running_total
FROM customer c
JOIN invoice i 
	ON c.CustomerId = i.CustomerId
ORDER BY c.CustomerId, i.InvoiceDate;


-- Q10. Which tracks have never been purchased?
SELECT t.TrackId, t.Name, g.Name AS genre
FROM track t
JOIN genre g ON t.GenreId = g.GenreId
WHERE t.TrackId NOT IN (
    SELECT DISTINCT TrackId 
    FROM invoiceline
);


-- Q11. Rank customers within each country by their total spend
WITH customer_ranking (CustomerId, customer_name, Country, total_spent) AS
(
SELECT 
	c.CustomerId, 
	CONCAT(c.FirstName, ' ', c.LastName) AS customer_name, 
	c.Country, SUM(i.Total) AS total_spent
FROM customer c
JOIN invoice i
	ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId, c.Country, c.FirstName, c.LastName
)
SELECT 
	customer_name, 
	Country, 
	total_spent,
DENSE_RANK() OVER(PARTITION BY Country ORDER BY total_spent DESC) AS customer_rank
FROM customer_ranking
ORDER BY Country, customer_rank;


-- Q12. Find the most popular genre per country by invoice revenue
WITH popular_genre (Genre, Country, Total_revenue) AS
(
SELECT g.name, c.country, SUM(i.total) AS total_revenue
FROM genre g
JOIN track t
	ON g.GenreId = t.GenreId
JOIN invoiceline inv
	ON t.TrackId = inv.TrackId
JOIN invoice i
	ON inv.InvoiceId = i.InvoiceId
JOIN customer c
	ON i.CustomerId = c.CustomerId
GROUP BY g.name, c.country
ORDER BY c.country, total_revenue DESC
), 
genre_ranking AS
(
SELECT Genre, Country, Total_revenue,
DENSE_RANK() OVER (PARTITION BY Country ORDER BY Total_revenue DESC) AS genre_rank
FROM popular_genre
ORDER BY Country, genre_rank
)
SELECT Country, Genre, Total_revenue
FROM genre_ranking
WHERE genre_rank = 1
ORDER BY total_revenue DESC;



























