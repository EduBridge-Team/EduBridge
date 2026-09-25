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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'أدخل رقم الهوية...',
                      prefixIcon: Icon(Icons.credit_card),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _search,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('بحث'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.red)))
                    : _results.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(AppIcons.search, size: 64, color: c.muted),
                                const SizedBox(height: 16),
                                Text('لا توجد نتائج مطابقة',
                                    style: TextStyle(fontSize: 18, color: c.muted)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _results.length,
                            itemBuilder: (context, i) {
                              final result = _results[i];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: c.tintTeal,
                                    child: Icon(
                                      result['type'] == 'child'
                                          ? AppIcons.child
                                          : AppIcons.profile,
                                      color: AppColors.brandBlue,
                                    ),
                                  ),
                                  title: Text(result['name'] ?? ''),
                                  subtitle: Text(
                                    '${result['type'] == 'child' ? 'طفل' : result['role'] == 'parent' ? 'ولي أمر' : result['role']} • ${result['national_id'] ?? ''}',
                                  ),
                                  trailing: const Icon(Icons.chevron_left),
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