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
[Authorize]
[Route("api/[controller]")]
public sealed class CallsController(IApplicationDbContext dbContext) : ControllerBase
{
    [HttpGet("sessions/incoming")]
    public async Task<ActionResult<IReadOnlyList<IncomingCallResponse>>> IncomingSessions(CancellationToken cancellationToken)
    {
        var userId = CurrentUserId();
        var sessions = await dbContext.CallSessions
            .AsNoTracking()
            .Include(x => x.Participants)
            .Where(x => x.Status == "ringing" && x.Participants.Any(p => p.UserId == userId))
            .OrderByDescending(x => x.StartedAt)
            .Take(5)
            .ToListAsync(cancellationToken);

        var callerIds = sessions.Select(x => x.StartedByUserId).Distinct().ToArray();
        var callers = await dbContext.Users
            .AsNoTracking()
            .Where(x => callerIds.Contains(x.Id))
            .ToDictionaryAsync(x => x.Id, cancellationToken);

        var response = sessions
            .Where(x => x.StartedByUserId != userId)
            .Select(x =>
            {
                var receiver = x.Participants.First(p => p.UserId == userId);
                callers.TryGetValue(x.StartedByUserId, out var caller);
                return new IncomingCallResponse(
                    x.Id,
                    x.StartedByUserId,
                    caller?.DisplayName ?? "Unknown caller",
                    receiver.SourceLanguage,
                    receiver.TargetLanguage);
            })
            .ToArray();

        return Ok(response);
    }

    [HttpPost("sessions")]
    public async Task<ActionResult<CallSessionResponse>> CreateSession(CreateCallSessionRequest request, CancellationToken cancellationToken)
    {
        if (request.StartedByUserId == Guid.Empty || request.ParticipantUserId == Guid.Empty)
            return BadRequest("Both users are required.");

        var session = new CallSession
        {
            StartedByUserId = request.StartedByUserId,
            Status = "live",
            Participants =
            [
                new CallParticipant
                {
                    UserId = request.StartedByUserId,
                    SourceLanguage = request.SourceLanguage,
                    TargetLanguage = request.TargetLanguage
                },
                new CallParticipant
                {
                    UserId = request.ParticipantUserId,
                    SourceLanguage = request.TargetLanguage,
                    TargetLanguage = request.SourceLanguage
                }
            ]
        };

        dbContext.CallSessions.Add(session);
        await dbContext.SaveChangesAsync(cancellationToken);
        return Ok(new CallSessionResponse(session.Id, session.Status));
    }

    [HttpPost("sessions/end")]
    public async Task<IActionResult> EndSession(EndCallRequest request, CancellationToken cancellationToken)
    {
        var session = await dbContext.CallSessions.FirstOrDefaultAsync(x => x.Id == request.CallSessionId, cancellationToken);
        if (session is null) return NotFound();

        session.Status = "ended";
        session.EndedAt = DateTimeOffset.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
        return Ok(new CallSessionResponse(session.Id, session.Status));
    }

    private Guid CurrentUserId()
    {
        var value = User.FindFirstValue(JwtRegisteredClaimNames.Sub)
            ?? User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(value, out var userId) ? userId : throw new UnauthorizedAccessException("Authenticated user id is missing.");
    }
}

public sealed record IncomingCallResponse(
    Guid CallSessionId,
    Guid CallerUserId,
    string CallerDisplayName,
    string SourceLanguage,
    string TargetLanguage);
