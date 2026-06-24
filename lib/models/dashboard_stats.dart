class DashboardStats {
  final int totalMembers;
  final int totalOpportunities;
  final int totalParticipants;
  final int totalConversations;
  final int totalMessages;
  final int totalNotifications;
  final int totalSavedOpportunities;
  final int totalBlockedUsers;
  final int totalUserReports;

  // Engagement Metrics
  final double avgMessagesPerConversation;
  final double avgParticipantsPerOpportunity;
  final int totalConversationMembers;

  // Recent data
  final List<RecentUser> recentUsers;
  final List<RecentOpportunity> recentOpportunities;
  final List<RecentConversation> recentConversations;

  // Growth analytics (Monthly data points)
  final List<GrowthDataPoint> memberGrowth;
  final List<GrowthDataPoint> opportunityGrowth;
  final List<GrowthDataPoint> conversationGrowth;

  DashboardStats({
    required this.totalMembers,
    required this.totalOpportunities,
    required this.totalParticipants,
    required this.totalConversations,
    required this.totalMessages,
    required this.totalNotifications,
    required this.totalSavedOpportunities,
    required this.totalBlockedUsers,
    required this.totalUserReports,
    required this.avgMessagesPerConversation,
    required this.avgParticipantsPerOpportunity,
    required this.totalConversationMembers,
    required this.recentUsers,
    required this.recentOpportunities,
    required this.recentConversations,
    required this.memberGrowth,
    required this.opportunityGrowth,
    required this.conversationGrowth,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      totalMembers: 0,
      totalOpportunities: 0,
      totalParticipants: 0,
      totalConversations: 0,
      totalMessages: 0,
      totalNotifications: 0,
      totalSavedOpportunities: 0,
      totalBlockedUsers: 0,
      totalUserReports: 0,
      avgMessagesPerConversation: 0.0,
      avgParticipantsPerOpportunity: 0.0,
      totalConversationMembers: 0,
      recentUsers: [],
      recentOpportunities: [],
      recentConversations: [],
      memberGrowth: [],
      opportunityGrowth: [],
      conversationGrowth: [],
    );
  }
}

class RecentUser {
  final String id;
  final String name;
  final String city; // profiles table has no email — city is shown instead
  final DateTime joinedDate;

  RecentUser({
    required this.id,
    required this.name,
    required this.city,
    required this.joinedDate,
  });
}

class RecentOpportunity {
  final String id;
  final String title;
  final String createdBy;
  final DateTime createdDate;

  RecentOpportunity({
    required this.id,
    required this.title,
    required this.createdBy,
    required this.createdDate,
  });
}

class RecentConversation {
  final String id;
  final String title;
  final int membersCount;
  final DateTime createdDate;

  RecentConversation({
    required this.id,
    required this.title,
    required this.membersCount,
    required this.createdDate,
  });
}

class GrowthDataPoint {
  final String label; // e.g. "Jan", "Feb"
  final double value;

  GrowthDataPoint({
    required this.label,
    required this.value,
  });
}
