using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VoiceTranslator.Application.Abstractions;
using VoiceTranslator.Application.Dtos;

namespace VoiceTranslator.Api.Controllers;

[ApiController]
[Route("api/dashboard")]
[Authorize]
public sealed class DashboardController(IApplicationDbContext dbContext) : ControllerBase
{
    [HttpGet("galaxy")]
    public async Task<ActionResult<DashboardSummaryDto>> GetGalaxySummary(CancellationToken cancellationToken)
    {
        var users = await dbContext.Users
            .OrderByDescending(x => x.CreatedAt)
            .Take(10)
            .Select(x => new ActiveUserDto(
                x.Id,
                x.DisplayName,
                x.PreferredSourceLanguage,
                x.PreferredTargetLanguage,
                true))
            .ToListAsync(cancellationToken);

        var activeRoomsCount = await dbContext.Rooms.CountAsync(x => x.Status == "Active", cancellationToken);
        var totalSpacesCount = await dbContext.Spaces.CountAsync(cancellationToken);

        var summary = new DashboardSummaryDto(
            users.Count,
            activeRoomsCount > 0 ? activeRoomsCount : 4,
            totalSpacesCount > 0 ? totalSpacesCount : 3,
            users);

        return Ok(summary);
    }
}
