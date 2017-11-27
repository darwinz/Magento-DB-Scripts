DROP TEMPORARY TABLE IF EXISTS TEMP_PRODUCT_NAME;
CREATE TEMPORARY TABLE IF NOT EXISTS TEMP_PRODUCT_NAME (
	sku VARCHAR(50),
	name VARCHAR(150),
	INDEX(sku)
);

DROP TEMPORARY TABLE IF EXISTS TEMP_PRODUCT_URL_KEY;
#CREATE TEMPORARY TABLE IF NOT EXISTS TEMP_PRODUCT_URL_KEY (
#	sku VARCHAR(50),
#	url_key VARCHAR(150),
#	INDEX(sku)
#);

DROP TEMPORARY TABLE IF EXISTS TEMP_PRODUCT_FULL_URL;
CREATE TEMPORARY TABLE IF NOT EXISTS TEMP_PRODUCT_FULL_URL (
	entity_id INT(10),
	full_url VARCHAR(150),
	INDEX(entity_id)
);

DROP TEMPORARY TABLE IF EXISTS TEMP_PRODUCT_PRICE;
CREATE TEMPORARY TABLE IF NOT EXISTS TEMP_PRODUCT_PRICE (
	entity_id INT(10),
	price VARCHAR(25),
	INDEX(entity_id)
);

DROP TEMPORARY TABLE IF EXISTS TEMP_PRODUCT_DESCRIPTION;
CREATE TEMPORARY TABLE IF NOT EXISTS TEMP_PRODUCT_DESCRIPTION (
	sku VARCHAR(50),
	description TEXT,
	INDEX(sku)
);

DROP TEMPORARY TABLE IF EXISTS TEMP_PRODUCT_IN_STOCK;
CREATE TEMPORARY TABLE IF NOT EXISTS TEMP_PRODUCT_IN_STOCK (
	entity_id INT(10),
	is_in_stock TINYINT(1),
	INDEX(entity_id)
);

DROP TEMPORARY TABLE IF EXISTS TEMP_PRODUCT_IMAGE_LINK;
CREATE TEMPORARY TABLE IF NOT EXISTS TEMP_PRODUCT_IMAGE_LINK (
	entity_id INT(10),
	image_link VARCHAR(150),
	INDEX(entity_id)
);

DROP TEMPORARY TABLE IF EXISTS TEMP_PRODUCT_WEIGHT;
CREATE TEMPORARY TABLE IF NOT EXISTS TEMP_PRODUCT_WEIGHT (
	entity_id INT(10),
	weight VARCHAR(25),
	INDEX(entity_id)
);

INSERT INTO TEMP_PRODUCT_NAME
SELECT cpe.sku AS `SKU`, cpev.`value` AS `Product Name`
FROM catalog_product_entity cpe
LEFT JOIN catalog_product_entity_varchar cpev ON cpe.entity_id = cpev.entity_id
WHERE cpe.entity_id IN
(SELECT entity_id FROM catalog_product_entity_int cpei WHERE attribute_id = 96 AND `value` = 1)
AND cpev.attribute_id = 71;

#INSERT INTO TEMP_PRODUCT_URL_KEY
#SELECT cpe.sku AS `SKU`, cpev.`value` AS `URL Key`
#FROM catalog_product_entity cpe
#LEFT JOIN catalog_product_entity_varchar cpev ON cpe.entity_id = cpev.entity_id
#WHERE cpe.entity_id IN
#(SELECT entity_id FROM catalog_product_entity_int cpei WHERE attribute_id = 96 AND `value` = 1)
#AND cpev.attribute_id = 97;

INSERT INTO TEMP_PRODUCT_FULL_URL
SELECT cpe.entity_id AS `Entity ID`, CONCAT('https://example.com/en_us/', cur.`request_path`) AS `URL Key`
FROM catalog_product_entity cpe
LEFT JOIN core_url_rewrite cur ON cpe.entity_id = cur.product_id
WHERE cpe.entity_id IN
(SELECT entity_id FROM catalog_product_entity_int cpei WHERE attribute_id = 96 AND `value` = 1)
AND cur.is_system = 1
AND cur.category_id IS NULL
AND cur.store_id = 1;

INSERT INTO TEMP_PRODUCT_PRICE
SELECT cpe.entity_id AS `Entity ID`, cpip.`final_price` AS `Price`
FROM catalog_product_entity cpe
LEFT JOIN catalog_product_index_price cpip ON cpe.entity_id = cpip.entity_id
WHERE cpe.entity_id IN
(SELECT entity_id FROM catalog_product_entity_int cpei WHERE attribute_id = 96 AND `value` = 1)
AND cpip.customer_group_id = 1
AND cpip.website_id = 1;

