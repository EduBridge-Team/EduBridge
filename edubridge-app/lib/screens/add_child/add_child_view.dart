part of 'add_child_screen.dart';

extension AddChildScreenStateView on _AddChildScreenState {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(title: 'إضافة طفل جديد'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAvatarHeader(c),
              const SizedBox(height: 20),
              _buildInfoBanner(c),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'اسم الطفل *',
                  prefixIcon: Icon(AppIcons.profile),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'العمر *',
                  prefixIcon: Icon(AppIcons.calendar),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'العمر مطلوب';
                  if (int.tryParse(v.trim()) == null) return 'أدخل عمراً صحيحاً';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              buildDisabilityField(
                context: context,
                c: c,
                selectedValue: _selectedDisabilityType,
                onTap: _openDisabilityPicker,
              ),

              if (_selectedDisabilityType == 'أخرى') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customDisabilityCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اكتب نوع الإعاقة *',
                    prefixIcon: Icon(AppIcons.edit),
                    hintText: 'مثال: اضطراب المعالجة السمعية',
                  ),
                  validator: (v) {
                    if (_selectedDisabilityType != 'أخرى') return null;
                    return (v == null || v.trim().isEmpty)
                        ? 'يجب كتابة نوع الإعاقة'
                        : null;
                  },
                ),
              ],
              const SizedBox(height: 20),

              buildDocumentsSection(
                context: context,
                c: c,
                idCardFile: _idCardFile,
                birthCertFile: _birthCertFile,
                onPickId: _pickIdCard,
                onCaptureId: _captureIdCard,
                onRemoveId: () => _refreshState(() => _idCardFile = null),
                onPickBirth: _pickBirthCert,
                onRemoveBirth: () => _refreshState(() => _birthCertFile = null),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _disabilityDescCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '*وصف الإعاقة',
                  prefixIcon: Icon(AppIcons.info),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'وصف الإعاقة مطلوب'
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _specialNeedsCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'احتياجات خاصة (اختياري)',
                  prefixIcon: Icon(AppIcons.info),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _learningStyleCtrl,
                decoration: const InputDecoration(
                  labelText: '*أسلوب التعلم المفضل',
                  prefixIcon: Icon(AppIcons.lesson),
                  hintText: 'مثال: بصري، سمعي، حركي',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'أسلوب التعلم مطلوب'
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _strengthsCtrl,
                decoration: const InputDecoration(
                  labelText: '*نقاط القوة',
                  prefixIcon: Icon(AppIcons.starFilled),
                  hintText: 'مفصولة بفواصل: قراءة، رسم،...',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'نقاط القوة مطلوبة'
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _challengesCtrl,
                decoration: const InputDecoration(
                  labelText: '*التحديات',
                  prefixIcon: Icon(AppIcons.warning),
                  hintText: 'مفصولة بفواصل',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'التحديات مطلوبة' : null,
              ),
              const SizedBox(height: 16),

              if (_error != null) _buildErrorBox(_error!),

              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandBlue,
                  ),
                  icon: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(AppIcons.send),
                  label: Text(
                    _loading ? 'جارٍ الإرسال...' : 'إرسال للمراجعة',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  
  }
}
