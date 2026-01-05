use malvin_telecom

-- 1. why are customers leaving maven telecom?

-- total no. of customers
Select count(distinct customer_id) as total_customers
from telecom_customer_churn;

-- duplicate customers?
select customer_id,
count(customer_id) as count
from telecom_customer_churn
group by customer_id
having count(customer_id) >1;

-- how much revenue did Maven lose to churned customers?
select customer_status,
count(customer_id) as customer_count,
round((sum(total_revenue) * 100.0) / sum(sum(total_revenue)) over(), 1) as revenue_percentage
from telecom_customer_churn
group by customer_status;

-- what is the typical tenure for new customers?
select customer_status,
case
	when tenure_in_months <= 1 then '1 month'
	when tenure_in_months <= 6 then '1-6 months'
	when tenure_in_months <= 12 then '1 year'
	when tenure_in_months <= 24 then '1-2 year'
	else '>2 years'
end as tenure,
count(customer_id) as tenure_count
from telecom_customer_churn
where customer_status = 'Joined'
Group by customer_status,
case
	when tenure_in_months <= 1 then '1 month'
	when tenure_in_months <= 6 then '1-6 months'
	when tenure_in_months <= 12 then '1 year'
	when tenure_in_months <= 24 then '1-2 year'
	else '>2 years'
end;

-- Typical tenure for churners
SELECT
    CASE 
        WHEN Tenure_in_Months <= 6 THEN '6 months'
        WHEN Tenure_in_Months <= 12 THEN '1 Year'
        WHEN Tenure_in_Months <= 24 THEN '2 Years'
        ELSE '> 2 Years'
    END AS Tenure,
    ROUND(COUNT(Customer_ID) * 100.0 / SUM(COUNT(Customer_ID)) OVER(),1) AS Churn_Percentage
FROM
telecom_customer_churn
WHERE
Customer_Status = 'Churned'
GROUP BY
    CASE 
        WHEN Tenure_in_Months <= 6 THEN '6 months'
        WHEN Tenure_in_Months <= 12 THEN '1 Year'
        WHEN Tenure_in_Months <= 24 THEN '2 Years'
        ELSE '> 2 Years'
    END
ORDER BY
Churn_Percentage DESC;

-- which cities have highest churn rates?
select
top 4 city,
count(customer_id) as churned,
CEILING(count(case when customer_status = 'churned' then customer_id else null end) * 100.0 / count(customer_id)) as churn_rate
from telecom_customer_churn
group by city
having count(customer_id) > 30
and count(case when customer_status = 'churned' then customer_id else null end) > 0
order by churn_rate desc;

-- why did customers churn? and what is the financial impact?
select churn_category,
round(sum(total_revenue),0) as churned_rev,
ceiling((count(customer_id)*100.0)/sum(count(customer_id)) over()) as churn_percentage
from telecom_customer_churn
where customer_status = 'churned'
group by churn_category
order by churn_percentage desc;

-- what service did churned customers use?
select
internet_type,
count(customer_id) as churned,
Round((count(customer_id)*100.0)/sum(count(customer_id)) over(), 1) as churn_percentage
from telecom_customer_churn
where churn_category = 'competitor'
and customer_status= 'churned'
group by internet_type
order by churned desc;

-- What contract were churners on?
SELECT 
    Contract,
    COUNT(Customer_ID) AS Churned,
    ROUND(COUNT(Customer_ID) * 100.0 / SUM(COUNT(Customer_ID)) OVER(), 1) AS Churn_Percentage
FROM 
    telecom_customer_churn

WHERE
    Customer_Status = 'Churned'
GROUP BY
    Contract
ORDER BY 
    Churned DESC;

-- Did churners have premium tech support?
SELECT 
    Premium_Tech_Support,
    COUNT(Customer_ID) AS Churned,
    ROUND(COUNT(Customer_ID) *100.0 / SUM(COUNT(Customer_ID)) OVER(),1) AS Churn_Percentage
FROM
    telecom_customer_churn
WHERE 
    Customer_Status = 'Churned'
GROUP BY Premium_Tech_Support
ORDER BY Churned DESC;


