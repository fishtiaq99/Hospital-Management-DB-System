create database HospitalManagement;

use HospitalManagement;

-- Creating the Patients Table
CREATE TABLE Patients (
    patient_id INT PRIMARY KEY,
    name VARCHAR(100),
    gender CHAR(1),
    dob DATETIME2,
    contact VARCHAR(15)
);

-- Add a 'flagged' column to the Patients table
ALTER TABLE Patients
ADD flagged BIT DEFAULT 0;  -- Default value is 0 (not flagged)


-- Creating the Doctors Table
CREATE TABLE Doctors (
    doctor_id INT PRIMARY KEY,
    name VARCHAR(100),
    specialization VARCHAR(100),
    availability_status VARCHAR(15)
);


-- Creating the Appointments Table
CREATE TABLE Appointments (
    appointment_id INT PRIMARY KEY,
    patient_id INT,
    doctor_id INT,
    appointment_date DATE,
    status VARCHAR(20),
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES Doctors(doctor_id)
);


-- Creating the Prescriptions Table
CREATE TABLE Prescriptions (
    prescription_id INT PRIMARY KEY,
    appointment_id INT,
    doctor_id INT,
    patient_id INT,
    medication VARCHAR(100),
    dosage VARCHAR(100),
    instructions VARCHAR(100),
    date_issued DATE,
    FOREIGN KEY (appointment_id) REFERENCES Appointments(appointment_id) on delete cascade,
    FOREIGN KEY (doctor_id) REFERENCES Doctors(doctor_id),
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id)
);

CREATE TABLE Users (
    user_id VARCHAR(10) PRIMARY KEY,  
    name VARCHAR(100),                 -- Name of the user
);

-- Creating the Audit_Log Table
CREATE TABLE Audit_Log (
    log_id INT PRIMARY KEY IDENTITY(1,1),
    action_type VARCHAR(30),           
    table_name VARCHAR(50),            -- Table being modified (PATIENTS, APPOINTMENTS, etc.)
    entity_id INT,                     -- ID of the affected entity (patient_id, appointment_id, etc.)
    performed_by VARCHAR(10),          -- User ID from Users table (who performed the action)
    timestamp DATETIME,  -- Timestamp of when the action occurred
    FOREIGN KEY (performed_by) REFERENCES Users(user_id)
);



bulk insert Patients
from 'C:\Users\eshaa\Downloads\patients_data.csv'
with (
   -- FORMAT = 'CSV',
    FIRSTROW = 2, 
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '0x0A',
    --codepage = '65001',
    TABLOCK
);

bulk insert Doctors
from 'C:\Users\eshaa\Downloads\doctors_data.csv'
with (
    FORMAT = 'CSV',
    FIRSTROW = 2, 
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '0x0A',
    codepage = '65001',
    TABLOCK
);

bulk insert Appointments
from 'C:\Users\eshaa\Downloads\appointments_data.csv'
with (
    FORMAT = 'CSV',
    FIRSTROW = 2, 
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '0x0A',
    codepage = '65001',
    TABLOCK
);

bulk insert Prescriptions
from 'C:\Users\eshaa\Downloads\prescriptions_data.csv'
with (
    FORMAT = 'CSV',
    FIRSTROW = 2, 
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '0x0A',
    codepage = '65001',
    TABLOCK
);

BULK INSERT Users
FROM 'C:\Users\eshaa\Downloads\users_data.csv'  -- Full path to the file
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0A',
    codepage = '65001',
    TABLOCK
);



-------------------------------------------------------------------------------------
---------------------- INSERT TRIGGER ON PATIENTS TABLE -----------------------------
-------------------------------------------------------------------------------------
CREATE TRIGGER trg_patient_insertion
ON Patients
AFTER INSERT
AS
BEGIN
    DECLARE @current_user VARCHAR(100);
    
    -- Assign the current user performing the action
    --SET @current_user = 'admin32';  -- or SYSTEM_USER depending on your needs
	SET @current_user = 'admin96';
    
    -- Insert into the Audit_Log table
    INSERT INTO Audit_Log (action_type, table_name, entity_id, performed_by, timestamp)
    SELECT 'INSERT', 'PATIENTS', patient_id, @current_user, CURRENT_TIMESTAMP
    FROM inserted;
END;

drop trigger trg_patient_insertion;

