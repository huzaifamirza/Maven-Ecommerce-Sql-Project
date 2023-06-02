use mavenfuzzyfactory;

# Site Traffic Breakdown

SELECT 
    utm_source, utm_campaign, http_referer, COUNT(*) AS sessions
FROM
    website_sessions
WHERE
    created_at < '2012-04-12'
GROUP BY 1 , 2 , 3
ORDER BY 4 DESC;

# gsearch conversion rate
SELECT 
    COUNT(distinct w.website_session_id) AS sessions,
    COUNT(distinct o.order_id) AS orders,
    (COUNT(distinct o.order_id) / COUNT(distinct w.website_session_id))*100 AS cvr
FROM
    website_sessions w
        LEFT JOIN
    orders o ON w.website_session_id = o.website_session_id
WHERE
    w.created_at < '2012-04-12'
        AND w.utm_source = 'gsearch'
        AND w.utm_campaign = 'nonbrand';

# gsearch volumes trend by week
SELECT 
    MIN(DATE(created_at)) AS week_start,
    COUNT(DISTINCT website_session_id)
FROM
    website_sessions
WHERE
    created_at < '2012-05-12'
        AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
GROUP BY YEAR(created_at) , WEEK(created_at);


# gsearch device level performance
SELECT 
w.device_type,
    COUNT(distinct w.website_session_id) AS sessions,
    COUNT(distinct o.order_id) AS orders,
    (COUNT(distinct o.order_id) / COUNT(distinct w.website_session_id))*100 AS cvr
FROM
    website_sessions w
        LEFT JOIN
    orders o ON w.website_session_id = o.website_session_id
WHERE
    w.created_at < '2012-05-11'
        AND w.utm_source = 'gsearch'
        AND w.utm_campaign = 'nonbrand'
group by 1;

# gsearch device level trends
SELECT 
    MIN(DATE(created_at)) AS week_start,
    COUNT(DISTINCT CASE
            WHEN device_type = 'desktop' THEN website_session_id
            ELSE NULL
        END) AS dtop_sessions,
    COUNT(DISTINCT CASE
            WHEN device_type = 'mobile' THEN website_session_id
            ELSE NULL
        END) AS mob_sessions
FROM
    website_sessions
WHERE
    created_at BETWEEN '2012-04-15' AND '2012-06-09'
        AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
GROUP BY YEAR(created_at) , WEEK(created_at);


# Top Website Pages

SELECT 
    pageview_url, COUNT(DISTINCT website_pageview_id) AS pvs
FROM
    website_pageviews
WHERE
    created_at < '2012-06-09'
GROUP BY 1
order by 2 desc;

# Top entry pages
SELECT 
    w.pageview_url, COUNT(DISTINCT f.first_page)
FROM
    f_p f
        LEFT JOIN
    website_pageviews w ON w.website_pageview_id = f.first_page
GROUP BY 1;


# Bounce Rate Analysis

# Step 1: finding the first website_pageview_id for relevant sessions

create temporary table first_pageview
select website_session_id, min(website_pageview_id) as first_page
from website_pageviews
where created_at < '2012-06-14'
group by 1;
select * from first_pageview;

# Step 2: identifying the landing page of each session 
create temporary table L_P
SELECT 
    f.website_session_id, w.pageview_url as landing_page_session
FROM
    first_pageview f
        LEFT JOIN
    website_pageviews w ON w.website_pageview_id = f.first_page
;
select * from L_P;


# Step 3: counting pageview for each session to identify bounces 
create temporary table boun
select l.website_session_id, l.landing_page_session,
count(w.website_pageview_id) as bounces 
from L_P l 
left join website_pageviews w 
on l.website_session_id = w.website_session_id
group by 1,2
having count(w.website_pageview_id) = 1 ;

SELECT 
    *
FROM
    boun;

# Step 4: 
SELECT 
    COUNT(DISTINCT f.website_session_id) AS total_visits,
    COUNT(DISTINCT b.website_session_id) AS bounces,
    (COUNT(DISTINCT b.website_session_id) / COUNT(DISTINCT f.website_session_id)) * 100 AS bounce_rate
FROM
    L_P f
        LEFT JOIN
    boun b ON f.website_session_id = b.website_session_id
;

# A/B Testing 
select 
min(website_pageview_id) as firstpageview_id,
min(created_at) as firstdate
from website_pageviews
where pageview_url = '/lander-1'
and created_at is not null;

# step 1
create temporary table first_test_pageviews
select w.website_session_id, min(w.website_pageview_id) as min_pageview_id
from website_pageviews w 
join website_sessions s 
on w.website_session_id = s.website_session_id
where s.created_at < '2012-07-28'
and w.website_pageview_id > 23504
and s.utm_source = 'gsearch'
and s.utm_campaign = 'nonbrand'
group by 1;
select * from first_test_pageviews;

# step 2
create temporary table landing_page_table
select f.website_session_id ,
w.pageview_url as landing_page
from first_test_pageviews f
left join website_pageviews w 
on w.website_pageview_id  = f.min_pageview_id
where w.pageview_url in ('/home','/lander-1');

# step 3
create temporary table bounce 
select l.website_session_id, l.landing_page,
count(w.website_pageview_id) as bounces 
from landing_page_table l 
left join website_pageviews w 
on l.website_session_id = w.website_session_id
group by 1,2
having count(w.website_pageview_id) = 1 ;
select * from bounce;

