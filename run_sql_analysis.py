"""
SQL Database Setup and Query Execution
Creates SQLite database and runs analysis queries
Author: Abhilash Pal
"""

import pandas as pd
import sqlite3
import os

print("="*70)
print("E-COMMERCE SQL ANALYSIS")
print("="*70)

# Load the cleaned data
print("\n1. Loading dataset...")
df = pd.read_csv('ecommerce_data.csv')
df['InvoiceDate'] = pd.to_datetime(df['InvoiceDate'])

# Clean the data (same as in notebook)
print("2. Cleaning data...")
original_len = len(df)
df = df[~df['InvoiceNo'].astype(str).str.startswith('C')]
df = df.dropna(subset=['CustomerID'])
df = df[df['Quantity'] > 0]
df = df[df['UnitPrice'] > 0]

# Create derived columns
df['TotalPrice'] = df['Quantity'] * df['UnitPrice']
df['Year'] = df['InvoiceDate'].dt.year
df['Month'] = df['InvoiceDate'].dt.month
df['Day'] = df['InvoiceDate'].dt.day
df['DayOfWeek'] = df['InvoiceDate'].dt.day_name()
df['Quarter'] = df['InvoiceDate'].dt.quarter

print(f"   Cleaned: {len(df):,} rows (removed {original_len - len(df):,} invalid records)")

# Create SQLite database
print("\n3. Creating SQLite database...")
db_file = 'ecommerce.db'
if os.path.exists(db_file):
    os.remove(db_file)

conn = sqlite3.connect(db_file)
df.to_sql('transactions', conn, if_exists='replace', index=False)
print(f"   ✅ Database created: {db_file}")

# Function to run query and display results
def run_query(name, query, limit=20):
    print(f"\n{'='*70}")
    print(f"{name}")
    print(f"{'='*70}")
    try:
        result = pd.read_sql_query(query, conn)
        if len(result) > limit:
            print(f"Showing first {limit} rows (total: {len(result)} rows)")
            print(result.head(limit).to_string(index=False))
        else:
            print(result.to_string(index=False))
        
        # Save to CSV
        csv_filename = f"query_{name.lower().replace(' ', '_').replace('/', '_')}.csv"
        result.to_csv(csv_filename, index=False)
        print(f"\n✅ Results saved to: {csv_filename}")
        return result
    except Exception as e:
        print(f"❌ Error: {e}")
        return None

# ============================================================================
# RUN KEY QUERIES
# ============================================================================

print("\n" + "="*70)
print("EXECUTING SQL QUERIES")
print("="*70)

# Query 1: Business Overview
query1 = """
SELECT 
    COUNT(DISTINCT InvoiceNo) as Total_Orders,
    COUNT(DISTINCT CustomerID) as Unique_Customers,
    ROUND(SUM(TotalPrice), 2) as Total_Revenue,
    ROUND(AVG(TotalPrice), 2) as Avg_Transaction_Value,
    SUM(Quantity) as Total_Units_Sold
FROM transactions;
"""
run_query("1. BUSINESS OVERVIEW", query1)

# Query 2: Monthly Trends
query2 = """
SELECT 
    Year,
    Month,
    ROUND(SUM(TotalPrice), 2) as Monthly_Revenue,
    COUNT(DISTINCT InvoiceNo) as Orders,
    COUNT(DISTINCT CustomerID) as Unique_Customers,
    ROUND(AVG(TotalPrice), 2) as Avg_Transaction_Value
FROM transactions
GROUP BY Year, Month
ORDER BY Year, Month;
"""
run_query("2. MONTHLY TRENDS", query2)

# Query 3: Top Products
query3 = """
SELECT 
    Description as Product,
    COUNT(DISTINCT InvoiceNo) as Orders,
    SUM(Quantity) as Units_Sold,
    ROUND(SUM(TotalPrice), 2) as Total_Revenue,
    ROUND(AVG(UnitPrice), 2) as Avg_Price
FROM transactions
GROUP BY Description
ORDER BY Total_Revenue DESC
LIMIT 20;
"""
run_query("3. TOP 20 PRODUCTS", query3)

