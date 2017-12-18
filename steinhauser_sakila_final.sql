USE sakila;
SELECT * FROM staff;
#housekeeping views
#all pertinent location ids
CREATE VIEW location_ids AS
(SELECT kk.*, staff_id FROM staff RIGHT JOIN
(SELECT jj.*, store_id FROM store RIGHT JOIN
(SELECT ii.*,customer_id FROM customer RIGHT JOIN
(SELECT address_id, hh.* FROM address  LEFT JOIN
(SELECT city, city_id, country, city.country_id FROM city LEFT JOIN country 
ON city.country_id = country.country_id) hh
ON address.city_id = hh.city_id) ii
ON ii.address_id = customer.address_id) jj
ON jj.address_id = store.address_id) kk
ON kk.address_id = staff.address_id);

#packing the movie id info in
CREATE VIEW actor_ids AS
SELECT first_name, last_name, jj.* FROM actor RIGHT JOIN
(SELECT actor_id, ii.* FROM film_actor LEFT JOIN
(SELECT film.film_id, title, language_id, category_id FROM film LEFT JOIN film_category 
ON film.film_id = film_category.film_id) ii
ON ii.film_id = film_actor.film_id) jj
ON jj.actor_id = actor.actor_id;

CREATE VIEW rental_ids AS
SELECT rental_id, customer_id, staff_id, jj.* FROM rental LEFT JOIN
(SELECT inventory_id, store_id, ii.* FROM inventory LEFT JOIN
(SELECT film.film_id, title, language_id, category_id FROM film LEFT JOIN film_category 
ON film.film_id = film_category.film_id) ii
ON inventory.film_id = ii.film_id) jj
ON rental.inventory_id = jj.inventory_id;



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
(SELECT last_name, COUNT(last_name) `count of last name` FROM actor  GROUP BY last_name) AS t
WHERE (`count of last name` >= 2);

# 4c. Oh, no! The actor `HARPO WILLIAMS` was accidentally entered in the `actor` table as `GROUCHO WILLIAMS`, the name of Harpo's second cousin's husband's yoga teacher. Write a query to fix the record.
SELECT * FROM actor WHERE last_name = "WILLIAMS"; #actor_id = 172

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
SELECT first_name, last_name, `$` FROM staff LEFT JOIN
(SELECT staff_id, SUM(amount) `$` FROM payment 
WHERE payment_date BETWEEN '2005-08-01 00:00:00' AND '2005-08-31 23:59:59'
GROUP BY(staff_id)) date_sums
ON staff.staff_id = date_sums.staff_id;

# 6c. List each film and the number of actors who are listed for that film. Use tables `film_actor` and `film`. Use inner join.
SELECT title, counts.actor_count  FROM film LEFT JOIN
(SELECT film_id, COUNT(actor_id) actor_count FROM film_actor GROUP BY(film_id)) counts 
ON film.film_id = counts.film_id;
    
# 6d. How many copies of the film `Hunchback Impossible` exist in the inventory system?
SELECT COUNT(DISTINCT inventory_id) `Copies of Hunchback Impossible` FROM rental_ids WHERE title = "Hunchback Impossible";

# 6e. Using the tables `payment` and `customer` and the `JOIN` command, list the total paid by each customer. List the customers alphabetically by last name:
SELECT first_name, last_name, customer_sums.customer_sum FROM customer JOIN
	(SELECT customer_id, SUM(amount) customer_sum FROM payment GROUP BY(customer_id)) customer_sums
	ON customer_sums.customer_id = customer.customer_id
	ORDER BY last_name;

# 7a. The music of Queen and Kris Kristofferson have seen an unlikely resurgence. As an unintended consequence, films starting with the letters `K` and `Q` have also soared in popularity. Use subqueries to display the titles of movies starting with the letters `K` and `Q` whose language is English. 
SELECT title FROM film WHERE title LIKE "K%" OR title LIKE "Q%" AND language_id = 1;

# 7b. Use subqueries to display all actors who appear in the film `Alone Trip`.
SELECT title, actors FROM nicer_but_slower_film_list WHERE title = "Alone Trip";

SELECT first_name, last_name FROM actor_ids WHERE title = "Alone Trip";

# 7c. You want to run an email marketing campaign in Canada, for which you will need the names and email addresses of all Canadian customers. Use joins to retrieve this information.
SELECT email FROM customer WHERE address_id IN
	(SELECT address_id FROM location_ids WHERE country = "CANADA");

# 7d. Sales have been lagging among young families, and you wish to target all family movies for a promotion. Identify all movies categorized as famiy films.
SELECT FID, title FROM film_list WHERE category = "family";

# 7e. Display the most frequently rented movies in descending order.
SELECT title, COUNT(rental_id) `rentals` FROM rental_ids 
GROUP BY(film_id) ORDER BY rentals DESC;

# 7f. Write a query to display how much business, in dollars, each store brought in.
SELECT * FROM sales_by_store;


# 7g. Write a query to display for each store its store ID, city, and country.
SELECT store.store_id, city, country 
FROM store LEFT JOIN location_ids 
ON store.store_id = location_ids.store_id;

# 7h. List the top five genres in gross revenue in descending order. (**Hint**: you may need to use the following tables: category, film_category, inventory, payment, and rental.)
SELECT * FROM sales_by_film_category
ORDER BY total_sales DESC
LIMIT 5;

# 8a. In your new role as an executive, you would like to have an easy way of viewing the Top five genres by gross revenue. Use the solution from the problem above to create a view. If you haven't solved 7h, you can substitute another query to create a view.

CREATE VIEW genre_top_5 AS
SELECT * FROM sales_by_film_category
ORDER BY total_sales DESC #which is default anyway
LIMIT 5;

# 8b. How would you display the view that you created in 8a?
SELECT * FROM genre_top_5;

# 8c. You find that you no longer need the view `top_five_genres`. Write a query to delete it.
DROP VIEW genre_top_5;