# step 4
select l.landing_page,
count(distinct l.website_session_id) as sessions,
count(distinct w.website_session_id) as bounce_sessions,
count(distinct w.website_session_id) / count(distinct l.website_session_id) as bounce_rate
from landing_page_table l 
left join bounce w 
on w.website_session_id = l.website_session_id 
group by 1;

# landing page analysis 
# step 1
create temporary table first_pv
select w.website_session_id, min(p.website_pageview_id) as first_page , count(p.website_pageview_id) as count_pv
from website_pageviews p 
left join website_sessions w
on w.website_session_id = p.website_session_id
where w.created_at > '2012-06-01'
and w.created_at < '2012-08-31'
and w.utm_source = 'gsearch'
and w.utm_campaign = 'nonbrand'
group by 1;

select * from first_pv;

#  step 2
create temporary table pv2
select w.website_session_id, w.first_page, w.count_pv, p.pageview_url, p.created_at
from first_pv w 
left join website_pageviews p 
on p.website_pageview_id = w.first_page;
select * from pv2;

# step 3
select 
yearweek(created_at) as year_week,
min(date(created_at)) as start_of_week,
count(distinct website_session_id) as total_sessions,
count(distinct case when count_pv = 1 then website_session_id else null end) as bounce,
count(distinct case when count_pv = 1 then website_session_id else null end)*1.0/ count(distinct website_session_id) as bounce_rate,
count(distinct case when pageview_url = '/home' then website_session_id else null end) as home_sessions,
count(distinct case when pageview_url = '/lander-1' then website_session_id else null end) as lander_session 
from pv2 
group by 1;

# help Analyzing conversion funnel
# step 1
SELECT 
    w.website_session_id,
    p.pageview_url,
    CASE
        WHEN p.pageview_url = '/products' THEN 1
        ELSE 0
    END AS products_page,
    CASE
        WHEN p.pageview_url = '/the-original-mr-fuzzy' THEN 1
        ELSE 0
    END AS mrfuzzy_page,
    CASE
        WHEN p.pageview_url = '/cart' THEN 1
        ELSE 0
    END AS cart_page,
    CASE
        WHEN p.pageview_url = '/shipping' THEN 1
        ELSE 0
    END AS shipping_page,
    CASE
        WHEN p.pageview_url = '/billing' THEN 1
        ELSE 0
    END AS billing_page,
    CASE
        WHEN p.pageview_url = '/thank-you-for-your-order' THEN 1
        ELSE 0
    END AS thankyou_page
FROM
    website_sessions w
        LEFT JOIN
    website_pageviews p ON w.website_session_id = p.website_session_id
WHERE
    w.created_at BETWEEN '2012-08-05' AND '2012-09-05'
        AND w.utm_source = 'gsearch'
        AND w.utm_campaign = 'nonbrand'
ORDER BY w.website_session_id , w.created_at;

# step 2

select website_session_id,
max(products_page) as product_made_it,
max(mrfuzzy_page) as fuzzy_made_it,
max(cart_page) as cart_made_it,
max(shipping_page) as shipping_made_it,
max(billing_page) as billing_made_it,
max(thankyou_page) as thank_made_it
from(
SELECT 
    w.website_session_id,
    p.pageview_url,
    CASE
        WHEN p.pageview_url = '/products' THEN 1
        ELSE 0
    END AS products_page,
    CASE
        WHEN p.pageview_url = '/the-original-mr-fuzzy' THEN 1
        ELSE 0
    END AS mrfuzzy_page,
    CASE
        WHEN p.pageview_url = '/cart' THEN 1
        ELSE 0
    END AS cart_page,
    CASE
        WHEN p.pageview_url = '/shipping' THEN 1
        ELSE 0
    END AS shipping_page,
    CASE
        WHEN p.pageview_url = '/billing' THEN 1
        ELSE 0
    END AS billing_page,
    CASE
        WHEN p.pageview_url = '/thank-you-for-your-order' THEN 1
        ELSE 0
    END AS thankyou_page
FROM
    website_sessions w
        LEFT JOIN
    website_pageviews p ON w.website_session_id = p.website_session_id
WHERE
    w.created_at BETWEEN '2012-08-05' AND '2012-09-05'
        AND w.utm_source = 'gsearch'
        AND w.utm_campaign = 'nonbrand'
ORDER BY w.website_session_id , w.created_at
) as pageview_level
group by 1;

# 3 step
select count(distinct website_session_id) as sessions,
count(distinct case when product_made_it = 1 then website_session_id else null end) as to_products,
count(distinct case when fuzzy_made_it = 1 then website_session_id else null end) as to_fuzzy,
count(distinct case when cart_made_it = 1 then website_session_id else null end) as to_cart,
count(distinct case when shipping_made_it = 1 then website_session_id else null end) as to_ship,
count(distinct case when billing_made_it = 1 then website_session_id else null end) as to_billings,
count(distinct case when thank_made_it = 1 then website_session_id else null end) as to_thanks
from pv;


