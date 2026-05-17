import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/hr/presentation/rider_detail_screen.dart';
import 'package:flutter/services.dart';

class AssetManagementScreen extends StatefulWidget {
  final bool showScaffold;
  const AssetManagementScreen({super.key, this.showScaffold = true});

  @override
  State<AssetManagementScreen> createState() => _AssetManagementScreenState();
}

class _AssetManagementScreenState extends State<AssetManagementScreen> {
  String _searchQuery = '';
  String _selectedRole = 'All';

  final List<Map<String, dynamic>> _staffAssets = [
    {
      'name': 'Ahmed Ali',
      'role': 'Rider',
      'assets': [
        {'type': 'Vehicle', 'id': 'V-9021', 'desc': 'Honda CD 110', 'status': 'Active', 'date': 'Issued: 12 Jan 2026'},
        {'type': 'Fuel Card', 'id': 'FC-442', 'desc': 'Aramco 500 SAR', 'status': 'Active', 'date': 'Issued: 15 Jan 2026'},
        {'type': 'Uniform', 'id': 'U-XL', 'desc': 'Set of 2', 'status': 'Active', 'date': 'Issued: 10 Jan 2026'},
      ]
    },
    {
      'name': 'Mohammed Khan',
      'role': 'Rider',
      'assets': [
        {'type': 'Vehicle', 'id': 'V-8812', 'desc': 'Yamaha YS125', 'status': 'Active', 'date': 'Issued: 02 Feb 2026'},
        {'type': 'Smartphone', 'id': 'SP-77', 'desc': 'Samsung A14', 'status': 'Pending Return', 'date': 'Return requested'},
      ]
    },
    {
      'name': 'Sarah Al-Otaibi',
      'role': 'Operations',
      'assets': [
        {'type': 'Laptop', 'id': 'LP-012', 'desc': 'MacBook Air M2', 'status': 'Active', 'date': 'Issued: 20 Dec 2025'},
        {'type': 'Access Badge', 'id': 'AB-404', 'desc': 'HQ Level 2', 'status': 'Active', 'date': 'Issued: 20 Dec 2025'},
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    // Filter logic
    final filteredStaff = _staffAssets.where((staff) {
      final matchesRole = _selectedRole == 'All' || staff['role'] == _selectedRole;
      final matchesQuery = _searchQuery.isEmpty ||
          staff['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          staff['role'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (staff['assets'] as List).any((asset) =>
              asset['type'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
              asset['id'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
              asset['desc'].toString().toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesRole && matchesQuery;
    }).toList();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAssetStats(context),
        const SizedBox(height: 24),
        _buildSearchAndFilterControls(context),
        const SizedBox(height: 24),
        _buildStaffAssetList(context, filteredStaff),
      ],
    );

    if (!widget.showScaffold) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 40 : 20,
              vertical: isDesktop ? 10 : 20,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                content,
              ]),
            ),
          ),
        ],
      );
    }

    return DashboardScaffold(
      title: 'ASSET RESPONSIBILITY',
      subtitle: 'Tracking company assets assigned to staff members',
      showBackButton: true,
      activeItem: 'Assets',
      children: [
        content,
      ],
    );
  }

  Widget _buildAssetStats(BuildContext context) {
    return Row(
      children: [
        _HoverableStatCard(
          label: 'Assigned Assets',
          value: '342',
          subtext: '94% of total inventory',
          icon: Icons.inventory_2_rounded,
          color: AppColors.primary,
          gradientColors: const [AppColors.primary, AppColors.primaryLight],
        ),
        const SizedBox(width: 16),
        _HoverableStatCard(
          label: 'Awaiting Return',
          value: '18',
          subtext: '8 items due today',
          icon: Icons.assignment_return_rounded,
          color: Colors.orange,
          gradientColors: const [Colors.orange, Colors.amber],
        ),
        const SizedBox(width: 16),
        _HoverableStatCard(
          label: 'Damaged/Lost',
          value: '4',
          subtext: '-2 cases since last month',
          icon: Icons.report_problem_rounded,
          color: Colors.red,
          gradientColors: const [Colors.red, Colors.redAccent],
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterControls(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // Search Input
          Expanded(
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              style: GoogleFonts.outfit(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search staff name, role, or asset serial...',
                hintStyle: GoogleFonts.outfit(color: isDark ? Colors.white38 : AppColors.textSecondary.withValues(alpha: 0.6)),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.02) : AppColors.background.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Filter Chips
          Row(
            children: ['All', 'Rider', 'Operations'].map((role) {
              final isSelected = _selectedRole == role;
              final chipColor = role == 'Rider' ? AppColors.primary : Colors.indigo;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text(
                    role == 'All' ? 'All Staff' : '$role Staff',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.textSecondary),
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedRole = role;
                      });
                    }
                  },
                  selectedColor: chipColor,
                  backgroundColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
                  checkmarkColor: Colors.white,
                  side: BorderSide(
                    color: isSelected 
                        ? Colors.transparent 
                        : (isDark ? Colors.white10 : theme.dividerColor.withValues(alpha: 0.5)),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffAssetList(BuildContext context, List<Map<String, dynamic>> filteredStaff) {
    if (filteredStaff.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: AppColors.primary.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(
                'No staff or assets match your criteria',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredStaff.length,
      itemBuilder: (context, index) {
        final staff = filteredStaff[index];
        return _StaffAssetCard(
          staff: staff,
          onAvatarTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const RiderDetailScreen()));
          },
        );
      },
    );
  }
}

class _HoverableStatCard extends StatefulWidget {
  final String label;
  final String value;
  final String subtext;
  final IconData icon;
  final Color color;
  final List<Color> gradientColors;

  const _HoverableStatCard({
    required this.label,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.color,
    required this.gradientColors,
  });

  @override
  State<_HoverableStatCard> createState() => _HoverableStatCardState();
}

class _HoverableStatCardState extends State<_HoverableStatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..translate(0.0, _isHovered ? -6.0 : 0.0),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isHovered 
                  ? widget.color.withValues(alpha: 0.5) 
                  : (isDark ? Colors.white10 : theme.dividerColor.withValues(alpha: 0.5)),
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered 
                    ? widget.color.withValues(alpha: isDark ? 0.15 : 0.08) 
                    : Colors.black.withValues(alpha: 0.01),
                blurRadius: _isHovered ? 20 : 10,
                offset: Offset(0, _isHovered ? 10 : 4),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isHovered 
                        ? widget.gradientColors 
                        : [widget.color.withValues(alpha: 0.12), widget.color.withValues(alpha: 0.06)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  widget.icon, 
                  color: _isHovered ? Colors.white : widget.color, 
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      textBaseline: TextBaseline.alphabetic,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      children: [
                        Text(
                          widget.value, 
                          style: GoogleFonts.outfit(
                            fontSize: 26, 
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (_isHovered)
                          Icon(
                            Icons.trending_up_rounded, 
                            color: widget.color, 
                            size: 16,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.label, 
                      style: GoogleFonts.outfit(
                        color: isDark ? Colors.white : AppColors.textPrimary, 
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      widget.subtext, 
                      style: GoogleFonts.outfit(
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5), 
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaffAssetCard extends StatefulWidget {
  final Map<String, dynamic> staff;
  final VoidCallback onAvatarTap;

  const _StaffAssetCard({
    required this.staff,
    required this.onAvatarTap,
  });

  @override
  State<_StaffAssetCard> createState() => _StaffAssetCardState();
}

class _StaffAssetCardState extends State<_StaffAssetCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isHovered = false;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _rotationController.forward();
      } else {
        _rotationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final staff = widget.staff;
    final List assets = staff['assets'];

    // Define colors based on role
    final bool isRider = staff['role'] == 'Rider';
    final Color roleColor = isRider ? AppColors.primary : Colors.indigo;
    final List<Color> avatarGradient = isRider 
        ? [AppColors.primary, AppColors.primaryLight] 
        : [Colors.indigo, Colors.blue];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isHovered 
                ? roleColor.withValues(alpha: 0.4) 
                : (isDark ? Colors.white10 : theme.dividerColor.withValues(alpha: 0.5)),
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered 
                  ? roleColor.withValues(alpha: isDark ? 0.08 : 0.04) 
                  : Colors.black.withValues(alpha: 0.01),
              blurRadius: _isHovered ? 24 : 12,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Collapse-Header
            InkWell(
              onTap: _toggleExpanded,
              borderRadius: BorderRadius.circular(24),
              hoverColor: Colors.transparent,
              splashColor: roleColor.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: widget.onAvatarTap,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: avatarGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                staff['name'][0], 
                                style: GoogleFonts.outfit(
                                  color: roleColor, 
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Name & Role Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            staff['name'], 
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold, 
                              fontSize: 17,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: roleColor.withValues(alpha: 0.15)),
                            ),
                            child: Text(
                              staff['role'].toUpperCase(), 
                              style: GoogleFonts.outfit(
                                fontSize: 10, 
                                fontWeight: FontWeight.bold,
                                color: roleColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Quick assets overview mini icons (cool desktop only feature)
                    if (MediaQuery.of(context).size.width > 700 && !_isExpanded)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: assets.map((asset) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Tooltip(
                              message: '${asset['type']}: ${asset['desc']}',
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.background,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isDark ? Colors.white10 : theme.dividerColor.withValues(alpha: 0.5)),
                                ),
                                child: Icon(
                                  _getAssetIconData(asset['type']),
                                  size: 14,
                                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(width: 16),
                    // Active badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 12, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            '${assets.length} Assets', 
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold, 
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Custom rotating chevron
                    RotationTransition(
                      turns: _rotationAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Expand-Body with AnimatedSize
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              child: _isExpanded
                  ? Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Divider(height: 1, color: isDark ? Colors.white10 : theme.dividerColor.withValues(alpha: 0.5)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'ASSIGNED EQUIPMENT',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Assigning new asset coming soon!')),
                                      );
                                    },
                                    icon: const Icon(Icons.add_rounded, size: 16),
                                    label: Text(
                                      'Add Asset',
                                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      padding: EdgeInsets.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Grid of mini-cards (or List for mobile)
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth > 650;
                                  if (isWide) {
                                    return GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                        mainAxisExtent: 90,
                                      ),
                                      itemCount: assets.length,
                                      itemBuilder: (context, idx) => _buildAssetItemCard(context, assets[idx]),
                                    );
                                  } else {
                                    return Column(
                                      children: assets.map((asset) => Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: _buildAssetItemCard(context, asset),
                                      )).toList(),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetItemCard(BuildContext context, Map<String, dynamic> asset) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final String type = asset['type'];
    final String id = asset['id'];
    final String desc = asset['desc'];
    final String status = asset['status'] ?? 'Active';
    final String date = asset['date'] ?? 'Issued: Just Now';

    // Color systems
    Color iconColor;
    List<Color> iconGrad;
    switch (type) {
      case 'Vehicle':
        iconColor = AppColors.primary;
        iconGrad = [AppColors.primary, AppColors.primaryLight];
        break;
      case 'Laptop':
        iconColor = Colors.purple;
        iconGrad = [Colors.purple, Colors.purpleAccent];
        break;
      case 'Smartphone':
        iconColor = Colors.teal;
        iconGrad = [Colors.teal, Colors.tealAccent];
        break;
      case 'Fuel Card':
        iconColor = Colors.amber;
        iconGrad = [Colors.amber, Colors.orange];
        break;
      default:
        iconColor = Colors.indigo;
        iconGrad = [Colors.indigo, Colors.blue];
    }

    final bool isPending = status == 'Pending Return';
    final Color statusColor = isPending ? Colors.orange : Colors.green;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : AppColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.04) : theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [iconGrad[0].withValues(alpha: 0.12), iconGrad[1].withValues(alpha: 0.04)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withValues(alpha: 0.2)),
            ),
            child: Icon(_getAssetIconData(type), size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          // Desc & details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      type, 
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, 
                        fontSize: 13,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.outfit(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  desc, 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 11, 
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Actions
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Code Tag
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Text('$type ID $id copied to clipboard!'),
                        ],
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? Colors.white10 : theme.dividerColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        id, 
                        style: GoogleFonts.robotoMono(
                          fontSize: 10, 
                          color: AppColors.primary, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.copy_rounded, size: 10, color: AppColors.primary.withValues(alpha: 0.6)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // More Actions Button
              InkWell(
                onTap: () {
                  _showAssetActionsMenu(context, type, id);
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Text(
                    'Manage',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAssetActionsMenu(BuildContext context, String type, String id) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Manage $type ($id)',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.assignment_return_rounded, color: Colors.blue),
                title: Text('Return / Handover Asset', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                subtitle: Text('Return this equipment to central inventory', style: GoogleFonts.outfit(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Return requested!')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.report_problem_rounded, color: Colors.orange),
                title: Text('Report Damaged or Lost', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                subtitle: Text('File an incident report for this asset', style: GoogleFonts.outfit(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Damage report initiated!')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.history_rounded, color: Colors.indigo),
                title: Text('View Assignment History', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                subtitle: Text('See previous staff assigned to this asset', style: GoogleFonts.outfit(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('History log coming soon!')));
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  IconData _getAssetIconData(String type) {
    switch (type) {
      case 'Vehicle': return Icons.motorcycle_rounded;
      case 'Laptop': return Icons.laptop_mac_rounded;
      case 'Smartphone': return Icons.phone_android_rounded;
      case 'Fuel Card': return Icons.credit_card_rounded;
      default: return Icons.inventory_2_outlined;
    }
  }
}