-- admin32 
INSERT INTO Patients (patient_id, name, gender, dob, contact)
VALUES (121, 'Tony Stark', 'M', '1983-09-12', '2947103865');

-- admin96
INSERT INTO Patients (patient_id, name, gender, dob, contact)
VALUES (122, 'Natalia Hastings', 'F', '2018-12-28', '0001112222');

select * from Audit_Log;



-------------------------------------------------------------------------------------
--------------------- INSERT TRIGGER ON APPOINTMENTS TABLE --------------------------
-------------------------------------------------------------------------------------
CREATE TRIGGER trg_appointment_insert
ON Appointments
AFTER INSERT 
AS
BEGIN
    DECLARE @current_user VARCHAR(100);
    
    -- Assign the current user performing the action
    --SET @current_user = 'admin32'; 
	SET @current_user = 'admin96';
    
    -- Log the booking action in the Audit_Log table
    INSERT INTO Audit_Log (action_type, table_name, entity_id, performed_by, timestamp)
    SELECT 'BOOK', 'APPOINTMENTS', appointment_id, @current_user, CURRENT_TIMESTAMP
    FROM inserted;
END;

drop trigger trg_appointment_insert;

-- admin32
INSERT INTO Appointments (appointment_id, patient_id, doctor_id, appointment_date, status)
VALUES (320, 120, 207, '2025-05-01 10:00:00', 'Booked');

-- admin96
INSERT INTO Appointments (appointment_id, patient_id, doctor_id, appointment_date, status)
VALUES (321, 114, 203, '2025-04-28 10:00:00', 'Cancelled');

select * from Audit_Log;


-------------------------------------------------------------------------------------
--------------------- DELETE TRIGGER ON APPOINTMENTS TABLE --------------------------
-------------------------------------------------------------------------------------
CREATE TRIGGER trg_appointment_delete
ON Appointments
AFTER DELETE
AS
BEGIN
    -- Declare the current_user variable for this trigger only
    DECLARE @current_user VARCHAR(100);
    
    -- Assign the current user performing the action
    --SET @current_user = 'admin32';
	SET @current_user = 'admin96';
    
    -- Log the cancellation action in the Audit_Log table
    INSERT INTO Audit_Log (action_type, table_name, entity_id, performed_by, timestamp)
    SELECT 'CANCEL', 'APPOINTMENTS', appointment_id, @current_user, CURRENT_TIMESTAMP
    FROM deleted;
END;

drop trigger trg_appointment_delete;

-- admin32
DELETE FROM Appointments WHERE appointment_id = 305;

-- admin96
DELETE FROM Appointments WHERE appointment_id = 311;


select * from Audit_Log;


-------------------------------------------------------------------------------------
----------------------- UPDATE TRIGGER ON DOCTORS TABLE -----------------------------
-------------------------------------------------------------------------------------
CREATE TRIGGER trg_doctor_update
ON Doctors
AFTER UPDATE 
AS
BEGIN
    DECLARE @current_user VARCHAR(100);
    
    -- Assign the current user performing the action
    --SET @current_user = 'admin32';  
	SET @current_user = 'admin96';  
    
    -- Directly log the change if availability_status is updated
    INSERT INTO Audit_Log (action_type, table_name, entity_id, performed_by, timestamp)
    SELECT 'STATUS_UPDATE', 'DOCTORS', doctor_id, @current_user, CURRENT_TIMESTAMP
    FROM inserted
    WHERE EXISTS (
        SELECT 1
        FROM deleted
        WHERE deleted.availability_status != inserted.availability_status
        AND inserted.doctor_id = deleted.doctor_id
    );
END;

drop trigger trg_doctor_update;

-- admin32, 202 originally unavailable, changing it to available
UPDATE Doctors
SET availability_status = 'Available'
WHERE doctor_id = 202;

-- admin96, 200 originally unavailable, changing it to available
UPDATE Doctors
SET availability_status = 'Available'
WHERE doctor_id = 200;

select * from Audit_Log;



