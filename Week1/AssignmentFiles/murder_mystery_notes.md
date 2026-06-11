##  The crime was a ​murder​ that occurred sometime on ​Jan.15, 2018​ and that it took place in ​SQL City​, 
## below are the queries used to solve the Murder Mystery.

### This was the provided query to display the names of the tables in the database,
SELECT name 
  FROM sqlite_master
 where type = 'table'
 
## Here is the results of that query:
crime_scene_report
drivers_license
facebook_event_checkin
interview
get_fit_now_member
get_fit_now_check_in
solution
income
person

### This is the query provided to dispaly the structure of the crime_scene_report table:
SELECT sql 
  FROM sqlite_master
 where name = 'crime_scene_report'

## Here is the output:
CREATE TABLE crime_scene_report ( date integer, type text, description text, city text )

### My queries:
### I ran this query to lists all entries in the report and get an idea of how they look.
select * from crime_scene_report; 

### Then this query, to list entries in the crime_scene_report based on the date, type of crime and city supplied:
select * 
  from crime_scene_report 
  where date = 20180115 and type = 'murder' and city = 'SQL City';

Results:
date	    type	description	                                                              city
20180115	murder	Security footage shows that there were 2 witnesses. The first witness     SQL City
                    lives at the last house on "Northwestern Dr". The second witness, 
                    named Annabel, lives somewhere on "Franklin Ave".	

### Ran this query to find the first witness who lives at the last house on Northwestern Dr,
used MAX(address_number) to get the last house on the street.

select name, MAX(address_number), address_street_name 
  from person 
  where address_street_name = 'Northwestern Dr';

id	    name	        MAX(address_number)	    address_street_name
14887	Morty Schapiro	4919	                Northwestern Dr


### Ran this query to find the second witness named Annabel who lived on Franklin Ave.
select * 
  from person 
  where name LIKE 'Annabel%' and address_street_name = 'Franklin Ave';

id	    name	        license_id	address_number	address_street_name	 ssn
16371	Annabel Miller	490173	    103	            Franklin Ave	     318771143

### Next ran queried to check interveiw data for the 2 witnesses, First Annabel Miller = 16371.
SELECT *
  FROM interview 
  where person_id = 16371;

person_id	transcript
16371	    I saw the murder happen, and I recognized the killer from my gym when I was 
            working out last week week on January the 9th.

### Next for the second witness, Morty Shapiro
SELECT *
  FROM interview 
  where person_id = 14887;

person_id	transcript
14887	    I heard a gunshot and then saw a man run out. He had a "Get Fit Now Gym" bag. 
            The membership number on the bag started with "48Z". Only gold members have 
            those bags. The man got into a car with a plate that included "H42W".

### Next check the membership number and license plate in the get_fit_now_ and drivers_licnese tables. 
select * 
  from get_fit_now_check_in 
  where membership_id like '48Z%' and check_in_date = 20180109;

membership_id	check_in_date	check_in_time	check_out_time
48Z7A	        20180109	    1600	        1730
48Z55	        20180109	    1530	        1700

### Two members matched the query. Now check get_fit_now_member table. 
SELECT * 
  from get_fit_now_member 
  where id like '48Z%' and membership_status ='gold';

id	    person_id	name	        membership_start_date	membership_status
48Z7A	28819	    Joe Germuska	20160305	            gold
48Z55	67318	    Jeremy Bowers	20160101	            gold

### Check drivers_license table for license plate.
select * 
  from drivers_license 
  where plate_number LIKE '%H42W%' and gender = 'male';

id	    age	height	eye_color	hair_color	gender	plate_number	car_make	car_model
423327	30	70	    brown	    brown	    male	0H42W2	        Chevrolet	Spark LS
664760	21	71	    black	    black	    male	4H42WR	        Nissan	    Altima

### Used previous info to put this join query together, and worked on in class.
select p.name
  from person p 
  join get_fit_now_member m on m.person_id = p.id
  join get_fit_now_check_in c on c.membership_id = m.id
  join drivers_license d on d.id = p.license_id
 where m.id like '48Z%' 
  and m.membership_status = 'gold' 
  and d.plate_number like '%H42W%' 
  and c.check_in_date = 20180109;

name
Jeremy Bowers

### Used the name Jeremy Bowers and got his person_id from above to run this query.
SELECT * 
  FROM interview
 where person_id = 67318;

person_id	transcript
67318	    I was hired by a woman with a lot of money. I don't know her name but I know she's 
            around 5'5" (65") or 5'7" (67"). She has red hair and she drives a Tesla Model S. I know that she attended the SQL Symphony Concert 3 times in December 2017.

### Checked the solution table and person_id 67318, Jeremy Bowers is the murderer. But based on his 
### interview he was hired to murder.

INSERT INTO solution VALUES (1, 'Jeremy Bowers');
        SELECT value FROM solution;

value
Congrats, you found the murderer! But wait, there's more... If you think you're up for a challenge, try querying the interview transcript of the murderer to find the real villain behind this crime. If you feel especially confident in your SQL skills, try to complete this final step with no more than 2 queries. Use this same INSERT statement with your new suspect to check your answer.

### Used all the previous info and we worked on in class, used this query to find the main villain.
SELECT p.name
  FROM person p
  join drivers_license d on p.license_id = d.id
  join facebook_event_checkin f on p.id = f.person_id
  join income i on p.ssn = i.ssn
 where d.height between 65 and 67
 and d.hair_color = 'red'
 and d.car_make = 'Tesla'
 and d.car_model = 'Model S'
 and f.event_name = 'SQL Symphony Concert'
 and f.date between 20171201 and 20171231
 group by p.id, p.name
having count(f.event_id) = 3
order by i.annual_income desc;

name
Miranda Priestly

### Checked the solution table for Miranda Priestly, she was the main villain.
INSERT INTO solution VALUES (1, 'Miranda Priestly');
       SELECT value FROM solution;

value
Congrats, you found the brains behind the murder! Everyone in SQL City hails you as the greatest SQL detective of all time. Time to break out the champagne!