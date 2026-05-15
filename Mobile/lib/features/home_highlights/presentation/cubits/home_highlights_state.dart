import 'package:equatable/equatable.dart';

sealed class HomeHighlightsState extends Equatable {
  const HomeHighlightsState();

  @override
  List<Object> get props => [];
}

class HomeHighlightsInitial extends HomeHighlightsState {
  const HomeHighlightsInitial();
}

class HomeHighlightsLoading extends HomeHighlightsState {
  const HomeHighlightsLoading();
}

class HomeHighlightsHidden extends HomeHighlightsState {
  const HomeHighlightsHidden();
}

class HomeHighlightsVisible extends HomeHighlightsState {
  const HomeHighlightsVisible();
}
