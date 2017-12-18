use sakila;
select * from staff;

# 1a. Display the first and last names of all actors from the table `actor`. 
select first_name, last_name from actor;

# 1b. Display the first and last name of each actor in a single column in upper case letters. Name the column `Actor Name`. 
select concat(first_name," ", last_name) from actor;

# 2a. You need to find the ID number, first name, and last name of an actor, of whom you know only the first name, "Joe." What is one query would you use to obtain this information?
select actor_id, first_name, last_name from actor where first_name = "Joe";

# 2b. Find all actors whose last name contain the letters `GEN`:
select * from actor where last_name like "%GEN%";
  	
# 2c. Find all actors whose last names contain the letters `LI`. This time, order the rows by last name and first name, in that order:
select * from actor where last_name like "%GEN%" order by last_name, first_name;

# 2d. Using `IN`, display the `country_id` and `country` columns of the following countries: Afghanistan, Bangladesh, and China:
select country_id, country from country where country in ("Afghanistan", "Bangladesh", "China");

# 3a. Add a `middle_name` column to the table `actor`. Position it between `first_name` and `last_name`. Hint: you will need to specify the data type.
alter table actor drop column middle_name;
alter table actor add middle_name VARCHAR(20) default "FRANCIS" After first_name;
select * from actor;

# 3b. You realize that some of these actors have tremendously long last names. Change the data type of the `middle_name` column to `blobs`.
alter table actor modify column middle_name blob;

# 3c. Now delete the `middle_name` column.
alter table actor drop column middle_name;

# 4a. List the last names of actors, as well as how many actors have that last name.
select last_name, count(last_name) from actor group by last_name;
  	
# 4b. List last names of actors and the number of actors who have that last name, but only for names that are shared by at least two actors
select * from
(select last_name, count(last_name) `count` from actor  group by last_name) as t
where (`count` > 2);
# 4c. Oh, no! The actor `HARPO WILLIAMS` was accidentally entered in the `actor` table as `GROUCHO WILLIAMS`, the name of Harpo's second cousin's husband's yoga teacher. Write a query to fix the record.
select * from actor where last_name = "WILLIAMS";

update actor set first_name = "HARPO"
where actor_id = 172;

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
  `address_id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `address` varchar(50) NOT NULL,
  `address2` varchar(50) DEFAULT NULL,
  `district` varchar(20) NOT NULL,
  `city_id` smallint(5) unsigned NOT NULL,
  `postal_code` varchar(10) DEFAULT NULL,
  `phone` varchar(20) NOT NULL,
  `location` geometry NOT NULL,
  `last_update` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`address_id`),
  KEY `idx_fk_city_id` (`city_id`),
  SPATIAL KEY `idx_location` (`location`),
  CONSTRAINT `fk_address_city` FOREIGN KEY (`city_id`) REFERENCES `city` (`city_id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=606 DEFAULT CHARSET=utf8;

# 6a. Use `JOIN` to display the first and last names, as well as the address, of each staff member. Use the tables `staff` and `address`:
select * from staff left join address on staff.address_id = address.address_id;

# 6b. Use `JOIN` to display the total amount rung up by each staff member in August of 2005. Use tables `staff` and `payment`. 
#select staff_id
select * from staff left join
(select staff_id, sum(amount) from payment 
where payment_date between '2005-08-01 00:00:00' AND '2005-08-31 23:59:59'
group by(staff_id)) sums
on staff.staff_id = sums.staff_id;

# 6c. List each film and the number of actors who are listed for that film. Use tables `film_actor` and `film`. Use inner join.
select title, counts.actor_count  from film left join
(select film_id, count(actor_id) actor_count from film_actor group by(film_id)) counts 
on film.film_id = counts.film_id;
    
# 6d. How many copies of the film `Hunchback Impossible` exist in the inventory system?
select * from film where title = "Hunchback Impossible"; # id = 439
select count(inventory_id) `Copies of Hunchback Impossible` from inventory where film_id = 439 group by(film_id);

# 6e. Using the tables `payment` and `customer` and the `JOIN` command, list the total paid by each customer. List the customers alphabetically by last name:
select first_name, last_name, customer_sums.customer_sum from customer join
	(select customer_id, sum(amount) customer_sum from payment group by(customer_id)) customer_sums
	on customer_sums.customer_id = customer.customer_id
	order by last_name;

# 7a. The music of Queen and Kris Kristofferson have seen an unlikely resurgence. As an unintended consequence, films starting with the letters `K` and `Q` have also soared in popularity. Use subqueries to display the titles of movies starting with the letters `K` and `Q` whose language is English. 
select title from film where title like "K%" or title like "Q%" and language_id = 1;

# 7b. Use subqueries to display all actors who appear in the film `Alone Trip`.
select first_name, last_name from actor where actor_id in
	(select actor_id from film_actor where film_id in
	(select film_id from film where title = "Alone Trip"));

# 7c. You want to run an email marketing campaign in Canada, for which you will need the names and email addresses of all Canadian customers. Use joins to retrieve this information.
select email from customer where address_id in
	(select address_id from address where city_id in
	(select city_id from city where country_id in
	(select country_id from country where country = "CANADA")));

# 7d. Sales have been lagging among young families, and you wish to target all family movies for a promotion. Identify all movies categorized as famiy films.
select * from film where film_id in
(select film_id from film_category where category_id in
(select category_id from category where name = "Family"));

# 7e. Display the most frequently rented movies in descending order.
select title,k.`# of rentals` from film join
(select film_id, count(rental_id) `# of rentals` from
(select rental_id, film_id from rental left join inventory on inventory.inventory_id = rental.inventory_id) j
group by(film_id)) k
on k.film_id = film.film_id
order by `# of rentals` desc;

# 7f. Write a query to display how much business, in dollars, each store brought in.
select store_id, sum(`1st`.amount) `$` from staff join
(select staff_id, amount from payment) `1st` 
where staff.staff_id = `1st`.staff_id
group by store_id;


# 7g. Write a query to display for each store its store ID, city, and country.
select store_id, city, country from store join
(select city, country, address_id from address join
(select city_id, city, country from city join country on city.country_id = country.country_id) ii
on address.city_id = ii.city_id) jj
on store.address_id = jj.address_id;


# 7h. List the top five genres in gross revenue in descending order. (**Hint**: you may need to use the following tables: category, film_category, inventory, payment, and rental.)
select `name`, sum(amount) `$` from category right join
(select amount, category_id from film_category right join
(select amount, film_id from inventory right join
(select amount, inventory_id from payment left join rental
on rental.rental_id = payment.rental_id) ii
on inventory.inventory_id = ii.inventory_id) jj
on film_category.film_id = jj.film_id) kk
on category.category_id = kk.category_id
group by(kk.category_id)
order by `$` desc;


# 8a. In your new role as an executive, you would like to have an easy way of viewing the Top five genres by gross revenue. Use the solution from the problem above to create a view. If you haven't solved 7h, you can substitute another query to create a view.
create view genre (`genre`,`$`) as
(select `name`, sum(amount) `$` from category right join
(select amount, category_id from film_category right join
(select amount, film_id from inventory right join
(select amount, inventory_id from payment left join rental
on rental.rental_id = payment.rental_id) ii
on inventory.inventory_id = ii.inventory_id) jj
on film_category.film_id = jj.film_id) kk
on category.category_id = kk.category_id
group by(kk.category_id)
order by `$` desc);

# 8b. How would you display the view that you created in 8a?
select * from genre;

# 8c. You find that you no longer need the view `top_five_genres`. Write a query to delete it.
drop view genre;