import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../models/dashboard_stats.dart';

// ─── Recent Users ─────────────────────────────────────────────────────────────

class RecentUsersTable extends StatelessWidget {
  final List<RecentUser> users;
  final String sortField;
  final bool sortAscending;
  final void Function(String) onSort;

  const RecentUsersTable({
    super.key,
    required this.users,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Recent Users',
      trailing: _countBadge(users.length),
      child: users.isEmpty
          ? const _EmptyState(
              icon: Icons.people_outline, message: 'No users yet')
          : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          headingRowColor:
              MaterialStateProperty.all(AppColors.surfaceElevated.withOpacity(0.4)),
          dataRowColor: MaterialStateProperty.resolveWith((states) =>
              states.contains(MaterialState.hovered)
                  ? AppColors.surfaceHover
                  : Colors.transparent),
          dividerThickness: 1,
          horizontalMargin: 16,
          sortColumnIndex: sortField == 'name'
              ? 0
              : sortField == 'city'
                  ? 1
                  : 2,
          sortAscending: sortAscending,
          columns: [
            DataColumn(
              label: _headerLabel('Name'),
              onSort: (_, __) => onSort('name'),
            ),
            DataColumn(
              label: _headerLabel('City'),
              onSort: (_, __) => onSort('city'),
            ),
            DataColumn(
              label: _headerLabel('Joined Date'),
              onSort: (_, __) => onSort('joinedDate'),
            ),
          ],
          rows: users.map((u) {
            return DataRow(
              cells: [
                DataCell(Row(children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Text(
                      u.name.isNotEmpty ? u.name[0].toUpperCase() : 'U',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(u.name,
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                ])),
                DataCell(Text(u.city.isNotEmpty ? u.city : '—',
                    style: GoogleFonts.inter(color: AppColors.textSecondary))),
                DataCell(Text(
                  DateFormat('MMM d, yyyy • h:mm a').format(u.joinedDate),
                  style: GoogleFonts.inter(color: AppColors.textMuted),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Recent Opportunities ─────────────────────────────────────────────────────

class RecentOpportunitiesTable extends StatelessWidget {
  final List<RecentOpportunity> opportunities;
  const RecentOpportunitiesTable({super.key, required this.opportunities});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Recent Opportunities',
      trailing: _countBadge(opportunities.length),
      child: opportunities.isEmpty
          ? const _EmptyState(
              icon: Icons.business_center_outlined, message: 'No opportunities yet')
          : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          headingRowColor:
              MaterialStateProperty.all(AppColors.surfaceElevated.withOpacity(0.4)),
          dataRowColor: MaterialStateProperty.resolveWith((states) =>
              states.contains(MaterialState.hovered)
                  ? AppColors.surfaceHover
                  : Colors.transparent),
          dividerThickness: 1,
          horizontalMargin: 16,
          columns: [
            DataColumn(label: _headerLabel('Title')),
            DataColumn(label: _headerLabel('Created By')),
            DataColumn(label: _headerLabel('Created Date')),
          ],
          rows: opportunities.map((o) {
            return DataRow(cells: [
              DataCell(SizedBox(
                width: 280,
                child: Text(
                  o.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600),
                ),
              )),
              DataCell(Text(o.createdBy,
                  style: GoogleFonts.inter(color: AppColors.textSecondary))),
              DataCell(Text(
                DateFormat('MMM d, yyyy').format(o.createdDate),
                style: GoogleFonts.inter(color: AppColors.textMuted),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Recent Conversations ─────────────────────────────────────────────────────

class RecentConversationsTable extends StatelessWidget {
  final List<RecentConversation> conversations;
  const RecentConversationsTable({super.key, required this.conversations});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Recent Conversations',
      trailing: _countBadge(conversations.length),
      child: conversations.isEmpty
          ? const _EmptyState(
              icon: Icons.forum_outlined, message: 'No conversations yet')
          : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          headingRowColor:
              MaterialStateProperty.all(AppColors.surfaceElevated.withOpacity(0.4)),
          dataRowColor: MaterialStateProperty.resolveWith((states) =>
              states.contains(MaterialState.hovered)
                  ? AppColors.surfaceHover
                  : Colors.transparent),
          dividerThickness: 1,
          horizontalMargin: 16,
          columns: [
            DataColumn(label: _headerLabel('Title')),
            DataColumn(label: _headerLabel('Members')),
            DataColumn(label: _headerLabel('Created Date')),
          ],
          rows: conversations.map((c) {
            return DataRow(cells: [
              DataCell(Text(c.title,
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600))),
              DataCell(
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${c.membersCount} members',
                      style: GoogleFonts.inter(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              DataCell(Text(
                DateFormat('MMM d, yyyy').format(c.createdDate),
                style: GoogleFonts.inter(color: AppColors.textMuted),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

Widget _headerLabel(String text) => Text(text, style: AppTextStyles.tableHeader);

Widget _countBadge(int count) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$count shown',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textMuted, size: 32),
            const SizedBox(height: 10),
            Text(message, style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _Card({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