-------------------------------------------------------------------------------------
------------------ CONDITIONAL TRIGGER WITH STATUS VALIDATION -----------------------
-------------------------------------------------------------------------------------
CREATE TRIGGER trg_validate_appointment_insert
ON Appointments
AFTER INSERT
AS
BEGIN
    DECLARE @current_user VARCHAR(100);
    
    -- Assign the current user performing the action
    --SET @current_user = 'admin32';  
	SET @current_user = 'admin96';
    
    -- Log if the insert is rejected due to doctor being unavailable
    INSERT INTO Audit_Log (action_type, table_name, entity_id, performed_by, timestamp)
    SELECT 'REJECTED_INSERT', 'APPOINTMENTS', appointment_id, @current_user, CURRENT_TIMESTAMP
    FROM inserted
    WHERE EXISTS (
        SELECT 1 
        FROM Doctors
        WHERE doctor_id = inserted.doctor_id 
          AND availability_status = 'Unavailable'
    );
    
    -- Log if the insert is rejected due to patient having an active appointment on the same day
    INSERT INTO Audit_Log (action_type, table_name, entity_id, performed_by, timestamp)
    SELECT 'REJECTED_INSERT', 'APPOINTMENTS', appointment_id, @current_user, CURRENT_TIMESTAMP
    FROM inserted
    WHERE EXISTS (
        SELECT 1 
        FROM Appointments 
        WHERE patient_id = inserted.patient_id 
          AND status = 'Booked' 
          AND appointment_date = inserted.appointment_date
    );
    
    -- Prevent the insert if any condition is met by signaling an error
   DELETE FROM Appointments 
    WHERE appointment_id IN (SELECT appointment_id FROM inserted
        WHERE EXISTS (
            SELECT 1
            FROM Doctors
            WHERE doctor_id = inserted.doctor_id 
              AND availability_status = 'Unavailable'
        ));

    DELETE FROM Appointments 
    WHERE appointment_id IN (SELECT appointment_id FROM inserted 
        WHERE EXISTS (
            SELECT 1 
            FROM Appointments 
            WHERE patient_id = inserted.patient_id 
              AND status = 'Booked' 
              AND appointment_date = inserted.appointment_date
        ));
END;

drop trigger trg_validate_appointment_insert;

-- admin32
INSERT INTO Appointments (appointment_id, patient_id, doctor_id, appointment_date, status)
VALUES (322, 106, 209, '2025-05-01 10:00:00', 'Booked');

-- admin96
INSERT INTO Appointments (appointment_id, patient_id, doctor_id, appointment_date, status)
VALUES (322, 111, 206, '2025-05-01 10:00:00', 'Booked');

select * from Audit_Log;



-------------------------------------------------------------------------------------
------------------ TRIGGER FOR AUTOMATIC PRESCRIPTION ISSUE  ------------------------
-------------------------------------------------------------------------------------
CREATE TRIGGER trg_auto_prescription
ON Appointments
AFTER UPDATE 
AS
BEGIN
    DECLARE @current_user VARCHAR(100);
    DECLARE @new_prescription_id INT;
    
    -- Assign the current user performing the action
    --SET @current_user = 'admin32';  
	SET @current_user = 'admin96';  
    
    -- Check if the appointment status has been updated to 'Completed'
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE status = 'Completed'
    )
    BEGIN
        -- Get the maximum prescription_id and increment by 1
        SELECT @new_prescription_id = MAX(prescription_id) + 1
        FROM Prescriptions;
        
        -- Insert a placeholder prescription when the appointment is marked as 'Completed'
        INSERT INTO Prescriptions (prescription_id, appointment_id, doctor_id, patient_id, medication, dosage, instructions, date_issued)
        SELECT @new_prescription_id, appointment_id, doctor_id, patient_id, 'Diagnosis Pending', NULL, NULL, CURRENT_TIMESTAMP
        FROM inserted;

        -- Log the creation of the prescription in the Audit_Log table
        INSERT INTO Audit_Log (action_type, table_name, entity_id, performed_by, timestamp)
        SELECT 'PRESCRIBE', 'PRESCRIPTIONS', @new_prescription_id, @current_user, CURRENT_TIMESTAMP
        FROM inserted;
    END
END;

drop trigger trg_auto_prescription;

-- admin32
UPDATE Appointments
SET status = 'Completed'
WHERE appointment_id = 304;


-- admin96
UPDATE Appointments
SET status = 'Completed'
WHERE appointment_id = 320;


select * from Audit_Log;


-------------------------------------------------------------------------------------
------------------ TRIGGER TO PREVENT MULTIPLE APPOINTMENTS  ------------------------
-------------------------------------------------------------------------------------

