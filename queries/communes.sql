select
    journey_start_insee as id_com,
    max(coalesce(b."LIBELLE", c."LIBCOG")) as libelle,
    count(*) as num_trajets
from
    trips a
left join cog b on
    a.journey_start_insee = b."COM"
left join cog_pays c on
    a.journey_start_insee = c."COG"::int::text
group by
    journey_start_insee
order by
    num_trajets desc