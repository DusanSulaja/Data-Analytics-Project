-- Switch to the newly created database
USE adventure_works_purchase_orders;

-- Create a table to hold the sales data
CREATE TABLE sales (
    SalesOrderNumber VARCHAR(20),
    OrderDate DATE,
    Sales_Person VARCHAR(100),
    Sales_Region VARCHAR(100),
    Sales_Province VARCHAR(100),
    Sales_City VARCHAR(100),
    Sales_Postal_Code INT,
    Customer_Code VARCHAR(50),
    Customer_Name VARCHAR(100),
    Customer_Region VARCHAR(100),
    Customer_Province VARCHAR(100),
    Customer_City VARCHAR(100),
    Customer_Postal_Code VARCHAR(20),
    LineItem_Id INT,
    Product_Category VARCHAR(100),
    Product_Sub_Category VARCHAR(100),
    Product_Name VARCHAR(150),
    Product_Code VARCHAR(50),
    Unit_Cost FLOAT,
    UnitPrice FLOAT,
    UnitPriceDiscount FLOAT,
    OrderQty INT,
    Unit_Freight_Cost FLOAT
);

-- Load the CSV file into the sales_data table using the import wizard

-- Analyzing newly improrted table
SELECT *
FROM sales;

-- Sales Trends Over Time
SELECT 
    YEAR(OrderDate) AS Year, 
    MONTH(OrderDate) AS Month, 
    ROUND(SUM((UnitPrice * OrderQty) - (UnitPrice*UnitPriceDiscount*OrderQty)),2) AS Total_Sales, 
	ROUND(SUM(((UnitPrice - (UnitPrice * UnitPriceDiscount) - Unit_Cost) * OrderQty) - Unit_Freight_Cost),2) AS Total_Profit,
    SUM(OrderQty) AS Total_Orders
FROM 
    sales
GROUP BY 
    YEAR(OrderDate), MONTH(OrderDate)
ORDER BY 
    Year, Month;
    
-- Checking Total(sales, profit, orders) and % change for sales, profit and orders.
WITH YearlyAggregates AS (
    SELECT 
        YEAR(OrderDate) AS Year, 
        MONTH(OrderDate) AS Month, 
        ROUND(SUM((UnitPrice * OrderQty) - (UnitPrice * UnitPriceDiscount * OrderQty)), 2) AS Total_Sales, 
        ROUND(SUM(((UnitPrice - (UnitPrice * UnitPriceDiscount) - Unit_Cost) * OrderQty) - Unit_Freight_Cost), 2) AS Total_Profit,
        SUM(OrderQty) AS Total_Orders
    FROM 
        sales
    GROUP BY 
        YEAR(OrderDate), MONTH(OrderDate)
)
SELECT 
    Year, 
    Month, 
    Total_Sales, 
    Total_Profit, 
    Total_Orders,
    
    -- Calculate the percentage difference in Total Sales from the same month in the previous year
    ROUND(
        (Total_Sales - LAG(Total_Sales) OVER (PARTITION BY Month ORDER BY Year)) / 
        LAG(Total_Sales) OVER (PARTITION BY Month ORDER BY Year) * 100, 2
    ) AS Percent_Change_Sales,
    
    -- Calculate the percentage difference in Total Profit from the same month in the previous year
    ROUND(
        (Total_Profit - LAG(Total_Profit) OVER (PARTITION BY Month ORDER BY Year)) / 
        LAG(Total_Profit) OVER (PARTITION BY Month ORDER BY Year) * 100, 2
    ) AS Percent_Change_Profit,
    
    -- Calculate the percentage difference in Total Orders from the same month in the previous year
    ROUND(
        (Total_Orders - LAG(Total_Orders) OVER (PARTITION BY Month ORDER BY Year)) / 
        LAG(Total_Orders) OVER (PARTITION BY Month ORDER BY Year) * 100, 2
    ) AS Percent_Change_Orders
FROM 
    YearlyAggregates
ORDER BY 
    Year, Month;

    

-- Weekly Sales Patterns (by Day of the Week)
SELECT 
    DAYOFWEEK(OrderDate) AS Weekday,  -- Extract the weekday number (1=Sunday, 7=Saturday)
    ROUND(SUM((UnitPrice * OrderQty) - (UnitPrice * UnitPriceDiscount * OrderQty)), 2) AS Total_Sales, 
    ROUND(SUM(((UnitPrice - (UnitPrice * UnitPriceDiscount) - Unit_Cost) * OrderQty) - Unit_Freight_Cost), 2) AS Total_Profit,
    SUM(OrderQty) AS Total_Orders
