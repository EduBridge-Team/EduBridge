part of 'case_discussion_screen.dart';

class _MessageBubble extends StatelessWidget {
  final CaseMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    Color bgColor;
    Color iconColor;
    String typeLabel;
    IconData typeIcon;

    switch (message.type) {
      case CaseMessageType.observation:
        bgColor = c.tintYellow;
        iconColor = AppColors.orangeDeep;
        typeLabel = 'ملاحظة';
        typeIcon = AppIcons.view;
        break;
      case CaseMessageType.decision:
        bgColor = AppColors.green.withValues(alpha: 0.1);
        iconColor = AppColors.green;
        typeLabel = 'قرار';
        typeIcon = AppIcons.check;
        break;
      case CaseMessageType.question:
        bgColor = c.tintTeal;
        iconColor = AppColors.brandBlue;
        typeLabel = 'سؤال';
        typeIcon = AppIcons.info;
        break;
      default:
        bgColor = c.card;
        iconColor = c.muted;
        typeLabel = '';
        typeIcon = AppIcons.chat;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: iconColor.withValues(alpha: 0.15),
                  child: Icon(typeIcon, size: 14, color: iconColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message.senderName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: c.heading,
                    ),
                  ),
                ),
                if (typeLabel.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                Text(
                  '${message.createdAt.hour}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 11, color: c.muted),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message.content,
              style: TextStyle(fontSize: 14, height: 1.5, color: c.body),
            ),
          ],
        ),
      ),
    );
  }
}