# step 4
SELECT 
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE
            WHEN product_made_it = 1 THEN website_session_id
            ELSE NULL
        END) / COUNT(DISTINCT website_session_id) AS to_products,
    COUNT(DISTINCT CASE
            WHEN fuzzy_made_it = 1 THEN website_session_id
            ELSE NULL
        END) / COUNT(DISTINCT CASE
            WHEN product_made_it = 1 THEN website_session_id
            ELSE NULL
        END) AS to_fuzzy,
    COUNT(DISTINCT CASE
            WHEN cart_made_it = 1 THEN website_session_id
            ELSE NULL
        END) / COUNT(DISTINCT CASE
            WHEN fuzzy_made_it = 1 THEN website_session_id
            ELSE NULL
        END) AS to_cart,
    COUNT(DISTINCT CASE
            WHEN shipping_made_it = 1 THEN website_session_id
            ELSE NULL
        END) / COUNT(DISTINCT CASE
            WHEN cart_made_it = 1 THEN website_session_id
            ELSE NULL
        END) AS to_ship,
    COUNT(DISTINCT CASE
            WHEN billing_made_it = 1 THEN website_session_id
            ELSE NULL
        END) / COUNT(DISTINCT CASE
            WHEN shipping_made_it = 1 THEN website_session_id
            ELSE NULL
        END) AS to_billings,
    COUNT(DISTINCT CASE
            WHEN thank_made_it = 1 THEN website_session_id
            ELSE NULL
        END) / COUNT(DISTINCT CASE
            WHEN billing_made_it = 1 THEN website_session_id
            ELSE NULL
        END) AS to_thanks
FROM
    pv;
    
# cnversion funnel trends 
# step 1
create temporary table first_pv
select w.website_session_id, min(p.website_pageview_id) as first_page , count(p.website_pageview_id) as count_pv
from website_pageviews p 
left join website_sessions w
on w.website_session_id = p.website_session_id
where w.created_at > '2012-06-01'
and w.created_at < '2012-08-31'
and w.utm_source = 'gsearch'
and w.utm_campaign = 'nonbrand'
group by 1;

select * from first_pv;

#  step 2
create temporary table pv2
select w.website_session_id, w.first_page, w.count_pv, p.pageview_url, p.created_at
from first_pv w 
left join website_pageviews p 
on p.website_pageview_id = w.first_page;
select * from pv2;

# step 3
select 
yearweek(created_at) as year_week,
min(date(created_at)) as start_of_week,
count(distinct website_session_id) as total_sessions,
count(distinct case when count_pv = 1 then website_session_id else null end) as bounce,
count(distinct case when count_pv = 1 then website_session_id else null end)*1.0/ count(distinct website_session_id) as bounce_rate,
count(distinct case when pageview_url = '/home' then website_session_id else null end) as home_sessions,
count(distinct case when pageview_url = '/lander-1' then website_session_id else null end) as lander_session 
from pv2 
group by 1;



# conversion funnel test
# step 1
select 
min(website_pageview_id) as firstpageview_id,
min(created_at) as firstdate
from website_pageviews
where pageview_url = '/billing-2'
and created_at is not null;

# step 2
create temporary table cf
select w.website_session_id, w.pageview_url,o.order_id
from website_pageviews w 
left join orders o 
on w.website_session_id = o.website_session_id
where w.website_pageview_id >= 53550
and w.created_at < '2012-11-10'
and w.pageview_url in ('/billing','/billing-2');
select * from cf;
# step 3
select pageview_url,
count(distinct website_session_id) as sessions,
count(distinct order_id) as orders,
count(distinct order_id)/count(distinct website_session_id) as conversion 
from cf 
group by 1;

# Mid project
# Q 1
select year(w.created_at) as yr, month(w.created_at) as months, count(distinct w.website_session_id) as sessions, count(distinct o.order_id) as orders from website_sessions w
left join orders o 
on w.website_session_id = o.website_session_id
where w.utm_source = 'gsearch' and w.created_at < '2012-11-27'
group by 1 , 2
order by 1;
    
# Q 2
SELECT 
    MONTH(w.created_at) AS months,
    w.utm_campaign,
    COUNT(distinct w.website_session_id) AS sessions,
    COUNT(distinct o.order_id) AS orders,
    (COUNT(distinct o.order_id) / COUNT(distinct w.website_session_id)) AS conv
FROM
    website_sessions w
        LEFT JOIN
    orders o ON w.website_session_id = o.website_session_id
WHERE
    w.utm_source = 'gsearch' and w.created_at < '2012-11-27'
GROUP BY 1 , w.utm_campaign
ORDER BY 1;


# Q 3
SELECT 
    MONTH(w.created_at) AS months,
    w.device_type,
    COUNT(distinct w.website_session_id) AS sessions,
    COUNT(distinct o.order_id) AS orders,
    (COUNT(distinct o.order_id) / COUNT(distinct w.website_session_id)) AS conv
FROM
    website_sessions w
        LEFT JOIN
    orders o ON w.website_session_id = o.website_session_id
WHERE
    utm_source = 'gsearch' and w.utm_campaign = 'nonbrand' and w.created_at < '2012-11-27'
GROUP BY 1 , w.device_type
ORDER BY 1;


# Q 4
SELECT 
    MONTH(w.created_at) AS months,
    COUNT(DISTINCT CASE
            WHEN utm_source = 'gsearch' THEN w.website_session_id
            ELSE NULL
        END) AS sear,
    COUNT(DISTINCT CASE
            WHEN utm_source = 'bsearch' THEN w.website_session_id
            ELSE NULL
        END) AS bsear,
    COUNT(DISTINCT CASE
            WHEN
                utm_source IS NULL
                    AND http_referer IS NOT NULL
            THEN
                w.website_session_id
            ELSE NULL
        END) AS oranic,
    COUNT(DISTINCT CASE
            WHEN
                utm_source IS NULL
                    AND http_referer IS NULL
            THEN
                w.website_session_id
            ELSE NULL
        END) AS direct