FROM 
    sales
GROUP BY 
    DAYOFWEEK(OrderDate)
ORDER BY 
    Weekday;
    
-- Identifying Daily Sales Spikes or Drops (Compared to Average Sales)
WITH DailySales AS (
    SELECT 
        OrderDate AS Date,
        ROUND(SUM((UnitPrice * OrderQty) - (UnitPrice * UnitPriceDiscount * OrderQty)), 2) AS Total_Sales
    FROM 
        sales
    GROUP BY 
        OrderDate
)
SELECT 
    Date, 
    Total_Sales,
    ROUND((Total_Sales - (SELECT AVG(Total_Sales) FROM DailySales)) / (SELECT AVG(Total_Sales) FROM DailySales) * 100, 2) AS Percent_Change_From_Average
FROM 
    DailySales
HAVING 
    ABS((Total_Sales - (SELECT AVG(Total_Sales) FROM DailySales)) / (SELECT AVG(Total_Sales) FROM DailySales)) > 0.30  -- 30% deviation threshold
ORDER BY 
    Date DESC;


-- Regional Perfomance by Costumer
SELECT 
    Customer_Region, 
    Customer_Province, 
    ROUND(SUM((UnitPrice * OrderQty) - (UnitPrice*UnitPriceDiscount*OrderQty)),2) AS Total_Sales,
    SUM((UnitPrice * OrderQty) - (UnitPrice * UnitPriceDiscount * OrderQty)) AS Total_Revenue, 
    SUM(((UnitPrice - UnitPrice * UnitPriceDiscount - Unit_Cost) * OrderQty) - Unit_Freight_Cost) AS Total_Profit, 
    SUM(OrderQty) AS Total_Orders
FROM 
    sales
GROUP BY 
    Customer_Region, Customer_Province
ORDER BY 
    Total_Revenue DESC;

-- Removing an anomily ( Sales from Germany) 
Select *
FROM sales
WHERE Sales_Region = 'Germany';

SET SQL_SAFE_UPDATES = 0;

DELETE FROM sales
WHERE Sales_Region = 'Germany'; 
    
-- Sales, Orders and Profit by Region (over the Years)
SELECT 
    YEAR(OrderDate) AS Year, 
	Sales_Region, 
    SUM((UnitPrice * OrderQty) - (UnitPrice * UnitPriceDiscount * OrderQty)) AS Total_Sales, 
    SUM(((UnitPrice - UnitPrice * UnitPriceDiscount - Unit_Cost) * OrderQty) - Unit_Freight_Cost) AS Total_Profit, 
    SUM(OrderQty) AS Total_Orders
FROM 
    sales
WHERE 
    YEAR(OrderDate) IN (2007, 2008)
GROUP BY 
    YEAR(OrderDate), Sales_Region
ORDER BY 
    Sales_Region, Year;


 -- Unit Price change between 2007 and 2008
SELECT 
	YEAR(OrderDate) AS Year,
	AVG(UnitPrice) AS Avg_Unit_Price,2
FROM 
    sales
WHERE 
    YEAR(OrderDate) IN (2007, 2008)
GROUP BY 
    YEAR(OrderDate), UnitPrice
ORDER BY 
    UnitPrice, Year;

 -- Comparing 2008 Sales, Profit and Orders with 2007 
SELECT 
	YEAR(OrderDate) AS Year, 
    SUM((UnitPrice * OrderQty) - (UnitPrice * UnitPriceDiscount * OrderQty)) AS Total_Sales, 
    SUM(((UnitPrice - UnitPrice * UnitPriceDiscount - Unit_Cost) * OrderQty) - Unit_Freight_Cost) AS Total_Profit, 
    SUM(OrderQty) AS Total_Orders
FROM 
    sales
WHERE 
    YEAR(OrderDate) BETWEEN 2007 AND 2008
GROUP BY 
    YEAR(OrderDate)
ORDER BY 
	Year;
    
-- Product Performance (Total Sales & Total Profit) over the years by sub-categories
SELECT 
	YEAR(OrderDate) AS Year,
    Product_Category, 
    Product_Sub_Category, 
    SUM((UnitPrice * OrderQty) - (UnitPrice * UnitPriceDiscount * OrderQty)) AS Total_Sales, 
    SUM(((UnitPrice - UnitPrice * UnitPriceDiscount - Unit_Cost) * OrderQty) - Unit_Freight_Cost) AS Total_Profit
