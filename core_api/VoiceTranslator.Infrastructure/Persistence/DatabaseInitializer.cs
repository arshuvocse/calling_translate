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
CREATE OR ALTER PROCEDURE dbo.sp_trans_GetUsers
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, DisplayName, Email, PreferredSourceLanguage, PreferredTargetLanguage, CreatedAt
    FROM dbo.tbltrans_Users
    ORDER BY DisplayName;
END
""", cancellationToken);

        await dbContext.Database.ExecuteSqlRawAsync("""
CREATE OR ALTER PROCEDURE dbo.sp_trans_GetTranslationLogsByCallSession
    @CallSessionId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, CallSessionId, SenderUserId, SourceLanguage, TargetLanguage, SourceText, TranslatedText, CreatedAt
    FROM dbo.tbltrans_TranslationLogs
    WHERE CallSessionId = @CallSessionId
    ORDER BY CreatedAt;
END
""", cancellationToken);

        logger.LogInformation("Translation database objects are ready.");
    }
}
