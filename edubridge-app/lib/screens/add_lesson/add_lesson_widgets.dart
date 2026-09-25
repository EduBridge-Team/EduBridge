part of 'add_lesson_sheet.dart';

extension _AddLessonWidgets on _AddLessonSheetState {
  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(AppIcons.lesson, color: AppColors.brandBlue, size: 26),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'إضافة درس جديد',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(AppIcons.close),
          onPressed: widget.onClose,
        ),
      ],
    );
  }

  Widget _buildForParentsToggle(JisrColors c) {
    return Container(
      decoration: BoxDecoration(
        color: _forParents ? AppColors.brandTealDeep.withValues(alpha: 0.1) : c.tintTeal,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _forParents ? AppColors.brandTeal : c.line,
          width: _forParents ? 2 : 1.5,
        ),
      ),
      child: SwitchListTile(
        value: _forParents,
        activeThumbColor: AppColors.brandTealDeep,
        onChanged: (v) => _updateLessonSheetState(() => _forParents = v),
        title: Row(
          children: [
            const Icon(AppIcons.parent, color: AppColors.brandTealDeep, size: 22),
            const SizedBox(width: 8),
            Text(
              'درس مخصص لأولياء الأمور',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: c.heading,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4, right: 30),
          child: Text(
            _forParents
                ? 'سيظهر في شاشة "دروس لولي الأمر" فقط'
                : 'فعّل هذا إذا كان الدرس موجّهاً للأسرة',
            style: TextStyle(fontSize: 12, color: c.muted, height: 1.4),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBox() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.error, color: AppColors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_error!, style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onClose,
            child: const Text('إلغاء'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _forParents ? AppColors.brandTealDeep : AppColors.green,
              foregroundColor: Colors.white,
            ),
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(AppIcons.save),
            onPressed: _saving ? null : _save,
            label: Text(
              _saving ? 'جارِ الحفظ...' : 'حفظ الدرس',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
