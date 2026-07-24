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
    DbSet<Space> Spaces { get; }
    DbSet<SpaceMember> SpaceMembers { get; }
    DbSet<Room> Rooms { get; }
    DbSet<RoomParticipant> RoomParticipants { get; }
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
