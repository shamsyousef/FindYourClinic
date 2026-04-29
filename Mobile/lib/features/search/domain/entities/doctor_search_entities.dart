// Domain entities for doctor search.
// Pure Dart — no Flutter imports.

class DoctorSearchResult {
  final String doctorId;
  final String doctorProfileId;
  final String fullName;
  final String specialty;
  final String? profileImageUrl;
  final String? clinicName;
  final String? clinicAddress;
  final double? latitude;
  final double? longitude;
  final double consultationFee;
  final int experienceYears;
  final String? bio;
  final double avgRating;
  final int reviewsCount;
  final double? distanceKm;
  final DateTime? nextAvailableSlot;

  const DoctorSearchResult({
    required this.doctorId,
    required this.doctorProfileId,
    required this.fullName,
    required this.specialty,
    this.profileImageUrl,
    this.clinicName,
    this.clinicAddress,
    this.latitude,
    this.longitude,
    required this.consultationFee,
    required this.experienceYears,
    this.bio,
    required this.avgRating,
    required this.reviewsCount,
    this.distanceKm,
    this.nextAvailableSlot,
  });
}

class SearchFilters {
  final String? name;
  final String? specialtyId;
  final double? lat;
  final double? lng;
  final double? radiusKm;
  final double? minRating;
  final double? maxFee;
  final double? minFee;
  final String? sortBy;
  final int page;
  final int pageSize;

  const SearchFilters({
    this.name,
    this.specialtyId,
    this.lat,
    this.lng,
    this.radiusKm,
    this.minRating,
    this.maxFee,
    this.minFee,
    this.sortBy,
    this.page = 1,
    this.pageSize = 15,
  });

  SearchFilters copyWith({
    String? name,
    String? specialtyId,
    double? lat,
    double? lng,
    double? radiusKm,
    double? minRating,
    double? maxFee,
    double? minFee,
    String? sortBy,
    int? page,
    int? pageSize,
  }) {
    return SearchFilters(
      name: name ?? this.name,
      specialtyId: specialtyId ?? this.specialtyId,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      radiusKm: radiusKm ?? this.radiusKm,
      minRating: minRating ?? this.minRating,
      maxFee: maxFee ?? this.maxFee,
      minFee: minFee ?? this.minFee,
      sortBy: sortBy ?? this.sortBy,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  Map<String, String> toQueryParameters() {
    final params = <String, String>{};
    if (name != null && name!.isNotEmpty) params['name'] = name!;
    if (specialtyId != null) params['specialtyId'] = specialtyId!;
    if (lat != null) params['lat'] = lat.toString();
    if (lng != null) params['lng'] = lng.toString();
    if (radiusKm != null) params['radiusKm'] = radiusKm.toString();
    if (minRating != null) params['minRating'] = minRating.toString();
    if (maxFee != null) params['maxFee'] = maxFee.toString();
    if (minFee != null) params['minFee'] = minFee.toString();
    if (sortBy != null) params['sortBy'] = sortBy!;
    params['page'] = page.toString();
    params['pageSize'] = pageSize.toString();
    return params;
  }
}

class PaginatedDoctors {
  final List<DoctorSearchResult> items;
  final int page;
  final int pageSize;
  final int totalCount;

  const PaginatedDoctors({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
  });

  bool get hasMore => page * pageSize < totalCount;
}
