-- ============================================================================
-- E-COMMERCE SALES ANALYSIS - SQL QUERIES
-- Author: Abhilash Pal
-- Description: SQL queries demonstrating data extraction and analysis skills
-- ============================================================================

-- ============================================================================
-- 1. BUSINESS OVERVIEW METRICS
-- ============================================================================

-- Total revenue, orders, and customers
SELECT 
    COUNT(DISTINCT InvoiceNo) as Total_Orders,
    COUNT(DISTINCT CustomerID) as Unique_Customers,
    SUM(TotalPrice) as Total_Revenue,
    AVG(TotalPrice) as Avg_Transaction_Value,
    SUM(Quantity) as Total_Units_Sold
FROM transactions;


-- Monthly revenue trend with growth rate
SELECT 
    Year,
    Month,
    SUM(TotalPrice) as Monthly_Revenue,
    COUNT(DISTINCT InvoiceNo) as Orders,
    COUNT(DISTINCT CustomerID) as Unique_Customers,
    ROUND(AVG(TotalPrice), 2) as Avg_Transaction_Value,
    LAG(SUM(TotalPrice)) OVER (ORDER BY Year, Month) as Previous_Month_Revenue,
    ROUND(
        (SUM(TotalPrice) - LAG(SUM(TotalPrice)) OVER (ORDER BY Year, Month)) 
        / LAG(SUM(TotalPrice)) OVER (ORDER BY Year, Month) * 100, 
        2
    ) as Growth_Rate_Pct
FROM transactions
GROUP BY Year, Month
ORDER BY Year, Month;


-- ============================================================================
-- 2. PRODUCT PERFORMANCE ANALYSIS
-- ============================================================================

-- Top 20 products by revenue
SELECT 
    Description as Product,
    COUNT(DISTINCT InvoiceNo) as Number_of_Orders,
    SUM(Quantity) as Units_Sold,
    COUNT(DISTINCT CustomerID) as Unique_Customers,
    ROUND(AVG(UnitPrice), 2) as Avg_Unit_Price,
    SUM(TotalPrice) as Total_Revenue,
    ROUND(SUM(TotalPrice) / (SELECT SUM(TotalPrice) FROM transactions) * 100, 2) as Revenue_Contribution_Pct
FROM transactions
GROUP BY Description
ORDER BY Total_Revenue DESC
LIMIT 20;


-- Product performance by category (if you have category data)
-- Products with highest growth month-over-month
WITH MonthlyProductSales AS (
    SELECT 
        Description,
        Year,
        Month,
        SUM(TotalPrice) as Monthly_Revenue
    FROM transactions
    GROUP BY Description, Year, Month
)
SELECT 
    Description,
    Year,
    Month,
    Monthly_Revenue,
    LAG(Monthly_Revenue) OVER (PARTITION BY Description ORDER BY Year, Month) as Prev_Month,
    ROUND(
        (Monthly_Revenue - LAG(Monthly_Revenue) OVER (PARTITION BY Description ORDER BY Year, Month))
        / LAG(Monthly_Revenue) OVER (PARTITION BY Description ORDER BY Year, Month) * 100,
        2
    ) as Growth_Rate_Pct
FROM MonthlyProductSales
WHERE LAG(Monthly_Revenue) OVER (PARTITION BY Description ORDER BY Year, Month) IS NOT NULL
ORDER BY Growth_Rate_Pct DESC
LIMIT 20;


-- ============================================================================
-- 3. CUSTOMER ANALYSIS
-- ============================================================================

-- Top 50 customers by revenue
SELECT 
    CustomerID,
    COUNT(DISTINCT InvoiceNo) as Total_Orders,
    SUM(Quantity) as Total_Units_Purchased,
    SUM(TotalPrice) as Total_Spent,
    ROUND(AVG(TotalPrice), 2) as Avg_Order_Value,
    MIN(InvoiceDate) as First_Purchase,
    MAX(InvoiceDate) as Last_Purchase,
    ROUND(JULIANDAY(MAX(InvoiceDate)) - JULIANDAY(MIN(InvoiceDate)), 0) as Customer_Lifetime_Days
