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
      body: _buildTabs(context, ref),
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
              color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDarkMode ? Colors.white10 : AppColors.divider),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
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
          Expanded(
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
                  color: AppColors.textSecondary.withValues(alpha: 0.2),
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
              ? rankColor.withValues(alpha: 0.3)
              : (isDarkMode ? Colors.white10 : AppColors.divider),
          width: rank <= 3 ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: rank <= 3
                ? rankColor.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
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
                          color: AppColors.textSecondary.withValues(alpha: 0.1),
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
                    colors: [
                      _getAvatarColor(name),
                      _getAvatarColor(name).withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _getAvatarColor(name).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _getInitials(name),
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
        color: color.withValues(alpha: 0.1),
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

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white.withValues(alpha: 0.02) 
              : Colors.black.withValues(alpha: 0.01),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white.withValues(alpha: 0.05) 
                : Colors.black.withValues(alpha: 0.02),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (second != null) _buildPodiumSpot(context, second, 2, 160),
            const SizedBox(width: 16),
            if (first != null) _buildPodiumSpot(context, first, 1, 210),
            const SizedBox(width: 16),
            if (third != null) _buildPodiumSpot(context, third, 3, 130),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumSpot(BuildContext context, Map<String, dynamic> entry, int rank, double height) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = entry['name'] as String? ?? 'Unknown';
    final score = (entry['baseScore'] as double? ?? 0).round();
    
    late Color color;
    late List<Color> blockColors;
    late double avatarSize;
    
    if (rank == 1) {
      color = const Color(0xFFFFC107); // Golden
      blockColors = [
        const Color(0xFFFFE082), 
        const Color(0xFFFFA000),
      ];
      avatarSize = 88;
    } else if (rank == 2) {
      color = const Color(0xFF9E9E9E); // Silver
      blockColors = [
        const Color(0xFFECEFF1),
        const Color(0xFF78909C),
      ];
      avatarSize = 72;
    } else {
      color = const Color(0xFF8D6E63); // Bronze
      blockColors = [
        const Color(0xFFFFCCBC),
        const Color(0xFFCA6A46),
      ];
      avatarSize = 64;
    }

    final initials = _getInitials(name);

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: avatarSize + 16,
                height: avatarSize + 16,
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none,
                  children: [
                    if (rank == 1)
                      Positioned(
                        top: -6,
                        child: Container(
                          width: avatarSize,
                          height: avatarSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD54F).withValues(alpha: 0.35),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: blockColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white,
                          width: rank == 1 ? 4 : 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.outfit(
                            fontSize: rank == 1 ? 26 : 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: const [
                              Shadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    if (rank == 1)
                      const Positioned(
                        top: -32,
                        child: Icon(
                          Icons.emoji_events_rounded,
                          color: Color(0xFFFFD54F),
                          size: 36,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              
              Positioned(
                bottom: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '#$rank',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              name,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, 
                fontSize: rank == 1 ? 16 : 14,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
            ),
            child: Text(
              '$score pts',
              style: GoogleFonts.outfit(
                color: color, 
                fontWeight: FontWeight.w900, 
                fontSize: rank == 1 ? 13 : 11,
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          Container(
            width: double.infinity,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  blockColors[0].withValues(alpha: 0.95),
                  blockColors[1].withValues(alpha: 0.8),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2), 
                  blurRadius: 16, 
                  offset: const Offset(0, -4),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: -15,
                  child: Opacity(
                    opacity: 0.15,
                    child: Text(
                      '$rank',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: height * 0.65,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                Icon(
                  rank == 1 
                      ? Icons.military_tech_rounded 
                      : (rank == 2 ? Icons.workspace_premium_rounded : Icons.stars_rounded),
                  size: height * 0.3,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFFEC4899), // Pink
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFEF4444), // Red
      const Color(0xFF06B6D4), // Cyan
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      final first = parts[0].trim();
      final second = parts[1].trim();
      if (first.isNotEmpty && second.isNotEmpty) {
        return '${first[0]}${second[0]}'.toUpperCase();
      }
    }
    return name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
  }
}
