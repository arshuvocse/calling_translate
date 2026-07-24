using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using VoiceTranslator.Application.Abstractions;
using VoiceTranslator.Application.Dtos;
using VoiceTranslator.Application.Services;
using VoiceTranslator.Domain.Entities;

namespace VoiceTranslator.Api.Hubs;

[Authorize]
public sealed class CallHub(IApplicationDbContext dbContext, LiveTranslationProcessor translationProcessor) : Hub
{
    public override async Task OnConnectedAsync()
    {
        var userId = CurrentUserId();
        await Groups.AddToGroupAsync(Context.ConnectionId, UserGroup(userId));
        await base.OnConnectedAsync();
    }

    public async Task<StartCallResponse> StartCall(StartCallRequest request)
    {
        var callerUserId = CurrentUserId();
        if (request.CalleeUserId == Guid.Empty || callerUserId == request.CalleeUserId)
            throw new HubException("A different callee user is required.");

        var session = new CallSession
        {
            StartedByUserId = callerUserId,
            Status = "ringing",
            Participants =
            [
                new CallParticipant
                {
                    UserId = callerUserId,
                    SourceLanguage = request.SourceLanguage,
                    TargetLanguage = request.TargetLanguage
                },
                new CallParticipant
                {
                    UserId = request.CalleeUserId,
                    SourceLanguage = request.CalleeSourceLanguage,
                    TargetLanguage = request.CalleeTargetLanguage
                }
            ]
        };

        dbContext.CallSessions.Add(session);
        await dbContext.SaveChangesAsync(Context.ConnectionAborted);

        var incoming = new IncomingCallMessage(
            session.Id,
            callerUserId,
            request.CallerDisplayName,
            request.CalleeSourceLanguage,
            request.CalleeTargetLanguage);

        await Clients.Group(UserGroup(request.CalleeUserId)).SendAsync("IncomingCall", incoming, Context.ConnectionAborted);
        return new StartCallResponse(session.Id, "ringing");
    }

    public async Task AcceptCall(Guid callSessionId)
    {
        var userId = CurrentUserId();
        var session = await LoadSession(callSessionId);
        EnsureParticipant(session, userId);
        session.Status = "live";
        await dbContext.SaveChangesAsync(Context.ConnectionAborted);

        await Clients.Groups(UserGroups(session)).SendAsync("CallAccepted", new CallStatusMessage(callSessionId, "live"), Context.ConnectionAborted);
    }

    public async Task RejectCall(Guid callSessionId)
    {
        var userId = CurrentUserId();
        var session = await LoadSession(callSessionId);
        EnsureParticipant(session, userId);
        session.Status = "rejected";
        session.EndedAt = DateTimeOffset.UtcNow;
        await dbContext.SaveChangesAsync(Context.ConnectionAborted);

        await Clients.Groups(UserGroups(session)).SendAsync("CallRejected", new CallStatusMessage(callSessionId, "rejected"), Context.ConnectionAborted);
    }

    public async Task SendOffer(WebRtcSignalMessage message) => await RelaySignal("ReceiveOffer", message);

    public async Task SendAnswer(WebRtcSignalMessage message) => await RelaySignal("ReceiveAnswer", message);

    public async Task SendIceCandidate(IceCandidateSignalMessage message) => await RelaySignal("ReceiveIceCandidate", message);

    public async Task SendAudioChunk(LiveAudioRequest request)
    {
        var senderUserId = CurrentUserId();
        if (request.SenderUserId != senderUserId)
            throw new HubException("Audio sender does not match the authenticated user.");

        var session = await LoadSession(request.CallSessionId);
        var recipient = OtherParticipant(session, senderUserId);
        var response = await translationProcessor.ProcessAsync(request, Context.ConnectionAborted);
        var message = new TranslatedAudioMessage(
            request.CallSessionId,
            senderUserId,
            response.TranslatedText,
            response.TranslatedAudioBase64);

        await Clients.Group(UserGroup(recipient.UserId)).SendAsync("TranslationReceived", message, Context.ConnectionAborted);
    }

    public async Task<IReadOnlyList<ChatMessageDto>> GetChatHistory(Guid otherUserId)
    {
        var userId = CurrentUserId();
        if (otherUserId == Guid.Empty || userId == otherUserId)
            throw new HubException("A different chat user is required.");

        var messages = await dbContext.ChatMessages
            .Where(x =>
                (x.SenderUserId == userId && x.RecipientUserId == otherUserId)
                || (x.SenderUserId == otherUserId && x.RecipientUserId == userId))
            .OrderByDescending(x => x.CreatedAt)
            .Take(100)
            .OrderBy(x => x.CreatedAt)
            .Select(x => new ChatMessageDto(x.Id, x.SenderUserId, x.RecipientUserId, x.Message, x.CreatedAt))
            .ToListAsync(Context.ConnectionAborted);

        return messages;
    }

