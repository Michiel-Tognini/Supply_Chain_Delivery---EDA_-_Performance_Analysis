**1) Project Overview**<br />
-------------------------------
*Main business question: Which routes and fleet segments drive the largest inefficiencies in delivery performance and cost?*<br />

![Screenshot Dashboard](https://github.com/Michiel-Tognini/Supply_Chain_Delivery---EDA_-_Performance_Analysis/blob/4d24764e13375d781d46c08877d72af1b357a756/Screenshot%20Dashboard.png)<br />

This project analyzes logistics performance data from 2022–2024 to identify inefficiencies across transportation routes and fleet operations.<br />

Using SQL and Power BI, the analysis evaluates delivery performance metrics such as on-time delivery rates, delivery delays, cost per mile, and route deviations. The dataset used originates from the Logistics Operations Database (Kaggle).<br />

SQL was used to perform exploratory data analysis (EDA) and to create a star schema data model consisting of fact and dimension tables, which were then used to build the analytical dashboard in Power BI.<br />

The analysis focuses on two perspectives:<br />

- **Route performance analysis** to identify inefficient delivery routes<br />
- **Fleet efficiency analysis** to evaluate operational performance across trucks and home terminals<br />

The goal is to uncover opportunities to improve delivery reliability, operational efficiency, and transportation cost management.<br /><br />

**2) Key Operational Metrics and Dimensions**<br />
---------------------------------------------------
**Key Metrics**<br />
- On-time delivery (%)<br />
- Average delivery delay (minutes)<br />
- Average cost per mile<br />
- Fuel cost per mile<br />
- Maintenance cost per mile<br />
- Total miles driven<br />
- Distance deviation (difference between planned and actual route distance)<br /><br />

**Dimensions**<br />
- Route (origin → destination)<br />
- Year (2022–2024)<br />
- Truck ID<br />
- Truck attributes<br />
- Fuel type<br />
- Tank capacity<br />
- Home terminal<br />
- Origin city<br />
- Destination city<br /><br />

These metrics allow performance analysis across routes, time periods, and fleet characteristics.<br /><br />

**3) Data Preparation & Modeling**<br />
-------------------------------------------
The analysis uses a star schema to support efficient analytics in Power BI.<br />

**Fact tables**<br />
- fact_route_cost_year<br />
- fact_route_service_year<br />
- fact_truck_cost_year<br />

**Dimension tables**<br />
- dim_routes<br />
- dim_trucks<br /><br />

Route-related fact tables are linked through route_id, while truck operational data connects through truck_id.<br />
This structure enables separate but complementary analysis of route efficiency and fleet efficiency.<br /><br />

**4) Data Quality Checks & Exploratory Analysis (SQL)**<br />
------------------------------------------------------------
Before creating the analytical model, SQL was used to perform extensive data validation and exploratory analysis on the raw dataset.<br />

Key checks included:<br />

**Operational consistency checks**<br />
- Verify that trips are evenly distributed across months<br />
- Check variance of actual delivery dates<br />
- Identify duplicate trips and loads<br />
- Verify each trip is linked to one load<br />
- Detect trips missing a load_id<br /><br />

**Data integrity checks**<br />
- Trips with drivers already terminated<br />
- Invalid planned dates (planned delivery < planned pickup)<br />
- Invalid actual dates (actual delivery < actual pickup)<br />
- Extreme delivery deviations (>72 hours difference from planned delivery)<br />
- Checks for NULL, zero, or negative values<br /><br />

**Cost validation checks**<br />
- Variation in fuel cost<br />
- Fuel cost per mile by truck and model year<br />
- Variation in maintenance costs<br />
- Validation that total maintenance cost calculations are correct<br />
- Maintenance cost by maintenance type<br />
- Maintenance cost per mile per truck<br /><br />

**Fleet structure checks**<br />
- Fleet size by truck model year<br />
- Distribution of miles driven per truck<br /><br />

**Service performance checks**<br />
- Extreme delivery delays<br />
- Minimum, maximum, and average delivery delay per route<br />
- Minimum, maximum, and average pickup delay per route<br />
- Variation and P90 values for detention time<br />
- Average pickup and delivery detention minutes<br /><br />

**Route performance validation**<br />
- Comparison between typical route distance and actual miles driven<br /><br />

