DELIMITER $$

CREATE PROCEDURE FixMissingLineItems
	(IN orderIncrementId int(10))

##########
BEGIN

SET @orderIncrementId = orderIncrementId;

DROP TEMPORARY TABLE IF EXISTS TEMP_ORDER_ITEMS;
DROP TEMPORARY TABLE IF EXISTS TEMP_QUOTE_ITEMS;

CREATE TEMPORARY TABLE TEMP_ORDER_ITEMS (
	order_item_id INT(10),
	quote_item_id INT(10),
	order_item_sku VARCHAR(100)
);

CREATE TEMPORARY TABLE TEMP_QUOTE_ITEMS (
	quote_item_id INT(10),
	quote_item_sku VARCHAR(100)
);

################################################
###  Get Order Entity ID from Increment ID  ###
################################################
SELECT sfo.entity_id INTO @orderEntityId
FROM sales_flat_order sfo
WHERE sfo.increment_id = @orderIncrementId;

################################################
################  Get Quote ID  ################
################################################
SELECT sfqi.quote_id, sfoi.item_id INTO @quote_id, @order_item_id
FROM sales_flat_order_item sfoi
LEFT JOIN sales_flat_quote_item sfqi ON sfqi.item_id = sfoi.quote_item_id
WHERE sfoi.order_id = @orderEntityId
GROUP BY sfoi.sku
HAVING COUNT(sfoi.sku) = 1
AND sfoi.item_id IN
(SELECT sfi.item_id
FROM sales_flat_order_item sfi
WHERE sfi.order_id = @orderEntityId
AND sfi.product_type = 'configurable')
LIMIT 1;


####################################################################
################  Insert Order Items in Temp Table  ################
####################################################################
INSERT INTO TEMP_ORDER_ITEMS
(order_item_id, quote_item_id, order_item_sku)

SELECT sfoi.item_id, sfoi.quote_item_id, sfoi.sku
FROM sales_flat_order_item sfoi
WHERE sfoi.order_id = @orderEntityId
GROUP BY sfoi.sku
HAVING COUNT(sfoi.sku) = 1
AND sfoi.item_id IN
(SELECT sfi.item_id
FROM sales_flat_order_item sfi
WHERE sfi.order_id = @orderEntityId
AND sfi.product_type = 'configurable');


####################################################################
################  Insert Quote Items in Temp Table  ################
####################################################################
INSERT INTO TEMP_QUOTE_ITEMS
(quote_item_id, quote_item_sku)

SELECT sfqi.item_id, sfqi.sku
FROM sales_flat_quote_item sfqi
WHERE sfqi.quote_id = @quote_id
GROUP BY sfqi.sku
HAVING COUNT(sfqi.sku) = 1
AND sfqi.item_id IN
(SELECT sfi.item_id
FROM sales_flat_quote_item sfi
WHERE sfi.quote_id = @quote_id
AND sfi.product_type = 'configurable');


########################################################################################################
################  Loop Through Quote Items and Insert Matching Simple/Entitlable Items  ################
########################################################################################################
SELECT COUNT(*) INTO @count_quote_items
FROM TEMP_QUOTE_ITEMS;

SET @i = 0;

