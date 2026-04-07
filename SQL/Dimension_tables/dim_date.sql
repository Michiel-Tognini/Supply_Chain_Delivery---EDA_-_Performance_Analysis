SELECT 
	DISTINCT(EXTRACT(year FROM load_date)) AS year
FROM loads
ORDER BY year