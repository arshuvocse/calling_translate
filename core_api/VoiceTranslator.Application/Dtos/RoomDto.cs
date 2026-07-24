namespace VoiceTranslator.Application.Dtos;

public sealed record RoomDto(
    Guid Id,
    string Name,
    string RoomType, // Voice, Video
    int ActiveParticipantCount,
    string Status,
    DateTimeOffset CreatedAt);

public sealed record CreateRoomRequest(
    string Name,
    string RoomType);
