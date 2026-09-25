part of 'choose_specialty_screen.dart';

extension _ChooseSpecialtyScreenStateView on _ChooseSpecialtyScreenState {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(title: 'تحديد التخصص'),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.orange.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  const Icon(AppIcons.warning,
                      color: AppColors.orangeDeep, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تخصصك غير محدد',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.orangeDeep,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'لتتمكن من متابعة الأطفال، يجب تحديد تخصصك. لا يمكن تغييره لاحقاً إلا عبر الدعم.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: c.onTint,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'اختر تخصصك:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: c.heading,
              ),
            ),
            const SizedBox(height: 16),

            _SpecialtyCard(
              icon: AppIcons.specialist,
              title: 'مختص دعم تعليمي',
              description:
                  'متابعة احتياجات التعلم والتكييفات التعليمية ودعم المشاركة والتقدم الأكاديمي',
              color: AppColors.purple,
              selected: _selected == 'learning_support',
              onTap: () => setState(() => _selected = 'learning_support'),
            ),
            const SizedBox(height: 12),

            _SpecialtyCard(
              icon: AppIcons.lesson,
              title: 'مختص تعليمي',
              description:
                  'تقييم الجانب التعليمي، تصميم الخطط التعليمية، ومتابعة تقدّم الأطفال',
              color: AppColors.brandBlue,
              selected: _selected == 'educational',
              onTap: () => setState(() => _selected = 'educational'),
            ),

            const Spacer(),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(AppIcons.error,
                        color: AppColors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selected == null
                      ? Colors.grey
                      : (_selected == 'learning_support'
                          ? AppColors.purple
                          : AppColors.brandBlue),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(AppIcons.check),
                label: Text(
                  _saving ? 'جارٍ الحفظ...' : 'تأكيد التخصص',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed:
                    _selected == null || _saving ? null : _save,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'بعد الحفظ، لا يمكن التغيير إلا بالتواصل مع الدعم الفني',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: c.muted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  
  }
}
