import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

import 'package:walim_logistics/features/finance/presentation/payroll_processing_screen.dart';
import 'package:intl/intl.dart';
import 'package:walim_logistics/features/finance/presentation/finance_notifier.dart';

class FinanceDashboard extends ConsumerWidget {
  final bool showScaffold;
  const FinanceDashboard({super.key, this.showScaffold = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(financeStatsProvider);
    final invoicesAsync = ref.watch(upcomingInvoicesProvider);

    final content = _buildContent(context, statsAsync, invoicesAsync);

    if (!showScaffold) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
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
      title: 'FINANCIAL CONTROL',
      subtitle: 'Payroll, vendor invoicing, and expenses',
      children: [
        content,
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    AsyncValue<Map<String, double>> statsAsync,
    AsyncValue<List<Map<String, dynamic>>> invoicesAsync,
  ) {
    final currencyFormat = NumberFormat.compactCurrency(symbol: '﷼ ', decimalDigits: 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Financial Health Section
        _buildSectionHeader('Fiscal Overview'),
        const SizedBox(height: 24),
        statsAsync.when(
          data: (stats) => ResponsiveGrid(
            children: [
              DashboardStatCard(
                label: 'COD Revenue',
                value: currencyFormat.format(stats['totalRevenue'] ?? 0.0),
                icon: Icons.payments_outlined,
                color: Colors.green,
                trend: 'This month',
                isPositive: (stats['totalRevenue'] ?? 0.0) > 0,
              ),
              DashboardStatCard(
                label: 'Avg per Delivery',
                value: currencyFormat.format(stats['profitPerDelivery'] ?? 0.0),
                icon: Icons.analytics_outlined,
                color: Colors.blue,
                trend: 'COD per delivery',
                isPositive: (stats['profitPerDelivery'] ?? 0.0) > 0,
              ),
              DashboardStatCard(
                label: 'Pending COD',
                value: currencyFormat.format(stats['pendingInvoices'] ?? 0.0),
                icon: Icons.receipt_long_outlined,
                color: Colors.orange,
                trend: 'Unreconciled',
                isPositive: (stats['pendingInvoices'] ?? 0.0) == 0,
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => const EmptyStatePlaceholder(
            icon: Icons.error_outline_rounded,
            title: 'Failed to load financial data',
            subtitle: 'Check your connection and try again.',
          ),
        ),

        const SizedBox(height: 48),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Side: Operations
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Financial Operations'),
                  const SizedBox(height: 24),
                  ResponsiveGrid(
                    mobileCrossAxisCount: 1,
                    tabletCrossAxisCount: 2,
                    desktopCrossAxisCount: 2,
                    childAspectRatio: 2.2,
                    children: [

                      DashboardActionCard(
                        title: 'Payroll & Bonuses',
                        subtitle: 'Automated salary & penalty calculation',
                        icon: Icons.monetization_on_outlined,
                        color: Colors.indigo,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PayrollProcessingScreen()));
                        },
                      ),
                      DashboardActionCard(
                        title: 'Vendor Invoicing',
                        subtitle: 'Generate monthly invoices for partners',
                        icon: Icons.description_outlined,
                        color: Colors.purple,
                        onTap: () {},
                      ),
                      DashboardActionCard(
                        title: 'Expense Management',
                        subtitle: 'Fuel card and maintenance tracking',
                        icon: Icons.receipt_long_outlined,
                        color: Colors.orange,
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            // Right Side: Cash Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Upcoming Invoices'),
                  const SizedBox(height: 24),
                  invoicesAsync.when(
                    data: (invoices) {
                      if (invoices.isEmpty) {
                        return const EmptyStatePlaceholder(
                          icon: Icons.description_outlined,
                          title: 'No upcoming invoices',
                          subtitle: 'All vendor and partner invoices are fully processed and up to date.',
                          color: Colors.purple,
                        );
                      }
                      return Column(
                        children: invoices.asMap().entries.map((entry) {
                          final invoice = entry.value;
                          final client = invoice['client_name'] ??
                              invoice['platform_name'] ??
                              'Unknown';
                          final cycle = invoice['billing_cycle'] ??
                              invoice['description'] ??
                              invoice['due_date'] ??
                              '';
                          final amount =
                              (invoice['amount'] as num?)?.toDouble() ?? 0.0;
                          return Column(children: [
                            _buildInvoiceItem(
                                client, cycle, currencyFormat.format(amount)),
                            if (entry.key < invoices.length - 1)
                              const Divider(height: 32),
                          ]);
                        }).toList(),
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (err, _) => const EmptyStatePlaceholder(
                      icon: Icons.error_outline_rounded,
                      title: 'Failed to load invoices',
                      subtitle: 'Check your connection and try again.',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInvoiceItem(String client, String cycle, String amount) {
    return Row(
      children: [
        const Icon(Icons.file_present_outlined, color: AppColors.textSecondary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(client, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(cycle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}
