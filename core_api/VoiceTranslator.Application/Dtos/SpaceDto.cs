namespace VoiceTranslator.Application.Dtos;

public sealed record SpaceDto(
    Guid Id,
    string Name,
    string Code,
    string Category,
    int MemberCount,
    int OnlineCount,
    DateTimeOffset CreatedAt);

public sealed record CreateSpaceRequest(
    string Name,
    string Category);

public sealed record JoinSpaceRequest(
    string Code);
