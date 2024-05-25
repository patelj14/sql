-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

WITH vendor_sales AS (
    SELECT 
        vn.vendor_name, 
        pn.product_name, 
        vi.original_price,
        ci.customer_id
    FROM 
        vendor_inventory vi
    JOIN 
        vendor vn ON vi.vendor_id = vn.vendor_id
    JOIN 
        product pn ON vi.product_id = pn.product_id
    CROSS JOIN 
        customer ci
)
SELECT 
    vendor_name, 
    product_name, 
    COUNT(customer_id) * 5 * original_price AS total_revenue
FROM 
    vendor_sales
GROUP BY 
    vendor_name, 
    product_name,
	original_price
ORDER BY
	vendor_name,
	product_name;


-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

DROP TABLE IF EXISTS product_units;
CREATE TABLE product_units AS
SELECT
	*,
	CURRENT_TIMESTAMP AS snapshot_timestamp
FROM
	product
WHERE
	product_qty_type = 'unit';
SELECT * FROM product_units;


/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */
INSERT INTO product_units(product_id, product_name, product_size, product_category_id, product_qty_type, snapshot_timestamp)
VALUES (24, 'Apple Pie', '10"', 3, 'unit', CURRENT_TIMESTAMP +1);
SELECT * from product_units;


-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time. */
DELETE FROM product_units
WHERE product_name = 'Apple Pie' AND snapshot_timestamp = (
	SELECT max(snapshot_timestamp)
	FROM product_units
	WHERE product_name = 'Apple Pie'
);
SELECT * FROM product_units;



-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */

DROP TABLE IF EXISTS product_quantity;
CREATE TEMP TABLE product_quantity AS
SELECT product_id,
       COALESCE(quantity, 0) AS last_qty
FROM (
    SELECT prod.product_id,
           vi.quantity,
           RANK() OVER (PARTITION BY vi.product_id ORDER BY vi.market_date DESC) AS ranked
    FROM product AS prod
    LEFT JOIN vendor_inventory AS vi ON prod.product_id = vi.product_id
) AS test
WHERE ranked = 1
ORDER BY product_id;

ALTER TABLE product_units
ADD current_quantity INT;

UPDATE product_units
SET current_quantity = (
    SELECT last_qty
    FROM product_quantity
    WHERE product_units.product_id = product_quantity.product_id
);
SELECT * FROM product_units;

