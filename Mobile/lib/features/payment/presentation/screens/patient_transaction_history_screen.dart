import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/widgets.dart';
import '../cubits/payment_history_cubit.dart';
import '../widgets/transaction_tile.dart';

class PatientTransactionHistoryScreen extends StatelessWidget {
  const PatientTransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PaymentHistoryCubit>()..load(),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        centerTitle: true,
      ),
      body: BlocBuilder<PaymentHistoryCubit, PaymentHistoryState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => context.read<PaymentHistoryCubit>().refresh(),
            child: switch (state) {
              PaymentHistoryInitial() ||
              PaymentHistoryLoading() =>
                const TransactionListSkeleton(),
              PaymentHistoryError(:final message) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.8,
                      child: ErrorView(
                        message: message,
                        onRetry: () =>
                            context.read<PaymentHistoryCubit>().refresh(),
                      ),
                    ),
                  ],
                ),
              PaymentHistoryLoaded(:final transactions) =>
                transactions.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.8,
                            child: const EmptyStateView(
                              icon: Icons.receipt_long_outlined,
                              title: 'No transactions yet',
                              subtitle:
                                  'Your payments and receipts will appear here.',
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: transactions.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => TransactionTile(
                          tx: transactions[i],
                          isPatient: true,
                          receiptRoute: '/patient/payments/receipt',
                        ),
                      ),
            },
          );
        },
      ),
    );
  }
}