FROM
    website_sessions w
        LEFT JOIN
    orders o ON o.website_session_id = w.website_session_id
WHERE
    w.created_at < '2012-11-27'
GROUP BY 1;
    
# Q 5 
SELECT 
    MONTH(w.created_at) AS months,
    COUNT(DISTINCT w.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT o.order_id) / COUNT(DISTINCT w.website_session_id) AS conv
FROM
    website_sessions w
        LEFT JOIN
    orders o ON o.website_session_id = w.website_session_id
WHERE
    w.created_at < '2012-11-27'
GROUP BY 1;
    
# Q 6
create temporary table first_test_pageview
select w.website_session_id, min(w.website_pageview_id) as min_pageview_id 
from website_pageviews w 
join website_sessions s 
on w.website_session_id = s.website_session_id 
where s.created_at < '2012-07-28'
and w.website_pageview_id >= 23504
and s.utm_source = 'gsearch'
and s.utm_campaign = 'nonbrand'
group by 1 ;


create temporary table test_session_land
select f.website_session_id, w.pageview_url as landing_page 
from first_test_pageview f 
left join website_pageviews w 
on f.min_pageview_id  = w.website_pageview_id
where w.pageview_url in ('/home','/lander-1');

create temporary table order_include
select t.website_session_id, t.landing_page, o.order_id  as order_id
from test_session_land t 
left join orders o 
on t.website_session_id = o.website_session_id;

select * from order_include;

select landing_page, count(distinct website_session_id) as sessions, count(distinct order_id) as orders,
count(distinct order_id)/count(distinct website_session_id) as conv 
from order_include 
group by 1;

select max(w.website_session_id) as max_id 
from website_sessions w
left join website_pageviews p 
on w.website_session_id = p.website_session_id 
where utm_source = 'gsearch'
and utm_campaign = 'nonbrand'
and pageview_url = '/home'
and w.created_at < '2012-11-27';

select count(website_session_id) as session 
from website_sessions 
where created_at < '2012-11-27'
and website_session_id > 17145 
and utm_source = 'gsearch'
and utm_campaign = 'nonbrand';


# Q 7
create temporary table session_level
select 
website_session_id,
max(homepage) as saw_homepage,
max(custom_lander) as saw_custom_lander,
max(products_page) as product_made_it,
max(mrfuzzy_page) as mrfuzzy_made_it,
max(cart_page) as cart_made_it,
max(shipping_page) as shipping_made_it,
max(billing_page) as billing_made_it,
max(thankyou_page) as thankyou_made_it
from(
select w.website_session_id,
p.pageview_url,
case when pageview_url = '/home' then 1 else 0 end as homepage,
case when pageview_url = '/lander-1' then 1 else 0 end as custom_lander,
case when pageview_url = '/products' then 1 else 0 end as products_page,
case when pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end as mrfuzzy_page,
case when pageview_url = '/cart' then 1 else 0 end as cart_page,
case when pageview_url = '/shipping' then 1 else 0 end as shipping_page,
case when pageview_url = '/billing' then 1 else 0 end as billing_page,
case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from website_sessions w 
 LEFT JOIN
    website_pageviews p ON w.website_session_id = p.website_session_id
    where w.utm_source = 'gsearch'
        AND w.utm_campaign = 'nonbrand'
        and w.created_at < '2012-07-28'
        and w.created_at > '2012-06-19' 
    order by w.website_session_id , w.created_at    

) as pageview_level
group by 1;


select case when saw_homepage = 1 then 'saw_homepage'
when saw_custom_lander = 1 then 'saw_custom_lander'
else 'check logic' end as segments,
count(distinct website_session_id) as sessions,
count(distinct case when product_made_it = 1 then website_session_id else null end) as to_products,
count(distinct case when mrfuzzy_made_it = 1 then website_session_id else null end) as to_fuzzy,
count(distinct case when cart_made_it = 1 then website_session_id else null end) as to_cart,
count(distinct case when shipping_made_it = 1 then website_session_id else null end) as to_ship,
count(distinct case when billing_made_it = 1 then website_session_id else null end) as to_billings,
count(distinct case when thankyou_made_it = 1 then website_session_id else null end) as to_thanks
from session_level
group by 1 ;

select case when saw_homepage = 1 then 'saw_homepage'
when saw_custom_lander = 1 then 'saw_custom_lander'
else 'check logic' end as segments,
count(distinct website_session_id) as sessions,
count(distinct case when product_made_it = 1 then website_session_id else null end) / count(distinct website_session_id) as to_products_click_rate,
count(distinct case when mrfuzzy_made_it = 1 then website_session_id else null end) / count(distinct case when product_made_it = 1 then website_session_id else null end) as to_fuzzy_click_rate,
count(distinct case when cart_made_it = 1 then website_session_id else null end) / count(distinct case when mrfuzzy_made_it = 1 then website_session_id else null end) as to_cart_click_rate,
count(distinct case when shipping_made_it = 1 then website_session_id else null end) / count(distinct case when cart_made_it = 1 then website_session_id else null end)  as to_ship_click_rates,
count(distinct case when billing_made_it = 1 then website_session_id else null end) / count(distinct case when shipping_made_it = 1 then website_session_id else null end) as to_billings_click_rates,
count(distinct case when thankyou_made_it = 1 then website_session_id else null end) / count(distinct case when billing_made_it = 1 then website_session_id else null end)  as to_thanks_click_rates
from session_level
group by 1 ;