FROM transactions
GROUP BY CustomerID
ORDER BY Total_Spent DESC
LIMIT 50;


-- Customer purchase frequency distribution
SELECT 
    CASE 
        WHEN Order_Count = 1 THEN '1 Order'
        WHEN Order_Count BETWEEN 2 AND 5 THEN '2-5 Orders'
        WHEN Order_Count BETWEEN 6 AND 10 THEN '6-10 Orders'
        WHEN Order_Count BETWEEN 11 AND 20 THEN '11-20 Orders'
        ELSE '20+ Orders'
    END as Order_Frequency,
    COUNT(*) as Number_of_Customers,
    SUM(Total_Revenue) as Total_Revenue,
    ROUND(AVG(Total_Revenue), 2) as Avg_Customer_Value
FROM (
    SELECT 
        CustomerID,
        COUNT(DISTINCT InvoiceNo) as Order_Count,
        SUM(TotalPrice) as Total_Revenue
    FROM transactions
    GROUP BY CustomerID
) customer_stats
GROUP BY 
    CASE 
        WHEN Order_Count = 1 THEN '1 Order'
        WHEN Order_Count BETWEEN 2 AND 5 THEN '2-5 Orders'
        WHEN Order_Count BETWEEN 6 AND 10 THEN '6-10 Orders'
        WHEN Order_Count BETWEEN 11 AND 20 THEN '11-20 Orders'
        ELSE '20+ Orders'
    END
ORDER BY 
    CASE Order_Frequency
        WHEN '1 Order' THEN 1
        WHEN '2-5 Orders' THEN 2
        WHEN '6-10 Orders' THEN 3
        WHEN '11-20 Orders' THEN 4
        ELSE 5
    END;


-- Customer cohort analysis (by first purchase month)
WITH FirstPurchase AS (
    SELECT 
        CustomerID,
        DATE(MIN(InvoiceDate), 'start of month') as Cohort_Month
    FROM transactions
    GROUP BY CustomerID
)
SELECT 
    fp.Cohort_Month,
    COUNT(DISTINCT fp.CustomerID) as Cohort_Size,
    COUNT(DISTINCT t.CustomerID) as Active_Customers,
    SUM(t.TotalPrice) as Cohort_Revenue,
    ROUND(AVG(t.TotalPrice), 2) as Avg_Order_Value
FROM FirstPurchase fp
LEFT JOIN transactions t ON fp.CustomerID = t.CustomerID
GROUP BY fp.Cohort_Month
ORDER BY fp.Cohort_Month;


-- ============================================================================
-- 4. GEOGRAPHIC ANALYSIS
-- ============================================================================

-- Sales performance by country
SELECT 
    Country,
    COUNT(DISTINCT CustomerID) as Unique_Customers,
    COUNT(DISTINCT InvoiceNo) as Total_Orders,
    SUM(Quantity) as Units_Sold,
    SUM(TotalPrice) as Total_Revenue,
    ROUND(AVG(TotalPrice), 2) as Avg_Transaction_Value,
    ROUND(SUM(TotalPrice) / COUNT(DISTINCT InvoiceNo), 2) as Avg_Order_Value,
    ROUND(SUM(TotalPrice) / (SELECT SUM(TotalPrice) FROM transactions) * 100, 2) as Revenue_Share_Pct
FROM transactions
GROUP BY Country
ORDER BY Total_Revenue DESC;


-- Country growth trends
SELECT 
    Country,
    Year,
    Month,
    SUM(TotalPrice) as Monthly_Revenue,
    COUNT(DISTINCT CustomerID) as Active_Customers,
    LAG(SUM(TotalPrice)) OVER (PARTITION BY Country ORDER BY Year, Month) as Prev_Month_Revenue,
    ROUND(
        (SUM(TotalPrice) - LAG(SUM(TotalPrice)) OVER (PARTITION BY Country ORDER BY Year, Month))
        / LAG(SUM(TotalPrice)) OVER (PARTITION BY Country ORDER BY Year, Month) * 100,
        2
    ) as Growth_Rate_Pct
