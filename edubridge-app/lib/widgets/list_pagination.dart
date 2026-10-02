import 'package:flutter/material.dart';
import '../services/paged_list_controller.dart';

class ListPagination extends StatelessWidget {
  const ListPagination({super.key, required this.controller});
  final PagedListController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.lastPage <= 1) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            TextButton(onPressed: controller.loading || controller.page <= 1 ? null : () => controller.load(controller.page - 1), child: const Text('السابق')),
            Text('صفحة ${controller.page} من ${controller.lastPage} · ${controller.total} نتيجة'),
            TextButton(onPressed: controller.loading || controller.page >= controller.lastPage ? null : () => controller.load(controller.page + 1), child: const Text('التالي')),
          ],
        ),
      ),
    );
  }
}
