IF OBJECT_ID('dbo.tbltrans_TranslationLogs', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tbltrans_TranslationLogs (
        Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        CallSessionId UNIQUEIDENTIFIER NOT NULL,
        SenderUserId UNIQUEIDENTIFIER NOT NULL,
        SourceLanguage NVARCHAR(12) NOT NULL,
        TargetLanguage NVARCHAR(12) NOT NULL,
        SourceText NVARCHAR(4000) NOT NULL,
        TranslatedText NVARCHAR(4000) NOT NULL,
        CreatedAt DATETIMEOFFSET NOT NULL
    );
END;

IF OBJECT_ID('dbo.tbltrans_CallParticipants', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tbltrans_CallParticipants (
        Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        CallSessionId UNIQUEIDENTIFIER NOT NULL,
        UserId UNIQUEIDENTIFIER NOT NULL,
        SourceLanguage NVARCHAR(12) NOT NULL,
        TargetLanguage NVARCHAR(12) NOT NULL,
        JoinedAt DATETIMEOFFSET NOT NULL,
        LeftAt DATETIMEOFFSET NULL
    );
END;

IF OBJECT_ID('dbo.tbltrans_CallSessions', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tbltrans_CallSessions (
        Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        StartedByUserId UNIQUEIDENTIFIER NOT NULL,
        Status NVARCHAR(32) NOT NULL,
        StartedAt DATETIMEOFFSET NOT NULL,
        EndedAt DATETIMEOFFSET NULL
    );
END;

IF OBJECT_ID('dbo.tbltrans_ChatMessages', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tbltrans_ChatMessages (
        Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        SenderUserId UNIQUEIDENTIFIER NOT NULL,
        RecipientUserId UNIQUEIDENTIFIER NOT NULL,
        Message NVARCHAR(4000) NOT NULL,
        CreatedAt DATETIMEOFFSET NOT NULL
    );

    CREATE INDEX IX_tbltrans_ChatMessages_Sender_Recipient_CreatedAt
    ON dbo.tbltrans_ChatMessages (SenderUserId, RecipientUserId, CreatedAt);

    CREATE INDEX IX_tbltrans_ChatMessages_Recipient_Sender_CreatedAt
    ON dbo.tbltrans_ChatMessages (RecipientUserId, SenderUserId, CreatedAt);
END;

IF OBJECT_ID('dbo.tbltrans_Users', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tbltrans_Users (
        Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        DisplayName NVARCHAR(120) NOT NULL,
        Email NVARCHAR(180) NOT NULL UNIQUE,
        PasswordHash NVARCHAR(500) NOT NULL,
        PreferredSourceLanguage NVARCHAR(12) NOT NULL,
        PreferredTargetLanguage NVARCHAR(12) NOT NULL,
        CreatedAt DATETIMEOFFSET NOT NULL
    );
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_trans_GetChatMessages
    @UserId UNIQUEIDENTIFIER,
    @OtherUserId UNIQUEIDENTIFIER,
    @Take INT = 100
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Take) Id, SenderUserId, RecipientUserId, Message, CreatedAt
    FROM dbo.tbltrans_ChatMessages
    WHERE (SenderUserId = @UserId AND RecipientUserId = @OtherUserId)
       OR (SenderUserId = @OtherUserId AND RecipientUserId = @UserId)
    ORDER BY CreatedAt DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_trans_GetUsers
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, DisplayName, Email, PreferredSourceLanguage, PreferredTargetLanguage, CreatedAt
    FROM dbo.tbltrans_Users
    ORDER BY DisplayName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_trans_GetTranslationLogsByCallSession
    @CallSessionId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, CallSessionId, SenderUserId, SourceLanguage, TargetLanguage, SourceText, TranslatedText, CreatedAt
    FROM dbo.tbltrans_TranslationLogs
    WHERE CallSessionId = @CallSessionId
    ORDER BY CreatedAt;
END;
GO
