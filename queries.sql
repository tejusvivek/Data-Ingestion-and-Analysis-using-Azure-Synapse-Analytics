--Creating External File Format
CREATE EXTERNAL FILE FORMAT csvfile
WITH (FORMAT_TYPE = DELIMITEDTEXT,
      FORMAT_OPTIONS(
          FIELD_TERMINATOR = ',',
          STRING_DELIMITER = '"',
          FIRST_ROW = 2,
          USE_TYPE_DEFAULT = FALSE)
);

--Creating External Data Source
CREATE EXTERNAL DATA SOURCE ext_src_adls
WITH
(   LOCATION = 'abfss://raw@adls21.dfs.core.windows.net'
)

--Creating External Tables
CREATE EXTERNAL TABLE dbo.customerData (
	CustomerID NVARCHAR(4000),
    NameStyle BIT,
    Title NVARCHAR(4000),
    FirstName NVARCHAR(4000),
    MiddleName NVARCHAR(4000),
    LastName NVARCHAR(4000),
    Suffix NVARCHAR(4000),
    CompanyName NVARCHAR(4000),
    SalesPerson NVARCHAR(4000),
    EmailAddress NVARCHAR(4000),
    Phone NVARCHAR(4000),
    PasswordHash NVARCHAR(4000),
    PasswordSalt NVARCHAR(4000),
    rowguid NVARCHAR(4000),
    ModifiedDate NVARCHAR(4000)
	)
	WITH (
	FILE_FORMAT = csvfile,
    DATA_SOURCE = ext_src_adls,
	LOCATION = 'saleslt/customer/*'
	)
GO

CREATE EXTERNAL TABLE dbo.Address (
    AddressID INT,
    AddressLine1 NVARCHAR(4000),
    AddressLine2 NVARCHAR(4000),
    City NVARCHAR(4000),
    StateProvince NVARCHAR(4000),
    CountryRegion NVARCHAR(4000),
    PostalCode NVARCHAR(4000),
    rowguid NVARCHAR(4000),
    ModifiedDate NVARCHAR(4000),
	)
	WITH (
	FILE_FORMAT = csvfile,
    DATA_SOURCE = ext_src_adls,
	LOCATION = 'saleslt/address/*'
	)
GO

CREATE EXTERNAL TABLE dbo.customerAddress (
    CustomerID BIGINT,
    AddressID INT,
    AddressType NVARCHAR(4000),
    rowguid NVARCHAR(4000),
    ModifiedDate NVARCHAR(4000)
	)
	WITH (
	FILE_FORMAT = csvfile,
    DATA_SOURCE = ext_src_adls,
	LOCATION = 'saleslt/customeraddress/*'
	)
GO

CREATE EXTERNAL TABLE dbo.product (
    ProductID INT,
    Name NVARCHAR(4000),
    ProductNumber NVARCHAR(4000),
    Color NVARCHAR(4000),
    StandardCost FLOAT,
    ListPrice FLOAT,
    Size NVARCHAR(50),
    Weight FLOAT,
    ProductCategoryID INT,
    ProductModelID TINYINT,
    SellStartDate DATETIME,
    SellEndDate DATETIME,
    DiscontinuedDate NVARCHAR(4000)
	)
	WITH (
	FILE_FORMAT = csvfile,
    DATA_SOURCE = ext_src_adls,
	LOCATION = 'saleslt/product/*'
	)
GO

CREATE EXTERNAL TABLE dbo.salesorderdetail (
    SalesOrderID BIGINT,
    SalesOrderDetailID BIGINT,
    OrderQty TINYINT,
    ProductID INT,
    UnitPrice FLOAT,
    UnitPriceDiscount FLOAT,
    LineTotal FLOAT
	)
	WITH (
	FILE_FORMAT = csvfile,
    DATA_SOURCE = ext_src_adls,
	LOCATION = 'saleslt/salesorderdetail/*'
	)
GO

CREATE EXTERNAL TABLE dbo.salesorderheader (
    SalesOrderID BIGINT,
    RevisionNumber TINYINT,
    OrderDate NVARCHAR(1000),
    DueDate NVARCHAR(1000),
    ShipDate NVARCHAR(1000),
    Status TINYINT,
    OnlineOrderFlag BIT,
    SalesOrderNumber NVARCHAR(1000),
    PurchaseOrderNumber NVARCHAR(1000),
    AccountNumber NVARCHAR(1000),
    CustomerID INT,
    ShipToAddressID INT,
    BillToAddressID INT,
    ShipMethod NVARCHAR(1000),
    CreditCardApprovalCode NVARCHAR(2000),
    SubTotal FLOAT,
    TaxAmt FLOAT,
    Freight FLOAT,
    TotalDue FLOAT,
    Comment NVARCHAR(1000),
    rowguid NVARCHAR(1000),
    ModifiedDate NVARCHAR(1000)
	)
	WITH (
	FILE_FORMAT = csvfile,
    DATA_SOURCE = ext_src_adls,
	LOCATION = 'saleslt/salesorderheader/*'
	)
GO

--What is the gender breakdown of customers?
SELECT Title as Title, count(title) as noOfPeople from customerData
GROUP BY Title

--What is the total bill amount for customers?
SELECT ca.CustomerID, a.AddressID, a.City, soh.TotalDue as BillAmount FROM Address as a
JOIN CustomerAddress as ca
ON a.AddressID = ca.AddressID
JOIN salesorderheader as soh
ON soh.CustomerID = ca.CustomerID
ORDER BY soh.totaldue DESC

---Which is the city that produces the highest sales?
SELECT a.City, SUM(soh.TotalDue) as BillAmount FROM Address as a
JOIN CustomerAddress as ca
ON a.AddressID = ca.AddressID
JOIN salesorderheader as soh
ON soh.CustomerID = ca.CustomerID
GROUP BY a.city
ORDER BY billamount DESC

---What percentage of Revenue came from online ordering
SELECT soh.onlineorderflag, SUM(soh.TotalDue) as BillAmount FROM Address as a
JOIN CustomerAddress as ca
ON a.AddressID = ca.AddressID
JOIN salesorderheader as soh
ON soh.CustomerID = ca.CustomerID
GROUP BY soh.onlineorderflag
ORDER BY billamount DESC

--Find out the most popular product based on sales
SELECT p.name, sum(sod.lineTotal) as TotalSales  from product as p
JOIN salesorderdetail as sod
ON p.productid = sod.productid 
GROUP by p.name
Order by totalsales desc

--What is the lifetime of the products sold?
SELECT (p.productid), (DATEDIFF(YEAR, p.sellstartdate, p.sellenddate)) as productLifetime_yrs from product as p
where (DATEDIFF(YEAR, p.sellstartdate, p.sellenddate)) is not NULL
ORDER by p.productid asc