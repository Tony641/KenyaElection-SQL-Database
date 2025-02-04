-- 1. Create the database
IF DB_ID('ElectionDB') IS NULL
BEGIN
    CREATE DATABASE ElectionDB;
END
GO

USE ElectionDB;
GO
 
 -- Main Tables
CREATE TABLE Positions (
    PositionID INT PRIMARY KEY IDENTITY(1,1),
    PositionName VARCHAR(100) NOT NULL,
    AdminLevel VARCHAR(50) NOT NULL CHECK (AdminLevel IN ('National','County','Constituency','Ward')),
    RequiresDeputy BIT NOT NULL DEFAULT 0
);


CREATE TABLE ElectoralRegions (
    RegionID INT PRIMARY KEY IDENTITY(1,1),
    RegionName VARCHAR(100) NOT NULL,
    RegionType VARCHAR(50) NOT NULL CHECK (RegionType IN ('Country','County','Constituency','Ward')),
    ParentRegionID INT,
    FOREIGN KEY (ParentRegionID) REFERENCES ElectoralRegions(RegionID)
);

CREATE TABLE PoliticalParties (
    PartyID INT PRIMARY KEY IDENTITY(1,1),
    PartyName VARCHAR(100) NOT NULL UNIQUE,
    Abbreviation VARCHAR(10) NOT NULL,
    RegistrationDate DATE NOT NULL
);

CREATE TABLE Candidates (
    CandidateID INT PRIMARY KEY IDENTITY(1,1),
    NationalID VARCHAR(20) UNIQUE NOT NULL,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    DateOfBirth DATE NOT NULL,
    PartyID INT,
    Photo VARBINARY(MAX),
    FOREIGN KEY (PartyID) REFERENCES PoliticalParties(PartyID)
);

CREATE TABLE Elections (
    ElectionID INT PRIMARY KEY IDENTITY(1,1),
    ElectionName VARCHAR(100) NOT NULL,
    ElectionDate DATE NOT NULL,
    ElectionType VARCHAR(50) CHECK (ElectionType IN ('General','By-Election','Repeat')),
    Status VARCHAR(20) DEFAULT 'Pending' CHECK (Status IN ('Pending','Ongoing','Completed'))
);

CREATE TABLE IEBCStructure (
    CommissionerID INT PRIMARY KEY IDENTITY(1,1),
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Role VARCHAR(50) NOT NULL CHECK (Role IN ('Chairperson','Commissioner','CEO')),
    CountyRegionID INT,
    AppointmentDate DATE NOT NULL,
    EndDate DATE,
    FOREIGN KEY (CountyRegionID) REFERENCES ElectoralRegions(RegionID)
);

CREATE TABLE PollingStations (
    PollingStationID INT PRIMARY KEY IDENTITY(1,1),
    StationName VARCHAR(100) NOT NULL,
    WardRegionID INT NOT NULL,
	Address NVARCHAR(255) NULL,
    Latitude DECIMAL(9,6),
    Longitude DECIMAL(9,6),
    FOREIGN KEY (WardRegionID) REFERENCES ElectoralRegions(RegionID)
);

CREATE TABLE Voters (
    VoterID INT PRIMARY KEY IDENTITY(1,1),
    NationalID VARCHAR(20) UNIQUE NOT NULL,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    DateOfBirth DATE NOT NULL,
    PollingStationID INT NOT NULL,
    RegistrationDate DATE NOT NULL,
    FingerprintData VARBINARY(MAX),
    Photo VARBINARY(MAX),
    FOREIGN KEY (PollingStationID) REFERENCES PollingStations(PollingStationID)
);


CREATE TABLE Nominations (
    NominationID INT PRIMARY KEY IDENTITY(1,1),
    ElectionID INT NOT NULL,
    PositionID INT NOT NULL,
    CandidateID INT NOT NULL,
    DeputyCandidateID INT,
    RegionID INT NOT NULL,
    PartyID INT NOT NULL,
    NominationDate DATE NOT NULL,
    ApprovalStatus VARCHAR(20) DEFAULT 'Pending' CHECK (ApprovalStatus IN ('Pending','Approved','Rejected')),
    FOREIGN KEY (ElectionID) REFERENCES Elections(ElectionID),
    FOREIGN KEY (PositionID) REFERENCES Positions(PositionID),
    FOREIGN KEY (CandidateID) REFERENCES Candidates(CandidateID),
    FOREIGN KEY (DeputyCandidateID) REFERENCES Candidates(CandidateID),
    FOREIGN KEY (RegionID) REFERENCES ElectoralRegions(RegionID),
    FOREIGN KEY (PartyID) REFERENCES PoliticalParties(PartyID)
);