CREATE TRIGGER trg_prevent_multiple_appointments
ON Appointments
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @patient_id INT;
    DECLARE @appointment_date DATETIME;
    DECLARE @current_user VARCHAR(100);

	SET @current_user = 'admin32'; 
	--SET @current_user = 'admin96';

    -- Get the values from the inserted table
    SELECT @patient_id = patient_id, @appointment_date = appointment_date FROM inserted;

    -- Check if the patient already has an active appointment on the same date
    IF EXISTS (
        SELECT 1
        FROM Appointments
        WHERE patient_id = @patient_id
        AND status = 'Booked'  -- Ensure status is 'Booked'
        AND appointment_date = @appointment_date
    )
    BEGIN
        -- Log the blocked attempt in the Audit_Log table
        INSERT INTO Audit_Log (action_type, table_name, entity_id, performed_by, timestamp)
        SELECT 'REJECTED_INSERT', 'APPOINTMENTS', appointment_id, @current_user, CURRENT_TIMESTAMP
        FROM inserted;

        -- Prevent the insert and raise an error
        RAISERROR ('Patient already has an active appointment on this date.', 16, 1);
    END
    ELSE
    BEGIN
        -- If no active appointment exists, insert the new appointment
        INSERT INTO Appointments (appointment_id, patient_id, doctor_id, appointment_date, status)
        SELECT appointment_id, patient_id, doctor_id, appointment_date, status
        FROM inserted;
    END
END;

select * from Appointments;

drop trigger trg_prevent_multiple_appointments;

-- admin32
INSERT INTO Appointments (appointment_id, patient_id, doctor_id, appointment_date, status)
VALUES (322, 119, 206, '2025-01-08 10:00:00', 'Booked');

select * from Audit_Log;

CREATE TRIGGER trg_log_appointment_insertion
ON Appointments
AFTER INSERT
AS
BEGIN
    DECLARE @current_user VARCHAR(100);
    DECLARE @new_appointment_id INT;

    -- Assign the current user performing the action
    SET @current_user = 'admin32'; 
	--SET @current_user = 'admin96';
    
    -- Log the new appointment insertion in the Audit_Log
    SELECT @new_appointment_id = appointment_id FROM inserted;

    -- Log the operation in Audit_Log (new values)
    INSERT INTO Audit_Log (action_type, table_name, entity_id, performed_by, timestamp)
    VALUES ('INSERT', 'APPOINTMENTS', @new_appointment_id, @current_user, CURRENT_TIMESTAMP);
END;

drop trigger trg_log_appointment_insertion;

-------------------------------------------------------------------------------------
-------------------- CASCADING TRIGGERS WITH LOGIC CONFLICT  ------------------------
-------------------------------------------------------------------------------------


--------- 1 ---------
select * from Appointments;

select * from Doctors;

INSERT INTO Appointments (appointment_id, patient_id, doctor_id, appointment_date, status)
VALUES (323, 108, 202, '2025-03-08 10:00:00', 'Missed');


INSERT INTO Appointments (appointment_id, patient_id, doctor_id, appointment_date, status)
VALUES (324, 108, 206, '2025-02-08 10:00:00', 'Missed');

INSERT INTO Appointments (appointment_id, patient_id, doctor_id, appointment_date, status)
VALUES (325, 108, 200, '2025-01-08 10:00:00', 'Missed');


CREATE TRIGGER trg_flag_missed_appointments
ON Appointments
AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @patient_id INT;
    DECLARE @missed_appointments INT;

    -- Get the patient_id from the inserted or updated row
    SELECT @patient_id = patient_id FROM inserted;

    -- Count the number of missed appointments for the patient
    SELECT @missed_appointments = COUNT(*)
    FROM Appointments
    WHERE patient_id = @patient_id
    AND status = 'Missed';

    -- If the patient has more than 3 missed appointments, flag them
    IF @missed_appointments > 3
    BEGIN
        UPDATE Patients
        SET flagged = 1  -- Flag the patient
        WHERE patient_id = @patient_id;
    END
END;

drop trigger trg_flag_missed_appointments;

INSERT INTO Appointments (appointment_id, patient_id, doctor_id, appointment_date, status)
VALUES (326, 108, 202, '2025-05-01 10:00:00', 'Missed');

select * from Patients;




----------- 2 -----------

select * from Appointments;

