USE sakila;
SELECT * FROM staff;

# 1a. Display the first and last names of all actors from the table `actor`. 
SELECT first_name, last_name FROM actor;

# 1b. Display the first and last name of each actor in a single column in upper case letters. Name the column `Actor Name`. 
SELECT CONCAT(first_name," ", last_name) FROM actor;

# 2a. You need to find the ID number, first name, and last name of an actor, of whom you know only the first name, "Joe." What is one query would you use to obtain this information?
SELECT actor_id, first_name, last_name FROM actor WHERE first_name = "Joe";

# 2b. Find all actors whose last name contain the letters `GEN`:
SELECT * FROM actor WHERE last_name LIKE "%GEN%";
  	
# 2c. Find all actors whose last names contain the letters `LI`. This time, order the rows by last name and first name, in that order:
SELECT * FROM actor WHERE last_name LIKE "%GEN%" ORDER BY last_name, first_name;

# 2d. Using `IN`, display the `country_id` and `country` columns of the following countries: Afghanistan, Bangladesh, and China:
SELECT country_id, country FROM country WHERE country IN ("Afghanistan", "Bangladesh", "China");

# 3a. Add a `middle_name` column to the table `actor`. Position it between `first_name` and `last_name`. Hint: you will need to specify the data type.
ALTER TABLE actor DROP COLUMN middle_name;
ALTER TABLE actor ADD middle_name VARCHAR(20) DEFAULT "FRANCIS" AFTER first_name;
SELECT * FROM actor;

# 3b. You realize that some of these actors have tremendously long last names. Change the data type of the `middle_name` column to `blobs`.
ALTER TABLE actor MODIFY COLUMN middle_name BLOB;

# 3c. Now delete the `middle_name` column.
ALTER TABLE actor DROP COLUMN middle_name;

# 4a. List the last names of actors, as well as how many actors have that last name.
SELECT last_name, COUNT(last_name) FROM actor GROUP BY last_name;
  	
# 4b. List last names of actors and the number of actors who have that last name, but only for names that are shared by at least two actors
SELECT * FROM
(SELECT last_name, COUNT(last_name) `count` FROM actor  GROUP BY last_name) AS t
WHERE (`count` > 2);
# 4c. Oh, no! The actor `HARPO WILLIAMS` was accidentally entered in the `actor` table as `GROUCHO WILLIAMS`, the name of Harpo's second cousin's husband's yoga teacher. Write a query to fix the record.
SELECT * FROM actor WHERE last_name = "WILLIAMS";

UPDATE actor SET first_name = "HARPO"
WHERE actor_id = 172;

# 4d. Perhaps we were too hasty in changing `GROUCHO` to `HARPO`. It turns out that `GROUCHO` was the correct name after all! In a single query, 
# if the first name of the actor is currently `HARPO`, change it to `GROUCHO`. Otherwise, change the first name to `MUCHO GROUCHO`, 
# as that is exactly what the actor will be with the grievous error. BE CAREFUL NOT TO CHANGE THE FIRST NAME OF EVERY ACTOR TO `MUCHO GROUCHO`, 
# HOWEVER! (Hint: update the record using a unique identifier.)
UPDATE ACTOR
SET FIRST_NAME = CASE 
WHEN FIRST_NAME = 'HARPO' THEN 'GROUCHO' ELSE 'MUCHO GROUCHO' END 
WHERE ACTOR_ID =172;

# 5a. You cannot locate the schema of the `address` table. Which query would you use to re-create it?
CREATE TABLE `address` (
  `address_id` SMALLINT(5) UNSIGNED NOT NULL AUTO_INCREMENT,
  `address` VARCHAR(50) NOT NULL,
  `address2` VARCHAR(50) DEFAULT NULL,
  `district` VARCHAR(20) NOT NULL,
  `city_id` SMALLINT(5) UNSIGNED NOT NULL,
  `postal_code` VARCHAR(10) DEFAULT NULL,
  `phone` VARCHAR(20) NOT NULL,
  `location` GEOMETRY NOT NULL,
  `last_update` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`address_id`),
  KEY `idx_fk_city_id` (`city_id`),
  SPATIAL KEY `idx_location` (`location`),
  CONSTRAINT `fk_address_city` FOREIGN KEY (`city_id`) REFERENCES `city` (`city_id`) ON UPDATE CASCADE
) ENGINE=INNODB AUTO_INCREMENT=606 DEFAULT CHARSET=UTF8;

# 6a. Use `JOIN` to display the first and last names, as well as the address, of each staff member. Use the tables `staff` and `address`:
SELECT * FROM staff LEFT JOIN address ON staff.address_id = address.address_id;

# 6b. Use `JOIN` to display the total amount rung up by each staff member in August of 2005. Use tables `staff` and `payment`. 
#select staff_id
SELECT * FROM staff LEFT JOIN
(SELECT staff_id, SUM(amount) FROM payment 
WHERE payment_date BETWEEN '2005-08-01 00:00:00' AND '2005-08-31 23:59:59'
GROUP BY(staff_id)) sums
ON staff.staff_id = sums.staff_id;

