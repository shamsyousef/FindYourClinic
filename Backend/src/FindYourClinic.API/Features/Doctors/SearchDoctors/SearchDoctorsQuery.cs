using FindYourClinic.API.Features.Doctors.Shared;
using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Doctors.SearchDoctors;

public class SearchDoctorsQuery : IRequest<ApiResponse<PaginatedResponse<DoctorSearchDto>>>
{
    public Guid? SpecialtyId { get; set; }
    public double? Lat { get; set; }
    public double? Lng { get; set; }
    public double? RadiusKm { get; set; }
    public double? MinRating { get; set; }
    public decimal? MaxFee { get; set; }
    public decimal? MinFee { get; set; }
    public string? Availability { get; set; }
    public string? SortBy { get; set; }
    public int? Page { get; set; }
    public int? PageSize { get; set; }
}
