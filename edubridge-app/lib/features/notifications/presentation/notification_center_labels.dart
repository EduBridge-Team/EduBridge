import 'package:flutter/widgets.dart';
import '../domain/notification_filter.dart';

class NotificationCenterLabels {
  NotificationCenterLabels(BuildContext context)
      : ar = Localizations.localeOf(context).languageCode == 'ar';
  final bool ar;
  String get search => ar ? 'البحث في الإشعارات' : 'Search notifications';
  String get clear => ar ? 'مسح البحث والفلاتر' : 'Clear search and filters';
  String get empty => ar ? 'لا توجد نتائج مطابقة في الإشعارات المحمّلة.'
      : 'No matching results in loaded notifications.';
  String get loadedOnly => ar
      ? 'البحث والفلاتر للإشعارات المحمّلة فقط. حمّل الأقدم للبحث في المزيد.'
      : 'Search and filters cover loaded notifications only. Load older notifications to search more.';
  String results(int shown, int loaded) => ar
      ? '$shown من $loaded إشعار محمّل' : '$shown of $loaded loaded notifications';
  String status(NotificationReadFilter filter) => switch (filter) {
    NotificationReadFilter.all => ar ? 'الكل' : 'All',
    NotificationReadFilter.unread => ar ? 'غير المقروء' : 'Unread',
    NotificationReadFilter.read => ar ? 'المقروء' : 'Read',
  };
}
