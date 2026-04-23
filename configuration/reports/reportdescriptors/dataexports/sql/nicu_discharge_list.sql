-- set @date = '2026-04-21';
SET @locale = GLOBAL_PROPERTY_VALUE('default_locale', 'en');

select encounter_type_id into @newborn_discharge from encounter_type where uuid = '153d3182-c76f-4047-b7f2-d83cf967b206';

DROP TABLE IF EXISTS temp_discharge_list;
CREATE TABLE temp_discharge_list
(
patient_id         int,          
encounter_id       int,          
visit_id           int,          
emr_id             varchar(50),  
name               text,         
discharge_datetime datetime,     
disposition        varchar(255), 
discharge_provider text,         
inborn_outborn     text);        

insert into temp_discharge_list (patient_id, encounter_id, discharge_datetime, visit_id) 
select patient_id, encounter_id, encounter_datetime, visit_id
from encounter e 
where encounter_type = @newborn_discharge 
and date(encounter_datetime) = @date
and voided = 0;

update temp_discharge_list 
set emr_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));

update temp_discharge_list 
set disposition = obs_value_coded_list(encounter_id, 'PIH', '8620', @locale);

update temp_discharge_list
set name = person_name(patient_id);

update temp_discharge_list
set discharge_provider = provider(encounter_id); 

set @patient_exists = concept_from_mapping('PIH','20150');
set @yes = concept_from_mapping('PIH','1065');
set @delivery_summary = (select encounter_type_id from encounter_type where uuid = 'fec2cc56-e35f-42e1-8ae3-017142c1ca59');

DROP TABLE IF EXISTS temp_inborn_baby_birthdates;
CREATE TABLE temp_inborn_baby_birthdates 
(select t.patient_id, o.obs_datetime "birthdatetime"  from temp_discharge_list t
inner join person p on p.person_id = t.patient_id
inner join obs o on o.comments = p.uuid 
	and o.concept_id = @patient_exists
	and o.value_coded = @yes);

update temp_discharge_list t  
inner join visit v on v.visit_id = t.visit_id
inner join temp_inborn_baby_birthdates bb on bb.patient_id = t.patient_id 
	and bb.birthdatetime >= v.date_started 
	and (bb.birthdatetime <= v.date_stopped or v.date_stopped is null)
set t.inborn_outborn = 'inborn';	
update temp_discharge_list t set inborn_outborn = 'outborn' where t.inborn_outborn is null;


select
  emr_id "EMR ID",
  name "Name", 
  CONCAT(DATE_FORMAT(discharge_datetime, '%b %e, %Y '), LTRIM(LOWER(DATE_FORMAT(discharge_datetime, '%l:%i%p')))) "Discharged date/time",
  disposition "Dispositon", 
  discharge_provider "Discharge provider",
  inborn_outborn "Inborn/Outborn"
from temp_discharge_list;
