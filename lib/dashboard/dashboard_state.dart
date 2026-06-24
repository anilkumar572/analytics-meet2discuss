import '../models/dashboard_stats.dart';

abstract class DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardStats stats;
  final String userSortField;
  final bool userSortAscending;

  DashboardLoaded({
    required this.stats,
    this.userSortField = 'joinedDate',
    this.userSortAscending = false,
  });

  DashboardLoaded copyWith({
    DashboardStats? stats,
    String? userSortField,
    bool? userSortAscending,
  }) {
    return DashboardLoaded(
      stats: stats ?? this.stats,
      userSortField: userSortField ?? this.userSortField,
      userSortAscending: userSortAscending ?? this.userSortAscending,
    );
  }
}

class DashboardError extends DashboardState {
  final String errorMessage;

  DashboardError(this.errorMessage);
}
