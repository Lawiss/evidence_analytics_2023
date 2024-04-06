---
queries:
   - communes: communes.sql
---

```sql communes_filtered
select * from ${communes}
where id_com = '${params.id_com}'
```

# <Value data={communes_filtered} column=libelle /> - portrait robot du covoiturage
```sql trip_stats_commune
select 
    mean(journey_duration) as duree_moyenne,
    median(journey_duration) as duree_mediane,
    max(journey_duration) as duree_maximale,
    min(journey_duration) as duree_minimale,
    mean(journey_distance)/1000 as distance_moyenne,
    median(journey_distance)/1000 as distance_mediane
from trips
where journey_start_insee = '${params.id_com}'

```


```sql mean_passengers_per_trip_commune
select mean(num_passagers) as num_passagers_moyen from (select 
    count(journey_id) as num_passagers
from trips
where journey_start_insee = '${params.id_com}'
group by trip_id)
```

<BigValue 
  data={trip_stats_commune}
  value=duree_moyenne
  title="Durée moyenne en minute"
  fmt='#,##0.0" minutes"'
/>

<BigValue 
  data={trip_stats_commune}
  value=distance_moyenne
  title="Distance moyenne"
  fmt='#,##0.0" km"'
/>

<BigValue 
  data={mean_passengers_per_trip_commune}
  value=num_passagers_moyen
  title="Nombres de passagers"
  fmt='#,##0.0" en moyenne"'
/>

```sql trips_by_week_commune  
select
    date_trunc('month',journey_start_datetime) as mois,
    case has_incentive when 'OUI' then 'Avec incitation' else 'Sans incitation' end as "Type de trajet",
    count(*) as "Nombre de trajets"
FROM trips
where journey_start_insee = '${params.id_com}'
group by 1,2
having date_part('year',mois)=2023
order by mois asc
```

<AreaChart 
    data={trips_by_week_commune}  
    x=mois 
    y="Nombre de trajets"
    series="Type de trajet"
    stackName="Test"
    yAxisTitle=true
    seriesTitle="Type de trajet"
    title = "Nombre de trajets par semaine"
/>


## Distribution de la distance et de la durée des trajets effectués

```sql durations_buckets_commune
with raw_data_duration as (
select 
    case 
        when journey_duration <=90 
            then journey_duration::INT // 5
        when journey_duration>90 then 9999
    end as time_bucket,
    count(*) as num_trajets
from
    trips
where journey_start_insee = '${params.id_com}'
group by
    1
order by
    1)
select 
    time_bucket,
    case
        time_bucket
    when 9999 then '>90'
        else cast((time_bucket * 5) as varchar) || '-' || cast(((time_bucket + 1)* 5) as varchar)
    end as formatted_time_bucket,
    num_trajets
from
    raw_data_duration
```

```sql distance_buckets_commune
with raw_data_distance as (
select 
    case 
        when journey_distance/1000 <=100 
            then (journey_distance/1000)::INT // 2
        when journey_distance/1000>100 then 9999
    end as bucket,
    count(*) as num_trajets
from
    trips
where journey_start_insee = '${params.id_com}'

group by
    1
order by
    1)
select 
    bucket,
    case
        bucket
    when 9999 then '>100'
        else cast((bucket * 2) as varchar) || '-' || cast(((bucket + 1)* 2) as varchar)
    end as formatted_bucket,
    num_trajets
from
    raw_data_distance
```
<Grid cols=2>

    <BarChart 
        title="Distribution de la durées des trajets"
        data={durations_buckets_commune}  
        x=formatted_time_bucket 
        y=num_trajets
        yAxisTitle="Nombre de trajets"
        xAxisTitle="Durée du trajets (intervalle de temps en minutes)"
        sort=False
    >
    </BarChart>

    
    <BarChart 
        title="Distribution de la distance des trajets"
        data={distance_buckets_commune}  
        x=formatted_bucket 
        y=num_trajets
        yAxisTitle="Nombre de trajets"
        xAxisTitle="Distance (en km)"
        sort=False
        fillColor="#807dba"
    />
</Grid>