# Q8 
SELECT 
    billing_version_seen,
    COUNT(DISTINCT website_session_id) AS sessions,
    SUM(price_usd) / COUNT(DISTINCT website_session_id) AS revenue_per_click
FROM
    (SELECT 
        w.website_session_id,
            w.pageview_url AS billing_version_seen,
            o.order_id,
            o.price_usd
    FROM
        website_pageviews w
    LEFT JOIN orders o ON o.website_session_id = w.website_session_id
    WHERE
        w.created_at > '2012-09-10'
            AND w.created_at < '2012-11-10'
            AND w.pageview_url IN ('/billing' , '/billing-2')) AS viewss
GROUP BY 1;


# Expended chanel protfolio
SELECT 
    MIN(DATE(created_at)) AS week_start,
    COUNT(DISTINCT case when utm_source = 'gsearch' then website_session_id else null end) as gsearch_sessions,
    COUNT(DISTINCT case when utm_source = 'bsearch' then website_session_id else null end) as bsearch_sessions
FROM
    website_sessions
WHERE
    created_at between '2012-8-22' and '2012-11-29'
        
        AND utm_campaign = 'nonbrand'
GROUP BY YEAR(created_at) , WEEK(created_at);

# Comparing our channels
select utm_source, count(distinct website_session_id) as sessions,
count(case when device_type = 'mobile' then website_session_id else null end) as mobile_sessions ,
count(case when device_type = 'mobile' then website_session_id else null end) / count(distinct website_session_id) as conv 
from website_sessions 
where created_at  between '2012-8-22' and '2012-11-30'
and utm_source in ('gsearch','bsearch')
and utm_campaign = 'nonbrand'
group by 1;

# Multi channnel bidings
select w.device_type, w.utm_source, count(distinct w.website_session_id) as sessions, count(distinct o.order_id) as orders,
count(distinct o.order_id) / count(distinct w.website_session_id) as conv 
from website_sessions w 
left join orders o 
on w.website_session_id = o.website_session_id
where w.created_at  between '2012-8-22' and '2012-9-19'
and w.utm_source in ('gsearch','bsearch')
and w.utm_campaign = 'nonbrand'
group by 1,2;

# impact of bid changes
select  MIN(DATE(created_at)) AS week_start,
COUNT(DISTINCT case when utm_source = 'gsearch' and device_type = 'desktop' then website_session_id else null end) as d_gsearch_sessions,
COUNT(DISTINCT case when utm_source = 'bsearch' and device_type = 'desktop' then website_session_id else null end) as d_bsearch_sessions,
COUNT(DISTINCT case when utm_source = 'bsearch' and device_type = 'desktop' then website_session_id else null end)/COUNT(DISTINCT case when utm_source = 'gsearch' and device_type = 'desktop' then website_session_id else null end) as d_conv,
COUNT(DISTINCT case when utm_source = 'gsearch' and device_type = 'mobile' then website_session_id else null end) as m_gsearch_sessions,
COUNT(DISTINCT case when utm_source = 'bsearch' and device_type = 'mobile' then website_session_id else null end) as m_bsearch_sessions,
COUNT(DISTINCT case when utm_source = 'bsearch' and device_type = 'mobile' then website_session_id else null end) / COUNT(DISTINCT case when utm_source = 'gsearch' and device_type = 'mobile' then website_session_id else null end) as m_conv
from website_sessions 
where created_at  between '2012-11-4' and '2012-12-22'
and utm_source in ('gsearch','bsearch')
and utm_campaign = 'nonbrand'
group by yearweek(created_at);

# Understanding seasonality
Select year(w.created_at), month(w.created_at),
count(distinct w.website_session_id) as sessions,
count(distinct o.order_id) as orders
from website_sessions w 
left join orders o 
on o.website_session_id = w.website_session_id 
where w.created_at <= '2012-12-31'
group by 1,2
order by 2;


Select week(w.created_at), min(date(w.created_at)),
count(distinct w.website_session_id) as sessions,
count(distinct o.order_id) as orders
from website_sessions w 
left join orders o 
on o.website_session_id = w.website_session_id 
where w.created_at <= '2012-12-31'
group by 1
order by 1;


# Data for Customer Service 
select hr,
avg(website_session) as sessions,
avg(case when wk = 0 then website_session else null end ) as mon,
avg(case when wk = 1 then website_session else null end ) as tues,
avg(case when wk = 2 then website_session else null end ) as wed,
avg(case when wk = 3 then website_session else null end ) as turs,
avg(case when wk = 4 then website_session else null end ) as fri,
avg(case when wk = 5 then website_session else null end ) as sat,
avg(case when wk = 6 then website_session else null end ) as sun
from(
select date(created_at), weekday(created_at) as wk, hour(created_at) as hr, count(distinct website_session_id) as website_session
from website_sessions 
where created_at between '2012-9-15' and '2012-11-15'
group by 1,2,3
) as  daily_sessions
group by 1
order by 1;

# Sales Trends
select year(created_at) as yr, month(created_at) as mon, count(order_id), sum(price_usd) as revenue, sum(price_usd-cogs_usd) as mar
from orders
where created_at < '2013-01-04'
group by 1,2;

