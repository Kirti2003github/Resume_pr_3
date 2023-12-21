USE try_project77;

select dist_code,district from dim_districts;

select * from fact_stamps;

---Query 1
select top(5) district,sum(documents_registered_rev) as district_wise_documents_registered_rev from fact_stamps f join dim_districts d on 
f.dist_code=d.dist_code group by district order by sum(documents_registered_rev) desc;

---Query 2
select top(5) district,sum(documents_registered_rev)as district_wise_documents_registered_rev,
sum(estamps_challans_rev) as district_wise_estamps_challans_rev,
sum(estamps_challans_rev)-sum(documents_registered_rev) as diff_document_estamps
from fact_stamps f join dim_districts d on 
f.dist_code=d.dist_code group by district,DATEPART(year,month) having DATEPART(year,month)=2022  order by 
sum(estamps_challans_rev)-sum(documents_registered_rev) desc;


---Query 3
select  month as date,sum(documents_registered_cnt)as district_wise_documents_registered_cnt,
sum(estamps_challans_cnt) as district_wise_estamps_challans_cnt,
sum(estamps_challans_cnt)-sum(documents_registered_cnt) as diff_document_estamps
from fact_stamps group by month 
order by 
month;

/*AS WE CAN SEE FROM THE RESULT of THE ABOVE QUERY THAT FROM DECEMBER 2022 COUNT OS ESTAMPS CHALLANS 
INCREASED GRADUALY EXCEPT FOR MAY 2021 AFTER WHICH IT INCREASED */



---Query 4
/*
if x>=1.247532e+08 and x<6.892411e+08:
        return 'low'
    elif x>=6.892411e+08 and x<2.616787e+09:
        return 'medium'
    elif x>=2.616787e+09:
        return 'high'
*/

---QUERY 4
with cte as(
select district,sum(sum_estamps_challans_rev) as district_sum_2021_2022,case when sum(sum_estamps_challans_rev)>=1.247532e+08
and sum(sum_estamps_challans_rev)<6.892411e+08 then 'low'
when sum(sum_estamps_challans_rev)>=6.892411e+08
and sum(sum_estamps_challans_rev)<2.616787e+09 then 'medium'
when sum(sum_estamps_challans_rev)>=2.616787e+09 then 'high'
end as segments
from(
select district,year(month) as year,sum(estamps_challans_rev) as sum_estamps_challans_rev from fact_stamps f join dim_districts d on 
f.dist_code=d.dist_code where year(month) in (2021,2022)
group by district,year(month)
)x group by district
)
select segments,STRING_AGG(district,'  |  ') as districts from cte group by segments

select DATENAME(MONTH, DATEADD(MONTH, 8 - 1, '19000101'))

---Query 5 
with cte as(
select x.petrol+': '+x.month as petrol,x.diesel+': '+x.month as diesel,y.electric+': '+y.month as electric from (
select DATENAME(MONTH, DATEADD(MONTH, month(month) - 1, '19000101')) as month,
case when rank() over (order by sum(fuel_type_diesel) desc)=1 then 'high_month'
when rank() over (order by sum(fuel_type_diesel) desc)=12 then 'low_month'
else null end
as diesel,
case when rank() over (order by sum(fuel_type_petrol) desc)=1 then 'high_month'
when rank() over (order by sum(fuel_type_petrol) desc)=12 then 'low_month'
else null end
as petrol
from fact_transport 
group by month(month)
)x cross join (
select DATENAME(MONTH, DATEADD(MONTH, month(month) - 1, '19000101')) as month,
case when rank() over (order by sum(fuel_type_electric) desc)=1 then 'high_month' 
when rank() over (order by sum(fuel_type_electric) desc)=12 then 'low_month' 
else null end
as electric
from fact_transport 
group by month(month)
) y
where x.diesel in ('high_month','low_month') or x.petrol in ('high_month','low_month') or y.electric in ('high_month','low_month')
)
select petrol,diesel,electric from cte where (petrol like 'high_month: %' and diesel like 'high_month: %' and electric like 'high_month: %')
or
(petrol like 'low_month: %' and diesel like 'low_month: %' and electric like 'low_month: %');
/*THE ABOVE QUERY DISPLAYs FOR EACH FUEL TYPE CATEGORY THEIR MONTHS DURING WHICH THEY HAVE HIGH AND LOW SALES */

