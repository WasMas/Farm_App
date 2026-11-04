import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/activity.dart';

class ActivityTile extends StatelessWidget {
  const ActivityTile(this.activity, {super.key, this.actions});
  final ActivityRecord activity;
  final Widget? actions;
  @override
  Widget build(BuildContext context) {
    final a = activity;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Text(
                  DateFormat('dd').format(DateTime.parse(a.date)),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  DateFormat('MMM')
                      .format(DateTime.parse(a.date))
                      .toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activityKinds[a.kind] ?? a.kind,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${a.cropName} / ${a.fieldName}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (a.amount.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      a.amount,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (a.product.isNotEmpty) Text(a.product),
                if (a.notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(a.notes),
                  ),
                const SizedBox(height: 8),
                Text(
                  '${a.farmName} · ${a.author}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          ?actions,
        ],
      ),
    );
  }
}
