namespace VoiceTranslator.Application.Dtos;

public sealed record ActiveUserDto(
    Guid Id,
    string DisplayName,
    string PreferredSourceLanguage,
    string PreferredTargetLanguage,
    bool IsOnline);

public sealed record DashboardSummaryDto(
    int TotalActiveUsers,
    int ActiveRoomsCount,
    int TotalSpacesCount,
    IReadOnlyList<ActiveUserDto> ActiveUsers);
