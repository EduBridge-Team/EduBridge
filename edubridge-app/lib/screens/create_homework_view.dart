part of 'create_homework_screen.dart';

extension _CreateHomeworkScreenStateView on _CreateHomeworkScreenState {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(title: 'واجب جديد'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + safeModalBottom(context),
          ),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'عنوان الواجب *',
                prefixIcon: Icon(AppIcons.edit),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'العنوان مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'الوصف *',
                prefixIcon: Icon(AppIcons.info),
                alignLabelWithHint: true,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'الوصف مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(
                labelText: 'المادة (اختياري)',
                prefixIcon: Icon(AppIcons.lesson),
                hintText: 'مثال: رياضيات',
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDueDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.line),
                ),
                child: Row(
                  children: [
                    const Icon(AppIcons.calendar,
                        color: AppColors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'موعد التسليم',
                            style: TextStyle(fontSize: 12),
                          ),
                          Text(
                            '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(AppIcons.edit),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'تعيين لطلاب (${_selectedChildIds.length} محدد):',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.children.map((child) {
              final id = child['id'] as int;
              final name = child['name']?.toString() ?? '';
              final selected = _selectedChildIds.contains(id);
              return CheckboxListTile(
                value: selected,
                title: Text(name),
                subtitle: Text(child['disability_type']?.toString() ?? ''),
                onChanged: (v) {
                  _refreshState(() {
                    if (v == true) {
                      _selectedChildIds.add(id);
                    } else {
                      _selectedChildIds.remove(id);
                    }
                  });
                },
              );
            }),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandBlue,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(AppIcons.attach),
                    label: const Text('إضافة مرفق'),
                    onPressed: _pickAttachment,
                  ),
                ),
              ],
            ),
            if (_attachments.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._attachments.asMap().entries.map((e) => ListTile(
                    dense: true,
                    leading: const Icon(AppIcons.attach),
                    title: Text(e.value.path.split('/').last),
                    trailing: IconButton(
                      icon: const Icon(AppIcons.close,
                          color: AppColors.red),
                      onPressed: () =>
                          _refreshState(() => _attachments.removeAt(e.key)),
                    ),
                  )),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
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
            const SizedBox(height: 20),
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
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(AppIcons.save),
                label: Text(_saving ? 'جارِ الحفظ...' : 'حفظ الواجب'),
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  
  }
}
