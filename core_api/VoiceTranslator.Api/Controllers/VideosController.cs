using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VoiceTranslator.Application.Abstractions;
using VoiceTranslator.Domain.Entities;

namespace VoiceTranslator.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class VideosController(IApplicationDbContext dbContext) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetVideos([FromQuery] string? type = null, [FromQuery] string? category = null, CancellationToken ct = default)
    {
        var query = dbContext.VideoItems.AsQueryable();

        if (!string.IsNullOrWhiteSpace(type))
        {
            query = query.Where(v => v.VideoType.ToLower() == type.ToLower());
        }

        if (!string.IsNullOrWhiteSpace(category) && !category.Equals("For You", StringComparison.OrdinalIgnoreCase))
        {
            query = query.Where(v => v.Category.ToLower() == category.ToLower());
        }

        var videos = await query
            .Include(v => v.Author)
            .OrderByDescending(v => v.CreatedAt)
            .Select(v => new
            {
                v.Id,
                v.Title,
                v.Description,
                v.VideoType,
                v.Category,
                v.VideoUrl,
                v.ThumbnailUrl,
                v.Duration,
                v.ViewsCount,
                v.LikesCount,
                v.CreatedAt,
                Author = v.Author != null ? v.Author.DisplayName : "Travel With Shuvo",
                AuthorAvatar = "https://i.pravatar.cc/150?img=3"
            })
            .ToListAsync(ct);

        return Ok(videos);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetVideoById(Guid id, CancellationToken ct = default)
    {
        var video = await dbContext.VideoItems
            .Include(v => v.Author)
            .Include(v => v.Comments)
            .FirstOrDefaultAsync(v => v.Id == id, ct);

        if (video == null) return NotFound();

        video.ViewsCount++;
        await dbContext.SaveChangesAsync(ct);

        return Ok(new
        {
            video.Id,
            video.Title,
            video.Description,
            video.VideoType,
            video.Category,
            video.VideoUrl,
            video.ThumbnailUrl,
            video.Duration,
            video.ViewsCount,
            video.LikesCount,
            video.CreatedAt,
            Author = video.Author != null ? video.Author.DisplayName : "Travel With Shuvo",
            Comments = video.Comments.Select(c => new { c.Id, c.CommentText, c.CreatedAt })
        });
    }

    [HttpPost]
    public async Task<IActionResult> CreateVideo([FromBody] CreateVideoRequest request, CancellationToken ct = default)
    {
        var author = await dbContext.Users.FirstOrDefaultAsync(u => u.Id == request.AuthorId, ct);
        if (author == null)
        {
            author = await dbContext.Users.FirstOrDefaultAsync(ct);
        }

        var video = new VideoItem
        {
            AuthorId = author?.Id ?? Guid.NewGuid(),
            Title = request.Title,
            Description = request.Description,
            VideoType = request.VideoType ?? "Quick",
            Category = request.Category ?? "For You",
            VideoUrl = request.VideoUrl ?? "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
            ThumbnailUrl = request.ThumbnailUrl ?? "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=600&q=80",
            Duration = request.Duration ?? "00:30",
            ViewsCount = 1,
            LikesCount = 0
        };

        dbContext.VideoItems.Add(video);
        await dbContext.SaveChangesAsync(ct);

        return CreatedAtAction(nameof(GetVideoById), new { id = video.Id }, video);
    }

    [HttpPost("{id:guid}/like")]
    public async Task<IActionResult> LikeVideo(Guid id, CancellationToken ct = default)
    {
        var video = await dbContext.VideoItems.FindAsync(new object[] { id }, ct);
        if (video == null) return NotFound();

        video.LikesCount++;
        await dbContext.SaveChangesAsync(ct);

        return Ok(new { video.Id, video.LikesCount });
    }
}

public record CreateVideoRequest(
    Guid AuthorId,
    string Title,
    string? Description,
    string? VideoType,
    string? Category,
    string? VideoUrl,
    string? ThumbnailUrl,
    string? Duration
);
