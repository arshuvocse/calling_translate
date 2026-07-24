using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VoiceTranslator.Application.Abstractions;

namespace VoiceTranslator.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public sealed class UsersController(IApplicationDbContext dbContext) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetUsers(CancellationToken cancellationToken)
    {
        var users = await dbContext.Users
            .OrderBy(x => x.DisplayName)
            .Select(x => new
            {
                x.Id,
                x.DisplayName,
                x.Email,
                x.PreferredSourceLanguage,
                x.PreferredTargetLanguage
            })
            .ToListAsync(cancellationToken);

        return Ok(users);
    }
}
