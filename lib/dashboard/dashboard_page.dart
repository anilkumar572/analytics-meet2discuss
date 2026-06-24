import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../auth/auth_cubit.dart';
import '../auth/auth_state.dart';
import 'dashboard_cubit.dart';
import 'dashboard_state.dart';
import '../widgets/stat_card.dart';
import '../widgets/growth_chart.dart';
import '../widgets/recent_users_table.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Section keys for sidebar scroll navigation
  final _overviewKey = GlobalKey();
  final _growthKey = GlobalKey();
  final _engagementKey = GlobalKey();
  final _usersKey = GlobalKey();
  final _oppsKey = GlobalKey();
  final _convosKey = GlobalKey();
  final _moderationKey = GlobalKey();

  int _selectedSection = 0;
  bool _sidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardCubit>().loadDashboard();
    });
  }

  void _scrollTo(GlobalKey key, int index) {
    setState(() => _selectedSection = index);
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w <= 700;
    final isTablet = w > 700 && w <= 1100;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _navBar(isMobile),
      drawer: isMobile ? _drawer() : null,
      body: Row(
        children: [
          if (!isMobile) _sidebar(_sidebarCollapsed || isTablet),
          Expanded(
            child: BlocBuilder<DashboardCubit, DashboardState>(
              builder: (context, state) {
                if (state is DashboardLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 3),
                  );
                }
                if (state is DashboardError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.danger, size: 48),
                        const SizedBox(height: 12),
                        Text(state.errorMessage,
                            style: GoogleFonts.inter(
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<DashboardCubit>().loadDashboard(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is DashboardLoaded) {
                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 32,
                            vertical: 24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _welcomeHeader(),
                              const SizedBox(height: 32),
                              _section('Overview Metrics', _overviewKey),
                              const SizedBox(height: 16),
                              _overviewGrid(state, isMobile, isTablet),
                              const SizedBox(height: 40),
                              _section('Growth Analytics', _growthKey),
                              const SizedBox(height: 16),
                              _growthCharts(state, isMobile, isTablet),
                              const SizedBox(height: 40),
                              _section('Engagement Metrics', _engagementKey),
                              const SizedBox(height: 16),
                              _engagementGrid(state, isMobile, isTablet),
                              const SizedBox(height: 40),
                              _section('Recent Users', _usersKey),
                              const SizedBox(height: 16),
                              RecentUsersTable(
                                users: state.stats.recentUsers,
                                sortField: state.userSortField,
                                sortAscending: state.userSortAscending,
                                onSort: context
                                    .read<DashboardCubit>()
                                    .sortUsers,
                              ),
                              const SizedBox(height: 40),
                              _section('Recent Opportunities', _oppsKey),
                              const SizedBox(height: 16),
                              RecentOpportunitiesTable(
                                  opportunities:
                                      state.stats.recentOpportunities),
                              const SizedBox(height: 40),
                              _section('Recent Conversations', _convosKey),
                              const SizedBox(height: 16),
                              RecentConversationsTable(
                                  conversations:
                                      state.stats.recentConversations),
                              const SizedBox(height: 40),
                              _section('Moderation', _moderationKey),
                              const SizedBox(height: 16),
                              _moderationGrid(state, isMobile),
                              const SizedBox(height: 48),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Builders
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _section(String title, GlobalKey key) {
    return Container(
      key: key,
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1))),
      child: Text(
        title,
        style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary),
      ),
    );
  }

  Widget _welcomeHeader() {
    final authState = context.read<AuthCubit>().state;
    String name = 'Admin';
    if (authState is Authenticated) {
      final raw = authState.user.email?.split('@')[0] ?? 'Admin';
      name = raw[0].toUpperCase() + raw.substring(1);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back, $name',
                  style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text("Here's what's happening at Meet2Discuss today.",
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => context.read<DashboardCubit>().loadDashboard(),
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Refresh'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _navBar(bool isMobile) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: isMobile,
      titleSpacing: isMobile ? null : 16,
      title: Row(
        children: [
          if (!isMobile) ...[
            IconButton(
              icon: Icon(
                _sidebarCollapsed ? Icons.menu_open : Icons.menu,
                color: AppColors.textPrimary,
              ),
              onPressed: () =>
                  setState(() => _sidebarCollapsed = !_sidebarCollapsed),
            ),
            const SizedBox(width: 8),
          ],
          Image.asset('assets/images/logo_full.png', height: 32),
          const SizedBox(width: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('Admin Console',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Sign Out',
          icon: const Icon(Icons.logout_outlined,
              color: AppColors.textSecondary),
          onPressed: () => context.read<AuthCubit>().logout(),
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppColors.border.withOpacity(0.5), height: 1),
      ),
    );
  }

  Widget _sidebar(bool collapsed) {
    final items = [
      (Icons.dashboard_outlined, 'Overview Metrics', _overviewKey),
      (Icons.trending_up_outlined, 'Growth Analytics', _growthKey),
      (Icons.analytics_outlined, 'Engagement', _engagementKey),
      (Icons.people_outline, 'Recent Users', _usersKey),
      (Icons.business_center_outlined, 'Opportunities', _oppsKey),
      (Icons.forum_outlined, 'Conversations', _convosKey),
      (Icons.gpp_maybe_outlined, 'Moderation', _moderationKey),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: collapsed ? 72 : 255,
      color: AppColors.surface,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final (icon, label, key) = items[i];
                final selected = _selectedSection == i;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  child: InkWell(
                    onTap: () => _scrollTo(key, i),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary.withOpacity(0.25)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: collapsed
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.start,
                        children: [
                          Icon(icon,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              size: 20),
                          if (!collapsed) ...[
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: selected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  )),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
                border: Border(
                    top: BorderSide(color: AppColors.border, width: 1))),
            child: collapsed
                ? const Icon(Icons.shield_outlined, color: AppColors.success)
                : Row(children: [
                    const Icon(Icons.shield_outlined,
                        color: AppColors.success, size: 16),
                    const SizedBox(width: 10),
                    Text('Secured Session',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500)),
                  ]),
          ),
        ],
      ),
    );
  }

  Widget _drawer() {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.background),
            child: Center(
              child: Image.asset('assets/images/logo_full.png', height: 48),
            ),
          ),
          Expanded(child: _sidebar(false)),
        ],
      ),
    );
  }

  Widget _overviewGrid(DashboardLoaded state, bool mobile, bool tablet) {
    final cols = mobile ? 1 : (tablet ? 2 : 3);
    final s = state.stats;
    // Use messages as the ceiling — it's typically the largest count
    final maxCount = [
      s.totalMembers, s.totalOpportunities, s.totalParticipants,
      s.totalConversations, s.totalMessages, s.totalNotifications,
    ].reduce((a, b) => a > b ? a : b);
    final base = maxCount > 0 ? maxCount.toDouble() : 1.0;

    return _grid(cols, [
      StatCard(title: 'Total Members', value: '${s.totalMembers}',
          icon: Icons.people_alt_outlined, iconColor: AppColors.primary,
          progressColor: AppColors.primary,
          progressPercent: s.totalMembers / base),
      StatCard(title: 'Total Opportunities', value: '${s.totalOpportunities}',
          icon: Icons.business_center_outlined, iconColor: AppColors.secondary,
          progressColor: AppColors.secondary,
          progressPercent: s.totalOpportunities / base),
      StatCard(title: 'Total Participants', value: '${s.totalParticipants}',
          icon: Icons.group_work_outlined, iconColor: AppColors.accent,
          progressColor: AppColors.accent,
          progressPercent: s.totalParticipants / base),
      StatCard(title: 'Total Conversations', value: '${s.totalConversations}',
          icon: Icons.forum_outlined, iconColor: AppColors.info,
          progressColor: AppColors.info,
          progressPercent: s.totalConversations / base),
      StatCard(title: 'Total Messages', value: '${s.totalMessages}',
          icon: Icons.chat_bubble_outline, iconColor: AppColors.success,
          progressColor: AppColors.success,
          progressPercent: s.totalMessages / base),
      StatCard(title: 'Total Notifications', value: '${s.totalNotifications}',
          icon: Icons.notifications_none_outlined, iconColor: AppColors.warning,
          progressColor: AppColors.warning,
          progressPercent: s.totalNotifications / base),
    ]);
  }

  Widget _growthCharts(DashboardLoaded state, bool mobile, bool tablet) {
    final s = state.stats;
    final charts = [
      GrowthChart(title: 'Member Growth', dataPoints: s.memberGrowth,
          lineColor: AppColors.primary,
          gradientColors: const [AppColors.primary, AppColors.accent]),
      GrowthChart(title: 'Opportunity Growth', dataPoints: s.opportunityGrowth,
          lineColor: AppColors.secondary,
          gradientColors: const [AppColors.secondary, AppColors.info]),
      GrowthChart(title: 'Conversation Growth', dataPoints: s.conversationGrowth,
          lineColor: AppColors.accent,
          gradientColors: const [AppColors.accent, AppColors.primary]),
    ];

    if (mobile) {
      return Column(
        children: charts
            .expand((c) => [c, const SizedBox(height: 20)])
            .toList()
          ..removeLast(),
      );
    }

    return LayoutBuilder(builder: (_, constraints) {
      final cols = tablet ? 2 : 3;
      final gap = 20.0;
      final w = (constraints.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: charts
            .asMap()
            .entries
            .map((e) => SizedBox(
                  width: tablet && e.key == 2 ? constraints.maxWidth : w,
                  child: e.value,
                ))
            .toList(),
      );
    });
  }

  Widget _engagementGrid(DashboardLoaded state, bool mobile, bool tablet) {
    final cols = mobile ? 1 : (tablet ? 2 : 4);
    final s = state.stats;
    // Saved / total opportunities = save rate (capped at 1.0)
    final saveRate = s.totalOpportunities > 0
        ? (s.totalSavedOpportunities / s.totalOpportunities).clamp(0.0, 1.0)
        : 0.0;
    // Convo members / total members = participation rate
    final convoMemberRate = s.totalMembers > 0
        ? (s.totalConversationMembers / s.totalMembers).clamp(0.0, 1.0)
        : 0.0;
    // Avg messages: cap at a sensible max of 100 for the bar
    final avgMsgRate = (s.avgMessagesPerConversation / 100).clamp(0.0, 1.0);
    // Avg participants: cap at 20 for the bar
    final avgPartRate = (s.avgParticipantsPerOpportunity / 20).clamp(0.0, 1.0);

    return _grid(cols, [
      StatCard(title: 'Avg Messages / Convo',
          value: s.avgMessagesPerConversation.toStringAsFixed(1),
          icon: Icons.message_outlined, iconColor: AppColors.info,
          progressColor: AppColors.info, progressPercent: avgMsgRate),
      StatCard(title: 'Avg Participants / Opp',
          value: s.avgParticipantsPerOpportunity.toStringAsFixed(1),
          icon: Icons.people_outline, iconColor: AppColors.primary,
          progressColor: AppColors.primary, progressPercent: avgPartRate),
      StatCard(title: 'Convo Members Total',
          value: '${s.totalConversationMembers}',
          icon: Icons.contacts_outlined, iconColor: AppColors.secondary,
          progressColor: AppColors.secondary, progressPercent: convoMemberRate),
      StatCard(title: 'Saved Opportunities', value: '${s.totalSavedOpportunities}',
          icon: Icons.bookmark_border_outlined, iconColor: AppColors.accent,
          progressColor: AppColors.accent, progressPercent: saveRate),
    ], aspectRatio: cols == 4 ? 1.8 : 2.0);
  }

  Widget _moderationGrid(DashboardLoaded state, bool mobile) {
    final s = state.stats;
    // Express blocked/reports as fraction of total members
    final blockedRate = s.totalMembers > 0
        ? (s.totalBlockedUsers / s.totalMembers).clamp(0.0, 1.0)
        : 0.0;
    final reportsRate = s.totalMembers > 0
        ? (s.totalUserReports / s.totalMembers).clamp(0.0, 1.0)
        : 0.0;

    return _grid(mobile ? 1 : 2, [
      StatCard(title: 'Blocked Users', value: '${s.totalBlockedUsers}',
          icon: Icons.block_outlined, iconColor: AppColors.danger,
          progressColor: AppColors.danger, progressPercent: blockedRate),
      StatCard(title: 'User Reports', value: '${s.totalUserReports}',
          icon: Icons.report_problem_outlined, iconColor: AppColors.warning,
          progressColor: AppColors.warning, progressPercent: reportsRate),
    ]);
  }

  Widget _grid(int cols, List<Widget> children, {double aspectRatio = 2.0}) {
    return GridView.count(
      crossAxisCount: cols,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: aspectRatio,
      children: children,
    );
  }
}
