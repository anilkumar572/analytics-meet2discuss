import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../auth/auth_cubit.dart';
import '../auth/auth_state.dart';
import 'dashboard_cubit.dart';
import 'dashboard_state.dart';
import '../models/dashboard_stats.dart';
import '../widgets/stat_card.dart';
import '../widgets/growth_chart.dart';
import '../widgets/recent_users_table.dart';

class _NavItem {
  final IconData icon;
  final String label;
  final GlobalKey key;
  final int index;
  const _NavItem(this.icon, this.label, this.key, this.index);
}

class _NavGroup {
  final String label;
  final List<_NavItem> items;
  const _NavGroup(this.label, this.items);
}

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

  final _searchController = TextEditingController();
  String _searchQuery = '';

  late final List<_NavGroup> _navGroups = [
    _NavGroup('Analytics', [
      _NavItem(Icons.dashboard_outlined, 'Overview Metrics', _overviewKey, 0),
      _NavItem(Icons.trending_up_outlined, 'Growth Analytics', _growthKey, 1),
      _NavItem(Icons.analytics_outlined, 'Engagement', _engagementKey, 2),
    ]),
    _NavGroup('Directory', [
      _NavItem(Icons.people_outline, 'Recent Users', _usersKey, 3),
      _NavItem(Icons.business_center_outlined, 'Opportunities', _oppsKey, 4),
      _NavItem(Icons.forum_outlined, 'Conversations', _convosKey, 5),
    ]),
    _NavGroup('Trust & Safety', [
      _NavItem(Icons.gpp_maybe_outlined, 'Moderation', _moderationKey, 6),
    ]),
  ];

  String get _currentSectionLabel {
    for (final group in _navGroups) {
      for (final item in group.items) {
        if (item.index == _selectedSection) return item.label;
      }
    }
    return 'Overview Metrics';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardCubit>().loadDashboard();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      body: Stack(
        children: [
          Positioned(
            top: -140,
            right: -120,
            child: IgnorePointer(child: _glowOrb(AppColors.primary, 320)),
          ),
          Positioned(
            bottom: -160,
            left: -140,
            child: IgnorePointer(child: _glowOrb(AppColors.accent, 300)),
          ),
          _body(isMobile, isTablet),
        ],
      ),
    );
  }

  Widget _glowOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.05)),
    );
  }

  Widget _body(bool isMobile, bool isTablet) {
    return Row(
        children: [
          if (!isMobile) _sidebar(_sidebarCollapsed || isTablet),
          Expanded(
            child: BlocBuilder<DashboardCubit, DashboardState>(
              builder: (context, state) {
                if (state is DashboardLoading) {
                  return _loadingState();
                }
                if (state is DashboardError) {
                  return _errorState(state.errorMessage);
                }
                if (state is DashboardLoaded) {
                  final filteredUsers = _searchQuery.isEmpty
                      ? state.stats.recentUsers
                      : state.stats.recentUsers
                          .where((u) =>
                              u.name.toLowerCase().contains(_searchQuery) ||
                              u.city.toLowerCase().contains(_searchQuery))
                          .toList();

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
                              _breadcrumb(),
                              const SizedBox(height: 12),
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
                                users: filteredUsers,
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
      );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // States
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _loadingState() {
    return const Center(
      child: SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
      ),
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.danger.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, color: AppColors.danger, size: 32),
            ),
            const SizedBox(height: 16),
            Text('Couldn\'t load the dashboard',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<DashboardCubit>().loadDashboard(),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Builders
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _breadcrumb() {
    return Row(
      children: [
        Text('Dashboard',
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
        ),
        Text(_currentSectionLabel,
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _section(String title, GlobalKey key) {
    return Container(
      key: key,
      padding: const EdgeInsets.only(bottom: 10),
      decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1))),
      child: Text(title, style: AppTextStyles.sectionTitle),
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
              Text('Welcome back, $name', style: AppTextStyles.pageTitle),
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
          if (!isMobile) ...[
            const SizedBox(width: 28),
            Expanded(child: Center(child: _searchField())),
          ],
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
        child: Container(color: AppColors.border, height: 1),
      ),
    );
  }

  Widget _searchField() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      height: 40,
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search recent users by name or city…',
          hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                  onPressed: () => setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  }),
                ),
          filled: true,
          fillColor: AppColors.surfaceElevated.withOpacity(0.5),
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _sidebar(bool collapsed) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: collapsed ? 72 : 255,
      color: AppColors.surface,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  for (final group in _navGroups) ...[
                    if (!collapsed) _groupLabel(group.label),
                    for (final item in group.items) _navTile(item, collapsed),
                    const SizedBox(height: 6),
                  ],
                ],
              ),
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

  Widget _groupLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _navTile(_NavItem item, bool collapsed) {
    final selected = _selectedSection == item.index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: InkWell(
        onTap: () => _scrollTo(item.key, item.index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            mainAxisAlignment:
                collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(item.icon,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  size: 20),
              if (!collapsed) ...[
                const SizedBox(width: 14),
                Expanded(
                  child: Text(item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                        color: selected ? AppColors.primary : AppColors.textSecondary,
                      )),
                ),
              ],
            ],
          ),
        ),
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
          progressPercent: s.totalMembers / base,
          trendPercent: s.memberGrowth.monthOverMonthChange),
      StatCard(title: 'Total Opportunities', value: '${s.totalOpportunities}',
          icon: Icons.business_center_outlined, iconColor: AppColors.secondary,
          progressColor: AppColors.secondary,
          progressPercent: s.totalOpportunities / base,
          trendPercent: s.opportunityGrowth.monthOverMonthChange),
      StatCard(title: 'Total Participants', value: '${s.totalParticipants}',
          icon: Icons.group_work_outlined, iconColor: AppColors.accent,
          progressColor: AppColors.accent,
          progressPercent: s.totalParticipants / base),
      StatCard(title: 'Total Conversations', value: '${s.totalConversations}',
          icon: Icons.forum_outlined, iconColor: AppColors.info,
          progressColor: AppColors.info,
          progressPercent: s.totalConversations / base,
          trendPercent: s.conversationGrowth.monthOverMonthChange),
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