CREATE TABLE ElectionStaff (
    StaffID INT PRIMARY KEY IDENTITY(1,1),
    NationalID VARCHAR(20) UNIQUE NOT NULL,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Role VARCHAR(50) NOT NULL CHECK (
        Role IN (
            'National Returning Officer',
            'County Returning Officer',
            'Deputy County Returning Officer',
            'Constituency Returning Officer',
            'Deputy Constituency Returning Officer',
			'Presiding Officer', 
            'Deputy Presiding Officer',
            'Clerk'
            
            
        )
    ),
    AssignedRegionID INT,
    
    TrainingDate DATE,
    FOREIGN KEY (AssignedRegionID) REFERENCES ElectoralRegions(RegionID)
 
);


CREATE TABLE TallyingCenters (
    TallyingCenterID INT PRIMARY KEY IDENTITY(1,1),
    TallyingCenterName VARCHAR(100) NOT NULL,
    TallyingCenterLocation VARCHAR(100) NOT NULL,
    Level VARCHAR(50) NOT NULL CHECK (Level IN ('National', 'County', 'Constituency')),
    RegionID INT NULL,
    FOREIGN KEY (RegionID) REFERENCES ElectoralRegions(RegionID)
);

CREATE TABLE TallyingCenterOfficial (
    AssignmentID INT PRIMARY KEY IDENTITY(1,1),
    OfficialID INT NOT NULL,
    TallyingCenterID INT NOT NULL,
    AssignmentDate DATE DEFAULT GETDATE(),
    FOREIGN KEY (OfficialID) REFERENCES ElectionStaff(STAFFID),
    FOREIGN KEY (TallyingCenterID) REFERENCES TallyingCenters(TallyingCenterID)
);

CREATE TABLE PollingStationOfficials (
    AssignmentID INT PRIMARY KEY IDENTITY(1,1),
    OfficialID INT NOT NULL,
    PollingStationID INT NOT NULL,
    Role VARCHAR(50) NOT NULL CHECK (
        Role IN (
            'Presiding Officer', 
            'Deputy Presiding Officer', 
            'Clerk'
          
             
             
        )
    ),
    AssignmentDate DATE DEFAULT GETDATE(),
    FOREIGN KEY (OfficialID) REFERENCES ElectionStaff(STAFFID),
    FOREIGN KEY (PollingStationID) REFERENCES PollingStations(PollingStationID)
);

CREATE TABLE PollingStationRoles (
    RoleID INT PRIMARY KEY IDENTITY(1,1),
    RoleName VARCHAR(100) NOT NULL UNIQUE,
    Description TEXT
);
INSERT INTO PollingStationRoles (RoleName, Description) VALUES 
('Presiding Officer', 'The person responsible for overseeing the entire election process at the polling station.'),
('Clerk', 'Assists in verifying voter registration, issuing ballots, and maintaining order.'),
('Deputy Presiding Officer', 'Assists the Presiding Officer in managing the polling station.'),
('Security Officer', 'Ensures the safety of the polling station and addresses security concerns.'),
('Election Agent', 'Represents a political party or candidate and observes the election process.'),
('Observer', 'Monitors the election process for fairness without directly participating.');

CREATE TABLE PollingClerkRoles (
    ClerkRoleID INT PRIMARY KEY IDENTITY(1,1),
    OfficialID INT NOT NULL,
    RoleID INT NOT NULL,
    PollingStationID INT NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NULL,
    FOREIGN KEY (OfficialID) REFERENCES ElectionStaff(STAFFID),
    FOREIGN KEY (RoleID) REFERENCES PollingStationRoles(RoleID),
    FOREIGN KEY (PollingStationID) REFERENCES PollingStations(PollingStationID)
);
CREATE TABLE TallyingCenterClerkRoles (
    RoleID INT PRIMARY KEY IDENTITY(1,1),
    RoleName VARCHAR(100) NOT NULL,
    RoleDescription TEXT NOT NULL
);


