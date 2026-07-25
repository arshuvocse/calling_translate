using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.Extensions.Logging;

namespace VoiceTranslator.Infrastructure.Persistence;

public sealed class DatabaseInitializer(ApplicationDbContext dbContext, ILogger<DatabaseInitializer> logger)
{
    public async Task InitializeAsync(CancellationToken cancellationToken = default)
    {
        logger.LogInformation("Initializing translation database objects.");

        var databaseCreator = dbContext.Database.GetService<IRelationalDatabaseCreator>();
        if (!await databaseCreator.ExistsAsync(cancellationToken))
        {
            await databaseCreator.CreateAsync(cancellationToken);
        }

        await dbContext.Database.ExecuteSqlRawAsync("""
IF OBJECT_ID('dbo.tbltrans_Users', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tbltrans_Users (
        Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_tbltrans_Users PRIMARY KEY,
        DisplayName NVARCHAR(120) NOT NULL,
        Email NVARCHAR(180) NOT NULL,
        PasswordHash NVARCHAR(500) NOT NULL,
        PreferredSourceLanguage NVARCHAR(12) NOT NULL,
        PreferredTargetLanguage NVARCHAR(12) NOT NULL,
        CreatedAt DATETIMEOFFSET NOT NULL,
        CONSTRAINT UX_tbltrans_Users_Email UNIQUE (Email)
    );
END
""", cancellationToken);

        await dbContext.Database.ExecuteSqlRawAsync("""
IF OBJECT_ID('dbo.tbltrans_CallSessions', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tbltrans_CallSessions (
        Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_tbltrans_CallSessions PRIMARY KEY,
        StartedByUserId UNIQUEIDENTIFIER NOT NULL,
        Status NVARCHAR(32) NOT NULL,
        StartedAt DATETIMEOFFSET NOT NULL,
        EndedAt DATETIMEOFFSET NULL
    );
END
""", cancellationToken);

        await dbContext.Database.ExecuteSqlRawAsync("""
IF OBJECT_ID('dbo.tbltrans_CallParticipants', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tbltrans_CallParticipants (
        Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_tbltrans_CallParticipants PRIMARY KEY,
        CallSessionId UNIQUEIDENTIFIER NOT NULL,
        UserId UNIQUEIDENTIFIER NOT NULL,
        SourceLanguage NVARCHAR(12) NOT NULL,
        TargetLanguage NVARCHAR(12) NOT NULL,
        JoinedAt DATETIMEOFFSET NOT NULL,
        LeftAt DATETIMEOFFSET NULL,
        CONSTRAINT FK_tbltrans_CallParticipants_CallSessions FOREIGN KEY (CallSessionId) REFERENCES dbo.tbltrans_CallSessions(Id),
        CONSTRAINT FK_tbltrans_CallParticipants_Users FOREIGN KEY (UserId) REFERENCES dbo.tbltrans_Users(Id)
    );
END
""", cancellationToken);

        await dbContext.Database.ExecuteSqlRawAsync("""
IF OBJECT_ID('dbo.tbltrans_TranslationLogs', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tbltrans_TranslationLogs (
        Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_tbltrans_TranslationLogs PRIMARY KEY,
        CallSessionId UNIQUEIDENTIFIER NOT NULL,
        SenderUserId UNIQUEIDENTIFIER NOT NULL,
        SourceLanguage NVARCHAR(12) NOT NULL,
        TargetLanguage NVARCHAR(12) NOT NULL,
        SourceText NVARCHAR(4000) NOT NULL,
        TranslatedText NVARCHAR(4000) NOT NULL,
        CreatedAt DATETIMEOFFSET NOT NULL,
        CONSTRAINT FK_tbltrans_TranslationLogs_CallSessions FOREIGN KEY (CallSessionId) REFERENCES dbo.tbltrans_CallSessions(Id),
        CONSTRAINT FK_tbltrans_TranslationLogs_Users FOREIGN KEY (SenderUserId) REFERENCES dbo.tbltrans_Users(Id)
    );
END
""", cancellationToken);

        await dbContext.Database.ExecuteSqlRawAsync("""
IF OBJECT_ID('dbo.tbltrans_Spaces', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tbltrans_Spaces (
        Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_tbltrans_Spaces PRIMARY KEY,
        Name NVARCHAR(150) NOT NULL,
        Code NVARCHAR(32) NOT NULL,
        Category NVARCHAR(50) NOT NULL,
        CreatedByUserId UNIQUEIDENTIFIER NOT NULL,
        CreatedAt DATETIMEOFFSET NOT NULL
    );
END
""", cancellationToken);

        await dbContext.Database.ExecuteSqlRawAsync("""
IF OBJECT_ID('dbo.tbltrans_SpaceMembers', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tbltrans_SpaceMembers (
        Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_tbltrans_SpaceMembers PRIMARY KEY,
        SpaceId UNIQUEIDENTIFIER NOT NULL,
        UserId UNIQUEIDENTIFIER NOT NULL,
        Role NVARCHAR(32) NOT NULL,
        JoinedAt DATETIMEOFFSET NOT NULL,
        CONSTRAINT FK_tbltrans_SpaceMembers_Spaces FOREIGN KEY (SpaceId) REFERENCES dbo.tbltrans_Spaces(Id)
    );
END
""", cancellationToken);

        await dbContext.Database.ExecuteSqlRawAsync("""
IF OBJECT_ID('dbo.tbltrans_Rooms', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tbltrans_Rooms (
        Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_tbltrans_Rooms PRIMARY KEY,
        Name NVARCHAR(150) NOT NULL,
        RoomType NVARCHAR(32) NOT NULL,
        Status NVARCHAR(32) NOT NULL,
        CreatedByUserId UNIQUEIDENTIFIER NOT NULL,
        CreatedAt DATETIMEOFFSET NOT NULL
    );
END
""", cancellationToken);

        await dbContext.Database.ExecuteSqlRawAsync("""
IF OBJECT_ID('dbo.tbltrans_RoomParticipants', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tbltrans_RoomParticipants (
        Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_tbltrans_RoomParticipants PRIMARY KEY,
        RoomId UNIQUEIDENTIFIER NOT NULL,
        UserId UNIQUEIDENTIFIER NOT NULL,
        IsMuted BIT NOT NULL DEFAULT 0,
        IsSpeaking BIT NOT NULL DEFAULT 0,
        JoinedAt DATETIMEOFFSET NOT NULL,
        CONSTRAINT FK_tbltrans_RoomParticipants_Rooms FOREIGN KEY (RoomId) REFERENCES dbo.tbltrans_Rooms(Id)
    );
END
""", cancellationToken);

        await dbContext.Database.ExecuteSqlRawAsync("""
IF OBJECT_ID('dbo.tbltrans_ChatMessages', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tbltrans_ChatMessages (
        Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_tbltrans_ChatMessages PRIMARY KEY,
        SenderUserId UNIQUEIDENTIFIER NOT NULL,
        RecipientUserId UNIQUEIDENTIFIER NOT NULL,
        Message NVARCHAR(4000) NOT NULL,
        CreatedAt DATETIMEOFFSET NOT NULL,
        CONSTRAINT FK_tbltrans_ChatMessages_Sender FOREIGN KEY (SenderUserId) REFERENCES dbo.tbltrans_Users(Id),
        CONSTRAINT FK_tbltrans_ChatMessages_Recipient FOREIGN KEY (RecipientUserId) REFERENCES dbo.tbltrans_Users(Id)
    );

    CREATE INDEX IX_tbltrans_ChatMessages_Sender_Recipient_CreatedAt
    ON dbo.tbltrans_ChatMessages (SenderUserId, RecipientUserId, CreatedAt);

    CREATE INDEX IX_tbltrans_ChatMessages_Recipient_Sender_CreatedAt
    ON dbo.tbltrans_ChatMessages (RecipientUserId, SenderUserId, CreatedAt);
END
""", cancellationToken);

        await dbContext.Database.ExecuteSqlRawAsync("""
CREATE OR ALTER PROCEDURE dbo.sp_trans_GetUsers
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, DisplayName, Email, PreferredSourceLanguage, PreferredTargetLanguage, CreatedAt
    FROM dbo.tbltrans_Users
    ORDER BY DisplayName;
END
""", cancellationToken);

        logger.LogInformation("Translation database objects are ready.");
    }
}