WHILE @i < @count_quote_items DO

	SET @sql1 = CONCAT('SELECT quote_item_id, quote_item_sku INTO @id, @sku
	FROM TEMP_QUOTE_ITEMS
	ORDER BY quote_item_id LIMIT 1 OFFSET ',@i);
	PREPARE stmt1 FROM @sql1;
	EXECUTE stmt1;

	SET @sql2 = CONCAT('SELECT entity_id, type_id INTO @product_id, @product_type_id
	FROM catalog_product_entity
	WHERE sku = ',@sku);
	PREPARE stmt2 FROM @sql2;
	EXECUTE stmt2;

	SET @sql3 = CONCAT('SELECT value INTO @product_name
	FROM catalog_product_entity_varchar
	WHERE attribute_id = 71
	AND entity_id = ',@product_id);
	PREPARE stmt3 FROM @sql3;
	EXECUTE stmt3;

	SET @sql4 = CONCAT('SELECT
		item_id,
		quote_id,
		created_at,
		updated_at,
		store_id,
		is_virtual,
		sku,
		applied_rule_ids,
		free_shipping,
		is_qty_decimal,
		no_discount,
		weight,
		qty,
		discount_percent,
		product_type
	INTO
		@item_id,
		@quote_id,
		@created_at,
		@updated_at,
		@store_id,
		@is_virtual,
		@sku,
		@applied_rule_ids,
		@free_shipping,
		@is_qty_decimal,
		@no_discount,
		@weight,
		@qty,
		@discount_percent,
		@product_type_id
	FROM sales_flat_quote_item
	WHERE item_id = ',@id);
	PREPARE stmt4 FROM @sql4;
	EXECUTE stmt4;

	SET @sql5 = CONCAT('INSERT INTO sales_flat_quote_item
	(
		quote_id, created_at, updated_at, product_id, store_id, parent_item_id,
		is_virtual, sku, name, applied_rule_ids, free_shipping, is_qty_decimal,
		no_discount, weight, qty, price, base_price, discount_percent, discount_amount,
		base_discount_amount, tax_percent, tax_amount, base_tax_amount, base_row_total,
		row_total_with_discount, row_weight, product_type, is_entitlable
	)
	VALUES
	(
		\'',@quote_id,'\', \'',@created_at,'\', \'',@updated_at,'\', \'',@product_id,'\', \'',@store_id,'\',
		\'',@item_id,'\', \'',@is_virtual,'\', \'',@sku,'\', \'',REPLACE(@product_name, '\'', '\\\''),'\', \'',IFNULL(@applied_rule_ids,'\'\''),'\',
		\'',@free_shipping,'\', \'',@is_qty_decimal,'\', \'',IFNULL(@no_discount,0),'\', \'',IFNULL(@weight,0),'\',
		',@qty,', 0, 0, ',@discount_percent,', 0, 0, 0, 0, 0, 0, 0, 0, \'',@product_type_id,'\', 0
	)');

	#SELECT @sql5;

	PREPARE stmt5 FROM @sql5;
	EXECUTE stmt5;

	SET @last_insert = LAST_INSERT_ID();

	SELECT @last_insert AS `New Quote Item ID`;


	########################################################################################################
	################  Create New Order Item and Insert Matching Simple/Entitlable Items  ###################
	########################################################################################################
	SET @sql6 = CONCAT('SELECT order_item_id, quote_item_id, order_item_sku INTO @order_item_id, @quote_item_id, @sku
	FROM TEMP_ORDER_ITEMS
	WHERE quote_item_id = ',@id,
	' ORDER BY order_item_id LIMIT 1');
	PREPARE stmt6 FROM @sql6;
	EXECUTE stmt6;

	SET @sql7 = CONCAT('SELECT entity_id, type_id INTO @product_id, @product_type_id
	FROM catalog_product_entity
	WHERE sku = ',@sku);
	PREPARE stmt7 FROM @sql7;
	EXECUTE stmt7;

	SET @sql9 = CONCAT('SELECT value INTO @product_name
	FROM catalog_product_entity_varchar
	WHERE attribute_id = 71
	AND entity_id = ',@product_id);
	PREPARE stmt9 FROM @sql9;
	EXECUTE stmt9;

	SET @sql10 = CONCAT('SELECT
		order_id,
		item_id,
		store_id,
		created_at,
		updated_at,
		product_options,
		weight,
		is_virtual,
		sku,
		applied_rule_ids,
		free_shipping,
		is_qty_decimal,
		no_discount,
		qty_canceled,
		qty_invoiced,
		qty_ordered,
		qty_refunded,
		qty_shipped,
		tax_percent,
		tax_amount,
		base_tax_amount,
		tax_invoiced,
		base_tax_invoiced,
		discount_percent,
		is_nominal
	INTO
		@order_id,
		@item_id,
		@store_id,
		@created_at,
		@updated_at,
		@product_options,
		@weight,
		@is_virtual,
		@sku,
		@applied_rule_ids,
		@free_shipping,
		@is_qty_decimal,
		@no_discount,
		@qty_canceled,
		@qty_invoiced,
		@qty_ordered,
		@qty_refunded,
		@qty_shipped,
		@tax_percent,
		@tax_amount,
		@base_tax_amount,
		@tax_invoiced,
		@base_tax_invoiced,
		@discount_percent,
		@is_nominal
	FROM sales_flat_order_item
	WHERE item_id = ',@order_item_id);
	PREPARE stmt10 FROM @sql10;
	EXECUTE stmt10;

	SET @sql11 = CONCAT('INSERT INTO sales_flat_order_item
	(
		order_id, parent_item_id, quote_item_id, store_id, created_at, updated_at, product_id, product_type, product_options, weight, is_virtual, sku, name,
		applied_rule_ids, free_shipping, is_qty_decimal, no_discount, qty_canceled, qty_invoiced, qty_ordered, qty_refunded, qty_shipped,
		price, base_price, original_price, tax_percent, tax_amount, base_tax_amount, tax_invoiced, base_tax_invoiced, discount_percent,
		discount_amount, base_discount_amount, discount_invoiced, base_discount_invoiced, amount_refunded, base_amount_refunded,
		row_total, base_row_total, row_invoiced, base_row_invoiced, row_weight, is_nominal, is_entitlable
	)
	VALUES
	(
		\'',@order_id,'\', \'',@item_id,'\', \'',@last_insert,'\', \'',@store_id,'\', \'',@created_at,'\', \'',@updated_at,'\', \'',@product_id,'\', \'',@product_type_id,'\', \'',REPLACE(@product_options, '\'', '\\\''),'\', \'',IFNULL(@weight,0),'\',
		\'',IFNULL(@is_virtual,0),'\', \'',@sku,'\', \'',REPLACE(@product_name, '\'', '\\\''),'\', \'',IFNULL(@applied_rule_ids,'\'\''),'\', ',IFNULL(@free_shipping,0),', ',@is_qty_decimal,', \'',IFNULL(@no_discount,0),'\', ',@qty_canceled,', ',@qty_invoiced,', ',@qty_ordered,',
		',@qty_refunded,', ',@qty_shipped,', 0, 0, 0, ',@tax_percent,', ',@tax_amount,', ',@base_tax_amount,', ',@tax_invoiced,', ',@base_tax_invoiced,', ',@discount_percent,',
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \'',IFNULL(@is_nominal,0),'\', 0
	)');

	#SELECT @sql11;

	PREPARE stmt11 FROM @sql11;
	EXECUTE stmt11;


	SET @last_insert = LAST_INSERT_ID();

	SELECT @last_insert AS `New Order Item ID`;



	####################################################
	###  Set SiteFinity ID back to 0 for this order  ###
	####################################################
	UPDATE sales_flat_order
	SET sitefinity_id = 0
	WHERE sitefinity_id = -102
	AND entity_id = @order_id;


	SET @i = @i + 1;

	#SELECT @i;

END WHILE;


END
##########

$$