# impact of new product lanuch
select year(w.created_at) as yr , month(w.created_at) as mon, 
count(distinct w.website_session_id) as sessions,
count(distinct o.order_id) as orders,
count(distinct o.order_id)/count(distinct w.website_session_id) as conv,
sum(o.price_usd)/count(distinct w.website_session_id) as rev_per_session,
count(distinct case when o.primary_product_id = 1 then order_id else null end) as product_one_order,
count(distinct case when o.primary_product_id = 2 then order_id else null end) as product_two_order
from 
website_sessions w 
left join orders o 
on o.website_session_id = w.website_session_id 
where w.created_at < '2013-4-5'
and w.created_at > '2012-4-1'
group by 1,2;

# help w user pathing
create temporary table pp
select website_session_id, website_pageview_id, created_at,
case when created_at < '2013-01-06' then 'A. Pre_product_2'
when created_at >= '2013-01-06' then 'B. Post_product_2'
else 'ceck loic' end as time_period
from website_pageviews
where created_at < '2013-4-6' and created_at > '2012-10-6' and pageview_url = '/products';

select * from pp;

create temporary table session_next
select p.time_period, p.website_session_id,min(w.website_pageview_id) as min_p_id
from pp p
left join website_pageviews w 
on w.website_session_id = p.website_session_id
and w.website_pageview_id > p.website_pageview_id 
group by 1,2;

create temporary table session_url
select s.time_period, s.website_session_id, w.pageview_url as next_pageview_url
from session_next s 
left join website_pageviews w 
on w.website_pageview_id = s.min_p_id;


select time_period,
count(distinct website_session_id) as sessions,
count(distinct case when next_pageview_url is not null then website_session_id else null end) as w_next_p,
count(distinct case when next_pageview_url is not null then website_session_id else null end) / count(distinct website_session_id) as pct_w_next,
count(distinct case when next_pageview_url = '/the-original-mr-fuzzy' then website_session_id else null end) as to_mrfuzzy,
count(distinct case when next_pageview_url = '/the-original-mr-fuzzy' then website_session_id else null end)/count(distinct website_session_id) as pct_to_mrfuzzy,
count(distinct case when next_pageview_url = '/the-forever-love-bear' then website_session_id else null end) as bear_love,
count(distinct case when next_pageview_url = '/the-forever-love-bear' then website_session_id else null end)/count(distinct website_session_id) as pct_bear_love 
from session_url
group by 1;


# cross sales

create temporary table session_cart
select 
case when created_at < '2013-09-05' then 'A. Pre_cross_sales_2'
when created_at >= '2013-01-06' then 'B. Post_cross_sales_2'
else 'ceck loic' end as time_period,website_session_id, website_pageview_id
from website_pageviews
where created_at between '2013-8-25' and '2013-10-25' and pageview_url = '/cart';


create temporary table session_nt
select p.time_period, p.website_session_id,min(w.website_pageview_id) as min_p_id
from session_cart p
left join website_pageviews w 
on w.website_session_id = p.website_session_id
and w.website_pageview_id > p.website_pageview_id 
group by 1,2
having min(w.website_pageview_id) is not null;
select * from session_nt;


create temporary table ses
select s.time_period, s.website_session_id, o.order_id, o.items_purchased, o.price_usd
from session_cart s  join orders o 
on s.website_session_id = o.website_session_id;

select 
s.time_period,
s.website_session_id,
case when se.website_session_id is null then 0 else 1 end as click_to_anoter_page,
case when pre.order_id is null then 0 else 1 end as placed_order,
pre.items_purchased,pre.price_usd from session_cart s 
left join session_nt se 
on s.website_session_id = se.website_session_id 
left join ses pre 
on se.website_session_id = pre.website_session_id  
order by 2;


select 
time_period,
count(distinct website_session_id) as cart_sessions,
sum(click_to_anoter_page) as ctr,
sum(placed_order) as cart_ctr,
sum(items_purchased)/sum(placed_order) as ppo,
sum(price_usd)/sum(placed_order) as aov,
sum(price_usd)/count(distinct website_session_id) as rev_per_cart_session
from(
select 
s.time_period,
s.website_session_id,
case when se.website_session_id is null then 0 else 1 end as click_to_anoter_page,
case when pre.order_id is null then 0 else 1 end as placed_order,
pre.items_purchased,pre.price_usd from session_cart s 
left join session_nt se 
on s.website_session_id = se.website_session_id 
left join ses pre 
on se.website_session_id = pre.website_session_id  
order by 2
) as full_data
group by 1;



select 
case when w.created_at < '2013-12-12' then 'A. Pre_cross_sales_2'
when w.created_at >= '2013-12-12' then 'B. Post_cross_sales_2'
else 'ceck loic' end as time_period,
count(distinct w.website_session_id) as sessions,
count(distinct o.order_id) as orders,
count(distinct o.order_id)/count(distinct w.website_session_id) as conv,
sum(o.price_usd) as total_rev,
sum(o.items_purchased) as total_products_sold,
sum(o.price_usd)/count(distinct o.order_id) as av_order_value,
sum(o.items_purchased)/count(distinct o.order_id) as product_per_order,
sum(o.price_usd)/count(distinct w.website_session_id) as revenue_per_session
from website_sessions w 
left join orders o 
on o.website_session_id = w.website_session_id
where w.created_at between '2013-11-12' and '2014-01-12'
group by 1;



