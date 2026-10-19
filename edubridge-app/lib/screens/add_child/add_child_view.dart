part of 'add_child_screen.dart';

extension _AddChildScreenStateView on _AddChildScreenState {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(title: context.l10n.addNewChild),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: c.line),
                ),
                child: Column(
                  children: [
                    _buildAvatarHeader(c),
                    const SizedBox(height: 14),
                    _buildInfoBanner(c),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                context.l10n.childData,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: c.heading,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: context.l10n.requiredFieldLabel(context.l10n.childName),
                  prefixIcon: Icon(AppIcons.profile),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? context.l10n.nameRequired : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.l10n.requiredFieldLabel(context.l10n.age),
                  prefixIcon: Icon(AppIcons.calendar),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return context.l10n.ageRequired;
                  if (int.tryParse(v.trim()) == null) return context.l10n.validAgeRequired;
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
                  decoration: InputDecoration(
                    labelText: context.l10n.requiredFieldLabel(context.l10n.enterDisabilityType),
                    prefixIcon: Icon(AppIcons.edit),
                    hintText: context.l10n.customDisabilityExample,
                  ),
                  validator: (v) {
                    if (_selectedDisabilityType != 'أخرى') return null;
                    return (v == null || v.trim().isEmpty)
                        ? context.l10n.customDisabilityRequired
                        : null;
                  },
                ),
              ],
              const SizedBox(height: 20),

              TextFormField(
                controller: _childIdCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: context.l10n.requiredFieldLabel(context.l10n.childIdNumber)),
                validator: (value) => value == null || value.trim().isEmpty
                    ? context.l10n.nationalIdRequired
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _guardianIdCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    InputDecoration(labelText: context.l10n.requiredFieldLabel(context.l10n.guardianIdNumber)),
                validator: (value) => value == null || value.trim().isEmpty
                    ? context.l10n.nationalIdRequired
                    : null,
              ),
              const SizedBox(height: 16),
              buildDocumentsSection(
                context: context,
                c: c,
                idCardFile: _idCardFile,
                birthCertFile: _birthCertFile,
                medicalReportFiles: _medicalReportFiles,
                onPickId: _pickIdCard,
                onCaptureId: _captureIdCard,
                onRemoveId: () => _refreshState(() => _idCardFile = null),
                onPickBirth: _pickBirthCert,
                onRemoveBirth: () => _refreshState(() => _birthCertFile = null),
                onPickMedical: _pickMedicalReport,
                onCaptureMedical: _captureMedicalReport,
                onRemoveMedical: _removeMedicalReport,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _disabilityDescCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: context.l10n.requiredFieldLabel(context.l10n.disabilityDescription),
                  prefixIcon: Icon(AppIcons.info),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.l10n.disabilityDescriptionRequired
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _specialNeedsCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: context.l10n.requiredFieldLabel(context.l10n.specialNeeds),
                  prefixIcon: Icon(AppIcons.info),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.l10n.specialNeedsRequired
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _learningStyleCtrl,
                decoration: InputDecoration(
                  labelText: context.l10n.requiredFieldLabel(context.l10n.preferredLearningStyle),
                  prefixIcon: Icon(AppIcons.lesson),
                  hintText: context.l10n.learningStyleExample,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.l10n.learningStyleRequired
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _strengthsCtrl,
                decoration: InputDecoration(
                  labelText: context.l10n.requiredFieldLabel(context.l10n.strengths),
                  prefixIcon: Icon(AppIcons.starFilled),
                  hintText: context.l10n.strengthsCommaHint,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.l10n.strengthsRequired
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _challengesCtrl,
                decoration: InputDecoration(
                  labelText: context.l10n.requiredFieldLabel(context.l10n.challenges),
                  prefixIcon: Icon(AppIcons.warning),
                  hintText: context.l10n.commaSeparatedHint,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? context.l10n.challengesRequired : null,
              ),
              const SizedBox(height: 16),

              if (_error != null) _buildErrorBox(_error!),

              FilledButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(AppIcons.send),
                label: Text(
                  _loading ? context.l10n.sendingAlt : context.l10n.submitForReview,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
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