INSERT INTO TallyingCenterClerkRoles (RoleName, RoleDescription) VALUES
('Receiving and Verifying Results', 'Collecting result forms (Form 34A) from polling stations and verifying their authenticity and completeness.'),
('Data Entry and Compilation', 'Inputting results into the tallying system and compiling data for higher-level tallying centers.'),
('Documentation and Reporting', 'Maintaining accurate records and preparing reports for the Returning Officer and other authorities.'),
('Assisting in Result Verification', 'Collaborating with other officials to cross-verify results and identifying discrepancies or irregularities.'),
('Ensuring Security and Confidentiality', 'Safeguarding sensitive election materials and ensuring processes adhere to legal and procedural standards.');



CREATE TABLE TallyingCenterClerks (
    AssignmentID INT PRIMARY KEY IDENTITY(1,1),
    ClerkID INT NOT NULL,
    TallyingCenterID INT NOT NULL,
    RoleID INT NOT NULL,
    AssignmentDate DATE DEFAULT GETDATE(),
    FOREIGN KEY (ClerkID) REFERENCES ElectionStaff(STAFFID),
    FOREIGN KEY (TallyingCenterID) REFERENCES TallyingCenters(TallyingCenterID),
    FOREIGN KEY (RoleID) REFERENCES TallyingCenterClerkRoles(RoleID)
);

CREATE TABLE Votes (
    VoteID INT PRIMARY KEY IDENTITY(1,1),
    VoterID INT NOT NULL,
    NominationID INT NOT NULL,
    PollingStationID INT NOT NULL,
    VoteTimestamp DATETIME DEFAULT GETDATE(),
    VerificationCode VARCHAR(50),
    FOREIGN KEY (VoterID) REFERENCES Voters(VoterID),
    FOREIGN KEY (NominationID) REFERENCES Nominations(NominationID),
    FOREIGN KEY (PollingStationID) REFERENCES PollingStations(PollingStationID),
    CONSTRAINT UC_VoterElection UNIQUE (VoterID, NominationID)
);



