select encounter_type_id into @admission from encounter_type where uuid = '260566e1-c909-4d61-a96f-c1019291a09d';
select encounter_type_id into @transfer from encounter_type where uuid = '436cfe33-6b81-40ef-a455-f134a9f7e580';
select encounter_type_id into @exit_from_care from encounter_type where uuid = 'b6631959-2105-49dd-b154-e1249e0fbcd7';

select location_id into @anc from location where uuid = '11f5c9f9-40b8-46ad-9e7e-59473ce43246';
select location_id into @labour from location where uuid = '11377a5b-6850-11ee-ab8d-0242ac120002';
select location_id into @nicu from location where uuid = '0ce2f6fb-6850-11ee-ab8d-0242ac120002';
select location_id into @pacu from location where uuid = '17596678-6850-11ee-ab8d-0242ac120002';
select location_id into @pnc from location where uuid = 'ff0d5e73-3fe0-437f-90ba-7d605ac03dc0';
select location_id into @quiet from location where uuid = '28660b7f-3450-4b86-b840-9670ec68235f';
select location_id into @mccu from location where uuid = '4d7e927d-6850-11ee-ab8d-0242ac120002';
select location_id into @postop from location where uuid = 'a39ec469-d1f9-11f0-9d46-169316be6a48';
select location_id into @preop from location where uuid = '142de844-6850-11ee-ab8d-0242ac120002';

drop temporary table if exists temp_census;
create temporary table temp_census
(select distinct e.location_id, e.patient_id from encounter e 
inner join visit v on e.visit_id = v.visit_id AND v.date_stopped is null 
where e.voided = 0
and e.encounter_type in (@admission, @transfer)
and e.location_id in (@anc, @labour, @nicu, @pacu, @pnc, @quiet, @mccu, @postop, @preop)
and not exists 
	(select 1 from encounter e2
	where e2.voided = 0
	and e2.patient_id = e.patient_id 
	and (e2.encounter_type in (@exit_from_care) or (e2.encounter_type = @transfer and e2.location_id <> e.location_id))
	and e2.encounter_datetime > e.encounter_datetime 
	));

delete t from temp_census t 
inner join person p on p.person_id = t.patient_id
where (p.birthdate is null or (TIMESTAMPDIFF(YEAR, p.birthdate, CURDATE()) < 10 and t.location_id <> @nicu))
   or (p.birthdate is null or (TIMESTAMPDIFF(YEAR, p.birthdate, CURDATE()) > 0 and t.location_id = @nicu)) ;

drop temporary table if exists temp_final;
create temporary table temp_final 
(ward varchar(255),
current_census int,
free_beds int);

INSERT INTO temp_final (ward)
(select name from location where location_id in(@anc, @labour, @nicu, @pacu, @pnc, @quiet, @mccu, @postop, @preop));

update temp_final t 
inner join  
	(select name "ward", count(*) "census"
	from temp_census t  
	inner join location l on l.location_id = t.location_id
	group by name) i on i.ward = t.ward 
set t.current_census = i.census;

update temp_final t 
inner join  
	(select l.name "ward", count(*) "free_beds" 
	from bed_location_map blm
	inner join bed b on b.bed_id = blm.bed_id and b.voided = 0
	inner join location l on l.location_id = blm.location_id
	and not exists 
		(select 1 from bed_patient_assignment_map bpam 
		where bpam.bed_id = blm.bed_id  
		and bpam.voided = 0
		and bpam.date_stopped is null)
	group by l.name) i on i.ward = t.ward
set t.free_beds = i.free_beds;

update temp_final t set t.current_census = 0 where t.current_census is null;
update temp_final t set t.free_beds = 0 where t.free_beds is null;

select 
ward "Ward",
current_census "Current_Census", 
free_beds "Free_Beds"
from temp_final;
