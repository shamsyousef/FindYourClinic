import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/token_storage.dart';
import 'home_highlights_state.dart';

class HomeHighlightsCubit extends Cubit<HomeHighlightsState> {
  final TokenStorage _tokenStorage;

  HomeHighlightsCubit({required TokenStorage tokenStorage})
      : _tokenStorage = tokenStorage,
        super(const HomeHighlightsInitial());

  Future<void> checkVisibility() async {
    if (state is! HomeHighlightsInitial) return;
    emit(const HomeHighlightsLoading());
    try {
      final hasSeen = await _tokenStorage.hasSeenHomeHighlights();
      if (hasSeen) {
        emit(const HomeHighlightsHidden());
      } else {
        emit(const HomeHighlightsVisible());
      }
    } catch (_) {
      emit(const HomeHighlightsHidden());
    }
  }

  Future<void> markAsSeen() async {
    try {
      await _tokenStorage.setHomeHighlightsSeen();
    } catch (_) {
      // Ignore — UI still dismisses.
    }
    emit(const HomeHighlightsHidden());
  }
}