-- Triggers (Example)
CREATE TRIGGER PreventOvervote
ON Votes
FOR INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Votes v ON i.VoterID = v.VoterID
        JOIN Nominations n1 ON i.NominationID = n1.NominationID
        JOIN Nominations n2 ON v.NominationID = n2.NominationID
        WHERE n1.ElectionID = n2.ElectionID
        AND n1.PositionID = n2.PositionID
        AND i.VoteID <> v.VoteID
    )
    BEGIN
        RAISERROR ('Duplicate vote for same position in election detected', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

CREATE PROCEDURE GetVoteCountsByPosition
    @ElectionID INT
AS
BEGIN
    SELECT 
        p.PositionName,
        er.RegionName,
        er.RegionType,
        COUNT(v.VoteID) AS TotalVotes
    FROM Votes v
    INNER JOIN Nominations n ON v.NominationID = n.NominationID
    INNER JOIN Positions p ON n.PositionID = p.PositionID
    INNER JOIN ElectoralRegions er ON n.RegionID = er.RegionID
    WHERE n.ElectionID = @ElectionID
    GROUP BY p.PositionName, er.RegionName, er.RegionType
    ORDER BY 
        CASE p.PositionName
            WHEN 'President' THEN 1
            WHEN 'Governor' THEN 2
            WHEN 'Senator' THEN 3
            WHEN 'Women Representative' THEN 4
            WHEN 'MP' THEN 5
            WHEN 'MCA' THEN 6
            ELSE 7
        END,
        er.RegionType,
        er.RegionName;
END;
GO


CREATE PROCEDURE GetDetailedVoteResults
    @ElectionID INT
AS
BEGIN
    SELECT
        p.PositionName,
        er.RegionName AS ElectoralRegion,
        pp.PartyName,
        c.FirstName + ' ' + c.LastName AS CandidateName,
        COUNT(v.VoteID) AS TotalVotes,
        ROUND(COUNT(v.VoteID) * 100.0 / SUM(COUNT(v.VoteID)) OVER (PARTITION BY p.PositionID, er.RegionID), 2) AS Percentage
    FROM Votes v
    INNER JOIN Nominations n ON v.NominationID = n.NominationID
    INNER JOIN Positions p ON n.PositionID = p.PositionID
    INNER JOIN Candidates c ON n.CandidateID = c.CandidateID
    INNER JOIN PoliticalParties pp ON n.PartyID = pp.PartyID
    INNER JOIN ElectoralRegions er ON n.RegionID = er.RegionID
    WHERE n.ElectionID = @ElectionID
    GROUP BY 
        p.PositionName,
        er.RegionName,
        pp.PartyName,
        c.FirstName + ' ' + c.LastName,
        p.PositionID,
        er.RegionID
    ORDER BY p.PositionName, er.RegionName, TotalVotes DESC;
END;
GO


-- 3. Function to Get Hierarchical Results
CREATE FUNCTION GetRegionalResults(@ElectionID INT, @RegionType VARCHAR(50))
RETURNS TABLE
AS
RETURN
(
    SELECT
        p.PositionName,
        er.RegionName,
        pp.PartyName,
        c.FirstName + ' ' + c.LastName AS CandidateName,
        COUNT(v.VoteID) AS TotalVotes
    FROM Votes v
    INNER JOIN Nominations n ON v.NominationID = n.NominationID
    INNER JOIN Positions p ON n.PositionID = p.PositionID
    INNER JOIN Candidates c ON n.CandidateID = c.CandidateID
    INNER JOIN PoliticalParties pp ON n.PartyID = pp.PartyID
    INNER JOIN ElectoralRegions er ON n.RegionID = er.RegionID
    WHERE n.ElectionID = @ElectionID
        AND er.RegionType = @RegionType
    GROUP BY p.PositionName, er.RegionName, pp.PartyName, c.FirstName + ' ' + c.LastName
);
GO


-- 4. Procedure for County-Level Results
CREATE PROCEDURE GetCountyResults
    @ElectionID INT,
    @CountyName VARCHAR(100) = NULL
AS
BEGIN
    SELECT
        er.RegionName AS County,
        p.PositionName,
        pp.PartyName,
        c.FirstName + ' ' + c.LastName AS CandidateName,
        COUNT(v.VoteID) AS TotalVotes
    FROM Votes v
    INNER JOIN Nominations n ON v.NominationID = n.NominationID
    INNER JOIN Positions p ON n.PositionID = p.PositionID
    INNER JOIN Candidates c ON n.CandidateID = c.CandidateID
    INNER JOIN PoliticalParties pp ON n.PartyID = pp.PartyID
    INNER JOIN ElectoralRegions er ON n.RegionID = er.RegionID
    WHERE n.ElectionID = @ElectionID
        AND er.RegionType = 'County'
        AND (@CountyName IS NULL OR er.RegionName = @CountyName)
    GROUP BY er.RegionName, p.PositionName, pp.PartyName, c.FirstName + ' ' + c.LastName
    ORDER BY er.RegionName, p.PositionName, TotalVotes DESC;
END;
GO



-- 5. National Presidential Results Procedure
CREATE PROCEDURE GetPresidentialResults
    @ElectionID INT
AS
BEGIN
    SELECT
        pp.PartyName,
        c.FirstName + ' ' + c.LastName AS CandidateName,
        COUNT(v.VoteID) AS TotalVotes,
        ROUND(COUNT(v.VoteID) * 100.0 / SUM(COUNT(v.VoteID)) OVER (), 2) AS NationalPercentage
    FROM Votes v
    INNER JOIN Nominations n ON v.NominationID = n.NominationID
    INNER JOIN Positions p ON n.PositionID = p.PositionID
    INNER JOIN Candidates c ON n.CandidateID = c.CandidateID
    INNER JOIN PoliticalParties pp ON n.PartyID = pp.PartyID
    WHERE n.ElectionID = @ElectionID
        AND p.PositionName = 'President'
    GROUP BY pp.PartyName, c.FirstName + ' ' + c.LastName
    ORDER BY TotalVotes DESC;
END;
GO

-- 6. Result Validation Check
CREATE PROCEDURE ValidateVoteCounts
    @ElectionID INT
AS
BEGIN
    -- Check 1: Compare total votes with registered voters
    SELECT 
        er.RegionName,
        er.RegionType,
        COUNT(DISTINCT v.VoterID) AS TotalVoters,
        COUNT(v.VoteID) AS TotalVotes,
        CASE 
            WHEN COUNT(v.VoteID) > COUNT(DISTINCT v.VoterID) 
            THEN 'Possible Overvoting' 
            ELSE 'OK' 
        END AS Status
    FROM Votes v
    INNER JOIN Nominations n ON v.NominationID = n.NominationID
    INNER JOIN ElectoralRegions er ON n.RegionID = er.RegionID
    WHERE n.ElectionID = @ElectionID
    GROUP BY er.RegionName, er.RegionType;

    -- Check 2: Verify candidate-vote relationships
    SELECT 
        c.FirstName + ' ' + c.LastName AS CandidateName,
        p.PositionName,
        COUNT(v.VoteID) AS TotalVotes,
        (SELECT COUNT(*) FROM Votes WHERE NominationID = n.NominationID) AS DirectCount
    FROM Votes v
    INNER JOIN Nominations n ON v.NominationID = n.NominationID
    INNER JOIN Candidates c ON n.CandidateID = c.CandidateID
    INNER JOIN Positions p ON n.PositionID = p.PositionID
    WHERE n.ElectionID = @ElectionID
    GROUP BY c.FirstName + ' ' + c.LastName, p.PositionName, n.NominationID;
END;
GO

CREATE INDEX IX_Votes_Election ON Votes(NominationID) INCLUDE (VoterID, VoteTimestamp);


CREATE TABLE AuditLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    SchemaName SYSNAME NOT NULL,
    TableName SYSNAME NOT NULL,
    Action CHAR(6) NOT NULL CHECK (Action IN ('INSERT','UPDATE','DELETE')),
    RecordID NVARCHAR(500) NOT NULL, -- Can handle composite keys
    AffectedColumns XML NULL,
    OldData XML NULL,
    NewData XML NULL,
    SystemUser NVARCHAR(128) NOT NULL DEFAULT SYSTEM_USER,
    HostName NVARCHAR(128) NOT NULL DEFAULT HOST_NAME(),
    ChangeDate DATETIME NOT NULL DEFAULT GETDATE(),
    ApplicationName NVARCHAR(128) DEFAULT APP_NAME()
);
GO

