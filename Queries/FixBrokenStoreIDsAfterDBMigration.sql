SET FOREIGN_KEY_CHECKS=0; 
UPDATE `core_store` SET store_id = 0 WHERE code='admin'; 
UPDATE `core_store_group` SET group_id = 0 WHERE name='Default'; 
UPDATE `core_website` SET website_id = 0 WHERE code='admin'; 
UPDATE `customer_group` SET customer_group_id = 0 WHERE customer_group_code='NOT LOGGED IN'; 
SET FOREIGN_KEY_CHECKS=1;
