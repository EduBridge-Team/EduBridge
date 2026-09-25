part of 'edit_child_screen.dart';

extension _EditChildScreenStateView on _EditChildScreenState {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(title: 'تعديل بيانات الطفل'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.currentUserRole == 'parent')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.tintOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(AppIcons.info,
                        color: AppColors.orangeDeep),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'يمكنك تعديل البيانات الأساسية فقط. لا يمكنك تغيير المعلّم أو الأخصائي.',
                        style: TextStyle(
                            color: c.onTint,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'اسم الطفل'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'العمر'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration:
                  const InputDecoration(labelText: 'ملاحظات عامة (اختياري)'),
            ),

            if (_isAdmin) ...[
              const SizedBox(height: 20),
              Divider(color: c.line),
              const SizedBox(height: 16),
              Text(
                'إدارة المتابعة (للأدمن)',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: c.heading),
              ),
              const SizedBox(height: 12),

              if (_loadingTeachers)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<String>(
                  decoration:
                      const InputDecoration(labelText: 'المعلم المسؤول'),
                  items: _teachers
                      .map((t) => DropdownMenuItem(
                            value: t['id'].toString(),
                            child: Text(t['name']?.toString() ?? ''),
                          ))
                      .toList(),
                  onChanged: (v) => _newTeacherId = v,
                ),

              const SizedBox(height: 12),

              if (_loadingSpecialists)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<String>(
                  decoration:
                      const InputDecoration(labelText: 'المختص المسؤول'),
                  items: _specialists
                      .map((s) => DropdownMenuItem(
                            value: s['id'].toString(),
                            child: Text(s['name']?.toString() ?? ''),
                          ))
                      .toList(),
                  onChanged: (v) => _newSpecialistId = v,
                ),
            ],

            if (_isSpecialist) ...[
              const SizedBox(height: 20),
              Divider(color: c.line),
              const SizedBox(height: 16),
              Text(
                'تغيير المعلم (للمختص)',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: c.heading),
              ),
              const SizedBox(height: 8),
              if (_loadingTeachers)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'المعلم الجديد'),
                  items: _teachers
                      .map((t) => DropdownMenuItem(
                            value: t['id'].toString(),
                            child: Text(t['name']?.toString() ?? ''),
                          ))
                      .toList(),
                  onChanged: (v) => _newTeacherId = v,
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'أسباب التغيير',
                  hintText: 'اكتب سبب تغيير المعلم هنا...',
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(AppIcons.error,
                        color: AppColors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(color: AppColors.red)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(AppIcons.save),
              label: Text(_loading ? 'جارِ الحفظ...' : 'حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );
  
  }
}
