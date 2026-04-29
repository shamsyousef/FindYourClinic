import '../../../../core/network/api_client.dart';
import '../models/availability_config_model.dart';

/// Maps day name strings to C# DayOfWeek integer values:
/// Sunday=0, Monday=1, Tuesday=2, Wednesday=3, Thursday=4, Friday=5, Saturday=6
const _dayOfWeekMap = {
  'Sunday': 0,
  'Monday': 1,
  'Tuesday': 2,
  'Wednesday': 3,
  'Thursday': 4,
  'Friday': 5,
  'Saturday': 6,
};

abstract class DoctorAvailabilityRemoteDataSource {
  Future<List<AvailabilityConfigModel>> getMyAvailability();

  Future<AvailabilityConfigModel> addAvailability({
    required String dayOfWeek,
    required String startTime,
    required String endTime,
  });

  Future<void> removeAvailability(String id);
}

class DoctorAvailabilityRemoteDataSourceImpl
    implements DoctorAvailabilityRemoteDataSource {
  final ApiClient _apiClient;

  DoctorAvailabilityRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<List<AvailabilityConfigModel>> getMyAvailability() async {
    final response = await _apiClient.dio.get('/api/doctors/availability/me');
    final data = response.data['data'] as List;
    return data.map((e) => AvailabilityConfigModel.fromJson(e)).toList();
  }

  @override
  Future<AvailabilityConfigModel> addAvailability({
    required String dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    // C# DayOfWeek is an integer enum: Sunday=0, Monday=1 ... Saturday=6
    final dayInt = _dayOfWeekMap[dayOfWeek] ?? 1;
    final response = await _apiClient.dio.post(
      '/api/doctors/availability',
      data: {
        'dayOfWeek': dayInt,
        'startTime': startTime,
        'endTime': endTime,
        'isActive': true,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return AvailabilityConfigModel.fromJson(data);
  }

  @override
  Future<void> removeAvailability(String id) async {
    // Send PUT with IsActive = false. Backend validates start < end,
    // so we pass a minimal valid window (00:00 – 00:01) alongside IsActive=false.
    await _apiClient.dio.put(
      '/api/doctors/availability/$id',
      data: {
        'dayOfWeek': 0,
        'startTime': '00:00:00',
        'endTime': '00:01:00',
        'isActive': false,
      },
    );
  }
}