SELECT 
    YEAR(o.created_at) AS yr,
    MONTH(o.created_at) AS mon,
    COUNT(DISTINCT CASE
            WHEN o.product_id = 1 THEN o.order_item_id
            ELSE NULL
        END) AS P1_orders,
    COUNT(DISTINCT CASE
            WHEN o.product_id = 1 THEN r.order_item_id
            ELSE NULL
        END) / COUNT(DISTINCT CASE
            WHEN o.product_id = 1 THEN o.order_item_id
            ELSE NULL
        END) AS P1_rt,
    COUNT(DISTINCT CASE
            WHEN o.product_id = 2 THEN o.order_item_id
            ELSE NULL
        END) AS P2_orders,
    COUNT(DISTINCT CASE
            WHEN o.product_id = 2 THEN r.order_item_id
            ELSE NULL
        END) / COUNT(DISTINCT CASE
            WHEN o.product_id = 2 THEN o.order_item_id
            ELSE NULL
        END) AS P2_rt,
    COUNT(DISTINCT CASE
            WHEN o.product_id = 3 THEN o.order_item_id
            ELSE NULL
        END) AS P3_orders,
    COUNT(DISTINCT CASE
            WHEN o.product_id = 3 THEN r.order_item_id
            ELSE NULL
        END) / COUNT(DISTINCT CASE
            WHEN o.product_id = 3 THEN o.order_item_id
            ELSE NULL
        END) AS P3_rt
FROM
    order_items o
        LEFT JOIN
    order_item_refunds r ON o.order_item_id = r.order_item_id
WHERE
    o.created_at < '2014-10-15'
GROUP BY 1 , 2;


# Repeated Sessions
create temporary table sessions
select new_sessions.user_id, new_sessions.website_session_id as new_session_id ,w.website_session_id as repeat_session_id
from
(select user_id, website_session_id
from website_sessions 
where created_at < '2014-11-01' and created_at >= '2014-1-1'
and is_repeat_session = 0 ) as new_sessions
left join website_sessions w 
on w.user_id = new_sessions.user_id 
and w.is_repeat_session = 1 
and w.website_session_id > new_sessions.website_session_id
and w.created_at < '2014-11-01' and w.created_at >= '2014-1-1';

select * from sessions;

select repeat_session, 
count(distinct user_id) as users
from(
select user_id,
count(distinct new_session_id) as new_sessions,
count(distinct repeat_session_id) as repeat_session
from sessions 
group by 1
order by 3 ) as user_level
group by 1;


# sessions_dates
create temporary table ses
select new_sessions.user_id, new_sessions.website_session_id as new_session_id,new_sessions.created_at as first_session ,w.website_session_id as repeat_session_id, w.created_at as second_session
from
(select user_id, website_session_id, created_at
from website_sessions 
where created_at < '2014-11-01' and created_at >= '2014-1-1'
and is_repeat_session = 0 ) as new_sessions
left join website_sessions w 
on w.user_id = new_sessions.user_id 
and w.is_repeat_session = 1 
and w.website_session_id > new_sessions.website_session_id
and w.created_at < '2014-11-01' and w.created_at >= '2014-1-1';


create temporary table diff
select user_id, datediff(repeat_session_date,first_session) as diff 
from(
select user_id,
new_session_id,
first_session,
min(repeat_session_id) as sec_session_id,
min(second_session) as repeat_session_date
from ses 
where repeat_session_id is not null 
group by 1,2,3) as session_level
group by 1;


select avg(diff) as avg_diff, max(diff) as max_diff, min(diff) as min_diff
from diff;


# direct customers vs brand  or nonbrand 
select 
case when utm_source is null and http_referer in ('https://www.gsearch,com','https://www.bsearch,com') then 'organic_search'
when utm_campaign = 'nonbrand' then 'paid_nonbrand'
when utm_campaign = 'brand' then 'paid_brand'
when utm_source is null and http_referer is null then 'direct_type_in'
when utm_source = 'socialbook' then 'social_paid'
end as channel_group,
count(case when is_repeat_session = 0 then website_session_id else null end) as new_sessions,
count(case when is_repeat_session = 1 then website_session_id else null end) as repeat_session
from website_sessions 
where created_at between '2014-01-01' and '2014-11-05'
group by 1;

# repeat conv rates vs new conv rates
select is_repeat_session, count(distinct w.website_session_id) as sessions, count(distinct o.order_id) as orders, count(distinct o.order_id)/count(distinct w.website_session_id) as conv, sum(o.price_usd)/count(distinct w.website_session_id) as rev_per_sesion
from website_sessions w 
left join orders o 
on w.website_session_id = o.website_session_id
where w.created_at between '2014-01-01' and '2014-11-08'
group by 1;