CREATE TRIGGER trg_mark_doctor_unavailable
ON Appointments
AFTER INSERT, UPDATE 
AS
BEGIN
    DECLARE @doctor_id INT;
    DECLARE @missed_appointments INT;

    -- Get the doctor_id from the inserted or updated row
    SELECT @doctor_id = doctor_id FROM inserted;

    -- Count the number of missed appointments for the doctor in the past 7 days
    SELECT @missed_appointments = COUNT(*)
    FROM Appointments
    WHERE doctor_id = @doctor_id
    AND status = 'Missed'
    AND appointment_date >= DATEADD(DAY, -7, GETDATE());  -- Appointments in the last 7 days

    -- If the doctor has 3 or more missed appointments in a week, mark them as 'Unavailable'
    IF @missed_appointments >= 3
    BEGIN
        UPDATE Doctors
        SET availability_status = 'Unavailable'
        WHERE doctor_id = @doctor_id;
    END
END;

drop trigger trg_mark_doctor_unavailable;

select * from Doctors;

----------- DOCTOR 200 INITIALLY AVAILABLE ------------

INSERT INTO Appointments (appointment_id, patient_id, doctor_id, appointment_date, status)
VALUES (327, 108, 200, '2025-05-04 10:00:00', 'Missed');

INSERT INTO Appointments (appointment_id, patient_id, doctor_id, appointment_date, status)
VALUES (328, 111, 200, '2025-05-01 10:00:00', 'Missed');

INSERT INTO Appointments (appointment_id, patient_id, doctor_id, appointment_date, status)
VALUES (329, 118, 200, '2025-05-03 10:00:00', 'Missed');

select * from Appointments;

select * from Doctors;


----------- DOCTOR 200 NOW UNAVAILABLE ------------



---------- 3 -----------
CREATE OR ALTER TRIGGER trg_limit_appointments_per_day
ON Appointments
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @doctor_id INT;
    DECLARE @appointment_date DATETIME;
    DECLARE @existing_appointments INT;

    -- Get the doctor_id and appointment_date from the inserted row
    SELECT @doctor_id = doctor_id, @appointment_date = appointment_date FROM inserted;

    -- Count how many appointments the doctor already has on the same day
    SELECT @existing_appointments = COUNT(*)
    FROM Appointments
    WHERE doctor_id = @doctor_id
    AND CAST(appointment_date AS DATE) = CAST(@appointment_date AS DATE);  -- Compare only the date part

    -- If the doctor already has 5 appointments for that day, prevent the insert
    IF @existing_appointments >= 5
    BEGIN
        -- Raise an error and block the insert
        RAISERROR ('Doctor cannot have more than 5 appointments per day.', 16, 1);
    END
    ELSE
    BEGIN
        -- If the limit is not reached, insert the new appointment
        INSERT INTO Appointments (appointment_id, patient_id, doctor_id, appointment_date, status)
        SELECT appointment_id, patient_id, doctor_id, appointment_date, status
        FROM inserted;
    END
END;


select * from Doctors;

-- Insert 5 appointments for doctor 1 on the same day

----- DOCTOR 202 WILL SEE AT LEAST 5 PATIENTS A DAY ----------------

INSERT INTO Appointments (appointment_id, patient_id, doctor_id, appointment_date, status)
VALUES (330, 118, 208, '2025-05-02 10:00:00', 'Booked');

INSERT INTO Appointments (appointment_id, patient_id, doctor_id, appointment_date, status)
VALUES (331, 104, 208, '2025-05-02 10:00:00', 'Booked');

INSERT INTO Appointments (appointment_id, patient_id, doctor_id, appointment_date, status)
VALUES (332, 117, 208, '2025-05-02 12:00:00', 'Booked');

INSERT INTO Appointments (appointment_id, patient_id, doctor_id, appointment_date, status)
VALUES (333, 106, 208, '2025-05-02 08:00:00', 'Booked');

INSERT INTO Appointments (appointment_id, patient_id, doctor_id, appointment_date, status)
VALUES (334, 108, 208, '2025-05-02 06:00:00', 'Booked');

INSERT INTO Appointments (appointment_id, patient_id, doctor_id, appointment_date, status)
VALUES (335, 112, 208, '2025-05-02 04:00:00', 'Booked');

select * from Appointments; 

select * from Audit_Log;