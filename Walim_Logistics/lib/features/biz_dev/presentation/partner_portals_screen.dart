import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

final partnerPortalsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final now = DateTime.now();
  final monthStart =
      DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];

  final platforms =
      await supabase.from('platforms').select('id, name, description');

  final reports = await supabase
      .from('platform_reports')
      .select('platform_id, delivery_count, total_cod_amount')
      .gte('report_date', monthStart);

  final deliveryMap = <String, int>{};
  final revenueMap = <String, double>{};
  for (final r in reports as List) {
    final pid = r['platform_id'] as String? ?? '';
    deliveryMap[pid] =
        (deliveryMap[pid] ?? 0) + ((r['delivery_count'] as num?)?.toInt() ?? 0);
    revenueMap[pid] = (revenueMap[pid] ?? 0) +
        ((r['total_cod_amount'] as num?)?.toDouble() ?? 0);
  }

  return (platforms as List).map<Map<String, dynamic>>((p) {
    final id = p['id'] as String;
    return {
      'id': id,
      'name': p['name'] as String? ?? 'Unknown',
      'description': p['description'] as String? ?? '',
      'deliveries': deliveryMap[id] ?? 0,
      'revenue': revenueMap[id] ?? 0.0,
    };
  }).toList();
});

const _platformColors = [
  Colors.amber,
  Colors.orange,
  Colors.blue,
  Colors.green,
  Colors.purple,
  Colors.teal,
];

class PartnerPortalsScreen extends ConsumerWidget {
  const PartnerPortalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platformsAsync = ref.watch(partnerPortalsProvider);
    final currFmt =
        NumberFormat.compactCurrency(symbol: '﷼ ', decimalDigits: 1);

    return DashboardScaffold(
      title: 'PARTNER PORTALS',
      subtitle: 'Platform performance this month',
      showBackButton: true,
      children: [
        platformsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (platforms) {
            if (platforms.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text('No platforms configured.',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.6,
              ),
              itemCount: platforms.length,
              itemBuilder: (context, index) {
                final p = platforms[index];
                final color = _platformColors[index % _platformColors.length];
                final deliveries = p['deliveries'] as int;
                final revenue = p['revenue'] as double;
                final name = p['name'] as String;

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10)),
                            child: Center(
                              child: Text(name[0],
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(name,
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        deliveries > 0
                            ? '${NumberFormat.compact().format(deliveries)} deliveries'
                            : 'No data this month',
                        style: GoogleFonts.outfit(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        revenue > 0 ? currFmt.format(revenue) : '—',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: color),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