CREATE TABLE AuditConfig (
    TableName SYSNAME PRIMARY KEY,
    AuditEnabled BIT NOT NULL DEFAULT 1,
    EnableInsert BIT NOT NULL DEFAULT 1,
    EnableUpdate BIT NOT NULL DEFAULT 1,
    EnableDelete BIT NOT NULL DEFAULT 1,
    LastTriggerRebuild DATETIME NULL
);
GO

 DECLARE @TableName SYSNAME;
DECLARE @SchemaName SYSNAME;
DECLARE @Action CHAR(6);
DECLARE @RecordID NVARCHAR(500);
DECLARE @AffectedColumns XML;
DECLARE @OldData XML;
DECLARE @NewData XML;
DECLARE @PrimaryKeyColumn NVARCHAR(128);
DECLARE @SQL NVARCHAR(MAX);

-- Cursor to loop through all tables in the database
DECLARE table_cursor CURSOR FOR
SELECT 
    t.name AS TableName, 
    s.name AS SchemaName
FROM 
    sys.tables t
JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    t.is_ms_shipped = 0  -- Exclude system tables
    AND t.name NOT LIKE 'AuditLog';  -- Exclude AuditLog table itself

OPEN table_cursor;

FETCH NEXT FROM table_cursor INTO @TableName, @SchemaName;




CREATE TABLE ElectionObservers (
    ObserverID INT PRIMARY KEY IDENTITY(1,1),
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Organization VARCHAR(100) NOT NULL,
    AccreditationDate DATE NOT NULL
);

CREATE TABLE Complaints (
    ComplaintID INT PRIMARY KEY IDENTITY(1,1),
    VoterID INT,
    ElectionID INT NOT NULL,
    ComplaintText TEXT NOT NULL,
    Status VARCHAR(20) DEFAULT 'Pending' CHECK (Status IN ('Pending', 'Reviewed', 'Resolved')),
    FilingDate DATE DEFAULT GETDATE(),
    FOREIGN KEY (VoterID) REFERENCES Voters(VoterID),
    FOREIGN KEY (ElectionID) REFERENCES Elections(ElectionID)
);