These checks ensured the dataset was consistent, reliable, and suitable for analytical modeling.<br /><br />

**5) Summary of Insights**<br />
------------------------------------
**Cost trends**<br />
Transportation costs improved over time:<br />
- Total cost per mile decreased significantly from 2022 to 2024<br />
- Both fuel and maintenance costs per mile declined<br /><br />

No significant differences were found in total maintenance cost per mile and total fuel cost per mile between the total of analyzed routes. On the contrary, on the truck level differences in costs were observed and hence are taken into account in the Fleet efficiency insights<br /><br />
  
**Delivery performance stability**<br />
Despite cost improvements:<br />
- On-time delivery (%) remained stable<br />
- Average delivery delay did not significantly change<br />
- Route performance distribution stayed consistent across years<br /><br />

**Best performing routes**<br />
*(Low delay + low distance deviation)*<br /><br />

15 routes consistently perform well, including:<br />
Atlanta–Miami<br />
Dallas–Denver<br />
Houston–Memphis<br />
Las Vegas–Los Angeles<br />
Miami–Dallas<br />
Philadelphia–New York<br />
Phoenix–Denver<br />
Kansas City–Charlotte<br />
and others.<br /><br />

These routes demonstrate efficient operations and reliable delivery performance.<br /><br />

**Worst performing routes**<br />
*(High delay + high distance deviation)*<br /><br />

13 routes show persistent inefficiencies, including:<br />
Charlotte–Denver<br />
Dallas–New York<br />
Houston–Seattle<br />
Las Vegas–New York<br />
Seattle–Charlotte<br />
Seattle–Houston<br />
Seattle–Indianapolis<br />
and others.<br /><br />

A clear pattern emerges: all routes originating from Seattle perform poorly.<br /><br />

**Geographic patterns**<br />
Additional network observations:<br />
- All Seattle-origin routes fall into the worst performance quadrant<br />
- Both routes ending in Memphis perform well<br />
- Routes ending in Portland show medium performance<br /><br />

This indicates regional logistics inefficiencies within the network.<br /><br />

**Fleet efficiency insights**<br />
Truck efficiency varies by home terminal location.<br /><br />

Best performing terminals include:<br />
*(High number of total miles driven + low total cost per mile (fuel+maintenance))*<br />
- Charlotte<br />
- Denver<br />
- Kansas City<br />
- Las Vegas<br /><br />

Worst performing terminals include:<br />
*(Low number of total miles driven + high total cost per mile (fuel+maintenance))*<br />
- Seattle<br />
- Portland<br />
- Minneapolis<br />
- Los Angeles<br />
- Atlanta<br />
- Columbus<br /><br />

Tank capacity showed no significant impact on truck efficiency.<br /><br />

**Fleet utilization**<br />
Annual mileage distribution:<br />
- 159 trucks drive 400k–450k miles<br />
- 71 trucks drive 450k–500k miles<br />
- 4 trucks exceed 500k miles<br /><br />

This suggests an opportunity to increase utilization of moderately used trucks, potentially reducing the required fleet size and lowering maintenance costs.<br /><br />

**6) Recommendations**<br />
-----------------------------
*Answer to the main business question:*<br />
The analysis shows that operational inefficiencies are mainly driven by route-level service performance, while cost differences are more visible at the truck level rather than between routes.<br />

Across routes, fuel cost per mile and maintenance cost per mile remain relatively consistent, indicating that route choice does not strongly affect transportation cost. However, clear differences in delivery delays and distance deviations reveal operational inefficiencies on specific routes.<br />

At the fleet level, efficiency varies based on the combination of miles driven and cost per mile, highlighting the importance of fleet utilization and operational management.<br /><br />

**Key recommendations**<br />

**Prioritize operational improvements on inefficient routes**<br />
Routes with high delivery delays and distance deviations should be investigated to improve routing, scheduling, and dispatching. The consistent underperformance of Seattle-origin routes suggests regional operational challenges.<br />

**Improve fleet utilization**<br />
Since cost variation appears mainly at the truck level, increasing utilization of trucks currently driving 400k–450k miles annually could improve asset efficiency and reduce the need for additional vehicles.<br />

**Investigate terminal-level performance differences**<br />
Clusters of underperforming trucks at terminals such as Seattle, Portland, and Minneapolis indicate potential differences in operational practices that should be further analyzed.