FROM 
    sales
GROUP BY 
    YEAR(OrderDate),Product_Category, Product_Sub_Category
ORDER BY 
    Year, Total_Sales DESC;

    
-- Product Category comperison 2007 and 2008 by average unit cost
SELECT 
    Product_Name, 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    AVG(Unit_Cost) AS Avg_Unit_Cost
FROM 
    sales
WHERE 
    YEAR(OrderDate) IN (2007, 2008)
GROUP BY 
    Product_Name, YEAR(OrderDate), MONTH(OrderDate)
ORDER BY 
    Product_Name, Year, Month;

-- Procentage change in Unit Cost by Product_Name
SELECT 
    a.Product_Name, 
    ((b.Avg_Unit_Cost - a.Avg_Unit_Cost) / a.Avg_Unit_Cost) * 100 AS Percent_Change_UnitCost
FROM 
    (SELECT Product_Name, AVG(Unit_Cost) AS Avg_Unit_Cost
     FROM sales
     WHERE YEAR(OrderDate) = 2007
     GROUP BY Product_Name) a
JOIN 
    (SELECT Product_Name, AVG(Unit_Cost) AS Avg_Unit_Cost
     FROM sales
     WHERE YEAR(OrderDate) = 2008
     GROUP BY Product_Name) b
ON 
    a.Product_Name = b.Product_Name
ORDER BY 
    Percent_Change_UnitCost DESC;

-- Average price and cost of Unit over the years
SELECT 
    YEAR(OrderDate) AS Year, 
    ROUND(AVG(Unit_Cost), 2) AS Avg_Unit_Cost, 
    ROUND(AVG(UnitPrice), 2) AS Avg_Unit_Price
FROM 
    sales
GROUP BY 
    YEAR(OrderDate)
ORDER BY 
    Year;
    
WITH YearlyAverages AS (
    SELECT 
        YEAR(OrderDate) AS Year, 
        ROUND(AVG(Unit_Cost), 2) AS Avg_Unit_Cost, 
        ROUND(AVG(UnitPrice), 2) AS Avg_Unit_Price
    FROM 
        sales
    GROUP BY 
        YEAR(OrderDate)
)
SELECT 
    Year, 
    Avg_Unit_Cost, 
    Avg_Unit_Price,
    
    -- Calculate % difference in Unit Cost from the previous year
    ROUND(
        (Avg_Unit_Cost - LAG(Avg_Unit_Cost) OVER (ORDER BY Year)) / 
        LAG(Avg_Unit_Cost) OVER (ORDER BY Year) * 100, 2
    ) AS Percent_Change_UnitCost,
    
    -- Calculate % difference in Unit Price from the previous year
    ROUND(
        (Avg_Unit_Price - LAG(Avg_Unit_Price) OVER (ORDER BY Year)) / 
        LAG(Avg_Unit_Price) OVER (ORDER BY Year) * 100, 2
    ) AS Percent_Change_UnitPrice,
    
    -- Calculate the % difference between Unit Price and Unit Cost increase
    ROUND(
        ((Avg_Unit_Price - Avg_Unit_Cost) - LAG(Avg_Unit_Price - Avg_Unit_Cost) OVER (ORDER BY Year)) / 
        LAG(Avg_Unit_Price - Avg_Unit_Cost) OVER (ORDER BY Year) * 100, 2
    ) AS Percent_Difference_UnitPrice_vs_UnitCost
FROM 
    YearlyAverages
ORDER BY 
    Year;


-- Total Sales per costumer
SELECT 
	Customer_Name,
	ROUND(SUM((UnitPrice * OrderQty) - (UnitPrice * UnitPriceDiscount * OrderQty)),2) AS Total_Sales
From sales
Group by Customer_Name;

-- Total sales per customer per year 
SELECT 
	DISTINCT Customer_Name, 
	YEAR(OrderDate) AS Year, 
    ROUND(SUM((UnitPrice * OrderQty) - (UnitPrice * UnitPriceDiscount * OrderQty)),2) AS Total_Sales
FROM sales
WHERE 
    YEAR(OrderDate) IN (2007, 2008)
GROUP BY 
    YEAR(OrderDate), Customer_Name
ORDER BY 
    Total_Sales, Year;

