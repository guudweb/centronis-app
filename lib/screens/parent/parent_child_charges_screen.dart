import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/finance_service.dart';
import '../../widgets/common/loading_widget.dart';

class ParentChildChargesScreen extends ConsumerStatefulWidget {
  final int studentId;
  const ParentChildChargesScreen({super.key, required this.studentId});

  @override
  ConsumerState<ParentChildChargesScreen> createState() =>
      _ParentChildChargesScreenState();
}

class _ParentChildChargesScreenState
    extends ConsumerState<ParentChildChargesScreen> {
  StudentCharges? _data;
  bool _loading = true;
  String? _error;

  String get _currency =>
      ref.read(authProvider).user?.institution?.currency ?? 'XAF';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(financeServiceProvider)
          .getStudentCharges(widget.studentId);
      if (!mounted) return;
      setState(() {
        _data = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Cargos y Pagos')),
      body: _loading
          ? const LoadingWidget(message: 'Cargando cargos...')
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.alertCircle,
                          size: 48, color: AppTheme.errorColor),
                      const SizedBox(height: 12),
                      Text('Error al cargar cargos',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _load,
                        icon: const Icon(LucideIcons.refreshCw, size: 16),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSummary(theme),
                      const SizedBox(height: 20),
                      Text('Detalle de Cargos',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      if (_data!.charges.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(LucideIcons.receipt,
                                    size: 40,
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.4)),
                                const SizedBox(height: 8),
                                Text('No hay cargos registrados',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme
                                            .colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._data!.charges.map((c) => _chargeCard(theme, c)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummary(ThemeData theme) {
    final summary = _data?.summary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen Financiero',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _summaryItem(
                    theme,
                    'Total Cobrado',
                    summary?.totalCharged ?? 0,
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _summaryItem(
                    theme,
                    'Total Pagado',
                    summary?.totalPaid ?? 0,
                    AppTheme.successColor,
                  ),
                ),
                Expanded(
                  child: _summaryItem(
                    theme,
                    'Pendiente',
                    summary?.totalPending ?? 0,
                    AppTheme.warningColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(
      ThemeData theme, String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          '${amount.toStringAsFixed(0)} $_currency',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: color),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center),
      ],
    );
  }

  Widget _chargeCard(ThemeData theme, Charge charge) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    charge.description.isNotEmpty
                        ? charge.description
                        : charge.conceptName ?? 'Cargo #${charge.id}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                _statusChip(charge.status),
              ],
            ),
            if (charge.conceptName != null &&
                charge.description.isNotEmpty &&
                charge.conceptName != charge.description)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(charge.conceptName!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                _amountCol(theme, 'Monto', charge.amountDue),
                _amountCol(theme, 'Pagado', charge.amountPaid),
                _amountCol(theme, 'Saldo', charge.balance),
              ],
            ),
            if (charge.dueDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(LucideIcons.calendar,
                      size: 13, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('Vence: ${charge.dueDate}',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _amountCol(ThemeData theme, String label, double amount) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text('${amount.toStringAsFixed(0)} $_currency',
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final (label, color) = switch (status.toLowerCase()) {
      'paid' => ('Pagado', AppTheme.successColor),
      'partial' => ('Parcial', AppTheme.infoColor),
      'overdue' => ('Vencido', AppTheme.errorColor),
      'cancelled' => ('Cancelado', Colors.grey),
      _ => ('Pendiente', AppTheme.warningColor),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