CREATE TABLE CandidateExpenditures (
    ExpenditureID INT PRIMARY KEY IDENTITY(1,1),
    CandidateID INT NOT NULL,
    ExpenseCategory VARCHAR(50) NOT NULL CHECK (ExpenseCategory IN ('Advertising', 'Transport', 'Event Organization', 'Salaries', 'Miscellaneous')),
    Amount DECIMAL(10,2) NOT NULL,
    ExpenseDate DATE NOT NULL,
    FOREIGN KEY (CandidateID) REFERENCES Candidates(CandidateID)
);











WHILE @@FETCH_STATUS = 0
BEGIN
    -- Build dynamic SQL for the trigger creation
    SET @SQL = N'
    CREATE TRIGGER trg_AuditLog_' + QUOTENAME(@SchemaName) + '_' + QUOTENAME(@TableName) + '
    ON ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + '
    FOR INSERT, UPDATE, DELETE
    AS
    BEGIN
        DECLARE @Action CHAR(6);
        DECLARE @RecordID NVARCHAR(500);
        DECLARE @AffectedColumns XML;
        DECLARE @OldData XML;
        DECLARE @NewData XML;
        DECLARE @PrimaryKeyColumn NVARCHAR(128);
        
        -- Get details from the INSERTED and DELETED pseudo-tables
        IF EXISTS(SELECT * FROM inserted)
        BEGIN
            SET @Action = ''INSERT'';
            SET @NewData = (SELECT * FROM inserted FOR XML PATH(''Row''));
        END

        IF EXISTS(SELECT * FROM deleted)
        BEGIN
            SET @Action = CASE 
                            WHEN @Action = ''INSERT'' THEN ''UPDATE'' 
                            ELSE ''DELETE'' 
                         END;
            SET @OldData = (SELECT * FROM deleted FOR XML PATH(''Row''));
        END

        -- Get the primary key column dynamically
        SET @PrimaryKeyColumn = (SELECT COLUMN_NAME 
                                 FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
                                 WHERE TABLE_NAME = ''' + @TableName + ''' AND CONSTRAINT_NAME LIKE ''PK_%'');

        -- Get Record ID from the primary key column
        SET @RecordID = (SELECT ' + @PrimaryKeyColumn + ' FROM inserted);

        -- Record affected columns
        SET @AffectedColumns = (SELECT * FROM inserted EXCEPT SELECT * FROM deleted FOR XML PATH(''ColumnChanges''));

        -- Insert data into the Audit Log table
        INSERT INTO AuditLog (SchemaName, TableName, Action, RecordID, AffectedColumns, OldData, NewData)
        VALUES (''' + @SchemaName + ''', ''' + @TableName + ''', @Action, @RecordID, @AffectedColumns, @OldData, @NewData);
    END
    ';
    
    -- Execute the dynamic SQL to create the trigger
    EXEC sp_executesql @SQL;

    FETCH NEXT FROM table_cursor INTO @TableName, @SchemaName;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;


CREATE PROCEDURE DeleteOldAuditLogs
AS
BEGIN
    DELETE FROM AuditLog
    WHERE ChangeDate < DATEADD(MONTH, -6, GETDATE());
END;



EXEC msdb.dbo.sp_add_job 
    @job_name = 'DeleteOldAuditLogs';

EXEC msdb.dbo.sp_add_jobstep 
    @job_name = 'DeleteOldAuditLogs', 
    @step_name = 'DeleteAuditLogsStep',
    @subsystem = 'TSQL', 
    @command = 'EXEC DeleteOldAuditLogs;',
    @retry_attempts = 3;

EXEC msdb.dbo.sp_add_schedule 
    @schedule_name = 'EverySixMonths', 
    @freq_type = 8, -- '8' indicates 'Once every 6 months'
    @freq_interval = 1, -- Run every 6 months
    @freq_recurrence_factor = 1, 
    @active_start_time = 000000; -- Start time: 00:00:00 (midnight)

EXEC msdb.dbo.sp_attach_schedule 
    @job_name = 'DeleteOldAuditLogs', 
    @schedule_name = 'EverySixMonths';



	CREATE TABLE VerificationMethods (
    MethodID INT PRIMARY KEY IDENTITY(1,1),
    MethodName VARCHAR(50) NOT NULL,  -- (Biometric, ID Card, Manual)
    Description VARCHAR(255)
);

