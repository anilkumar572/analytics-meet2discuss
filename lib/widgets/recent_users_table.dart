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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          headingRowColor:
              MaterialStateProperty.all(AppColors.surfaceElevated.withOpacity(0.3)),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          headingRowColor:
              MaterialStateProperty.all(AppColors.surfaceElevated.withOpacity(0.3)),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          headingRowColor:
              MaterialStateProperty.all(AppColors.surfaceElevated.withOpacity(0.3)),
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

Widget _headerLabel(String text) => Text(
      text,
      style: GoogleFonts.inter(
          fontWeight: FontWeight.bold, color: AppColors.textPrimary),
    );

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
