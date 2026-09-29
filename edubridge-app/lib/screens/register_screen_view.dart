part of 'register_screen.dart';

extension _RegisterScreenStateView on _RegisterScreenState {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: const JisrAppBar(title: 'إنشاء حساب'),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const BrandLockup(
                      iconSize: 44,
                      fontSize: 26,
                      gap: 6,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ابدأ رحلتك مع EduBridge',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        color: c.heading,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'أنشئ حسابك خلال دقيقة، ويمكنك استكمال بياناتك لاحقًا.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.5,
                        color: c.muted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: c.line),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brandBlue.withValues(alpha: .06),
                            blurRadius: 34,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'بيانات الحساب',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: c.heading,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'الاسم',
                              prefixIcon: Icon(AppIcons.profile),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'الاسم مطلوب'
                                    : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'البريد الإلكتروني',
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'الإيميل مطلوب';
                              }
                              if (!v.contains('@') || !v.contains('.')) {
                                return 'صيغة الإيميل غير صحيحة';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue: _role,
                            isExpanded: true,
                            alignment: AlignmentDirectional.centerStart,
                            decoration: const InputDecoration(
                              labelText: 'نوع الحساب',
                              prefixIcon: Icon(AppIcons.users),
                              contentPadding: EdgeInsetsDirectional.fromSTEB(
                                16,
                                18,
                                12,
                                18,
                              ),
                            ),
                            items: _RegisterScreenState._roles.entries
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Align(
                                      alignment: AlignmentDirectional.centerStart,
                                      child: Text(e.value),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              _refreshState(() {
                                _role = v ?? 'parent';
                                if (_role != 'specialist') {
                                  _specialty = 'learning_support';
                                }
                              });
                            },
                          ),
                          if (_needsSpecialty) ...[
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              initialValue: _specialty,
                              isExpanded: true,
                              alignment: AlignmentDirectional.centerStart,
                              decoration: const InputDecoration(
                                labelText: 'التخصص',
                                prefixIcon: Icon(AppIcons.specialist),
                                contentPadding: EdgeInsetsDirectional.fromSTEB(
                                  16,
                                  18,
                                  12,
                                  18,
                                ),
                              ),
                              items: _RegisterScreenState._specialties.entries
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e.key,
                                      child: Align(
                                        alignment: AlignmentDirectional.centerStart,
                                        child: Text(e.value),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => _refreshState(
                                () => _specialty =
                                    v ?? 'learning_support',
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: true,
                            maxLength: 128,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'كلمة المرور',
                              prefixIcon: Icon(AppIcons.lock),
                              helperText: '8 أحرف على الأقل',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'كلمة المرور مطلوبة';
                              }
                              if (v.length < 8 || v.length > 128) {
                                return 'كلمة المرور يجب أن تكون بين 8 و128 حرفاً';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _confirmCtrl,
                            obscureText: true,
                            onFieldSubmitted: (_) {
                              if (!_loading) _register();
                            },
                            decoration: const InputDecoration(
                              labelText: 'تأكيد كلمة المرور',
                              prefixIcon: Icon(AppIcons.lock),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                            ),
                            validator: (v) => v != _passwordCtrl.text
                                ? 'كلمتا المرور غير متطابقتين'
                                : null,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.red.withValues(alpha: .08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    AppIcons.error,
                                    color: AppColors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                        color: AppColors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: _loading ? null : _register,
                            icon: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.3,
                                    ),
                                  )
                                : const Icon(AppIcons.check),
                            label: Text(
                              _loading
                                  ? 'جارٍ إنشاء الحساب...'
                                  : 'إنشاء الحساب',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
