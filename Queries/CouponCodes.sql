SELECT 
	rule_id AS `Rule ID`, 
	code AS `Coupon Code`, 
	usage_limit AS `Usage Limit`, 
	usage_per_customer AS `Usage Per Customer`, 
	times_used AS `Times Used`, 
	expiration_date AS `Expiration Date`,
	IF(src.type = 1, 'Specific Coupon', 'No Coupon') AS `Coupon Type`
FROM salesrule_coupon src 
WHERE rule_id = 82;