---Query 6
select district,FORMAT(round(sum(vehicleClass_MotorCar)*100.0/(sum(vehicleClass_MotorCar)+sum(vehicleClass_MotorCycle)+sum(vehicleClass_AutoRickshaw)+sum(vehicleClass_Agriculture)),4),'0.##')+'%' as MotorCar,
format(round(sum(vehicleClass_MotorCycle)*100.0/(sum(vehicleClass_MotorCar)+sum(vehicleClass_MotorCycle)+sum(vehicleClass_AutoRickshaw)+sum(vehicleClass_Agriculture)),4),'0.##')+'%' as MotorCycle,
format(round(sum(vehicleClass_AutoRickshaw)*100.0/(sum(vehicleClass_MotorCar)+sum(vehicleClass_MotorCycle)+sum(vehicleClass_AutoRickshaw)+sum(vehicleClass_Agriculture)),4),'0.##')+'%' as AutoRickshaw,
format(round(sum(vehicleClass_Agriculture)*100.0/(sum(vehicleClass_MotorCar)+sum(vehicleClass_MotorCycle)+sum(vehicleClass_AutoRickshaw)+sum(vehicleClass_Agriculture)),4),'0.##')+'%' as Agriculture
from dim_districts d join fact_transport t on d.dist_code=t.dist_code group by district,year(month) having year(month)=2022;

/*THE ABOVE QUERY DISPLAY THE PERCENTAGE DISTRIBUTION OF vehicle class ACROSS DISTRICTS.
EXCEPT FOR Rangareddy AND Sangareddy ALL DISTRICTS HAVE ATLEST 70% VEHICLE TYPE AS MOTOR CYCLE.
SECOND HIGHEST DISTRIBTUION IS OF MOTOR CAR.
SALES OF AGRICULTURE VEHICLE TYPES ARE VERY LESS IN HYDERABAD(0.01),MEDCHAL_MALKAJGIRI(0.13%) AND RANGAREDDY(0.19%).
SALES OF AUTORICKSHAW VEHICLE TYPES ARE VERY LESS IN Jogulamba Gadwal(0.79),MEDCHAL_MALKAJGIRI(0.02%) AND RANGAREDDY(0.02%).
*/



---Query7
with cte_2022 as(
select district,sum(Fuel_type_petrol) as petrol,sum(fuel_type_diesel) as diesel ,sum(fuel_type_electric) as electric
from dim_districts d join fact_transport t
on d.dist_code=t.dist_code
group by district,year(month)
having year(month)=2022
),
cte_2021 as(
select district,sum(Fuel_type_petrol) as petrol,sum(fuel_type_diesel) as diesel ,sum(fuel_type_electric) as electric
from dim_districts d join fact_transport t
on d.dist_code=t.dist_code
group by district,year(month)
having year(month)=2021
),
cte_2021_2022 as(
select cte_2021.district as district,cte_2021.petrol as petrol_2021,cte_2022.petrol as petrol_2022,cte_2022.petrol-cte_2021.petrol as petrol_diff,
rank() over(order by cte_2022.petrol-cte_2021.petrol desc) as petrol_rank,
cte_2021.diesel as diesel_2021,cte_2022.diesel as diesel_2022,cte_2022.diesel-cte_2021.diesel as diesel_diff,
rank() over(order by cte_2022.diesel-cte_2021.diesel desc) as diesel_rank,
cte_2021.electric as electric_2021,cte_2022.electric as electric_2022,cte_2022.electric-cte_2021.electric as electric_diff,
rank() over(order by cte_2022.electric-cte_2021.electric desc) as electric_rank
 from cte_2021 inner join cte_2022 on cte_2021.district=cte_2022.district
 ),