# final project
# Question 1 
SELECT 
    YEAR(w.created_at) AS yr,
    QUARTER(w.created_at) AS quat,
    COUNT(DISTINCT w.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders
FROM
    website_sessions w
        LEFT JOIN
    orders o ON w.website_session_id = o.website_session_id
GROUP BY 1 , 2;

# Question 2
SELECT 
    YEAR(w.created_at) AS yr,
    QUARTER(w.created_at) AS quat,
    COUNT(DISTINCT w.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT o.order_id) / COUNT(DISTINCT w.website_session_id) as conv,
    sum(price_usd)/COUNT(DISTINCT o.order_id) as rev_per_session,
    sum(price_usd)/COUNT(DISTINCT w.website_session_id) as rev_per_order
FROM
    website_sessions w
        LEFT JOIN
    orders o ON w.website_session_id = o.website_session_id
GROUP BY 1 , 2;


# Question 3
SELECT 
    YEAR(w.created_at) AS yr,
    QUARTER(w.created_at) AS quat,
    COUNT(DISTINCT CASE
            WHEN
                w.utm_source = 'gsearch'
                    AND w.utm_campaign = 'nonbrand'
            THEN
                o.order_id
            ELSE NULL
        END) / COUNT(DISTINCT CASE
            WHEN
                w.utm_source = 'gsearch'
                    AND w.utm_campaign = 'nonbrand'
            THEN
                w.website_session_id
            ELSE NULL
        END) AS gsearch_nonbrand_orders,
    COUNT(DISTINCT CASE
            WHEN
                w.utm_source = 'bsearch'
                    AND w.utm_campaign = 'nonbrand'
            THEN
                o.order_id
            ELSE NULL
        END) / COUNT(DISTINCT CASE
            WHEN
                w.utm_source = 'bsearch'
                    AND w.utm_campaign = 'nonbrand'
            THEN
                w.website_session_id
            ELSE NULL
        END) AS bsearch_nonbrand_orders,
    COUNT(DISTINCT CASE
            WHEN w.utm_campaign = 'brand' THEN o.order_id
            ELSE NULL
        END) / COUNT(DISTINCT CASE
            WHEN w.utm_campaign = 'brand' THEN w.website_session_id
            ELSE NULL
        END) AS brand_searc_orders,
    COUNT(DISTINCT CASE
            WHEN
                utm_source IS NULL
                    AND http_referer IS NOT NULL
            THEN
                o.order_id
            ELSE NULL
        END) / COUNT(DISTINCT CASE
            WHEN
                utm_source IS NULL
                    AND http_referer IS NOT NULL
            THEN
                w.website_session_id
            ELSE NULL
        END) AS or_searc_orders,
    COUNT(DISTINCT CASE
            WHEN
                utm_source IS NULL
                    AND http_referer IS NULL
            THEN
                o.order_id
            ELSE NULL
        END) / COUNT(DISTINCT CASE
            WHEN
                utm_source IS NULL
                    AND http_referer IS NULL
            THEN
                w.website_session_id
            ELSE NULL
        END) AS direct_type_in
FROM
    website_sessions w
        LEFT JOIN
    orders o ON w.website_session_id = o.website_session_id
GROUP BY 1 , 2;



# question 5
select year(created_at) as yr,
month(created_at) as mont,
sum(case when product_id = 1 then price_usd else null end) as mrfuzz_rev,
sum(case when product_id = 1 then price_usd - cogs_usd else null end) as mrfuzz_mr,
sum(case when product_id = 2 then price_usd else null end) as lovebear_rev,
sum(case when product_id = 2 then price_usd - cogs_usd else null end) as lovebear_mr,
sum(case when product_id = 3 then price_usd else null end) as bdbear_rev,
sum(case when product_id = 3 then price_usd - cogs_usd else null end) as bdbear_mr,
sum(case when product_id = 4 then price_usd else null end) as minbear_rev,
sum(case when product_id = 4 then price_usd - cogs_usd else null end) as minbear_mr
from order_items
GROUP BY 1 , 2;

# question 6

create temporary table sess_prod
select website_session_id,
website_pageview_id,
created_at as saw_product
from website_pageviews
where pageview_url = '/products';


select year(p.saw_product) as yr,
month(p.saw_product) as mont,
count(distinct p.website_session_id) as session_to_product,
count(distinct w.website_session_id) as clicked_to_next_p,
count(distinct w.website_session_id) / count(distinct p.website_session_id) as ctr,
count(distinct o.order_id) as orders,
count(distinct o.order_id) / count(distinct p.website_session_id) as order_to_product
from sess_prod p 
left join website_pageviews w 
on p.website_session_id = w.website_session_id 
and w.website_pageview_id > p.website_pageview_id
left join orders o 
on o.website_session_id = p.website_session_id 
GROUP BY 1 , 2;



# Wuestion 7
create temporary table ord
select order_id,
primary_product_id,
created_at as order_at
from orders
where created_at > '2012-12-05';

select primary_product_id,
count(distinct order_id) as orders,
count(distinct case when cross_sell = 1 then order_id else null end) as sold_p1x,
count(distinct case when cross_sell = 2 then order_id else null end) as sold_p2x,
count(distinct case when cross_sell = 3 then order_id else null end) as sold_p3x,
count(distinct case when cross_sell = 4 then order_id else null end) as sold_p4x,
count(distinct case when cross_sell = 1 then order_id else null end) / count(distinct order_id) as sold_p1x_rt,
count(distinct case when cross_sell = 2 then order_id else null end) / count(distinct order_id) as sold_p2x_rt,
count(distinct case when cross_sell = 3 then order_id else null end) / count(distinct order_id) as sold_p3x_rt,
count(distinct case when cross_sell = 4 then order_id else null end) / count(distinct order_id) as sold_p4x_rt
from
(
select ord.* , o.product_id as cross_sell
from ord 
left join order_items o 
on o.order_id = ord.order_id
and o.is_primary_item = 0) as primary_sales
GROUP BY 1
;