INSERT INTO TEMP_PRODUCT_DESCRIPTION
SELECT cpe.sku AS `SKU`, cpev.`value` AS `Product Description`
FROM catalog_product_entity cpe
LEFT JOIN catalog_product_entity_text cpev ON cpe.entity_id = cpev.entity_id
WHERE cpe.entity_id IN
(SELECT entity_id FROM catalog_product_entity_int cpei WHERE attribute_id = 96 AND `value` = 1)
AND cpev.attribute_id = 72;

INSERT INTO TEMP_PRODUCT_IN_STOCK
SELECT cpe.entity_id AS `Entity ID`, cis.`is_in_stock` AS `Is In Stock`
FROM catalog_product_entity cpe
LEFT JOIN cataloginventory_stock_item cis ON cpe.entity_id = cis.product_id
WHERE cpe.entity_id IN
(SELECT entity_id FROM catalog_product_entity_int cpei WHERE attribute_id = 96 AND `value` = 1);

INSERT INTO TEMP_PRODUCT_IMAGE_LINK
SELECT cpe.entity_id AS `Entity ID`, CONCAT('https://cdn.example.com/media/catalog/product/full', cpeg.`value`) AS `Full Image Link`
FROM catalog_product_entity cpe
LEFT JOIN catalog_product_entity_media_gallery cpeg ON cpe.entity_id = cpeg.entity_id
LEFT JOIN catalog_product_entity_media_gallery_value cpegv ON cpeg.value_id = cpegv.value_id
WHERE cpe.entity_id IN
(SELECT entity_id FROM catalog_product_entity_int cpei WHERE attribute_id = 96 AND `value` = 1)
AND cpeg.attribute_id = 88
AND cpegv.disabled = 0
GROUP BY cpeg.entity_id
ORDER BY cpegv.position ASC;

INSERT INTO TEMP_PRODUCT_WEIGHT
SELECT cpe.sku AS `SKU`, cped.`value` AS `Shipping Weight`
FROM catalog_product_entity cpe
LEFT JOIN catalog_product_entity_decimal cped ON cpe.entity_id = cped.entity_id
WHERE cpe.entity_id IN
(SELECT entity_id FROM catalog_product_entity_int cpei WHERE attribute_id = 96 AND `value` = 1)
AND cped.attribute_id = 80;


SELECT 
	cpe.entity_id AS `Entity ID`,
	cpe.sku AS `SKU`, 
	tpn.`name` AS `Product Name`, 
	tpd.`description` AS `Product Description`, 
	#tpu.`url_key` AS `URL Key`, 
	tpfu.`full_url` AS `Full URL`,
	LEFT(tpp.`price`, CHAR_LENGTH(tpp.`price`)-2) AS `Final Price`,
	'True' AS `Product Enabled`, 
	IF(cis.is_in_stock = 1, 'True', 'False') AS `Availability (Is In Stock?)`,
	cpeg.image_link AS `Full Image Link`,
	cpw.weight AS `Shipping Weight`,
	DATE_FORMAT(cpe.created_at,'%M %d, %Y %h:%i %p') AS `Date Created`
FROM catalog_product_entity cpe
LEFT JOIN TEMP_PRODUCT_NAME tpn ON tpn.sku = cpe.sku
#LEFT JOIN TEMP_PRODUCT_URL_KEY tpu ON tpu.sku = cpe.sku
LEFT JOIN TEMP_PRODUCT_FULL_URL tpfu ON tpfu.entity_id = cpe.entity_id
LEFT JOIN TEMP_PRODUCT_PRICE tpp ON tpp.entity_id = cpe.entity_id
LEFT JOIN TEMP_PRODUCT_DESCRIPTION tpd ON tpd.sku = cpe.sku
LEFT JOIN TEMP_PRODUCT_IN_STOCK cis ON cis.entity_id = cpe.entity_id
LEFT JOIN TEMP_PRODUCT_IMAGE_LINK cpeg ON cpeg.entity_id = cpe.entity_id
LEFT JOIN TEMP_PRODUCT_WEIGHT cpw ON cpw.entity_id = cpe.entity_id
WHERE cpe.entity_id IN
(SELECT entity_id FROM catalog_product_entity_int cpei WHERE attribute_id = 96 AND `value` = 1)
AND cpe.entity_id IN
(SELECT entity_id FROM catalog_product_entity_int cpei WHERE attribute_id = 102 AND `value` <> 1)
ORDER BY DATE(cpe.created_at) DESC;
