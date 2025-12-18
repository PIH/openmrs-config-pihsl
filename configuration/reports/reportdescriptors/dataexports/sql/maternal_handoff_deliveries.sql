set @baby_construct = concept_from_mapping('PIH','13555');
set @type_delivery = concept_from_mapping('PIH','11663');
set @outcome = concept_from_mapping('PIH','13561');
set @csection = concept_from_mapping('PIH','9336');
set @vacuum = concept_from_mapping('PIH','10752');
set @vaginal = concept_from_mapping('PIH','1170');
select encounter_type_id into @delivery from encounter_type where uuid = 'fec2cc56-e35f-42e1-8ae3-017142c1ca59';


DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs 
(select o.obs_id, o.voided ,o.obs_group_id ,o.concept_id, o.value_coded 
from obs o
inner join encounter e on e.encounter_id = o.encounter_id and e.voided = 0 and e.encounter_type =  @delivery
where o.voided = 0
and o.concept_id in (@type_delivery,@outcome)
and obs_datetime >= DATE_SUB(CURDATE(), INTERVAL 1 DAY) + INTERVAL 8 HOUR
and obs_datetime <  CURDATE() + INTERVAL 8 HOUR);

drop temporary table if exists temp_births;
create temporary table temp_births
(select obs_group_id,
max(case when concept_id = @outcome then concept_name(value_coded,'en') end) "outcome",
max(case when concept_id = @type_delivery then value_coded end) "type"
from temp_obs
group by obs_group_id);



drop temporary table if exists temp_final;
create temporary table temp_final
(select outcome,
sum(case when type = @csection then 1 else 0 end) "C_Section",
sum(case when type = @vacuum then 1 else 0 end) "Vacuum",
sum(case when type = @vaginal then 1 else 0 end) "Vaginal",
sum(case when type is null then 1 else 0 end) "No_Type_of_Delivery",
0 "Total"
from temp_births
group by outcome) 
;

update temp_final 
set outcome = 'No Outcome'
where outcome is null;

update temp_final 
set Total = C_Section + Vacuum + Vaginal + No_Type_of_Delivery;

SELECT
  SUM(C_Section),
  SUM(Vacuum),
  SUM(Vaginal),
  SUM(No_Type_of_Delivery),
  SUM(Total)
INTO
  @c_section,
  @vacuum,
  @vaginal,
  @no_type,
  @total
FROM temp_final;


INSERT INTO temp_final (
  outcome, C_Section, Vacuum, Vaginal, No_Type_of_Delivery, Total
)
VALUES (
  'Total', @c_section, @vacuum, @vaginal, @no_type, @total
);

select * from temp_final;
