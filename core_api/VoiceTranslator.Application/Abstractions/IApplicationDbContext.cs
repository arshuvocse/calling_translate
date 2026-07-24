using Microsoft.EntityFrameworkCore;
using VoiceTranslator.Domain.Entities;

namespace VoiceTranslator.Application.Abstractions;

public interface IApplicationDbContext
{
    DbSet<AppUser> Users { get; }
    DbSet<CallSession> CallSessions { get; }
    DbSet<CallParticipant> CallParticipants { get; }
    DbSet<TranslationLog> TranslationLogs { get; }
    DbSet<ChatMessage> ChatMessages { get; }
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
