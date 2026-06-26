using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Admin.GetUsers;

public class GetUsersQuery : IRequest<ApiResponse<PagedUsersDto>>
{
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

public class UserDto
{
    public Guid Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public Guid? DoctorId { get; set; }
}

public sealed record PagedUsersDto(
    List<UserDto> Items,
    int Page,
    int PageSize,
    int TotalCount);
