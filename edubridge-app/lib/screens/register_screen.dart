// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/brand_lockup.dart';
part 'register_screen_view.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  void _refreshState(VoidCallback callback) => setState(callback);

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _specialty = 'learning_support';

  String _role = 'parent';
  bool _loading = false;
  String? _error;

  static const _roles = {
    'parent': 'ولي أمر',
    'teacher': 'معلّم',
    'specialist': 'مختص',
  };

  bool get _needsSpecialty => _role == 'specialist';

  static const _specialties = {
    'learning_support': 'دعم تعليمي',
    'educational': 'خطط تعلم',
    'communication_support': 'دعم التواصل التعليمي',
    'learning_behavior': 'دعم سلوك التعلم',
  };

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final specialty = _needsSpecialty ? _specialty : null;

    final error = await ApiService.register(
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
      _role,
      phone: null,
      specialty: specialty,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إنشاء الحساب بنجاح — سجّل دخولك الآن'),
          backgroundColor: AppColors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => buildView(context);
}