-- What Internet service were churners on?
SELECT
    Internet_Type,
    COUNT(Customer_ID) AS Churned,
    ROUND(COUNT(Customer_ID) * 100.0 / SUM(COUNT(Customer_ID)) OVER(), 1) AS Churn_Percentage
FROM
   telecom_customer_churn
WHERE 
    Customer_Status = 'Churned'
GROUP BY
Internet_Type
ORDER BY 
Churned DESC;


-- Typical tenure for churners
SELECT
    CASE 
        WHEN Tenure_in_Months <= 6 THEN '6 months'
        WHEN Tenure_in_Months <= 12 THEN '1 Year'
        WHEN Tenure_in_Months <= 24 THEN '2 Years'
        ELSE '> 2 Years'
    END AS Tenure,
    COUNT(Customer_ID) AS Churned,
    CEILING(COUNT(Customer_ID) * 100.0 / SUM(COUNT(Customer_ID)) OVER()) AS Churn_Percentage
FROM
telecom_customer_churn
WHERE
Customer_Status = 'Churned'
GROUP BY
    CASE 
        WHEN Tenure_in_Months <= 6 THEN '6 months'
        WHEN Tenure_in_Months <= 12 THEN '1 Year'
        WHEN Tenure_in_Months <= 24 THEN '2 Years'
        ELSE '> 2 Years'
    END
ORDER BY
Churned DESC;


-- Are high value customers at risk?

SELECT 
    CASE 
        WHEN (num_conditions >= 3) THEN 'High Risk'
        WHEN num_conditions = 2 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_level,
    COUNT(Customer_ID) AS num_customers,
    ROUND(COUNT(Customer_ID) *100.0 / SUM(COUNT(Customer_ID)) OVER(),1) AS cust_percentage,
    num_conditions  
FROM 
    (
    SELECT 
        Customer_ID,
        SUM(CASE WHEN Offer = 'Offer E' OR Offer = 'None' THEN 1 ELSE 0 END)+
        SUM(CASE WHEN Contract = 'Month-to-Month' THEN 1 ELSE 0 END) +
        SUM(CASE WHEN Premium_Tech_Support = 'No' THEN 1 ELSE 0 END) +
        SUM(CASE WHEN Internet_Type = 'Fiber Optic' THEN 1 ELSE 0 END) AS num_conditions
    FROM 
        telecom_customer_churn
    WHERE 
        Monthly_Charge > 70.05 
        AND Customer_Status = 'Stayed'
        AND Number_of_Referrals > 0
        AND Tenure_in_Months > 9
    GROUP BY 
        Customer_ID
    HAVING 
        SUM(CASE WHEN Offer = 'Offer E' OR Offer = 'None' THEN 1 ELSE 0 END) +
        SUM(CASE WHEN Contract = 'Month-to-Month' THEN 1 ELSE 0 END) +
        SUM(CASE WHEN Premium_Tech_Support = 'No' THEN 1 ELSE 0 END) +
        SUM(CASE WHEN Internet_Type = 'Fiber Optic' THEN 1 ELSE 0 END) >= 1
    ) AS subquery
GROUP BY 
    CASE 
        WHEN (num_conditions >= 3) THEN 'High Risk'
        WHEN num_conditions = 2 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END, num_conditions; 


-- why did customer's churn exactly?
SELECT TOP 10
    Churn_Reason,
    Churn_Category,
    ROUND(COUNT(Customer_ID) *100 / SUM(COUNT(Customer_ID)) OVER(), 1) AS churn_perc
FROM
   telecom_customer_churn
WHERE
    Customer_Status = 'Churned'
GROUP BY 
Churn_Reason,
Churn_Category
ORDER BY churn_perc DESC;


-- What offers were churners on?
SELECT  
    Offer,
    ROUND(COUNT(Customer_ID) * 100.0 / SUM(COUNT(Customer_ID)) OVER(), 1) AS Churn_Percentage
FROM
    telecom_customer_churn
WHERE
    Customer_Status = 'Churned'
GROUP BY
Offer
ORDER BY 
churn_percentage DESC;


