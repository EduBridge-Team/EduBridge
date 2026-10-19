part of 'create_homework_screen.dart';

extension _CreateHomeworkScreenStateView on _CreateHomeworkScreenState {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(title: context.l10n.homeworkNew),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _save,
        icon: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(AppIcons.save),
        label: Text(
          _saving ? context.l10n.homeworkPublishing : context.l10n.homeworkPublish,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            104 + safeModalBottom(context),
          ),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: context.l10n.homeworkTitleField,
                prefixIcon: const Icon(AppIcons.edit),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? context.l10n.homeworkTitleRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: context.l10n.homeworkDescriptionField,
                prefixIcon: const Icon(AppIcons.info),
                alignLabelWithHint: true,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? context.l10n.homeworkDescriptionRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _subjectCtrl,
              decoration: InputDecoration(
                labelText: context.l10n.homeworkSubjectOptional,
                prefixIcon: const Icon(AppIcons.lesson),
                hintText: context.l10n.homeworkSubjectHint,
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
                    const Icon(AppIcons.calendar, color: AppColors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.l10n.homeworkDueDateLabel, style: const TextStyle(fontSize: 12)),
                          Text(
                            MaterialLocalizations.of(context).formatMediumDate(_dueDate),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              context.l10n.homeworkAssignCount(_selectedChildIds.length),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...widget.children.map((child) {
              final id = child['id'] as int;
              final name = child['name']?.toString() ?? '';
              final selected = _selectedChildIds.contains(id);
              return CheckboxListTile(
                value: selected,
                title: Text(name),
                subtitle: Text(DisabilityDisplay.label(child['disability_type']?.toString() ?? '', context.l10n)),
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
            SizedBox(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandBlue,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(AppIcons.upload),
                label: Text(context.l10n.homeworkUploadAttachment),
                onPressed: _pickAttachment,
              ),
            ),
            if (_attachments.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._attachments.asMap().entries.map((e) => ListTile(
                    dense: true,
                    leading: const Icon(AppIcons.attach),
                    title: Text(e.value.path.split('/').last),
                    trailing: IconButton(
                      icon: const Icon(AppIcons.close, color: AppColors.red),
                      tooltip: context.l10n.homeworkRemoveAttachment,
                      onPressed: () => _refreshState(() => _attachments.removeAt(e.key)),
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
                    const Icon(AppIcons.error, color: AppColors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(context.sharedMessage(_error), style: const TextStyle(color: AppColors.red))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
