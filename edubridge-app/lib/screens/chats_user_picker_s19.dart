// S19 specialist-only contact picker: centered modal matching the Figma image.
// Names come from /conversation-users, never from the design's sample content.
part of 'chats_screen.dart';

class SpecialistContactPickerDialog extends StatelessWidget {
  const SpecialistContactPickerDialog({
    super.key,
    required this.users,
    required this.onSelect,
  });

  final List users;
  final ValueChanged<Map> onSelect;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF112F4B);
    const blue = Color(0xFF176BC9);
    const pale = Color(0xFFF0F5FA);
    final available = users.whereType<Map>().toList(growable: false);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.68;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 360, maxHeight: maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline_rounded, color: blue, size: 23),
                    SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        'فريق التواصل',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ink,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                if (available.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 22),
                    child: Text(
                      'لا يوجد مستخدمون متاحون',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF637D97), fontSize: 14),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: available.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 9),
                      itemBuilder: (context, index) {
                        final user = available[index];
                        final name = (user['name'] ?? '').toString().trim();
                        return Material(
                          color: pale,
                          borderRadius: BorderRadius.circular(19),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            key: ValueKey('s19_contact_${user['id']}'),
                            onTap: user['id'] == null
                                ? null : () => onSelect(user),
                            child: SizedBox(
                              height: 53,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name.isEmpty ? 'مستخدم' : name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: ink,
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: Icon(
                                        Icons.arrow_back_rounded,
                                        color: Colors.white,
                                        size: 23,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 53,
                  child: OutlinedButton(
                    key: const ValueKey('s19_cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFE6F0FB),
                      foregroundColor: blue,
                      side: const BorderSide(color: blue, width: 1.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17)),
                    ),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