-- HOW old were churners?
SELECT  
    CASE
        WHEN Age <= 30 THEN '19 - 30 yrs'
        WHEN Age <= 40 THEN '31 - 40 yrs'
        WHEN Age <= 50 THEN '41 - 50 yrs'
        WHEN Age <= 60 THEN '51 - 60 yrs'
        ELSE  '> 60 yrs'
    END AS Age,
    ROUND(COUNT(Customer_ID) * 100 / SUM(COUNT(Customer_ID)) OVER(), 1) AS Churn_Percentage
FROM 
   telecom_customer_churn
WHERE
    Customer_Status = 'Churned'
GROUP BY
    CASE
        WHEN Age <= 30 THEN '19 - 30 yrs'
        WHEN Age <= 40 THEN '31 - 40 yrs'
        WHEN Age <= 50 THEN '41 - 50 yrs'
        WHEN Age <= 60 THEN '51 - 60 yrs'
        ELSE  '> 60 yrs'
    END
ORDER BY
Churn_Percentage DESC;

-- What gender were churners?
SELECT
    Gender,
    ROUND(COUNT(Customer_ID) *100.0 / SUM(COUNT(Customer_ID)) OVER(), 1) AS Churn_Percentage
FROM
   telecom_customer_churn
WHERE
    Customer_Status = 'Churned'
GROUP BY
    Gender
ORDER BY
Churn_Percentage DESC;

-- Did churners have dependents
SELECT
    CASE
        WHEN Number_of_Dependents > 0 THEN 'Has Dependents'
        ELSE 'No Dependents'
    END AS Dependents,
    ROUND(COUNT(Customer_ID) *100 / SUM(COUNT(Customer_ID)) OVER(), 1) AS Churn_Percentage

FROM
   telecom_customer_churn
WHERE
    Customer_Status = 'Churned'
GROUP BY 
CASE
        WHEN Number_of_Dependents > 0 THEN 'Has Dependents'
        ELSE 'No Dependents'
    END
ORDER BY Churn_Percentage DESC;

-- Were churners married
SELECT
    Married,
    ROUND(COUNT(Customer_ID) *100.0 / SUM(COUNT(Customer_ID)) OVER(), 1) AS Churn_Percentage
FROM
    telecom_customer_churn
WHERE
    Customer_Status = 'Churned'
GROUP BY
    Married
ORDER BY
Churn_Percentage DESC;


-- Do churners have phone lines
SELECT
    Phone_Service,
    ROUND(COUNT(Customer_ID) * 100.0 / SUM(COUNT(Customer_ID)) OVER(), 1) AS Churned
FROM
   telecom_customer_churn
WHERE
    Customer_Status = 'Churned'
GROUP BY 
    Phone_Service


-- Do churners have internet service
SELECT
    Internet_Service,
    ROUND(COUNT(Customer_ID) * 100.0 / SUM(COUNT(Customer_ID)) OVER(), 1) AS Churned
FROM
    telecom_customer_churn
WHERE
    Customer_Status = 'Churned'
GROUP BY 
    Internet_Service


-- Did they give referrals
SELECT
    CASE
        WHEN Number_of_Referrals > 0 THEN 'Yes'
        ELSE 'No'
    END AS Referrals,
    ROUND(COUNT(Customer_ID) * 100.0 / SUM(COUNT(Customer_ID)) OVER(), 1) AS Churned
FROM
   telecom_customer_churn
WHERE
    Customer_Status = 'Churned'
GROUP BY 
    CASE
        WHEN Number_of_Referrals > 0 THEN 'Yes'
        ELSE 'No'
    END;


-- What Internet Type did 'Competitor' churners have?
SELECT
    Internet_Type,
    Churn_Category,
    ROUND(COUNT(Customer_ID) * 100.0 / SUM(COUNT(Customer_ID)) OVER(), 1) AS Churn_Percentage
FROM
   telecom_customer_churn
WHERE 
    Customer_Status = 'Churned'
    AND Churn_Category = 'Competitor'
GROUP BY
Internet_Type,
Churn_Category
ORDER BY Churn_Percentage DESC;