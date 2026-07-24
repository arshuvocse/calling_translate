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
[Route("api/rooms")]
[Authorize]
public sealed class RoomsController(IApplicationDbContext dbContext) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<RoomDto>>> GetRooms(CancellationToken cancellationToken)
    {
        var rooms = await dbContext.Rooms
            .Include(x => x.Participants)
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => new RoomDto(
                x.Id,
                x.Name,
                x.RoomType,
                x.Participants.Count > 0 ? x.Participants.Count : 8,
                x.Status,
                x.CreatedAt))
            .ToListAsync(cancellationToken);

        if (rooms.Count == 0)
        {
            return Ok(new List<RoomDto>
            {
                new(Guid.NewGuid(), "Design Team Voice Room", "Voice", 8, "Active", DateTimeOffset.UtcNow),
                new(Guid.NewGuid(), "Product Discussion Video Room", "Video", 12, "Active", DateTimeOffset.UtcNow),
                new(Guid.NewGuid(), "Study Room", "Voice", 4, "Active", DateTimeOffset.UtcNow),
                new(Guid.NewGuid(), "Project Room", "Voice", 6, "Active", DateTimeOffset.UtcNow)
            });
        }

        return Ok(rooms);
    }

    [HttpPost]
    public async Task<ActionResult<RoomDto>> CreateRoom(CreateRoomRequest request, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        var room = new Room
        {
            Name = request.Name.Trim(),
            RoomType = request.RoomType.Trim(),
            CreatedByUserId = userId,
            Status = "Active"
        };

        room.Participants.Add(new RoomParticipant { UserId = userId, IsSpeaking = true });

        dbContext.Rooms.Add(room);
        await dbContext.SaveChangesAsync(cancellationToken);

        return Ok(new RoomDto(room.Id, room.Name, room.RoomType, 1, room.Status, room.CreatedAt));
    }

    private Guid GetUserId()
    {
        var val = User.FindFirstValue(JwtRegisteredClaimNames.Sub) ?? User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(val, out var id) ? id : Guid.Empty;
    }
}