-- Diference in Total number of Orders 2007 and 2008
Select 
	YEAR(OrderDate) AS Year,
	Sales_Region,
    SUM(OrderQty) AS Sum_of_Order
FROM sales
WHERE YEAR(OrderDate) IN (2007,2008)
GROUP BY YEAR(OrderDate), Sales_Region
ORDER BY Sales_Region, Year;

-- Diference in Sum of Orders 2007 and 2008 by Product Sub Category
Select 
	YEAR(OrderDate) AS Year,
	Product_Sub_Category,
    SUM(OrderQty) AS Sum_of_Order
FROM sales
WHERE YEAR(OrderDate) IN (2007,2008)
GROUP BY YEAR(OrderDate), Product_Sub_Category
ORDER BY Product_Sub_Category, Year;

-- Total Purchases 2007/2008 with Percent Change by Costomer Name (additionally checking if the costumor continued in 2008)
SELECT 
    a.Customer_Name,
    ROUND(a.Total_Purchases_2007, 2) AS Total_Purchases_2007, 
    ROUND(IFNULL(b.Total_Purchases_2008, 0), 2) AS Total_Purchases_2008, 
    ROUND(
        CASE 
            WHEN a.Total_Purchases_2007 = 0 THEN NULL
            ELSE ((IFNULL(b.Total_Purchases_2008, 0) - a.Total_Purchases_2007) / a.Total_Purchases_2007) * 100
        END, 2
    ) AS Percent_Change, 
    CASE 
        WHEN b.Customer_Name IS NULL THEN 'No'
        ELSE 'Yes'
    END AS Continued_In_2008
FROM
    (
        SELECT 
            distinct Customer_Name, 
            SUM(UnitPrice * OrderQty * (1 - UnitPriceDiscount)) AS Total_Purchases_2007
        FROM 
            sales
        WHERE 
            YEAR(OrderDate) = 2007
        GROUP BY 
            Customer_Name
    ) a
LEFT JOIN 
    (
        SELECT 
            distinct Customer_Name, 
            SUM(UnitPrice * OrderQty * (1 - UnitPriceDiscount)) AS Total_Purchases_2008
        FROM 
            sales
        WHERE 
            YEAR(OrderDate) = 2008
        GROUP BY 
            Customer_Name
    ) b
ON 
    a.Customer_Name = b.Customer_Name
ORDER BY 
    Percent_Change DESC;



-- Customer Perfomance comperison 2007 and 2008 
SELECT 
    YEAR(OrderDate) AS Year, 
	Customer_Name, 
    SUM((UnitPrice * OrderQty) - (UnitPrice * UnitPriceDiscount * OrderQty)) AS Total_Sales, 
    SUM(((UnitPrice - UnitPrice * UnitPriceDiscount - Unit_Cost) * OrderQty) - Unit_Freight_Cost) AS Total_Profit, 
    SUM(OrderQty) AS Total_Orders
FROM 
    sales
WHERE 
    YEAR(OrderDate) IN (2007, 2008)
GROUP BY 
    YEAR(OrderDate), Customer_Name
ORDER BY 
    Customer_Name, Year;
    

-- total sales and orders per customer in 2007
SELECT 
    Customer_Name, 
	SUM((UnitPrice * OrderQty) - (UnitPrice * UnitPriceDiscount * OrderQty)) AS TotalSalesIn2007, 
    COUNT(OrderQty) AS TotalOrdersIn2007
FROM 
    sales
WHERE 
    YEAR(OrderDate) = 2007
    AND Customer_Name NOT IN (
        SELECT 
            Customer_Name 
        FROM 
            sales 
        WHERE 
            YEAR(OrderDate) = 2008
    )
GROUP BY 
    Customer_Name
ORDER BY 
    TotalSalesIn2007 DESC;



-- Top performing Sales Person
SELECT 
	distinct Sales_Person, 
    SUM((UnitPrice * OrderQty) - (UnitPrice * UnitPriceDiscount * OrderQty)) AS Total_Sales
FROM sales
GROUP BY Sales_Person
ORDER BY Total_Sales;

-- Top Performing Region
SELECT 
	distinct Sales_Province, 
	Sales_Region,
    SUM((UnitPrice * OrderQty) - (UnitPrice * UnitPriceDiscount * OrderQty)) AS Total_Sales
FROM sales
GROUP BY Sales_Province, Sales_Region
ORDER BY Total_Sales desc;

