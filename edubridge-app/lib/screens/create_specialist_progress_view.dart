part of 'create_specialist_progress_screen.dart';

extension CreateSpecialistProgressScreenStateView on _CreateSpecialistProgressScreenState {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(title: 'تقييم تقدّم ${widget.childName}'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loadingReport)
              const Center(child: CircularProgressIndicator())
            else if (_teacherReport != null)
              _buildTeacherReportCard(_teacherReport!, c)
            else
              _buildNoReportCard(c),

            const SizedBox(height: 20),

            TextFormField(
              controller: _notesCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'ملاحظاتك على تقدّم الطفل',
                prefixIcon: Icon(AppIcons.edit),
                alignLabelWithHint: true,
                hintText: 'كيف ترى تقدّم الطفل من واقع تقرير المعلم؟',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _recommendationsCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'توصياتك للمعلم',
                prefixIcon: Icon(AppIcons.info),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.tintTeal,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'هل الخطة التعليمية مناسبة لتقدّم الطفل؟',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  RadioGroup<bool>(
                    groupValue: _planAppropriate,
                    onChanged: (v) {
                      if (v != null) setState(() => _planAppropriate = v);
                    },
                    child: const Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            contentPadding: EdgeInsets.zero,
                            title: Text('مناسبة'),
                            value: true,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            contentPadding: EdgeInsets.zero,
                            title: Text('تحتاج تعديل'),
                            value: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_planAppropriate) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _planEvalCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'ما التعديلات المقترحة؟',
                        hintText: 'اشرح للمعلم ما يحتاج تغيير',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.tintYellow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'مشاركة الطفل التعليمية هذا الأسبوع:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (i) {
                      final rating = i + 1;
                      final icons = [
                        Icons.sentiment_very_dissatisfied,
                        Icons.sentiment_dissatisfied,
                        Icons.sentiment_neutral,
                        Icons.sentiment_satisfied,
                        Icons.sentiment_very_satisfied,
                      ];
                      final isSelected = _moodRating == rating;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _moodRating = rating),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.yellow.withValues(alpha: 0.3)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(
                                    color: AppColors.orange, width: 2)
                                : null,
                          ),
                          child: Icon(
                            icons[i],
                            size: 34,
                            color: isSelected
                                ? AppColors.orangeDeep
                                : c.muted,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: AppColors.red)),
            ],

            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(AppIcons.check),
                label: Text(
                  _saving ? 'جارِ الحفظ...' : 'حفظ التقييم',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  
  }
}
