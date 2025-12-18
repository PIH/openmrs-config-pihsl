select encounter_type_id into @admission from encounter_type where uuid = '260566e1-c909-4d61-a96f-c1019291a09d';
select encounter_type_id into @mat_discharge from encounter_type where uuid = '2110a810-db62-4914-ba95-604b96010164';
select encounter_type_id into @newb_discharge from encounter_type where uuid = '436cfe33-6b81-40ef-a455-f134a9f7e580';
select encounter_type_id into @transfer from encounter_type where uuid = '436cfe33-6b81-40ef-a455-f134a9f7e580';

select location_id into @anc from location where uuid = '11f5c9f9-40b8-46ad-9e7e-59473ce43246';
select location_id into @labour from location where uuid = '11377a5b-6850-11ee-ab8d-0242ac120002';
select location_id into @nicu from location where uuid = '0ce2f6fb-6850-11ee-ab8d-0242ac120002';
select location_id into @pacu from location where uuid = '17596678-6850-11ee-ab8d-0242ac120002';
select location_id into @pnc from location where uuid = 'ff0d5e73-3fe0-437f-90ba-7d605ac03dc0';
select location_id into @kangaroo from location where uuid = '81080213-d1f9-11f0-9d46-169316be6a48';

-- insert all admission, discharges, transfers into one table
drop temporary table if exists temp_adt;
create temporary table temp_adt
(patient_id int(11),
visit_id int(11),
location_name varchar(255),
encounter_type int(11),
previous_location_id int(11),
previous_location_name varchar(255));

insert into temp_adt (patient_id, visit_id, location_name, encounter_type)
select patient_id, visit_id, location_name(location_id), encounter_type from encounter e 
where e.voided = 0
and e.location_id in (@anc, @labour, @nicu, @pacu, @pnc, @kangaroo) 
and encounter_type in (@admission, @mat_discharge, @newb_discharge, @transfer)
and encounter_datetime >= DATE_SUB(CURDATE(), INTERVAL 1 DAY) + INTERVAL 8 HOUR
and encounter_datetime <  CURDATE() + INTERVAL 8 HOUR;

-- create table of all admissions and transfer ins to locations to prepare for updating the previous location for transfers 
drop temporary table if exists temp_transfer_ins;
create temporary table temp_transfer_ins
(select e.encounter_id, e.patient_id, e.location_id, encounter_datetime  
from encounter e  
inner join temp_adt t on t.patient_id = e.patient_id and t.encounter_type = @transfer  and e.visit_id = t.visit_id
and e.encounter_type in (@admission, @transfer)
where e.voided = 0
and e.location_id in (@anc, @labour, @nicu, @pacu, @pnc, @kangaroo));

-- create duplicate table to overcome MySQL limitation
drop temporary table if exists temp_transfer_ins_dup;
create temporary table temp_transfer_ins_dup
(select * from temp_transfer_ins);
create index temp_transfer_ins_dup_pi on temp_transfer_ins_dup(patient_id, encounter_datetime);

-- update previous location for every transfer
update temp_adt a  
inner join temp_transfer_ins t on t.encounter_id = 
(select t2.encounter_id from temp_transfer_ins_dup t2
where t2.patient_id = a.patient_id
order by t2.encounter_datetime desc limit 1)
set previous_location_name = location_name(t.location_id)
where encounter_type = @transfer;

-- create table of transfer outs only
drop temporary table if exists temp_adt_transfer_outs;
create temporary table temp_adt_transfer_outs
(select previous_location_name from temp_adt where previous_location_name is not null);

-- insert fake transfer out transactions (encounter type = 999999)
insert into temp_adt (location_name, encounter_type)
select previous_location_name, 999999 from temp_adt_transfer_outs;

-- final aggregation
select location_name "Ward", 
sum(case when encounter_type = @admission then 1 else 0 end) "Admissions",
sum(case when encounter_type = @transfer then 1 else 0 end) "Transfers In",
sum(case when encounter_type = 999999 then 1 else 0 end) "Transfers Out",
sum(case when encounter_type in (@mat_discharge, @newb_discharge) then 1 else 0 end) "Discharges"
from temp_adt 
group by location_name;

