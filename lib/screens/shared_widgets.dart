import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../providers/menu_filter_provider.dart';

// ==================== SEARCH PANEL ====================
class SearchPanel extends ConsumerWidget {
  const SearchPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextField(
      onChanged: (value) => ref.read(menuFilterProvider.notifier).search(value),
      decoration: const InputDecoration(
        hintText: 'Search menu or order code',
        prefixIcon: Icon(Icons.search),
      ),
    );
  }
}

// ==================== CATEGORY CHIPS ====================
class CategoryChips extends ConsumerWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(menuFilterProvider).category;
    const categories = ['All', 'Meals', 'Drinks', 'Snacks', 'Dessert'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final category in categories) ...[
            FilterChip(
              selected: category == selectedCategory,
              onSelected: (_) => ref
                  .read(menuFilterProvider.notifier)
                  .selectCategory(category),
              label: Text(category),
              selectedColor: SmartCashierTheme.primary,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: category == selectedCategory
                    ? Colors.white
                    : SmartCashierTheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

// ==================== EMPTY MENU RESULT ====================
class EmptyMenuResult extends StatelessWidget {
  const EmptyMenuResult({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.search_off,
              size: 44,
              color: SmartCashierTheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'Menu not found',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text('Try another keyword or category.'),
          ],
        ),
      ),
    );
  }
}

// ==================== SECTION CARD ====================
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

// ==================== DETAIL ROW ====================
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: strong
                  ? SmartCashierTheme.onSurface
                  : SmartCashierTheme.onSurfaceVariant,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ==================== ORDER PROGRESS ====================
class OrderProgress extends StatelessWidget {
  const OrderProgress({super.key, required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const steps = ['Paid', 'Preparing', 'Ready', 'Picked up'];
    return SectionCard(
      title: 'Status',
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: i <= currentStep
                      ? SmartCashierTheme.primary
                      : SmartCashierTheme.surfaceVariant,
                  foregroundColor: i <= currentStep
                      ? Colors.white
                      : SmartCashierTheme.outline,
                  child: Icon(
                    i <= currentStep ? Icons.check : Icons.circle_outlined,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    steps[i],
                    style: TextStyle(
                      fontWeight: i <= currentStep
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (i != steps.length - 1)
              Container(
                height: 24,
                margin: const EdgeInsets.only(left: 13),
                alignment: Alignment.centerLeft,
                child: const VerticalDivider(
                  color: SmartCashierTheme.surfaceVariant,
                  thickness: 2,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ==================== ORDER HEADER CARD ====================
class OrderHeaderCard extends StatelessWidget {
  const OrderHeaderCard({super.key, required this.order});

  final CashierOrder order;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: SmartCashierTheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              foregroundColor: SmartCashierTheme.primary,
              child: Icon(Icons.receipt_long),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order ${order.id}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.status.label} - paid with QRIS',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== SMART CASHIER LOGO ====================
class SmartCashierLogo extends StatelessWidget {
  const SmartCashierLogo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: SmartCashierTheme.primary,
          borderRadius: BorderRadius.circular(size * 0.24),
        ),
        child: Icon(
          Icons.point_of_sale,
          color: Colors.white,
          size: size * 0.48,
        ),
      ),
    );
  }
}

// ==================== QR MARK ====================
class QrMark extends StatelessWidget {
  const QrMark({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 9,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: 81,
      itemBuilder: (context, index) {
        final filled = index % 2 == 0 || index % 7 == 0 || index == 40;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: filled ? SmartCashierTheme.onSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}