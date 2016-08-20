SELECT 
    `e`.`sku`, 
    IF(at_name.value_id > 0, at_name.value, at_name_default.value) AS `name`,
    IF(at_description.value_id > 0, at_name.value, at_description_default.value) AS `description`,
    IF(at_price.value_id > 0, at_name.value, at_price_default.value) AS `price`,
    IF(at_special_price.value_id > 0, at_name.value, at_special_price_default.value) AS `special price`

FROM 
   `catalog_product_entity` AS `e` 
    INNER JOIN 
         `catalog_product_entity_varchar` AS `at_name_default` 
               ON (`at_name_default`.`entity_id` = `e`.`entity_id`) AND 
                  (`at_name_default`.`attribute_id` = (SELECT attribute_id FROM `eav_attribute` ea LEFT JOIN `eav_entity_type` et ON ea.entity_type_id = et.entity_type_id  WHERE `ea`.`attribute_code` = 'name' AND et.entity_type_code = 'catalog_product')) AND 
                  `at_name_default`.`store_id` = 0 
    LEFT JOIN 
          `catalog_product_entity_varchar` AS `at_name` 
               ON (`at_name`.`entity_id` = `e`.`entity_id`) AND 
                  (`at_name`.`attribute_id` = (SELECT attribute_id FROM `eav_attribute` ea LEFT JOIN `eav_entity_type` et ON ea.entity_type_id = et.entity_type_id  WHERE `ea`.`attribute_code` = 'name' AND et.entity_type_code = 'catalog_product')) AND 
                  (`at_name`.`store_id` = 1) 
    INNER JOIN 
         `catalog_product_entity_text` AS `at_description_default` 
               ON (`at_description_default`.`entity_id` = `e`.`entity_id`) AND 
                  (`at_description_default`.`attribute_id` = (SELECT attribute_id FROM `eav_attribute` ea LEFT JOIN `eav_entity_type` et ON ea.entity_type_id = et.entity_type_id  WHERE `ea`.`attribute_code` = 'description' AND et.entity_type_code = 'catalog_product')) AND 
                  `at_description_default`.`store_id` = 0 
    LEFT JOIN 
          `catalog_product_entity_text` AS `at_description` 
               ON (`at_description`.`entity_id` = `e`.`entity_id`) AND 
                  (`at_description`.`attribute_id` = (SELECT attribute_id FROM `eav_attribute` ea LEFT JOIN `eav_entity_type` et ON ea.entity_type_id = et.entity_type_id  WHERE `ea`.`attribute_code` = 'description' AND et.entity_type_code = 'catalog_product')) AND 
                  (`at_description`.`store_id` = 1) 
    INNER JOIN 
         `catalog_product_entity_decimal` AS `at_price_default` 
               ON (`at_price_default`.`entity_id` = `e`.`entity_id`) AND 
                  (`at_price_default`.`attribute_id` = (SELECT attribute_id FROM `eav_attribute` ea LEFT JOIN `eav_entity_type` et ON ea.entity_type_id = et.entity_type_id  WHERE `ea`.`attribute_code` = 'price' AND et.entity_type_code = 'catalog_product')) AND 
                  `at_price_default`.`store_id` = 0 
    LEFT JOIN 
          `catalog_product_entity_decimal` AS `at_price` 
               ON (`at_price`.`entity_id` = `e`.`entity_id`) AND 
                  (`at_price`.`attribute_id` = (SELECT attribute_id FROM `eav_attribute` ea LEFT JOIN `eav_entity_type` et ON ea.entity_type_id = et.entity_type_id  WHERE `ea`.`attribute_code` = 'price' AND et.entity_type_code = 'catalog_product')) AND 
                  (`at_price`.`store_id` = 1) 
    INNER JOIN 
         `catalog_product_entity_decimal` AS `at_special_price_default` 
               ON (`at_special_price_default`.`entity_id` = `e`.`entity_id`) AND 
                  (`at_special_price_default`.`attribute_id` = (SELECT attribute_id FROM `eav_attribute` ea LEFT JOIN `eav_entity_type` et ON ea.entity_type_id = et.entity_type_id  WHERE `ea`.`attribute_code` = 'special_price' AND et.entity_type_code = 'catalog_product')) AND 
                  `at_special_price_default`.`store_id` = 0 
    LEFT JOIN 
          `catalog_product_entity_decimal` AS `at_special_price` 
               ON (`at_special_price`.`entity_id` = `e`.`entity_id`) AND 
                  (`at_special_price`.`attribute_id` = (SELECT attribute_id FROM `eav_attribute` ea LEFT JOIN `eav_entity_type` et ON ea.entity_type_id = et.entity_type_id  WHERE `ea`.`attribute_code` = 'special_price' AND et.entity_type_code = 'catalog_product')) AND 
                  (`at_special_price`.`store_id` = 1) 