-- 2. Election Security Features
CREATE TABLE SecurityFeatures (
    FeatureID INT PRIMARY KEY IDENTITY(1,1),
    ElectionID INT NOT NULL,
    BallotSerialPrefix VARCHAR(10),
    UVSecurityCode VARCHAR(50),
    HologramType VARCHAR(50),
    FOREIGN KEY (ElectionID) REFERENCES Elections(ElectionID)
);

-- 3. Candidate Requirements
CREATE TABLE CandidateRequirements (
    RequirementID INT PRIMARY KEY IDENTITY(1,1),
    PositionID INT NOT NULL,
    MinimumAge INT NOT NULL,
    EducationLevel VARCHAR(50),
    SignatureThreshold INT,  -- Required nomination signatures
    ClearanceCertRequired BIT DEFAULT 1,
    FOREIGN KEY (PositionID) REFERENCES Positions(PositionID)
);
-- 4. Campaign Finance
CREATE TABLE CampaignFinance (
    FinanceID INT PRIMARY KEY IDENTITY(1,1),
    CandidateID INT NOT NULL,
    ElectionID INT NOT NULL,
    TotalDonations DECIMAL(18,2),
    Expenditure DECIMAL(18,2),
    SourceOfFunds XML,  -- Structured donor information
    AuditDate DATE,
    FOREIGN KEY (CandidateID) REFERENCES Candidates(CandidateID),
    FOREIGN KEY (ElectionID) REFERENCES Elections(ElectionID)
);

-- 5. Result Transmission
CREATE TABLE ResultTransmission (
    TransmissionID INT PRIMARY KEY IDENTITY(1,1),
    PollingStationID INT NOT NULL,
    TransmissionTime DATETIME DEFAULT GETDATE(),
    TransmissionMethod VARCHAR(50) CHECK (TransmissionMethod IN ('KIEMS','Manual','Satellite')),
    ReceivedByID INT NOT NULL,  -- IEBC official
    Checksum VARCHAR(64),  -- For digital verification
    FOREIGN KEY (PollingStationID) REFERENCES PollingStations(PollingStationID),
    FOREIGN KEY (ReceivedByID) REFERENCES ElectionStaff(StaffID)
);

-- 6. Election Observers
CREATE TABLE ElectionObservers (
    ObserverID INT PRIMARY KEY IDENTITY(1,1),
    Organization VARCHAR(100) NOT NULL,
    ObserverType VARCHAR(50) CHECK (ObserverType IN ('Local','International')),
    AccreditationNumber VARCHAR(50) UNIQUE,
    AssignedRegionID INT,
    StartDate DATE,
    EndDate DATE,
    FOREIGN KEY (AssignedRegionID) REFERENCES ElectoralRegions(RegionID)
);


CREATE TABLE ElectionDisputes (
    DisputeID INT PRIMARY KEY IDENTITY(1,1),
    ElectionID INT NOT NULL,
    RegionID INT NOT NULL,
    CandidateID INT NOT NULL,
    DisputeType VARCHAR(50) CHECK (DisputeType IN ('Results','Campaign','Procedure')),
    FilingDate DATE DEFAULT GETDATE(),
    ResolutionDate DATE,
    Status VARCHAR(50) DEFAULT 'Pending' CHECK (Status IN ('Pending','Resolved','Dismissed')),
 FOREIGN KEY (ElectionID) REFERENCES Elections(ElectionID),
    FOREIGN KEY (RegionID) REFERENCES ElectoralRegions(RegionID),
    FOREIGN KEY (CandidateID) REFERENCES Candidates(CandidateID)
);

-- 8. Media Coverage
CREATE TABLE MediaCoverage (
    CoverageID INT PRIMARY KEY IDENTITY(1,1),
    ElectionID INT NOT NULL,
    MediaHouse VARCHAR(100) NOT NULL,
    CoverageType VARCHAR(50) CHECK (CoverageType IN ('TV','Radio','Online','Print')),
    TimeAllocated INT,  -- In minutes for broadcast
    FairnessRating INT CHECK (FairnessRating BETWEEN 1 AND 5),
    FOREIGN KEY (ElectionID) REFERENCES Elections(ElectionID)
);