cte_final as (
select case when x.petrol_rank=1 then 'Top1: '+x.district when x.petrol_rank=2 then 'Top2: '+x.district when x.petrol_rank=3 then 'Top3: '+x.district
when x.petrol_rank=28 then 'Bottom3: '+x.district when x.petrol_rank=29 then 'Bottom2: '+x.district when x.petrol_rank=30 then 'Bottom1: '+x.district else null 
end as petrol,
case when x.petrol_diff>0 then 'sales increased' when x.petrol_diff<0 then 'sales decreased' else 'remained same' end petrol_sales_status,

case when y.diesel_rank=1 then 'Top1: '+y.district when y.diesel_rank=2 then 'Top2: '+y.district when y.diesel_rank=3 then 'Top3: '+y.district
when y.diesel_rank=28 then 'Bottom3: '+y.district when y.diesel_rank=29 then 'Bottom2: '+y.district when y.diesel_rank=30 then 'Bottom1: '+y.district else null 
end as diesel,
case when y.diesel_diff>0 then 'sales increased' when y.diesel_diff<0 then 'sales decreased' else 'remained same' end diesel_sales_status,

case when z.electric_rank=1 then 'Top1: '+z.district when z.electric_rank=2 then 'Top2: '+z.district when z.electric_rank=3 then 'Top3: '+z.district
when z.electric_rank=28 then 'Bottom3: '+z.district when z.electric_rank=29 then 'Bottom2: '+z.district when z.electric_rank=30 then 'Bottom1: '+z.district else null 
end as electric,
case when z.electric_diff>0 then 'sales increased' when z.electric_diff<0 then 'sales decreased' else 'remained same' end electric_sales_status

from cte_2021_2022 x cross join cte_2021_2022 y cross join cte_2021_2022 z
where x.petrol_rank in (1,2,3,28,29,30) or y.diesel_rank in (1,2,3,28,29,30) or z.electric_rank in (1,2,3,28,29,30)
)
select * from cte_final where (petrol like 'Top1: %' and diesel like 'Top1: %' and electric like 'Top1: %')
or
(petrol like 'Top2: %' and diesel like 'Top2: %' and electric like 'Top2: %')
or
(petrol like 'Top3: %' and diesel like 'Top3: %' and electric like 'Top3: %')
or
(petrol like 'Bottom1: %' and diesel like 'Bottom1: %' and electric like 'Bottom1: %')
or
(petrol like 'Bottom2: %' and diesel like 'Bottom2: %' and electric like 'Bottom2: %')
or
(petrol like 'Bottom3: %' and diesel like 'Bottom3: %' and electric like 'Bottom3: %')
order by petrol 
;

/*The above query  displays the top 3 and bottom 3 districts   that have shown the highest 
and lowest vehicle sales growth during FY 2022 compared to FY 
2021. it also displays whether the sales increased or decresed with respect to 2021 in 2022*/

---Query 8
select top(5) sector,sum(investment_in_cr) as investment_in_cr  from fact_TS_iPASS group by sector,year(month) having year(month)=2022
order by sum(investment_in_cr) desc;


---Query 9
select top(3) district,sum(investment_in_cr) as investment_in_cr from fact_TS_iPASS t join dim_districts d on t.dist_code=d.dist_code
group by district order by sum(investment_in_cr) desc;

---Q10 is a graphical question and in solved in jupyter notebook and bower bi


---Query 11
with cte as(
select district,sector,sum(investment_in_cr) as investment_in_cr,rank() over(partition by district order by sum(investment_in_cr) desc) as rnk from(
select district,sector,year(month) as year,sum(investment_in_cr) as investment_in_cr from fact_TS_iPASS t join dim_districts d on t.dist_code=d.dist_code
group by district,sector,year(month) having year(month) in (2021,2022) 
)x group by district,sector
),
cte2 as(
select district,sector from cte where rnk in (1,2,3,4,5)
)
select district,STRING_AGG(sector,'   ||   ') as top_sectors_having_significant_impact from cte2 group by district;


---QUERY 12
with cte as(
select sector,month from(
select sector,DATENAME(MONTH, DATEADD(MONTH, day(month) - 1, '19000101')) as month,
rank() over(partition by sector order by sum(investment_in_cr) desc) as rnk, 
sum(investment_in_cr) as investment_in_cr from fact_TS_iPASS group by sector,DATENAME(MONTH, DATEADD(MONTH, day(month) - 1, '19000101'))
)x where rnk in (1,2,3)
)
select sector,STRING_AGG(month,'  ||  ') as high_investment_month from cte group by sector

--Query 13
select district,sum(investment_in_cr) as investment_in_commercial_properties from fact_TS_iPASS join dim_districts on fact_TS_iPASS.dist_code=dim_districts.dist_code
group by sector,district having sector='Real Estate,Industrial Parks and IT Buildings' order by sum(investment_in_cr) desc;  
