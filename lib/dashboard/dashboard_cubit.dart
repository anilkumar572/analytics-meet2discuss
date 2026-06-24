import 'package:flutter_bloc/flutter_bloc.dart';
import 'dashboard_state.dart';
import 'analytics_service.dart';
import '../models/dashboard_stats.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final AnalyticsService _analyticsService;

  DashboardCubit(this._analyticsService) : super(DashboardLoading());

  Future<void> loadDashboard() async {
    emit(DashboardLoading());
    try {
      final stats = await _analyticsService.fetchDashboardStats();
      emit(DashboardLoaded(stats: stats));
    } catch (e) {
      emit(DashboardError('Failed to load dashboard: $e'));
    }
  }

  void sortUsers(String field) {
    final currentState = state;
    if (currentState is DashboardLoaded) {
      final stats = currentState.stats;
      final bool isAscending = currentState.userSortField == field
          ? !currentState.userSortAscending
          : true;

      final List<RecentUser> sortedUsers = List.from(stats.recentUsers);
      sortedUsers.sort((a, b) {
        int cmp = 0;
        if (field == 'name') {
          cmp = a.name.compareTo(b.name);
        } else if (field == 'city') {
          cmp = a.city.compareTo(b.city);
        } else if (field == 'joinedDate') {
          cmp = a.joinedDate.compareTo(b.joinedDate);
        }
        return isAscending ? cmp : -cmp;
      });

      final newStats = DashboardStats(
        totalMembers: stats.totalMembers,
        totalOpportunities: stats.totalOpportunities,
        totalParticipants: stats.totalParticipants,
        totalConversations: stats.totalConversations,
        totalMessages: stats.totalMessages,
        totalNotifications: stats.totalNotifications,
        totalSavedOpportunities: stats.totalSavedOpportunities,
        totalBlockedUsers: stats.totalBlockedUsers,
        totalUserReports: stats.totalUserReports,
        avgMessagesPerConversation: stats.avgMessagesPerConversation,
        avgParticipantsPerOpportunity: stats.avgParticipantsPerOpportunity,
        totalConversationMembers: stats.totalConversationMembers,
        recentUsers: sortedUsers,
        recentOpportunities: stats.recentOpportunities,
        recentConversations: stats.recentConversations,
        memberGrowth: stats.memberGrowth,
        opportunityGrowth: stats.opportunityGrowth,
        conversationGrowth: stats.conversationGrowth,
      );

      emit(currentState.copyWith(
        stats: newStats,
        userSortField: field,
        userSortAscending: isAscending,
      ));
    }
  }
}