# Query 4: Top Customers
query4 = """
SELECT 
    CustomerID,
    COUNT(DISTINCT InvoiceNo) as Total_Orders,
    SUM(Quantity) as Units_Purchased,
    ROUND(SUM(TotalPrice), 2) as Total_Spent,
    ROUND(AVG(TotalPrice), 2) as Avg_Order_Value
FROM transactions
GROUP BY CustomerID
ORDER BY Total_Spent DESC
LIMIT 30;
"""
run_query("4. TOP 30 CUSTOMERS", query4, limit=30)

# Query 5: Country Performance
query5 = """
SELECT 
    Country,
    COUNT(DISTINCT CustomerID) as Customers,
    COUNT(DISTINCT InvoiceNo) as Orders,
    ROUND(SUM(TotalPrice), 2) as Revenue,
    ROUND(AVG(TotalPrice), 2) as Avg_Transaction
FROM transactions
GROUP BY Country
ORDER BY Revenue DESC;
"""
run_query("5. GEOGRAPHIC PERFORMANCE", query5)

# Query 6: Day of Week Analysis
query6 = """
SELECT 
    DayOfWeek,
    COUNT(DISTINCT InvoiceNo) as Orders,
    ROUND(SUM(TotalPrice), 2) as Revenue,
    ROUND(AVG(TotalPrice), 2) as Avg_Transaction
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
"""
run_query("6. DAY OF WEEK ANALYSIS", query6)

# Query 7: Quarterly Performance
query7 = """
SELECT 
    Year,
    Quarter,
    COUNT(DISTINCT InvoiceNo) as Orders,
    COUNT(DISTINCT CustomerID) as Customers,
    ROUND(SUM(TotalPrice), 2) as Revenue
FROM transactions
GROUP BY Year, Quarter
ORDER BY Year, Quarter;
"""
run_query("7. QUARTERLY PERFORMANCE", query7)

# Query 8: Customer Purchase Frequency
query8 = """
SELECT 
    CASE 
        WHEN Order_Count = 1 THEN '1 Order'
        WHEN Order_Count BETWEEN 2 AND 5 THEN '2-5 Orders'
        WHEN Order_Count BETWEEN 6 AND 10 THEN '6-10 Orders'
        WHEN Order_Count BETWEEN 11 AND 20 THEN '11-20 Orders'
        ELSE '20+ Orders'
    END as Purchase_Frequency,
    COUNT(*) as Number_of_Customers,
    ROUND(SUM(Total_Revenue), 2) as Total_Revenue,
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
    CASE Purchase_Frequency
        WHEN '1 Order' THEN 1
        WHEN '2-5 Orders' THEN 2
        WHEN '6-10 Orders' THEN 3
        WHEN '11-20 Orders' THEN 4
        ELSE 5
    END;
"""
run_query("8. CUSTOMER PURCHASE FREQUENCY", query8)

# Query 9: Product Affinity (Basket Analysis)
query9 = """
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
    Times_Bought_Together
FROM ProductPairs
WHERE Times_Bought_Together >= 10
ORDER BY Times_Bought_Together DESC
LIMIT 20;
"""
run_query("9. PRODUCT AFFINITY (Top 20)", query9)

# Query 10: Churn Analysis
query10 = """
WITH LastPurchase AS (
    SELECT 
        CustomerID,
        MAX(InvoiceDate) as Last_Purchase_Date,
        ROUND(JULIANDAY('2024-12-31') - JULIANDAY(MAX(InvoiceDate)), 0) as Days_Since_Purchase,
        COUNT(DISTINCT InvoiceNo) as Total_Orders,
        ROUND(SUM(TotalPrice), 2) as Total_Revenue
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
    ROUND(SUM(Total_Revenue), 2) as Total_Revenue,
    ROUND(AVG(Total_Revenue), 2) as Avg_Customer_Value
FROM LastPurchase
GROUP BY Customer_Status
ORDER BY 
    CASE Customer_Status
        WHEN 'Active' THEN 1
        WHEN 'At Risk' THEN 2
        WHEN 'Churning' THEN 3
        ELSE 4
    END;
"""
run_query("10. CUSTOMER CHURN ANALYSIS", query10)

# Close connection
conn.close()

print("\n" + "="*70)
print("SQL ANALYSIS COMPLETE!")
print("="*70)
print("\n📊 All query results have been saved as CSV files")
print(f"📁 Database: {db_file}")
print("\nYou can now:")
print("  1. Use these CSV files in Tableau for visualization")
print("  2. Reference the SQL queries in your resume/portfolio")
print("  3. Share the database file for further analysis")
print("\n✅ SQL demonstration complete!")
