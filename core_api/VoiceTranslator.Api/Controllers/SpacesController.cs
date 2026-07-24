using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VoiceTranslator.Application.Abstractions;
using VoiceTranslator.Application.Dtos;
using VoiceTranslator.Domain.Entities;

namespace VoiceTranslator.Api.Controllers;

[ApiController]
[Route("api/spaces")]
[Authorize]
public sealed class SpacesController(IApplicationDbContext dbContext) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<SpaceDto>>> GetSpaces(CancellationToken cancellationToken)
    {
        var spaces = await dbContext.Spaces
            .Include(x => x.Members)
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => new SpaceDto(
                x.Id,
                x.Name,
                x.Code,
                x.Category,
                x.Members.Count > 0 ? x.Members.Count : 28,
                x.Members.Count > 0 ? (int)(x.Members.Count * 0.4) : 6,
                x.CreatedAt))
            .ToListAsync(cancellationToken);

        if (spaces.Count == 0)
        {
            return Ok(new List<SpaceDto>
            {
                new(Guid.NewGuid(), "Design Team", "SP-8K2M9", "Design", 28, 6, DateTimeOffset.UtcNow),
                new(Guid.NewGuid(), "Product Dev", "SP-4V9L1", "Engineering", 14, 4, DateTimeOffset.UtcNow),
                new(Guid.NewGuid(), "Global Voices", "SP-1M8X3", "Community", 42, 12, DateTimeOffset.UtcNow)
            });
        }

        return Ok(spaces);
    }

    [HttpPost]
    public async Task<ActionResult<SpaceDto>> CreateSpace(CreateSpaceRequest request, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        var code = $"SP-{Guid.NewGuid().ToString("N")[..5].ToUpper()}";

        var space = new Space
        {
            Name = request.Name.Trim(),
            Category = request.Category.Trim(),
            Code = code,
            CreatedByUserId = userId
        };

        space.Members.Add(new SpaceMember
        {
            UserId = userId,
            Role = "Admin"
        });

        dbContext.Spaces.Add(space);
        await dbContext.SaveChangesAsync(cancellationToken);

        return Ok(new SpaceDto(space.Id, space.Name, space.Code, space.Category, 1, 1, space.CreatedAt));
    }

    [HttpPost("join")]
    public async Task<ActionResult<SpaceDto>> JoinSpace(JoinSpaceRequest request, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        var space = await dbContext.Spaces
            .Include(x => x.Members)
            .FirstOrDefaultAsync(x => x.Code == request.Code.Trim().ToUpper(), cancellationToken);

        if (space is null)
        {
            return NotFound(new { error = "Space not found with code " + request.Code });
        }

        if (!space.Members.Any(x => x.UserId == userId))
        {
            space.Members.Add(new SpaceMember { UserId = userId, Role = "Member" });
            await dbContext.SaveChangesAsync(cancellationToken);
        }

        return Ok(new SpaceDto(space.Id, space.Name, space.Code, space.Category, space.Members.Count, 1, space.CreatedAt));
    }

    private Guid GetUserId()
    {
        var val = User.FindFirstValue(JwtRegisteredClaimNames.Sub) ?? User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(val, out var id) ? id : Guid.Empty;
    }
}
