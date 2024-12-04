set @deliveryEncounterType = encounterName('fec2cc56-e35f-42e1-8ae3-017142c1ca59');
set @pregnancyProgram = program('Pregnancy');
set @pregnancyProgramId = mostRecentPatientProgramId(@patientId,@pregnancyProgram);
set @pregnancyProgramStartDate = programStartDate(@pregnancyProgramId);
set @latestDeliveryEncounterId = latestEnc(@patientId, @deliveryEncounterType, @pregnancyProgramStartDate);
set @newborn1ObsGroupId = obs_id(@latestDeliveryEncounterId, 'PIH','13555',0);
set @baby1UUID = obs_from_group_id_comment(@newborn1ObsGroupId, 'PIH','20150');
set @baby1PatientId = (select person_id from person where UUID = @baby1UUID);
set @baby1Identifier = patient_identifier(@baby1PatientId, 'c09a1d24-7162-11eb-8aa6-0242ac110002');

select @baby1Identifier as baby1Identifier; 
