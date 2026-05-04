import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/performance/presentation/performance_notifier.dart';
import 'package:intl/intl.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardScaffold(
      title: 'LEADERBOARD',
      subtitle: 'Top performers this month — riders and supervisors',
      showBackButton: true,
      activeItem: 'Performance',
      children: [
        _buildTabs(context, ref),
      ],
    );
  }

  Widget _buildTabs(BuildContext context, WidgetRef ref) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 380,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white.withOpacity(0.05) : AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDarkMode ? Colors.white10 : AppColors.divider),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(text: 'Riders'),
                Tab(text: 'Supervisors'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 700,
            child: TabBarView(
              children: [
                _buildList(context, ref, isRider: true),
                _buildList(context, ref, isRider: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, {required bool isRider}) {
    final provider = isRider ? riderLeaderboardProvider : supervisorLeaderboardProvider;
    final boardAsync = ref.watch(provider);

    return boardAsync.when(
      data: (board) {
        if (board.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.leaderboard_rounded,
                  size: 64,
                  color: AppColors.textSecondary.withOpacity(0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${isRider ? 'riders' : 'supervisors'} found',
                  style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 16),
                ),
              ],
            ),
          );
        }
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: _buildPodium(context, board),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // Skip top 3 for the list if there are enough entries
                  final actualIndex = board.length > 3 ? index + 3 : -1;
                  if (actualIndex == -1 || actualIndex >= board.length) return null;
                  return _buildLeaderboardEntry(context, board[actualIndex], actualIndex);
                },
                childCount: board.length > 3 ? board.length - 3 : 0,
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildLeaderboardEntry(BuildContext context, Map<String, dynamic> entry, int index) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final rank = index + 1;
    final name = entry['name'] as String? ?? 'Unknown';
    final baseScore = (entry['baseScore'] as double? ?? 0).round();
    final attScore = (entry['attendanceScore'] as double? ?? 0);
    final incScore = (entry['incidentScore'] as double? ?? 0);
    final bonus = (entry['bonusTotal'] as double? ?? 0);
    final penalty = (entry['penaltyTotal'] as double? ?? 0);
    final net = entry['netAdjustment'] as double? ?? 0;
    final currencyFmt = NumberFormat.compactCurrency(symbol: '﷼ ', decimalDigits: 0);

    Color rankColor;
    IconData? rankIcon;
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700);
      rankIcon = Icons.emoji_events_rounded;
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0);
      rankIcon = Icons.emoji_events_rounded;
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32);
      rankIcon = Icons.emoji_events_rounded;
    } else {
      rankColor = AppColors.textSecondary;
      rankIcon = null;
    }

    Color scoreColor;
    if (baseScore >= 80) {
      scoreColor = Colors.green;
    } else if (baseScore >= 60) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: rank <= 3
              ? rankColor.withOpacity(0.3)
              : (isDarkMode ? Colors.white10 : AppColors.divider),
          width: rank <= 3 ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: rank <= 3
                ? rankColor.withOpacity(0.08)
                : Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Rank badge
              SizedBox(
                width: 44,
                child: rankIcon != null
                    ? Icon(rankIcon, color: rankColor, size: 28)
                    : Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '#$rank',
                            style: GoogleFonts.outfit(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                    ),
                    if (bonus > 0 || penalty > 0)
                      Row(
                        children: [
                          if (bonus > 0)
                            _buildSmallBadge('+${currencyFmt.format(bonus)}', Colors.green),
                          if (penalty > 0) ...[
                            const SizedBox(width: 6),
                            _buildSmallBadge('-${currencyFmt.format(penalty)}', Colors.red),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
              // Score
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$baseScore',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                      height: 1,
                    ),
                  ),
                  Text(
                    '/${(entry['maxScore'] as num?)?.toInt() ?? 90}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Score breakdown bar
          Row(
            children: [
              _buildMiniScore('Att', attScore, (entry['weightAtt'] as num?)?.toDouble() ?? 40, Colors.blue, isDarkMode),
              const SizedBox(width: 8),
              _buildMiniScore('Inc', incScore, (entry['weightInc'] as num?)?.toDouble() ?? 20, Colors.orange, isDarkMode),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMiniScore(String label, double score, double max, Color color, bool isDarkMode) {
    final pct = (score / max).clamp(0.0, 1.0);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${score.round()}',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: isDarkMode ? Colors.white12 : AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(BuildContext context, List<Map<String, dynamic>> board) {
    if (board.isEmpty) return const SizedBox.shrink();
    
    final first = board.isNotEmpty ? board[0] : null;
    final second = board.length > 1 ? board[1] : null;
    final third = board.length > 2 ? board[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (second != null) _buildPodiumSpot(context, second, 2, 140),
        const SizedBox(width: 12),
        if (first != null) _buildPodiumSpot(context, first, 1, 180),
        const SizedBox(width: 12),
        if (third != null) _buildPodiumSpot(context, third, 3, 120),
      ],
    );
  }

  Widget _buildPodiumSpot(BuildContext context, Map<String, dynamic> entry, int rank, double height) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = entry['name'] as String? ?? 'Unknown';
    final score = (entry['baseScore'] as double? ?? 0).round();
    
    Color color;
    if (rank == 1) color = const Color(0xFFFFD700);
    else if (rank == 2) color = const Color(0xFFC0C0C0);
    else color = const Color(0xFFCD7F32);

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
              image: const DecorationImage(
                image: NetworkImage('https://ui-avatars.com/api/?name=User&background=random'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$score pts',
              style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w900, fontSize: 11),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.8), color.withOpacity(0.4)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -4)),
              ],
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 32,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
