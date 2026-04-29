import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:last_mile_fleet/features/finance/presentation/cod_reconciliation_screen.dart';
import 'package:last_mile_fleet/features/finance/presentation/payroll_processing_screen.dart';

class FinanceDashboard extends ConsumerWidget {
  final bool showScaffold;
  const FinanceDashboard({super.key, this.showScaffold = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!showScaffold) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildContent(context),
              ]),
            ),
          ),
        ],
      );
    }

    return DashboardScaffold(
      title: 'FINANCIAL CONTROL',
      subtitle: 'COD reconciliation, payroll, and vendor invoicing',
      children: [
        _buildContent(context),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Financial Health Section
        _buildSectionHeader('Fiscal Overview'),
        const SizedBox(height: 24),
        ResponsiveGrid(
          children: const [
            DashboardStatCard(
              label: 'Pending COD',
              value: '﷼ 42.8k',
              icon: Icons.payments_outlined,
              color: Colors.green,
              trend: 'To be reconciled',
              sparklineData: [35, 40, 38, 45, 42, 42.8],
            ),
            DashboardStatCard(
              label: 'Fuel Expenses',
              value: '﷼ 8.2k',
              icon: Icons.local_gas_station_outlined,
              color: Colors.orange,
              trend: 'Within budget',
            ),
            DashboardStatCard(
              label: 'Net Profit/Deliv',
              value: '﷼ 4.2',
              icon: Icons.analytics_outlined,
              color: Colors.blue,
              trend: 'High efficiency',
            ),
            DashboardStatCard(
              label: 'Vendor Receivables',
              value: '﷼ 124k',
              icon: Icons.account_balance_outlined,
              color: Colors.purple,
              trend: 'Invoicing due',
            ),
          ],
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
                        title: 'COD Reconciliation Hub',
                        subtitle: 'Match cash collected with platform data',
                        icon: Icons.account_balance_wallet_outlined,
                        color: Colors.green,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CODReconciliationScreen()));
                        },
                      ),
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
                  _buildSectionHeader('Cash Reconciliation'),
                  const SizedBox(height: 24),
                  _buildCashStatusCard('Amazon COD', 12400, Colors.blue),
                  const SizedBox(height: 12),
                  _buildCashStatusCard('Noon COD', 8500, Colors.amber),
                  const SizedBox(height: 12),
                  _buildCashStatusCard('Keeta COD', 4200, Colors.orange),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Upcoming Invoices'),
                  const SizedBox(height: 24),
                  _buildInvoiceItem('Noon Logistics', 'May 2024 Cycle', '﷼ 45,000'),
                  const Divider(height: 32),
                  _buildInvoiceItem('Amazon SA', 'April Reconciliation', '﷼ 32,400'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCashStatusCard(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.currency_exchange_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Text('Pending deposit', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text('﷼ ${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
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