# 6c. List each film and the number of actors who are listed for that film. Use tables `film_actor` and `film`. Use inner join.
SELECT title, counts.actor_count  FROM film LEFT JOIN
(SELECT film_id, COUNT(actor_id) actor_count FROM film_actor GROUP BY(film_id)) counts 
ON film.film_id = counts.film_id;
    
# 6d. How many copies of the film `Hunchback Impossible` exist in the inventory system?
SELECT * FROM film WHERE title = "Hunchback Impossible"; # id = 439
SELECT COUNT(inventory_id) `Copies of Hunchback Impossible` FROM inventory WHERE film_id = 439 GROUP BY(film_id);

# 6e. Using the tables `payment` and `customer` and the `JOIN` command, list the total paid by each customer. List the customers alphabetically by last name:
SELECT first_name, last_name, customer_sums.customer_sum FROM customer JOIN
	(SELECT customer_id, SUM(amount) customer_sum FROM payment GROUP BY(customer_id)) customer_sums
	ON customer_sums.customer_id = customer.customer_id
	ORDER BY last_name;

# 7a. The music of Queen and Kris Kristofferson have seen an unlikely resurgence. As an unintended consequence, films starting with the letters `K` and `Q` have also soared in popularity. Use subqueries to display the titles of movies starting with the letters `K` and `Q` whose language is English. 
SELECT title FROM film WHERE title LIKE "K%" OR title LIKE "Q%" AND language_id = 1;

# 7b. Use subqueries to display all actors who appear in the film `Alone Trip`.
SELECT first_name, last_name FROM actor WHERE actor_id IN
	(SELECT actor_id FROM film_actor WHERE film_id IN
	(SELECT film_id FROM film WHERE title = "Alone Trip"));

# 7c. You want to run an email marketing campaign in Canada, for which you will need the names and email addresses of all Canadian customers. Use joins to retrieve this information.
SELECT email FROM customer WHERE address_id IN
	(SELECT address_id FROM address WHERE city_id IN
	(SELECT city_id FROM city WHERE country_id IN
	(SELECT country_id FROM country WHERE country = "CANADA")));

# 7d. Sales have been lagging among young families, and you wish to target all family movies for a promotion. Identify all movies categorized as famiy films.
SELECT * FROM film WHERE film_id IN
(SELECT film_id FROM film_category WHERE category_id IN
(SELECT category_id FROM category WHERE name = "Family"));

# 7e. Display the most frequently rented movies in descending order.
SELECT title,k.`# of rentals` FROM film JOIN
(SELECT film_id, COUNT(rental_id) `# of rentals` FROM
(SELECT rental_id, film_id FROM rental LEFT JOIN inventory ON inventory.inventory_id = rental.inventory_id) j
GROUP BY(film_id)) k
ON k.film_id = film.film_id
ORDER BY `# of rentals` DESC;

# 7f. Write a query to display how much business, in dollars, each store brought in.
SELECT store_id, SUM(`1st`.amount) `$` FROM staff JOIN
(SELECT staff_id, amount FROM payment) `1st` 
WHERE staff.staff_id = `1st`.staff_id
GROUP BY store_id;


# 7g. Write a query to display for each store its store ID, city, and country.
SELECT store_id, city, country FROM store JOIN
(SELECT city, country, address_id FROM address JOIN
(SELECT city_id, city, country FROM city JOIN country ON city.country_id = country.country_id) ii
ON address.city_id = ii.city_id) jj
ON store.address_id = jj.address_id;


# 7h. List the top five genres in gross revenue in descending order. (**Hint**: you may need to use the following tables: category, film_category, inventory, payment, and rental.)
SELECT `name`, SUM(amount) `$` FROM category RIGHT JOIN
(SELECT amount, category_id FROM film_category RIGHT JOIN
(SELECT amount, film_id FROM inventory RIGHT JOIN
(SELECT amount, inventory_id FROM payment LEFT JOIN rental
ON rental.rental_id = payment.rental_id) ii
ON inventory.inventory_id = ii.inventory_id) jj
ON film_category.film_id = jj.film_id) kk
ON category.category_id = kk.category_id
GROUP BY(kk.category_id)
ORDER BY `$` DESC
LIMIT 5;


# 8a. In your new role as an executive, you would like to have an easy way of viewing the Top five genres by gross revenue. Use the solution from the problem above to create a view. If you haven't solved 7h, you can substitute another query to create a view.
CREATE VIEW genre (`genre`,`$`) AS
(SELECT `name`, SUM(amount) `$` FROM category RIGHT JOIN
(SELECT amount, category_id FROM film_category RIGHT JOIN
(SELECT amount, film_id FROM inventory RIGHT JOIN
(SELECT amount, inventory_id FROM payment LEFT JOIN rental
ON rental.rental_id = payment.rental_id) ii
ON inventory.inventory_id = ii.inventory_id) jj
ON film_category.film_id = jj.film_id) kk
ON category.category_id = kk.category_id
GROUP BY(kk.category_id)
ORDER BY `$` DESC)
LIMIT 5;

# 8b. How would you display the view that you created in 8a?
SELECT * FROM genre;

# 8c. You find that you no longer need the view `top_five_genres`. Write a query to delete it.
DROP VIEW genre;