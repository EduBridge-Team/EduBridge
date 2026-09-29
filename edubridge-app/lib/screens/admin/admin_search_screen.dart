// lib/screens/admin/admin_search_screen.dart
part of 'admin_screen.dart';

class SearchByIdentityScreen extends StatefulWidget {
  const SearchByIdentityScreen({super.key});

  @override
  State<SearchByIdentityScreen> createState() => _SearchByIdentityScreenState();
}

class _SearchByIdentityScreenState extends State<SearchByIdentityScreen> {
  final _searchCtrl = TextEditingController();
  List _results = [];
  bool _loading = false;
  String? _error;

  Future<void> _search() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await ApiService.searchByIdentity(query);
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'تعذّر البحث';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(title: 'البحث بالهوية'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ابحث برقم الهوية',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: c.heading,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'اعثر بسرعة على المستخدم أو الطفل المرتبط برقم الهوية.',
                  style: TextStyle(fontSize: 13.5, color: c.muted),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'أدخل رقم الهوية...',
                          prefixIcon: const Icon(Icons.badge_outlined),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _results = []);
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                )
                              : null,
                        ),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: _loading ? null : _search,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(AppIcons.search),
                      label: const Text('بحث'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          const SizedBox(height: 90),
                          const Icon(AppIcons.error, size: 54, color: AppColors.red),
                          const SizedBox(height: 14),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.red,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    : _results.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.all(24),
                            children: [
                              const SizedBox(height: 90),
                              Center(
                                child: Container(
                                  width: 82,
                                  height: 82,
                                  decoration: BoxDecoration(
                                    color: c.tintTeal,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    AppIcons.search,
                                    size: 38,
                                    color: AppColors.brandBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'لا توجد نتائج مطابقة',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: c.heading,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'تحقق من رقم الهوية وحاول مرة أخرى.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13.5, color: c.muted),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                            itemCount: _results.length,
                            itemBuilder: (context, i) {
                              final result = _results[i];
                              final typeLabel = result['type'] == 'child'
                                  ? 'طفل'
                                  : result['role'] == 'parent'
                                      ? 'ولي أمر'
                                      : (result['role'] ?? '').toString();
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: c.card,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: c.line),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(14),
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: c.tintTeal,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Icon(
                                      result['type'] == 'child'
                                          ? AppIcons.child
                                          : AppIcons.profile,
                                      color: AppColors.brandBlue,
                                    ),
                                  ),
                                  title: Text(
                                    result['name'] ?? '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: c.heading,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '$typeLabel • ${result['national_id'] ?? ''}',
                                    style: TextStyle(color: c.muted),
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_back_rounded,
                                    color: c.muted,
                                  ),
                                  onTap: () {},
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}