FROM transactions
GROUP BY Country, Year, Month
HAVING LAG(SUM(TotalPrice)) OVER (PARTITION BY Country ORDER BY Year, Month) IS NOT NULL
ORDER BY Country, Year, Month;


-- ============================================================================
-- 5. TEMPORAL ANALYSIS
-- ============================================================================

-- Sales by day of week
SELECT 
    DayOfWeek,
    COUNT(DISTINCT InvoiceNo) as Orders,
    SUM(TotalPrice) as Revenue,
    COUNT(DISTINCT CustomerID) as Unique_Customers,
    ROUND(AVG(TotalPrice), 2) as Avg_Transaction_Value
FROM transactions
GROUP BY DayOfWeek
ORDER BY 
    CASE DayOfWeek
        WHEN 'Monday' THEN 1
        WHEN 'Tuesday' THEN 2
        WHEN 'Wednesday' THEN 3
        WHEN 'Thursday' THEN 4
        WHEN 'Friday' THEN 5
        WHEN 'Saturday' THEN 6
        WHEN 'Sunday' THEN 7
    END;


-- Quarterly performance
SELECT 
    Year,
    Quarter,
    COUNT(DISTINCT InvoiceNo) as Orders,
    COUNT(DISTINCT CustomerID) as Customers,
    SUM(Quantity) as Units_Sold,
    SUM(TotalPrice) as Revenue,
    ROUND(AVG(TotalPrice), 2) as Avg_Transaction_Value
FROM transactions
GROUP BY Year, Quarter
ORDER BY Year, Quarter;


-- Hourly sales pattern (if you have hour data)
SELECT 
    CAST(strftime('%H', InvoiceDate) AS INTEGER) as Hour_of_Day,
    COUNT(DISTINCT InvoiceNo) as Orders,
    SUM(TotalPrice) as Revenue,
    ROUND(AVG(TotalPrice), 2) as Avg_Transaction_Value
FROM transactions
GROUP BY Hour_of_Day
ORDER BY Hour_of_Day;


-- ============================================================================
-- 6. BASKET ANALYSIS
-- ============================================================================

-- Average basket size
SELECT 
    ROUND(AVG(Items_Per_Order), 2) as Avg_Items_Per_Order,
    ROUND(AVG(Revenue_Per_Order), 2) as Avg_Revenue_Per_Order,
    MAX(Items_Per_Order) as Max_Items_In_Order,
    MAX(Revenue_Per_Order) as Max_Order_Value
FROM (
    SELECT 
        InvoiceNo,
        COUNT(*) as Items_Per_Order,
        SUM(TotalPrice) as Revenue_Per_Order
    FROM transactions
    GROUP BY InvoiceNo
) order_stats;


-- Product affinity (products frequently bought together)
WITH ProductPairs AS (
    SELECT 
        t1.Description as Product_A,
        t2.Description as Product_B,
        COUNT(DISTINCT t1.InvoiceNo) as Times_Bought_Together
    FROM transactions t1
    JOIN transactions t2 
        ON t1.InvoiceNo = t2.InvoiceNo 
        AND t1.Description < t2.Description
    GROUP BY t1.Description, t2.Description
)
SELECT 
    Product_A,
    Product_B,
    Times_Bought_Together,
    ROUND(Times_Bought_Together * 100.0 / (SELECT COUNT(DISTINCT InvoiceNo) FROM transactions), 2) as Occurrence_Pct
FROM ProductPairs
WHERE Times_Bought_Together >= 10
ORDER BY Times_Bought_Together DESC
LIMIT 20;


-- ============================================================================
-- 7. ADVANCED ANALYTICS
-- ============================================================================

