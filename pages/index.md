---
title: Analyse des données du covoiturage
---

_Données récoltées en 2023_

![Covoiturage.beta.gouv.fr](logo_rnpc.webp)

# Introduction
[Covoiturage.beta.gouv.fr](https://covoiturage.beta.gouv.fr/) est développé sous la forme d'une Startup d'État dans la communauté beta.gouv.fr et porté par le Ministère de la Transition écologique, chargé des Transports.

[Covoiturage.beta.gouv.fr](https://covoiturage.beta.gouv.fr/) a pour mission d'aider l'écosystème du covoiturage quotidien : les autorités Organisatrices de la mobilité, les employeurs et les plateformes de covoiturage à mettre en place de manière sécurisée des mesures d’incitation au covoiturage courte distance.

<br>

# Les données

Chaque mois, la Startup d'État publie sur [data.gouv.fr](https://www.data.gouv.fr/fr/datasets/trajets-realises-en-covoiturage-registre-de-preuve-de-covoiturage/) les données des trajets de covoiturage effectués et validés par la Startup, ces jeux de données forment le Registre de Preuve du Covoiturage (RPC).

Dans cette étude, nous avons sélectionné les données de l'ensemble de l'année 2023.



```sql trips_stats
select 
    count(*) as num_trajets, 
    min(journey_start_datetime) as date_premier_trajet,
    max(journey_end_datetime) as date_dernier_trajet
from trips 
```
Le jeu de données comprend <Value data={trips_stats} column=num_trajets fmt="#,##0" /> trajets, les dates de trajets s'étalant du <Value data={trips_stats} column=date_premier_trajet fmt="dd/mm/YYYY HH:MM"/> UTC au <Value data={trips_stats} column=date_dernier_trajet fmt="dd/mm/YYYY HH:MM"/> UTC.

Voici un aperçu du jeu de données :

```sql trips_sample
SELECT * from trips limit 10
```

<DataTable data="{trips_sample}" search="true" formatColumnTitles="false"/>


Chaque ligne correspond à un trajet de covoiturage, c'est à dire un couple passager / conducteur. A chaque passager est donc affecté un trajet.

Exemple : un conducteur réalise un déplacement avec deux passagers différents au sein de son véhicule, le nombre de trajets réalisés et de 2. Ceci se traduit par deux lignes.

# Les chiffres du covoiturage courte distance

```sql trips_by_week    
select
    date_trunc('month',journey_start_datetime) as mois,
    case has_incentive when 'OUI' then 'Avec incitation' else 'Sans incitation' end as "Type de trajet",
    count(*) as "Nombre de trajets"
FROM trips
group by 1,2
having date_part('year',mois)=2023
order by mois asc
```

Chaque mois, plusieurs centaines de milliers de trajets sont effectués : 

<AreaChart 
    data={trips_by_week}  
    x=mois 
    y="Nombre de trajets"
    series="Type de trajet"
    stackName="Test"
    yAxisTitle=true
    seriesTitle="Type de trajet"
/>

<Alert status="info">
On peut remarquer que la part du nombre de trajets sans incitation a augmentée au cours de l'année. Peut être que les campagnes d'incitations sont menées en priorité au début de l'année et qu'elles ont porté leur fruit, le covoiturage s'étant maintenu sur la fin d'année.
</Alert>

Dans le Registre de Preuve de Covoiturage, chaque trajet se voit attribuer une classe en fonction des mécanismes et processus de vérification du trajet mis en place par la plateforme de covoiturage. On retrouve trois classes :
- Classe A : la plateforme certifie la mise en relation avec intention de covoiturer ;
- Classe B : la plateforme certifie la mise en relation et le trajet d’un occupant du véhicule (conducteur ou passager) ;
- Classe C : la plateforme certifie la mise en relation, les trajets des occupants du véhicule et une identité distincte des occupants.

La classe C est donc le niveau de vérification le plus avancé. C'est aussi la classe que l'on retrouve le plus souvent avec plus de <Value data={operator_count} column="ratio" row=0 fmt=pct /> des trajets effectués avec ce niveau de vérification.

```sql operator_count
select operator_class as "name",
    count(*) as "value",
    count(*)/ (select count(*) from trips) as "ratio"
from trips
group by 1
```

<ECharts config={
    {
        tooltip: {
            formatter: '{b}: {c} ({d}%)'
        },
        series: [
        {
          type: 'pie',
          data: data.operator_count,
        }
      ]
      }
    }
/>

```sql operator_count_by_week
select 
    date_trunc('week',journey_start_datetime) as semaine,
    operator_class,
    count(*) as num_trajets
from trips
group by 1,2
```

C'est une tendance qui est quasiment stable depuis fin mars 2023 :

<AreaChart 
    data={operator_count_by_week}  
    x=semaine 
    y=num_trajets
    series=operator_class
    type=stacked100
    yAxisTitle="% des trajets" 
    xAxisTitle="Semaine"
/>



# Le trajet type

Le covoiturage courte distance est en grande partie utilisé pour les trajets domicile-travail. On peut dresser la carte d'indentité du covoiturage type :

```sql trip_stats
select 
    mean(journey_duration) as duree_moyenne,
    median(journey_duration) as duree_mediane,
    max(journey_duration) as duree_maximale,
    min(journey_duration) as duree_minimale,
    mean(journey_distance)/1000 as distance_moyenne,
    median(journey_distance)/1000 as distance_mediane
from trips
```

```sql mean_passengers_per_trip
select mean(num_passagers) as num_passagers_moyen from (select 
    count(journey_id) as num_passagers
from trips
group by trip_id)
```

<BigValue 
  data={trip_stats}
  value=duree_moyenne
  title="Durée moyenne en minute"
  fmt='#,##0.0" minutes"'
/>

<BigValue 
  data={trip_stats}
  value=distance_moyenne
  title="Distance moyenne"
  fmt='#,##0.0" km"'
/>

<BigValue 
  data={mean_passengers_per_trip}
  value=num_passagers_moyen
  title="Nombres de passagers"
  fmt='#,##0.0" en moyenne"'
/>

```sql durations_buckets
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

```sql distance_buckets
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
        data={durations_buckets}  
        x=formatted_time_bucket 
        y=num_trajets
        yAxisTitle="Nombre de trajets"
        xAxisTitle="Durée du trajets (intervalle de temps en minutes)"
        sort=False
    >
    </BarChart>

    
    <BarChart 
        title="Distribution de la distance des trajets"
        data={distance_buckets}  
        x=formatted_bucket 
        y=num_trajets
        yAxisTitle="Nombre de trajets"
        xAxisTitle="Distance (en km)"
        sort=False
        fillColor="#807dba"
    />
</Grid>

Le covoiturage courte distance est surtout utilisé en semaine pour les trajets domicile-travail, cette tendance est confirmée par les données qui illustrent également l'impact, modéré, des vacances d'été et fermetures annuelles des entreprises qui ont surtout lieu en août :
```sql trips_by_day
with deduplicated as (
    select
        trip_id,
        min(journey_start_date) as journey_start_date
    from
        trips
    group by
        1
)
select 
    journey_start_date,
    count(*) as num_trajets
from
    deduplicated
group by
    1
order by
    1
```

<CalendarHeatmap
    data={trips_by_day}
    date=journey_start_date
    value=num_trajets
    title="Une année de trajets"
    subtitle="Des trajets surtout effectués en semaine"
    yearLabel=false
    echartsOptions={{calendar: [{
    dayLabel: {
        firstDay: 1 // start on Monday
    }
}]}}
/>

```sql trips_by_day_hour
with grouped as (select 
    date_part('dayofweek',journey_start_datetime) as jour,
    date_part('hour',journey_start_datetime) as heure,
    count(*) as num_trajets
from trips 
group by 1,2
order by (CASE
        WHEN jour = 1 THEN 0
        WHEN jour = 0 THEN 7
        ELSE jour
    END),2)
SELECT 
    CASE jour
        when 0 then 'Dimanche'
        when 1 then 'Lundi'
        when 2 then 'Mardi'
        when 3 then 'Mercredi'
        when 4 then 'Jeudi'
        when 5 then 'Vendredi'
        when 6 then 'Samedi'
    end as jour,
    heure::text || 'h' as heure,
    num_trajets
from grouped
```

    

Sans surprise, l'heure de départ des trajets est calquée sur les heures de bureau. On remarque qu'un covoitureur courte-distance type va partir au travail aux alentours de 6H du matin pour repartir, depuis son lieu de travail, aux environs de 16H :

<Heatmap 
    data={trips_by_day_hour} 
    x=jour 
    y=heure 
    value=num_trajets
    title="Aperçu de la distribution des trajets par jour de la semaine et heure"
/>