    public async Task<ChatMessageDto> SendChatMessage(SendChatMessageRequest request)
    {
        var senderUserId = CurrentUserId();
        if (request.RecipientUserId == Guid.Empty || senderUserId == request.RecipientUserId)
            throw new HubException("A different recipient user is required.");

        var text = request.Message.Trim();
        if (text.Length == 0)
            throw new HubException("Message is required.");
        if (text.Length > 4000)
            throw new HubException("Message is too long.");

        var recipientExists = await dbContext.Users.AnyAsync(x => x.Id == request.RecipientUserId, Context.ConnectionAborted);
        if (!recipientExists)
            throw new HubException("Recipient user was not found.");

        var message = new ChatMessage
        {
            SenderUserId = senderUserId,
            RecipientUserId = request.RecipientUserId,
            Message = text
        };

        dbContext.ChatMessages.Add(message);
        await dbContext.SaveChangesAsync(Context.ConnectionAborted);

        var dto = new ChatMessageDto(message.Id, message.SenderUserId, message.RecipientUserId, message.Message, message.CreatedAt);
        await Clients.Group(UserGroup(request.RecipientUserId)).SendAsync("ChatMessageReceived", dto, Context.ConnectionAborted);
        await Clients.Group(UserGroup(senderUserId)).SendAsync("ChatMessageReceived", dto, Context.ConnectionAborted);
        return dto;
    }

    public async Task EndCall(Guid callSessionId)
    {
        var userId = CurrentUserId();
        var session = await LoadSession(callSessionId);
        EnsureParticipant(session, userId);

        session.Status = "ended";
        session.EndedAt = DateTimeOffset.UtcNow;
        foreach (var participant in session.Participants.Where(x => x.LeftAt is null))
            participant.LeftAt = DateTimeOffset.UtcNow;

        await dbContext.SaveChangesAsync(Context.ConnectionAborted);
        await Clients.Groups(UserGroups(session)).SendAsync("CallEnded", new CallStatusMessage(callSessionId, "ended"), Context.ConnectionAborted);
    }

    private async Task RelaySignal<T>(string methodName, T message) where T : ICallSignal
    {
        var senderUserId = CurrentUserId();
        var session = await LoadSession(message.CallSessionId);
        var recipient = OtherParticipant(session, senderUserId);
        await Clients.Group(UserGroup(recipient.UserId)).SendAsync(methodName, message, Context.ConnectionAborted);
    }

    private async Task<CallSession> LoadSession(Guid callSessionId)
    {
        var session = await dbContext.CallSessions
            .Include(x => x.Participants)
            .FirstOrDefaultAsync(x => x.Id == callSessionId, Context.ConnectionAborted);

        return session ?? throw new HubException("Call session was not found.");
    }

    private static CallParticipant EnsureParticipant(CallSession session, Guid userId) =>
        session.Participants.FirstOrDefault(x => x.UserId == userId)
        ?? throw new HubException("User is not a participant in this call.");

    private static CallParticipant OtherParticipant(CallSession session, Guid senderUserId)
    {
        EnsureParticipant(session, senderUserId);
        return session.Participants.FirstOrDefault(x => x.UserId != senderUserId)
            ?? throw new HubException("No remote participant is available.");
    }

    private Guid CurrentUserId()
    {
        var value = Context.User?.FindFirstValue(JwtRegisteredClaimNames.Sub)
            ?? Context.User?.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(value, out var userId) ? userId : throw new HubException("Authenticated user id is missing.");
    }

    private static IReadOnlyList<string> UserGroups(CallSession session) =>
        session.Participants.Select(x => UserGroup(x.UserId)).Distinct().ToArray();

    private static string UserGroup(Guid userId) => $"user:{userId:N}";
}

public sealed record StartCallRequest(
    Guid CalleeUserId,
    string CallerDisplayName,
    string SourceLanguage,
    string TargetLanguage,
    string CalleeSourceLanguage,
    string CalleeTargetLanguage);

public sealed record StartCallResponse(Guid CallSessionId, string Status);

public sealed record IncomingCallMessage(
    Guid CallSessionId,
    Guid CallerUserId,
    string CallerDisplayName,
    string SourceLanguage,
    string TargetLanguage);

public sealed record CallStatusMessage(Guid CallSessionId, string Status);

public interface ICallSignal
{
    Guid CallSessionId { get; }
}

public sealed record WebRtcSignalMessage(Guid CallSessionId, string Type, string Sdp) : ICallSignal;

public sealed record IceCandidateSignalMessage(
    Guid CallSessionId,
    string Candidate,
    string? SdpMid,
    int? SdpMLineIndex) : ICallSignal;

public sealed record TranslatedAudioMessage(
    Guid CallSessionId,
    Guid SenderUserId,
    string TranslatedText,
    string TranslatedAudioBase64);

public sealed record SendChatMessageRequest(Guid RecipientUserId, string Message);

public sealed record ChatMessageDto(
    Guid Id,
    Guid SenderUserId,
    Guid RecipientUserId,
    string Message,
    DateTimeOffset CreatedAt);
