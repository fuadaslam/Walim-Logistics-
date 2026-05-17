import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';

class DashboardStatCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final bool? isPositive;
  final List<double>? sparklineData;
  final VoidCallback? onTap;

  const DashboardStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.isPositive,
    this.sparklineData,
    this.onTap,
  });

  @override
  State<DashboardStatCard> createState() => _DashboardStatCardState();
}

class _DashboardStatCardState extends State<DashboardStatCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.all(isMobile ? 8 : 12),
            decoration: BoxDecoration(
              color: isDark 
                  ? AppColors.surfaceDark.withValues(alpha:0.9) 
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isDark ? Colors.white.withValues(alpha:0.02) : Colors.white,
                  widget.color.withValues(alpha:isDark ? (_isHovered ? 0.06 : 0.02) : (_isHovered ? 0.03 : 0.005)),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered 
                      ? widget.color.withValues(alpha:0.1) 
                      : Colors.black.withValues(alpha:isDark ? 0.15 : 0.015),
                  blurRadius: _isHovered ? 20 : 10,
                  offset: Offset(0, _isHovered ? 6 : 4),
                ),
              ],
              border: Border.all(
                color: _isHovered 
                    ? widget.color.withValues(alpha:0.3) 
                    : (isDark ? Colors.white.withValues(alpha:0.05) : AppColors.divider.withValues(alpha:0.4)),
                width: 1.0,
              ),
            ),
            child: Stack(
              children: [
                // Decorative background blob
                Positioned(
                  top: -20,
                  right: -20,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.color.withValues(alpha: _isHovered ? 0.12 : 0.06),
                          widget.color.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                if (widget.sparklineData != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: isMobile ? 35 : 60,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _isHovered ? 0.5 : 0.3,
                      child: MetricSparkline(
                        data: widget.sparklineData!,
                        color: widget.color,
                        fill: true,
                      ),
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: widget.color.withValues(alpha:0.2)),
                          ),
                          child: Icon(
                            widget.icon, 
                            color: widget.color, 
                            size: isMobile ? 14 : 16,
                          ),
                        ),
                        if (widget.trend != null)
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (widget.isPositive ?? true) 
                                    ? Colors.green.withValues(alpha:0.1) 
                                    : Colors.red.withValues(alpha:0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      (widget.isPositive ?? true) ? Icons.trending_up : Icons.trending_down,
                                      size: 9,
                                      color: (widget.isPositive ?? true) ? Colors.green : Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.trend!,
                                      style: GoogleFonts.outfit(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: (widget.isPositive ?? true) ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.value,
                          style: GoogleFonts.outfit(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                            letterSpacing: -0.8,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: isMobile ? 10 : 11,
                            color: (isDark ? Colors.white70 : AppColors.textSecondary).withValues(alpha: 0.85),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MetricSparkline extends StatelessWidget {
  final List<double> data;
  final Color color;
  final bool fill;

  const MetricSparkline({
    super.key,
    required this.data,
    required this.color,
    this.fill = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(data, color, fill),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final bool fill;

  _SparklinePainter(this.data, this.color, this.fill);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final path = Path();
    final double stepX = size.width / (data.length - 1);
    final double min = data.reduce((a, b) => a < b ? a : b);
    final double max = data.reduce((a, b) => a > b ? a : b);
    final double range = max - min;

    double getY(double value) {
      if (range == 0) return size.height / 2;
      return size.height - ((value - min) / range * size.height);
    }

    path.moveTo(0, getY(data[0]));
    for (int i = 0; i < data.length - 1; i++) {
      final x1 = i * stepX;
      final y1 = getY(data[i]);
      final x2 = (i + 1) * stepX;
      final y2 = getY(data[i + 1]);
      
      final cx = (x1 + x2) / 2;
      
      path.cubicTo(cx, y1, cx, y2, x2, y2);
    }

    if (fill) {
      final fillPath = Path.from(path);
      fillPath.lineTo(size.width, size.height);
      fillPath.lineTo(0, size.height);
      fillPath.close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DashboardActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const DashboardActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  State<DashboardActionCard> createState() => _DashboardActionCardState();
}

class _DashboardActionCardState extends State<DashboardActionCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.all(isMobile ? 10 : 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isHovered ? widget.color.withValues(alpha:0.6) : (isDark ? Colors.white.withValues(alpha:0.05) : AppColors.divider.withValues(alpha:0.5)),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered 
                      ? widget.color.withValues(alpha:0.15) 
                      : Colors.black.withValues(alpha:isDark ? 0.2 : 0.03),
                  blurRadius: _isHovered ? 20 : 10,
                  offset: Offset(0, _isHovered ? 8 : 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.color,
                        widget.color.withValues(alpha:0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha:0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon, 
                    color: Colors.white, 
                    size: isMobile ? 14 : 15,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: isMobile ? 11 : 12,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          if (widget.badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: widget.color.withValues(alpha:0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: widget.color.withValues(alpha:0.2)),
                              ),
                              child: Text(
                                widget.badge!,
                                style: GoogleFonts.outfit(
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                  color: widget.color,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: isMobile ? 9 : 10,
                          color: (isDark ? Colors.white70 : AppColors.textSecondary).withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isHovered)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: widget.color,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ActivityFeed extends StatelessWidget {
  final List<ActivityItem> items;
  final VoidCallback? onViewAll;

  const ActivityFeed({super.key, required this.items, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark.withValues(alpha:0.9) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? Colors.white.withValues(alpha:0.02) : Colors.white,
            isDark ? Colors.white.withValues(alpha:0.00) : AppColors.divider.withValues(alpha:0.1),
          ],
        ),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha:0.08) : AppColors.divider.withValues(alpha:0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:isDark ? 0.15 : 0.02),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE ACTIVITY',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View All',
                  style: GoogleFonts.outfit(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const EmptyStatePlaceholder(
              icon: Icons.notifications_none_rounded,
              title: 'No recent activity',
              subtitle: 'All systems operational. New updates will appear here in real-time.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: (isDark ? Colors.white : AppColors.divider).withValues(alpha: 0.06)),
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return InkWell(
                  onTap: item.onTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                item.color.withValues(alpha: 0.15),
                                item.color.withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: item.color.withValues(alpha: 0.2), width: 1),
                          ),
                          child: Center(
                            child: Icon(item.icon, color: item.color, size: 18),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.subtitle,
                                style: GoogleFonts.outfit(
                                  color: (isDark ? Colors.white70 : AppColors.textSecondary).withValues(alpha:0.8),
                                  fontSize: 12,
                                  height: 1.3,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.time,
                          style: GoogleFonts.outfit(
                            color: AppColors.textSecondary.withValues(alpha:0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class ActivityItem {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  ActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileCrossAxisCount;
  final int tabletCrossAxisCount;
  final int desktopCrossAxisCount;
  final double spacing;
  final double? childAspectRatio;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileCrossAxisCount = 2,
    this.tabletCrossAxisCount = 3,
    this.desktopCrossAxisCount = 4,
    this.spacing = 24,
    this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = mobileCrossAxisCount;
        if (constraints.maxWidth > 1200) {
          crossAxisCount = desktopCrossAxisCount;
        } else if (constraints.maxWidth > 700) {
          crossAxisCount = tabletCrossAxisCount;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: childAspectRatio ?? (constraints.maxWidth > 700 ? 1.4 : 1.1),
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

class AnimatedTransform extends StatelessWidget {
  final Widget child;
  final Matrix4 transform;
  final Duration duration;

  const AnimatedTransform({
    super.key,
    required this.child,
    required this.transform,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Matrix4>(
      tween: Matrix4Tween(begin: Matrix4.identity(), end: transform),
      duration: duration,
      builder: (context, value, child) {
        return Transform(
          transform: value,
          child: child,
        );
      },
      child: child,
    );
  }
}

class DashboardRefreshBar extends StatelessWidget {
  final DateTime? lastUpdated;
  final bool isLoading;
  final VoidCallback onRefresh;

  const DashboardRefreshBar({
    super.key,
    required this.lastUpdated,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String label;
    if (isLoading) {
      label = 'Refreshing...';
    } else if (lastUpdated != null) {
      final diff = DateTime.now().difference(lastUpdated!);
      if (diff.inSeconds < 60) {
        label = 'Updated just now';
      } else if (diff.inMinutes < 60) {
        label = 'Updated ${diff.inMinutes}m ago';
      } else {
        label = 'Updated at ${DateFormat('HH:mm').format(lastUpdated!)}';
      }
    } else {
      label = 'Not yet loaded';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: isDark ? Colors.white38 : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 30,
          height: 30,
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(6),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                  tooltip: 'Refresh',
                  onPressed: onRefresh,
                ),
        ),
      ],
    );
  }
}

class EmptyStatePlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? color;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStatePlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor = color ?? AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark 
            ? AppColors.surfaceDark.withValues(alpha:0.3) 
            : themeColor.withValues(alpha:0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha:0.05) 
              : themeColor.withValues(alpha:0.05),
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha:0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 40,
              color: themeColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: (isDark ? Colors.white70 : AppColors.textSecondary).withValues(alpha:0.8),
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(actionLabel!),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
