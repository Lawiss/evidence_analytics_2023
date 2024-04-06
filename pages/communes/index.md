---
title: La géographie du covoiturage
queries:
   - communes: communes.sql
---

Le réseau de transports en commun francilien étant très développé, on retrouve peu de villes d'Île de France dans le top des villes de départ des covoitureurs. On remarque que Montpellier est la ville avec le plus de départ de covoitureurs, ceci peut s'expliquer par son agglomération dense mais un réseau de transports péri-urbain à la traine, les transports en commun étant surtout dévellopé à l'intèrieur de la ville.

Certains pays frontaliers apparaissent dans le classement. Ce sont les pays avec un niveau de vie et de rémunération plus élevé qu'en france qui sont des bassins d'emplois très attractifs pour les français vivant à la frontière.


```sql trips_by_city
select * from ${communes}
LIMIT 15
```

<BarChart 
    data={trips_by_city} 
    x=libelle 
    y=num_trajets 
    swapXY=true 
    xAxisTitle="Nom de la ville/Pays" 
    yAxisTitle="Nombre de trajets"
    title="TOP 15 des villes le plus de fois indiquées comme ville de départ de covoiturage"
/>

```sql mean_duration_by_city
select
    journey_start_insee as id_com,
    max(coalesce(b."LIBELLE", c."LIBCOG")) as libelle,
    count(*) as num_trajets,
    mean(journey_duration) as duree_moyenne
from
    trips a
left join cog b on
    a.journey_start_insee = b."COM"
left join cog_pays c on
    a.journey_start_insee = c."COG"::int::text
group by
    journey_start_insee
having num_trajets>10000     
order by 4 desc
LIMIT 15
```

Si l'on jette un coup d'oeil aux communes de départ pour lesquelles les plus longs trajets de covoiturages ont été effectués, on s'aperçoit que ce sont des pays frontaliers qui se disputent les premières places :

<Details title="Détail sur les données">
    Les communes qui ont enregistrée moins de 10 000 départs ont été exclues pour limiter l'impact des valeurs aberrantes

</Details>

<BarChart 
    data={mean_duration_by_city} 
    x=libelle 
    y=duree_moyenne 
    xAxisTitle="Nom de la ville/Pays" 
    yAxisTitle="Durée moyenne des trajets (minutes)"
    title="TOP 15 des villes où les covoitureurs font les plus longs trajets"
    labels=true
    xTickMarks=true
    echartsOptions={
        {"xAxis" :
            {"axisLabel":{
                "rotate":-45
                }
            }
        }
    }
    chartAreaHeight=300
    colorPalette={["#fd7f6f"]}
/>

On note l'apparition de deux arrondissements de Paris dans les résultats.

## Détail par commune

Pour afficher le portrait robot du covoiturage par commune, cliquez sur le nom de la commune :

```sql communes_with_link
select 
*, 
row_number() OVER () as rn,
'/communes/' || id_com as link
from ${communes}
```

<DataTable data={communes_with_link} search=true link=link>
    <Column id=rn title="Rang" fmt="num0"/>
    <Column id=libelle title="Nom de la commune" />
    <Column id=num_trajets title="Nombre de trajets" />
</DataTable>