
import 'package:edubridge_app/screens/child_lessons_screen.dart';
import 'package:edubridge_app/screens/child_progress_screen.dart';
import 'package:edubridge_app/screens/children_screen.dart';
import 'package:edubridge_app/screens/login_screen.dart';

import 'package:edubridge_app/screens/register_screen.dart';
import 'package:edubridge_app/theme.dart';

import 'package:flutter/material.dart';

enum userType { teacher, specialized, admin, student, guest }

class home_screen extends StatefulWidget {
  const home_screen({super.key});
  @override
  State<home_screen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<home_screen> {

  userType currentRole =
      userType.guest; // الدور الحالي للمستخدم (افتراضيًا ضيف)
  bool isSwitched = false;
  int _selectedIndex = 0;
  final _emailCtrl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    var scaffold = Scaffold(
      backgroundColor: const Color.fromARGB(255, 246, 247, 249),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.all(2),
          children: [
            if (currentRole == userType.guest)
              DrawerHeader(
                decoration: const BoxDecoration(color: Colors.indigo),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'أهلاً بك في منصتنا!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // زر تسجيل الدخول
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);

                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.indigo,
                          ),
                          child: const Text('دخول'),
                        ),
                        const SizedBox(width: 8),
                        // زر إنشاء حساب
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                          ),
                          child: const Text('حساب جديد'),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              // هيدر القائمة الجانبية (معلومات المستخدم مثلاً)
              const UserAccountsDrawerHeader(
                accountName: Text('User name'),
                accountEmail: Text('Name@email.com'),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child:
                      Icon(Icons.person, color: Color.fromARGB(255, 3, 0, 35)),
                ),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 3, 0, 35),
                ),
              ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('الرئيسية'),
              onTap: () {
                Navigator.pop(context); // إغلاق الـ Drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('الملف الشخصي'),
              onTap: () {
                Navigator.pop(context);
                if (currentRole == userType.guest) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>LoginScreen(),
                    ),
                  );
                }
              },
            ),

            ListTile(
              leading: const Icon(Icons.explore),
              title: const Text('تصفح الدورات والمسارات'),
              onTap: () => Navigator.pop(context),
            ),
            
            ListTile(
              leading: const Icon(Icons.contact_support),
              title: const Text('تواصل معنا'),
              onTap: () => Navigator.pop(context),
            ),
            if (currentRole == userType.guest) ...[
              const Divider(), // خط فاصل
              ListTile(
                  leading: const Icon(Icons.login,
                      color: Color.fromARGB(255, 3, 0, 35)),
                  title: const Text('تسجيل الدخول',
                      style: TextStyle(color: Color.fromARGB(255, 3, 0, 35))),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  })
            ],

            if (currentRole == userType.student) ...[
              ListTile(
                leading: const Icon(Icons.menu_book),
                title: const Text('دروسي'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChildLessonsScreen(
                        childId: 0,
                        childName: '',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                  leading: const Icon(Icons.assignment, color: Colors.blue),
                  title: const Text('الواجبات والاختبارات'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChildrenScreen(),
                      ),
                    );
                  }),
              const Divider(), // خط فاصل
              ListTile(
                  leading: const Icon(Icons.login,
                      color: Color.fromARGB(255, 3, 0, 35)),
                  title: const Text('تسجيل الخروج',
                      style: TextStyle(color: Color.fromARGB(255, 3, 0, 35))),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  }),
            ],
            if (currentRole == userType.teacher) ...[
              ListTile(
                leading: const Icon(Icons.video_call),
                title: const Text('إدارة المحاضرات'),
                onTap: () => Navigator.pop(context),
              ),
              const Divider(), // خط فاصل
              ListTile(
                  leading: const Icon(Icons.login,
                      color: Color.fromARGB(255, 3, 0, 35)),
                  title: const Text('تسجيل الخروج',
                      style: TextStyle(color: Color.fromARGB(255, 3, 0, 35))),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  }),
            ],

            // ------------------ عناصر تظهر للأدمن ------------------
            if (currentRole == userType.admin) ...[
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('لوحة التحكم بالأدمن'),
                onTap: () => Navigator.pop(context),
              ),
              const Divider(), // خط فاصل
              ListTile(
                  leading: const Icon(Icons.login,
                      color: Color.fromARGB(255, 3, 0, 35)),
                  title: const Text('تسجيل الخروج',
                      style: TextStyle(color: Color.fromARGB(255, 3, 0, 35))),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  }),
            ],
          ],
        ),
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color.fromARGB(255, 1, 17, 88)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(children: [
          Image.asset('assets/icon.png', height: 32),
          SizedBox(width: 8),
          const Text(
            'جسر تعليمي EduBridge',
            style: TextStyle(
              fontSize: 20,
              color: Color.fromARGB(255, 1, 17, 88),
              fontWeight: FontWeight.bold,
            ),
          )
        ]),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1.5,
          ),
        ),
      ),
      body: SafeArea(
      
          child: _selectedIndex == 0
              ? SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      SizedBox(height: 16),
                      Text(
                        " نبني جسورا نحو مستقبل شامل للجميع",
                        style: TextStyle(
                          fontSize: 18,
                          color: Color.fromARGB(255, 1, 17, 88),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "  نحن نؤمن بأن التعليم حق للجميع، ونسعى لتقديم محتوى تعليمي .",
                        style: TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(255, 0, 3, 17),
                            fontWeight: FontWeight.normal),
                      ),
                      Text(
                        " متاح وميسر لكل طفل، بغض النظر عن قدراته الجسدية أو العقلية.",
                        style: TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(255, 0, 3, 17),
                            fontWeight: FontWeight.normal),
                      ),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => LoginScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 1, 17, 88),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            ' ابدأ رحلتك التعليمية',
                            style: TextStyle(
                              fontSize: 16,
                              color: const Color.fromARGB(255, 255, 255, 255),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color.fromARGB(
                                255, 200, 211, 232), // لون الحدود
                            width: 1.5, // سمك الحدود
                          ),
                        ),
                        child: const Column(
                          children: [
                            Text("😀", style: TextStyle(fontSize: 24)),
                            Text("0%",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text("نسبة رضا الطلاب"),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color.fromARGB(
                                255, 200, 211, 232), // لون الحدود
                            width: 1.5, // سمك الحدود
                          ), // درجة ا
                        ),
                        child: const Column(
                          children: [
                            Text("👤", style: TextStyle(fontSize: 24)),
                            Text("0",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text("طالب وطالية"),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            borderRadius: BorderRadius.circular(20), // درجة ا
                            border: Border.all(
                              color: const Color.fromARGB(
                                  255, 200, 211, 232), // لون الحدود
                              width: 1.5,
                            )),
                        child: const Column(
                          children: [
                            Text("🤝", style: TextStyle(fontSize: 24)),
                            Text("0",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text("شريك تعليمي"),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(30),
                        margin: const EdgeInsets.all(30),
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: const Color.fromARGB(
                                255, 8, 0, 59), // لون الخلفية
                            borderRadius: BorderRadius.circular(
                                20), // درجة الاستدارة // سمك الحدود
                            border: Border.all(
                              color: const Color.fromARGB(
                                  255, 200, 211, 232), // لون الحدود
                              width: 1.5,
                            )),
                        child: const Column(
                          children: [
                            Text("رؤية بلا حدود",
                                style: TextStyle(
                                    fontSize: 18,
                                    color: Color.fromARGB(255, 255, 255, 255),
                                    fontWeight: FontWeight.bold)),
                            Text(
                              "نسعى لأن نكون المرجع الأول في الوطن العربي للتعليم الرقمي المتاح، حيث تذوب الفوارق الجسدية وتبرز القدرات العقلية والإبداعية.",
                              style: TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.all(12),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 246, 246, 246),
                            borderRadius: BorderRadius.circular(20), // درجة ا
                            border: Border.all(
                              color: const Color.fromARGB(255, 200, 211, 232),
                              width: 1.5,
                            ),
                          ),
                          child: const Column(
                            children: [
                              Text("🤝", style: TextStyle(fontSize: 24)),
                              Text("الدعم المستمر",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              Text("مرافقة المتعلم في كل خطوة لضمان النجاح."),
                            ],
                          )),
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 246, 246, 246),
                          borderRadius: BorderRadius.circular(20), // درجة ا
                          border: Border.all(
                            color: const Color.fromARGB(255, 200, 211, 232),
                            width: 1.5,
                          ),
                        ),
                        child: const Column(
                          children: [
                            Text("📚", style: TextStyle(fontSize: 24)),
                            Text("تنوع المناهج",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text("محتوى تعليمي يناسب مختلف أنواع الإعاقات"),
                          ],
                        ),
                      ),
                      Text(
                        'مسارات تعليمية متخصصة',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color.fromARGB(255, 1, 17, 88),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 246, 246, 246),
                          borderRadius: BorderRadius.circular(20), // درجة ا
                          border: Border.all(
                            color: const Color.fromARGB(255, 200, 211, 232),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text("🤟", style: TextStyle(fontSize: 24)),
                            Text("لغة الإشارة المتقدمة",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(
                                "دورة شاملة لتعلم لغة الإشارة من الأساسيات وحتى الاحتراف."),
                            Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChildLessonsScreen(
                                        childId: 0,
                                        childName: '',
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Color.fromARGB(255, 1, 17, 88),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  ' اكتشف المسار',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: const Color.fromARGB(
                                        255, 255, 255, 255),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 246, 246, 246),
                          borderRadius: BorderRadius.circular(20), // درجة ا
                          border: Border.all(
                            color: const Color.fromARGB(255, 200, 211, 232),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text("📖", style: TextStyle(fontSize: 24)),
                            Text("تقنيات القراءة الميسّرة",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(
                                "تدريب عملي لتعزيز استقلالية القراءة والتعلم لكل طفل."),
                            Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ChildLessonsScreen(
                                              childId: 0,
                                              childName: '',
                                            )),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Color.fromARGB(255, 1, 17, 88),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  ' اكتشف المسار',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: const Color.fromARGB(
                                        255, 255, 255, 255),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 246, 246, 246),
                          borderRadius: BorderRadius.circular(20), // درجة ا
                          border: Border.all(
                            color: const Color.fromARGB(255, 200, 211, 232),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "💡",
                              style: TextStyle(fontSize: 24),
                            ),
                            Text("المهارات الحياتية الرقمية",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(
                                "رنامج مخصص لتمكين الأطفال ذوي الإعاقات الإدراكية من التعامل مع العالم الرقمي بأمان."),
                            Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ChildLessonsScreen(
                                              childId: 0,
                                              childName: '',
                                            )),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Color.fromARGB(255, 1, 17, 88),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  ' اكتشف المسار',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: const Color.fromARGB(
                                        255, 255, 255, 255),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 173, 173, 173),
                          borderRadius: BorderRadius.circular(20), // درجة ا
                          border: Border.all(
                            color: const Color.fromARGB(255, 200, 211, 232),
                            width: 1.5,
                          ),
                        ),
                        child: Column(children: [
                          Text("ميزات وصول صممت خصيصا ",
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Color.fromARGB(255, 1, 17, 88),
                                  fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.all(12),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 196, 194, 194),
                              borderRadius: BorderRadius.circular(20), // درجة ا
                              border: Border.all(
                                color: const Color.fromARGB(255, 200, 211, 232),
                                width: 1.5,
                              ),
                            ),
                               
                            child: Row(
                              
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      "الوضع الليلي",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Color.fromARGB(255, 1, 17, 88),
                                      ),
                                    ),
                                    Text(
                                        "تقليل إجهاد العين في الإضاءة المنخفضة"),
                                  ],
                                ),
                                 ValueListenableBuilder<ThemeMode>(
                          valueListenable: jisrThemeMode,
                          builder: (context, mode, _) => IconButton(
                            icon: Icon(
                              mode == ThemeMode.dark
                                  ? Icons.light_mode
                                  : Icons.dark_mode,
                              color: const Color.fromARGB(255, 236, 236, 238),
                              
                            ),
                            tooltip: mode == ThemeMode.dark
                                ? 'الوضع الفاتح'
                                : 'الوضع الليلي',
                            onPressed: toggleThemeMode,
                          ),
                        ),                         ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.all(12),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 191, 190, 190),
                              borderRadius: BorderRadius.circular(20), // درجة ا
                              border: Border.all(
                                color: const Color.fromARGB(255, 200, 211, 232),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      "تكبير النص",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Color.fromARGB(255, 1, 17, 88),
                                      ),
                                    ),
                                    Text("زيادة حجم النصوص في التطبيق"),
                                  ],  
                                ),
                              ],
                            ),
                          ),
                        ]),
                      ),
                      SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 16, 0, 65),
                          borderRadius: BorderRadius.circular(20), // درجة ا
                          border: Border.all(
                            color: const Color.fromARGB(255, 0, 26, 73),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "كن جزءا من مسيرة التغيير",
                              style: TextStyle(
                                fontSize: 18,
                                color: Color.fromARGB(255, 255, 255, 255),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "اشترك في نشرتنا البريدية لتصلك احدث الدورات والمقالات التخصصية.",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
                            SizedBox(height: 16),
                            TextField(
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(fontSize: 18),
                              decoration: const InputDecoration(
                                labelText: 'الإيميل',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email),
                                filled: true,
                                fillColor: Color.fromARGB(255, 240, 239, 240),
                                hintText: 'أدخل بريدك الإلكتروني',
                                hintStyle: const TextStyle(
                                    color: Color.fromARGB(179, 66, 64, 64)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : _selectedIndex == 1
                  ? ChildProgressScreen(
                      childId: 0,
                      childName: '',
                    )
                  : _selectedIndex == 2
                      ? ChildLessonsScreen(
                          childId: 0,
                          childName: '',
                        )
                      : LoginScreen(),
                      //profile_screen(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              color: Color.fromARGB(255, 1, 17, 88),
            ),
            label: 'Home',
            backgroundColor: Color.fromARGB(255, 238, 236, 235),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.school,
              color: Color.fromARGB(255, 1, 17, 88),
            ),
            label: 'Tracks',
            backgroundColor: Color.fromRGBO(242, 246, 243, 1),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.local_library,
              color: Color.fromARGB(255, 1, 17, 88),
            ),
            label: 'Learning',
            backgroundColor: Color.fromARGB(255, 250, 247, 250),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
              color: Color.fromARGB(255, 1, 17, 88),
            ),
            label: 'Profile',
            backgroundColor: Color.fromARGB(255, 255, 255, 255),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 255, 255, 255),
        onTap: _onItemTapped,
      ),
    );
    return Directionality(
      textDirection: TextDirection.rtl,
      child: scaffold,
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = [
    home_screen(),
    ChildProgressScreen(
      childId: 0,
      childName: '',
    ),
    ChildLessonsScreen(
      childId: 0,
      childName: '',
    ),
    LoginScreen(),
  ];
}

