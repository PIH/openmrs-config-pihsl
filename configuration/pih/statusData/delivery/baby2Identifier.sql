set @deliveryEncounterType = encounterName('fec2cc56-e35f-42e1-8ae3-017142c1ca59');
set @pregnancyProgram = program('Pregnancy');
set @pregnancyProgramId = mostRecentPatientProgramId(@patientId,@pregnancyProgram);
set @pregnancyProgramStartDate = programStartDate(@pregnancyProgramId);
set @latestDeliveryEncounterId = latestEnc(@patientId, @deliveryEncounterType, @pregnancyProgramStartDate);
set @newborn2ObsGroupId = obs_id(@latestDeliveryEncounterId, 'PIH','13555',1);
set @baby2UUID = obs_from_group_id_comment(@newborn2ObsGroupId, 'PIH','20150');
set @baby2PatientId = (select person_id from person where UUID = @baby2UUID);
set @baby2Identifier = patient_identifier(@baby2PatientId, 'c09a1d24-7162-11eb-8aa6-0242ac110002');

select @baby2Identifier as baby2Identifier; 
