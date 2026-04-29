import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../search/domain/entities/doctor_search_entities.dart';
import '../cubits/nearby_clinics_cubit.dart';
import '../cubits/nearby_clinics_state.dart';

class NearbyClinicsScreen extends StatefulWidget {
  const NearbyClinicsScreen({super.key});

  @override
  State<NearbyClinicsScreen> createState() => _NearbyClinicsScreenState();
}

class _NearbyClinicsScreenState extends State<NearbyClinicsScreen> {
  DoctorSearchResult? _selectedClinic;

  @override
  void initState() {
    super.initState();
    context.read<NearbyClinicsCubit>().loadNearbyClinics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Clinics')),
      body: BlocBuilder<NearbyClinicsCubit, NearbyClinicsState>(
        builder: (context, state) => switch (state) {
          NearbyClinicsInitial() || NearbyClinicsLoading() => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Finding nearby clinics...'),
                ],
              ),
            ),
          NearbyClinicsError(:final message) => ErrorView(
              message: message,
              onRetry: () =>
                  context.read<NearbyClinicsCubit>().loadNearbyClinics(),
            ),
          NearbyClinicsLoaded(:final clinics, :final lat, :final lng) => Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(lat, lng),
                    initialZoom: 13,
                    onTap: (_, p) => setState(() => _selectedClinic = null),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.findyourclinic.app',
                    ),
                    MarkerLayer(
                      markers: [
                        // User location marker
                        Marker(
                          point: LatLng(lat, lng),
                          width: 30,
                          height: 30,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary.withAlpha(80),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Clinic markers
                        ..._buildClinicMarkers(clinics),
                      ],
                    ),
                  ],
                ),
                // Selected Clinic Card
                if (_selectedClinic != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: _ClinicCard(
                      clinic: _selectedClinic!,
                      onTap: () => context.pushNamed(
                        'doctorDetails',
                        pathParameters: {'id': _selectedClinic!.doctorId},
                      ),
                    ),
                  ),
              ],
            ),
        },
      ),
    );
  }

  List<Marker> _buildClinicMarkers(List<DoctorSearchResult> clinics) {
    return clinics
        .where((c) => c.latitude != null && c.longitude != null)
        .map(
          (clinic) => Marker(
            point: LatLng(clinic.latitude!, clinic.longitude!),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => setState(() => _selectedClinic = clinic),
              child: const Icon(
                Icons.local_hospital,
                color: AppColors.primary,
                size: 36,
              ),
            ),
          ),
        )
        .toList();
  }
}

class _ClinicCard extends StatelessWidget {
  final DoctorSearchResult clinic;
  final VoidCallback onTap;

  const _ClinicCard({required this.clinic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withAlpha(20),
              child: const Icon(Icons.local_hospital,
                  color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Dr. ${clinic.fullName}', style: AppTextStyles.label),
                  Text(clinic.specialty,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: AppColors.starRating, size: 14),
                      const SizedBox(width: 3),
                      Text(
                          '${clinic.avgRating.toStringAsFixed(1)} · ${clinic.distanceKm?.toStringAsFixed(1) ?? "?"} km',
                          style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${clinic.consultationFee.toStringAsFixed(0)}',
                  style: AppTextStyles.heading3.copyWith(color: AppColors.primary),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: AppColors.textHint),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
