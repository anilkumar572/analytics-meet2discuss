import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../core/supabase_config.dart';
import '../models/dashboard_stats.dart';

class AnalyticsService {
  sb.SupabaseClient get _client => SupabaseConfig.client;

  Future<DashboardStats> fetchDashboardStats() async {
    // Run all counts in parallel for performance
    final results = await Future.wait([
      _count('profiles'),
      _count('opportunities'),
      _count('participants'),
      _count('conversations'),
      _count('messages'),
      _count('notifications'),
      _count('saved_opportunities'),
      _count('blocked_users'),
      _count('user_reports'),
      _count('conversation_members'),
    ]);

    final membersCount        = results[0];
    final opportunitiesCount  = results[1];
    final participantsCount   = results[2];
    final conversationsCount  = results[3];
    final messagesCount       = results[4];
    final notificationsCount  = results[5];
    final savedCount          = results[6];
    final blockedCount        = results[7];
    final reportsCount        = results[8];
    final convoMembersCount   = results[9];

    // Fetch recent users from profiles
    // Real schema: id, name, title, bio, avatar_url, city, interests,
    //              visibility, created_at, updated_at, linkedin_url
    // NOTE: No email column in profiles — email lives in auth.users
    List<RecentUser> recentUsers = [];
    try {
      final profilesRaw = await _client
          .from('profiles')
          .select('id, name, city, created_at')
          .order('created_at', ascending: false)
          .limit(10);

      recentUsers = (profilesRaw as List).map((u) => RecentUser(
            id: u['id']?.toString() ?? '',
            name: (u['name']?.toString() ?? '').isNotEmpty
                ? u['name'].toString()
                : 'Anonymous',
            city: u['city']?.toString() ?? '',
            joinedDate:
                DateTime.tryParse(u['created_at']?.toString() ?? '') ??
                    DateTime.now(),
          )).toList();
    } catch (e) {
      debugPrint('Profiles fetch error: $e');
    }

    // Fetch recent opportunities
    // Real schema: opportunities.host_id → profiles.id (FK is host_id, NOT created_by)
    List<RecentOpportunity> recentOpportunities = [];
    try {
      final oppsRaw = await _client
          .from('opportunities')
          .select('id, title, host_id, created_at, host:profiles!host_id(name)')
          .order('created_at', ascending: false)
          .limit(10);

      recentOpportunities = (oppsRaw as List).map((o) {
        final hostMap = o['host'];
        final hostName = (hostMap is Map)
            ? (hostMap['name']?.toString() ?? 'Unknown')
            : (o['host_id']?.toString() ?? 'Unknown');
        return RecentOpportunity(
          id: o['id']?.toString() ?? '',
          title: o['title']?.toString() ?? 'Untitled',
          createdBy: hostName,
          createdDate:
              DateTime.tryParse(o['created_at']?.toString() ?? '') ??
                  DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Opportunities fetch error: $e');
      // Fallback: fetch without join, show host_id as creator
      try {
        final oppsRaw = await _client
            .from('opportunities')
            .select('id, title, host_id, created_at')
            .order('created_at', ascending: false)
            .limit(10);

        recentOpportunities = (oppsRaw as List).map((o) => RecentOpportunity(
              id: o['id']?.toString() ?? '',
              title: o['title']?.toString() ?? 'Untitled',
              createdBy: o['host_id']?.toString() ?? 'Unknown',
              createdDate:
                  DateTime.tryParse(o['created_at']?.toString() ?? '') ??
                      DateTime.now(),
            )).toList();
      } catch (e2) {
        debugPrint('Opportunities fallback error: $e2');
      }
    }

    // Fetch recent conversations with real member count per conversation
    final convosRaw = await _client
        .from('conversations')
        .select('id, title, created_at')
        .order('created_at', ascending: false)
        .limit(10);

    final convoIds =
        (convosRaw as List).map((c) => c['id']).whereType<Object>().toList();

    // Count members per conversation in one query
    Map<String, int> memberCountMap = {};
    if (convoIds.isNotEmpty) {
      try {
        final membersRaw = await _client
            .from('conversation_members')
            .select('conversation_id')
            .inFilter('conversation_id', convoIds);

        for (final m in membersRaw as List) {
          final id = m['conversation_id']?.toString() ?? '';
          if (id.isNotEmpty) {
            memberCountMap[id] = (memberCountMap[id] ?? 0) + 1;
          }
        }
      } catch (_) {
        // member counts remain 0 if table/column differs
      }
    }

    final recentConversations = convosRaw.map((c) {
      final id = c['id']?.toString() ?? '';
      return RecentConversation(
        id: id,
        title: c['title']?.toString() ?? 'Conversation',
        membersCount: memberCountMap[id] ?? 0,
        createdDate:
            DateTime.tryParse(c['created_at']?.toString() ?? '') ??
                DateTime.now(),
      );
    }).toList();

    // Fetch real growth data (last 6 calendar months) in parallel
    final growthResults = await Future.wait([
      _buildRealGrowth('profiles'),
      _buildRealGrowth('opportunities'),
      _buildRealGrowth('conversations'),
    ]);

    return DashboardStats(
      totalMembers: membersCount,
      totalOpportunities: opportunitiesCount,
      totalParticipants: participantsCount,
      totalConversations: conversationsCount,
      totalMessages: messagesCount,
      totalNotifications: notificationsCount,
      totalSavedOpportunities: savedCount,
      totalBlockedUsers: blockedCount,
      totalUserReports: reportsCount,
      avgMessagesPerConversation: conversationsCount > 0
          ? messagesCount / conversationsCount
          : 0.0,
      avgParticipantsPerOpportunity: opportunitiesCount > 0
          ? participantsCount / opportunitiesCount
          : 0.0,
      totalConversationMembers: convoMembersCount,
      recentUsers: recentUsers,
      recentOpportunities: recentOpportunities,
      recentConversations: recentConversations,
      memberGrowth: growthResults[0],
      opportunityGrowth: growthResults[1],
      conversationGrowth: growthResults[2],
    );
  }

  /// Counts all rows in [table] using server-side count.
  /// Uses `*` so it works on tables without an `id` column.
  Future<int> _count(String table) async {
    try {
      final r = await _client
          .from(table)
          .select('*')
          .count(sb.CountOption.exact);
      return r.count;
    } catch (e) {
      debugPrint('Count error on $table: $e');
      return 0;
    }
  }

  /// Queries [table] for `created_at` values in the last 6 calendar months
  /// and groups them by month, returning real historical data points.
  Future<List<GrowthDataPoint>> _buildRealGrowth(String table) async {
    final now = DateTime.now();

    // Build the ordered list of the last 6 months (oldest → newest)
    final months = List.generate(6, (i) {
      final m = DateTime(now.year, now.month - 5 + i, 1);
      return m;
    });

    // Start of the oldest month
    final from = months.first;
    // End of the current month
    final to = DateTime(now.year, now.month + 1, 1);

    try {
      final raw = await _client
          .from(table)
          .select('created_at')
          .gte('created_at', from.toIso8601String())
          .lt('created_at', to.toIso8601String());

      // Group by "yyyy-MM" key
      final Map<String, int> counts = {
        for (final m in months) _monthKey(m): 0,
      };

      for (final row in raw as List) {
        final dt = DateTime.tryParse(row['created_at']?.toString() ?? '');
        if (dt != null) {
          final key = _monthKey(dt);
          if (counts.containsKey(key)) {
            counts[key] = counts[key]! + 1;
          }
        }
      }

      return months
          .map((m) => GrowthDataPoint(
                label: DateFormat('MMM').format(m),
                value: counts[_monthKey(m)]!.toDouble(),
              ))
          .toList();
    } catch (e) {
      debugPrint('Growth query error on $table: $e');
      // Return empty points for each month (no fake data)
      return months
          .map((m) => GrowthDataPoint(
                label: DateFormat('MMM').format(m),
                value: 0,
              ))
          .toList();
    }
  }

  String _monthKey(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
}