-- Top Performing Customer Region
SELECT 
	distinct Customer_Province, 
	Customer_Region,
    SUM((UnitPrice * OrderQty) - (UnitPrice * UnitPriceDiscount * OrderQty)) AS Total_Sales
FROM sales
GROUP BY Customer_Province,Customer_Region
ORDER BY Total_Sales desc;

-- Which products driving high profits?
SELECT
	Product_Category,
	Product_Sub_Category,
	Sales_Region,
	Sales_Province,
    SUM(((UnitPrice - UnitPrice * UnitPriceDiscount - Unit_Cost) * OrderQty) - Unit_Freight_Cost) AS Total_Profit, 
    SUM(OrderQty) AS Total_Orders
FROM sales
GROUP BY Product_Category,Product_Sub_Category,Sales_Region,Sales_Province
ORDER BY Total_Profit DESC;

-- Ineditifying Low-Profit Products
SELECT
	Product_Category,
	Product_Sub_Category,
	SUM(((UnitPrice - UnitPrice * UnitPriceDiscount - Unit_Cost) * OrderQty) - Unit_Freight_Cost) AS Total_Profit,
    SUM(OrderQty) AS Total_Orders,
    SUM(UnitPrice*OrderQty) AS Total_Revenue
FROM sales
GROUP BY Product_Category,Product_Sub_Category
HAVING Total_Profit <=0
ORDER BY Total_Profit;

-- Total Freight Costs and Profit per Region
SELECT 
    Sales_Region,
    SUM(Unit_Freight_Cost * OrderQty) AS Total_Freight_Cost,
    SUM((UnitPrice * OrderQty) - (Unit_Cost * OrderQty) - (Unit_Freight_Cost * OrderQty)) AS Total_Profit,
    ROUND((SUM((UnitPrice * OrderQty) - (Unit_Cost * OrderQty) - (Unit_Freight_Cost * OrderQty)) / SUM(UnitPrice * OrderQty)) * 100, 2) AS Profit_Margin_Percentage
FROM 
    sales
GROUP BY 
    Sales_Region
ORDER BY 
    Total_Freight_Cost DESC;

-- Freight Costs and Profit by Product Category
SELECT 
    Product_Category,
    SUM(Unit_Freight_Cost * OrderQty) AS Total_Freight_Cost,
    SUM((UnitPrice * OrderQty) - (Unit_Cost * OrderQty) - (Unit_Freight_Cost * OrderQty)) AS Total_Profit,
    ROUND((SUM((UnitPrice * OrderQty) - (Unit_Cost * OrderQty) - (Unit_Freight_Cost * OrderQty)) / SUM(UnitPrice * OrderQty)) * 100, 2) AS Profit_Margin_Percentage
FROM 
    sales
GROUP BY 
    Product_Category
ORDER BY 
    Total_Freight_Cost DESC;

-- Freight Costs and Margins Over Time
SELECT 
    YEAR(OrderDate) AS Year,
    ROUND(SUM(Unit_Freight_Cost * OrderQty),2) AS Total_Freight_Cost,
    ROUND(SUM((UnitPrice * OrderQty) - (Unit_Cost * OrderQty) - (Unit_Freight_Cost * OrderQty)),2) AS Total_Profit,
    ROUND((SUM((UnitPrice * OrderQty) - (Unit_Cost * OrderQty) - (Unit_Freight_Cost * OrderQty)) / SUM(UnitPrice * OrderQty)) * 100, 2) AS Profit_Margin_Percentage
FROM 
    sales
GROUP BY 
    YEAR(OrderDate)
ORDER BY 
    Year;

-- Freight Costs by Product and Region
SELECT 
    Product_Name,
    Sales_Region,
    ROUND(SUM(Unit_Freight_Cost * OrderQty),2) AS Total_Freight_Cost,
    ROUND(SUM((UnitPrice * OrderQty) - (Unit_Cost * OrderQty) - (Unit_Freight_Cost * OrderQty)),2) AS Total_Profit,
    ROUND((SUM((UnitPrice * OrderQty) - (Unit_Cost * OrderQty) - (Unit_Freight_Cost * OrderQty)) / SUM(UnitPrice * OrderQty)) * 100, 2) AS Profit_Margin_Percentage
FROM 
    sales
GROUP BY 
    Product_Name, Sales_Region
ORDER BY 
    Total_Freight_Cost DESC;