-- Customer Lifetime Value (CLV) estimation
WITH CustomerMetrics AS (
    SELECT 
        CustomerID,
        COUNT(DISTINCT InvoiceNo) as Total_Orders,
        SUM(TotalPrice) as Total_Revenue,
        MIN(InvoiceDate) as First_Purchase,
        MAX(InvoiceDate) as Last_Purchase,
        ROUND(JULIANDAY(MAX(InvoiceDate)) - JULIANDAY(MIN(InvoiceDate)), 0) as Customer_Age_Days
    FROM transactions
    GROUP BY CustomerID
)
SELECT 
    CustomerID,
    Total_Orders,
    Total_Revenue,
    ROUND(Total_Revenue / NULLIF(Total_Orders, 0), 2) as Avg_Order_Value,
    Customer_Age_Days,
    ROUND(Total_Revenue / NULLIF(Customer_Age_Days, 0) * 365, 2) as Annualized_Revenue,
    CASE 
        WHEN Total_Revenue > 1000 AND Total_Orders > 10 THEN 'High Value'
        WHEN Total_Revenue > 500 AND Total_Orders > 5 THEN 'Medium Value'
        ELSE 'Low Value'
    END as Customer_Segment
FROM CustomerMetrics
WHERE Customer_Age_Days > 0
ORDER BY Total_Revenue DESC
LIMIT 100;


-- Churn analysis - customers who haven't purchased in 90 days
WITH LastPurchase AS (
    SELECT 
        CustomerID,
        MAX(InvoiceDate) as Last_Purchase_Date,
        ROUND(JULIANDAY('2024-12-31') - JULIANDAY(MAX(InvoiceDate)), 0) as Days_Since_Purchase,
        COUNT(DISTINCT InvoiceNo) as Total_Orders,
        SUM(TotalPrice) as Total_Revenue
    FROM transactions
    GROUP BY CustomerID
)
SELECT 
    CASE 
        WHEN Days_Since_Purchase <= 30 THEN 'Active'
        WHEN Days_Since_Purchase <= 60 THEN 'At Risk'
        WHEN Days_Since_Purchase <= 90 THEN 'Churning'
        ELSE 'Churned'
    END as Customer_Status,
    COUNT(*) as Number_of_Customers,
    SUM(Total_Revenue) as Total_Revenue,
    ROUND(AVG(Total_Revenue), 2) as Avg_Customer_Value,
    ROUND(AVG(Total_Orders), 2) as Avg_Orders_Per_Customer
FROM LastPurchase
GROUP BY Customer_Status
ORDER BY 
    CASE Customer_Status
        WHEN 'Active' THEN 1
        WHEN 'At Risk' THEN 2
        WHEN 'Churning' THEN 3
        ELSE 4
    END;


-- ============================================================================
-- 8. PERFORMANCE BENCHMARKS
-- ============================================================================

-- Compare current month vs previous month
WITH MonthlyMetrics AS (
    SELECT 
        Year,
        Month,
        SUM(TotalPrice) as Revenue,
        COUNT(DISTINCT InvoiceNo) as Orders,
        COUNT(DISTINCT CustomerID) as Customers
    FROM transactions
    GROUP BY Year, Month
),
CurrentMonth AS (
    SELECT * FROM MonthlyMetrics 
    WHERE Year = (SELECT MAX(Year) FROM MonthlyMetrics)
    AND Month = (SELECT MAX(Month) FROM MonthlyMetrics WHERE Year = (SELECT MAX(Year) FROM MonthlyMetrics))
),
PreviousMonth AS (
    SELECT * FROM MonthlyMetrics 
    WHERE (Year = (SELECT Year FROM CurrentMonth) AND Month = (SELECT Month FROM CurrentMonth) - 1)
    OR (Year = (SELECT Year FROM CurrentMonth) - 1 AND Month = 12 AND (SELECT Month FROM CurrentMonth) = 1)
)
SELECT 
    'Current Month' as Period,
    cm.Revenue as Current_Revenue,
    pm.Revenue as Previous_Revenue,
    cm.Revenue - pm.Revenue as Revenue_Change,
    ROUND((cm.Revenue - pm.Revenue) / pm.Revenue * 100, 2) as Revenue_Growth_Pct,
    cm.Orders as Current_Orders,
    pm.Orders as Previous_Orders,
    cm.Customers as Current_Customers,
    pm.Customers as Previous_Customers
FROM CurrentMonth cm, PreviousMonth pm;


-- ============================================================================
-- END OF SQL QUERIES
-- ============================================================================
