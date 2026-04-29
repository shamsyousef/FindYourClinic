import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';


import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/doctor_search_entities.dart';
import '../cubits/search_cubit.dart';
import '../cubits/search_state.dart';
import '../widgets/doctor_list_tile.dart';
import '../widgets/filter_bottom_sheet.dart';

class SearchScreen extends StatefulWidget {
  final String? initialSpecialtyId;

  const SearchScreen({super.key, this.initialSpecialtyId});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final filters = widget.initialSpecialtyId != null
        ? SearchFilters(specialtyId: widget.initialSpecialtyId)
        : const SearchFilters();
    context.read<SearchCubit>().search(filters);

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SearchCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final cubit = context.read<SearchCubit>();
      final currentFilters = switch (cubit.state) {
        SearchLoaded(:final filters) => filters,
        _ => const SearchFilters(),
      };
      cubit.search(currentFilters.copyWith(name: query.trim(), page: 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Doctor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Filters',
            onPressed: () => _showFilters(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by doctor name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<SearchCubit, SearchState>(
              builder: (context, state) => switch (state) {
          SearchInitial() || SearchLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
          SearchError(:final message) => ErrorView(
              message: message,
              onRetry: () => context.read<SearchCubit>().search(),
            ),
          SearchLoaded(result: final result) ||
          SearchLoadingMore(currentResult: final result) =>
            result.items.isEmpty
                ? const EmptyStateView(
                    icon: Icons.search_off,
                    title: 'No Doctors Found',
                    subtitle:
                        'Try adjusting your filters or search in a different area.',
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: result.items.length + (state is SearchLoadingMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index >= result.items.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      final doctor = result.items[index];
                      return DoctorListTile(
                        doctor: doctor,
                        onTap: () => context.pushNamed(
                          'doctorDetails',
                          pathParameters: {'id': doctor.doctorId},
                        ),
                      );
                    },
                  ),
            },
          ),
        ),
      ],
    ),
  );
}

  void _showFilters(BuildContext context) {
    final cubit = context.read<SearchCubit>();
    final currentFilters = switch (cubit.state) {
      SearchLoaded(:final filters) => filters,
      _ => const SearchFilters(),
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FilterBottomSheet(
        currentFilters: currentFilters,
        onApply: (filters) {
          cubit.applyFilters(filters);
          Navigator.pop(context);
        },
      ),
    );
  }
}