-- 9. Accessibility Features
CREATE TABLE Accessibility (
    AccessibilityID INT PRIMARY KEY IDENTITY(1,1),
    PollingStationID INT NOT NULL,
    BrailleBallots BIT DEFAULT 0,
    WheelchairAccess BIT DEFAULT 0,
    SignLanguageInterpreter BIT DEFAULT 0,
    AssistedVoting BIT DEFAULT 0,
    FOREIGN KEY (PollingStationID) REFERENCES PollingStations(PollingStationID)
);

-- 10. Training Modules
CREATE TABLE IEBC_Training (
    TrainingID INT PRIMARY KEY IDENTITY(1,1),
    StaffID INT NOT NULL,
    TrainingType VARCHAR(50) CHECK (TrainingType IN ('Presiding Officer','Technology','Security')),
    CompletionDate DATE,
    CertificationNumber VARCHAR(50),
    FOREIGN KEY (StaffID) REFERENCES ElectionStaff(StaffID)
);

ALTER TABLE Candidates ADD
    EACCClearance BIT DEFAULT 0,
    KRACompliance BIT DEFAULT 0,
    EducationLevel VARCHAR(50);

	ALTER TABLE Votes ADD
    TransmissionID INT,
    VerificationMethodID INT,
    FOREIGN KEY (TransmissionID) REFERENCES ResultTransmission(TransmissionID),
    FOREIGN KEY (VerificationMethodID) REFERENCES VerificationMethods(MethodID);

-- Add to ElectionStaff table
ALTER TABLE ElectionStaff ADD
    SecurityClearanceLevel VARCHAR(20) CHECK (SecurityClearanceLevel IN ('National','County','Local'));


	CREATE TABLE ObserverRecommendations (
    RecommendationID INT PRIMARY KEY IDENTITY(1,1),
    ObserverID INT NOT NULL,
    ElectionID INT NOT NULL,
    RegionID INT NOT NULL,
    RecommendationType VARCHAR(50) CHECK (RecommendationType IN (
        'Security Issue', 
        'Procedural Concern', 
        'Technology Improvement',
        'Accessibility Suggestion',
        'Voter Education',
        'Staff Training'
    )),
    Description NVARCHAR(MAX) NOT NULL,
    PriorityLevel VARCHAR(20) CHECK (PriorityLevel IN ('Critical','High','Medium','Low')),
    Status VARCHAR(20) DEFAULT 'Pending' CHECK (Status IN ('Pending','Under Review','Implemented','Rejected')),
    DateReported DATETIME DEFAULT GETDATE(),
    DateResolved DATETIME,
    AdminResponse NVARCHAR(MAX),
    FOREIGN KEY (ObserverID) REFERENCES ElectionObservers(ObserverID),
    FOREIGN KEY (ElectionID) REFERENCES Elections(ElectionID),
    FOREIGN KEY (RegionID) REFERENCES ElectoralRegions(RegionID)
);

CREATE INDEX IX_ObserverRecs_Status ON ObserverRecommendations(Status);
CREATE INDEX IX_ObserverRecs_Type ON ObserverRecommendations(RecommendationType);

CREATE TABLE VoterRecommendations (
    FeedbackID INT PRIMARY KEY IDENTITY(1,1),
    VoterID INT NOT NULL,
    PollingStationID INT NOT NULL,
    Category VARCHAR(50) CHECK (Category IN (
        'Registration Issue',
        'Voting Process',
        'Accessibility',
        'Security Concern',
        'Staff Conduct',
        'Technology Problem'
    )),
    Description NVARCHAR(MAX) NOT NULL,
    SeverityLevel VARCHAR(20) CHECK (SeverityLevel IN ('Critical','High','Medium','Low')),
    Status VARCHAR(20) DEFAULT 'Received' CHECK (Status IN ('Received','Being Addressed','Resolved')),
    SubmissionDate DATETIME DEFAULT GETDATE(),
    ResolutionDate DATETIME,
    ResponseDetails NVARCHAR(MAX),
    FOREIGN KEY (VoterID) REFERENCES Voters(VoterID),
    FOREIGN KEY (PollingStationID) REFERENCES PollingStations(PollingStationID)
);

CREATE INDEX IX_VoterFeedback_Category ON VoterRecommendations(Category);
CREATE INDEX IX_VoterFeedback_Status ON VoterRecommendations(Status);