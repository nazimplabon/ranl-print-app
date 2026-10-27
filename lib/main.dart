import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RanlPrintApp());
}

const brandNavy = Color(0xFF101B35);
const brandBlue = Color(0xFF245BDB);
const pageBg = Color(0xFFF5F7FB);

class RanlPrintApp extends StatelessWidget {
  const RanlPrintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RANL PRINT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: pageBg,
        colorScheme: ColorScheme.fromSeed(seedColor: brandBlue),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: pageBg,
          foregroundColor: brandNavy,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE3E8F1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE3E8F1)),
          ),
        ),
      ),
      home: const MainShell(),
    );
  }
}

class RanlApi {
  RanlApi._() {
    dio = Dio(BaseOptions(
      baseUrl: 'https://ranlprint.com',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ));
    dio.interceptors.add(CookieManager(CookieJar()));
  }

  static final RanlApi instance = RanlApi._();
  late final Dio dio;

  Future<String> _prepareCsrf() async {
    final response = await dio.get('/api/csrf/');
    final token = response.data is Map ? response.data['csrfToken']?.toString() : null;
    if (token == null || token.isEmpty) {
      throw Exception('Could not obtain a CSRF token from the server.');
    }
    return token;
  }

  Future<List<PrintProduct>> products() async {
    final response = await dio.get('/api/catalog/products/');
    final list = (response.data['products'] as List? ?? []);
    return list.map((e) => PrintProduct.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<String> submitQuote({
    required String name,
    required String phone,
    required String email,
    required PrintProduct product,
    required String quantity,
    required String size,
    required String paper,
    required String printing,
    required List<String> finishingIds,
    required String notes,
  }) async {
    final csrfToken = await _prepareCsrf();
    final form = FormData.fromMap({
      'name': name,
      'phone': phone,
      'email': email,
      'product': product.slug,
      'quantity': quantity,
      'size': size,
      'paper': paper,
      'printing': printing,
      'notes': notes,
      for (final id in finishingIds) 'finishing': id,
    });
    final response = await dio.post(
      '/api/quotes/create/',
      data: form,
      options: Options(headers: {'X-CSRFToken': csrfToken}),
    );
    if (response.data['ok'] == true) return '${response.data['quote_number']}';
    throw Exception(response.data['error'] ?? 'Could not submit quote request.');
  }


  Future<void> submitContact({
    required String name,
    required String phone,
    required String email,
    required String message,
  }) async {
    final csrfToken = await _prepareCsrf();
    final response = await dio.post(
      '/api/contact/',
      data: FormData.fromMap({
        'name': name, 'phone': phone, 'email': email, 'message': message,
      }),
      options: Options(headers: {'X-CSRFToken': csrfToken}),
    );
    if (response.data['ok'] != true) {
      throw Exception(response.data['error'] ?? 'Could not send message.');
    }
  }
}

class PrintProduct {
  final int id;
  final String name;
  final String slug;
  final String category;
  final String description;
  final List<Map<String, dynamic>> sizes;
  final List<Map<String, dynamic>> papers;
  final List<Map<String, dynamic>> printing;
  final List<Map<String, dynamic>> finishing;

  PrintProduct({
    required this.id, required this.name, required this.slug,
    required this.category, required this.description,
    required this.sizes, required this.papers, required this.printing,
    required this.finishing,
  });

  factory PrintProduct.fromJson(Map<String, dynamic> json) => PrintProduct(
    id: json['id'] as int? ?? 0,
    name: json['name']?.toString() ?? 'Printing service',
    slug: json['slug']?.toString() ?? '',
    category: json['category']?.toString() ?? 'print',
    description: json['description']?.toString() ?? '',
    sizes: List<Map<String, dynamic>>.from((json['sizes'] as List? ?? []).map((e) => Map<String, dynamic>.from(e))),
    papers: List<Map<String, dynamic>>.from((json['papers'] as List? ?? []).map((e) => Map<String, dynamic>.from(e))),
    printing: List<Map<String, dynamic>>.from((json['printing'] as List? ?? []).map((e) => Map<String, dynamic>.from(e))),
    finishing: List<Map<String, dynamic>>.from((json['finishing'] as List? ?? []).map((e) => Map<String, dynamic>.from(e))),
  );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  final pages = const [HomeScreen(), ServicesScreen(), QuoteScreen(), ContactScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: index, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'Services'),
          NavigationDestination(icon: Icon(Icons.request_quote_outlined), selectedIcon: Icon(Icons.request_quote), label: 'Get a Quote'),
          NavigationDestination(icon: Icon(Icons.call_outlined), selectedIcon: Icon(Icons.call), label: 'Contact'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        const BrandHeader(),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [brandNavy, Color(0xFF263F76)],
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(30)),
              child: const Text('PROFESSIONAL PRINTING SOLUTIONS',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ),
            const SizedBox(height: 22),
            const Text('Design.\nPrint. Deliver.', style: TextStyle(color: Colors.white, fontSize: 35, height: 1.08, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Text('Bring your ideas to life with quality printing and creative design.',
              style: TextStyle(color: Colors.white.withOpacity(.82), fontSize: 15, height: 1.5)),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuoteScreen())),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Request a Quote'),
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: brandNavy, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15)),
            ),
          ]),
        ),
        const SizedBox(height: 26),
        const SectionTitle(title: 'What we print', subtitle: 'Print solutions for your business and everyday needs.'),
        const SizedBox(height: 14),
        const Wrap(spacing: 12, runSpacing: 12, children: [
          ServiceTile(icon: Icons.badge_outlined, title: 'Business Cards', color: Color(0xFFE9EEFF)),
          ServiceTile(icon: Icons.menu_book_outlined, title: 'Brochures', color: Color(0xFFE5F6F0)),
          ServiceTile(icon: Icons.local_offer_outlined, title: 'Stickers', color: Color(0xFFFFF0DF)),
          ServiceTile(icon: Icons.photo_outlined, title: 'Photo Printing', color: Color(0xFFF5E9FF)),
          ServiceTile(icon: Icons.article_outlined, title: 'Flyers & Posters', color: Color(0xFFE5F1FF)),
          ServiceTile(icon: Icons.design_services_outlined, title: 'Graphic Design', color: Color(0xFFFFE9EB)),
        ]),
        const SizedBox(height: 24),
        const InfoBanner(),
      ],
    );
  }
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 48, height: 48,
      decoration: BoxDecoration(color: brandNavy, borderRadius: BorderRadius.circular(15)),
      child: const Center(child: Text('R', style: TextStyle(color: Colors.white, fontSize: 29, fontWeight: FontWeight.w900))),
    ),
    const SizedBox(width: 12),
    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('RANL PRINT', style: TextStyle(color: brandNavy, fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: .4)),
      Text('Design. Print. Deliver.', style: TextStyle(color: Color(0xFF7C879B), fontSize: 12)),
    ])),
    IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
  ]);
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const SectionTitle({super.key, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: brandNavy)),
    const SizedBox(height: 5),
    Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF778198), height: 1.4)),
  ]);
}

class ServiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const ServiceTile({super.key, required this.icon, required this.title, required this.color});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: (MediaQuery.of(context).size.width - 52) / 2,
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE9EDF4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: brandNavy)),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: brandNavy)),
      ]),
    ),
  );
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: const Color(0xFFE9EEFF), borderRadius: BorderRadius.circular(20)),
    child: const Row(children: [
      Icon(Icons.support_agent_rounded, color: brandBlue, size: 34),
      SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Need something custom?', style: TextStyle(fontWeight: FontWeight.w800, color: brandNavy)),
        SizedBox(height: 4),
        Text('Send us your requirements. Our team will contact you with a price.', style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF5E6B84))),
      ])),
    ]),
  );
}

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});
  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}
class _ServicesScreenState extends State<ServicesScreen> {
  late Future<List<PrintProduct>> future;
  @override
  void initState() { super.initState(); future = RanlApi.instance.products(); }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    const BrandHeader(), const SizedBox(height: 24),
    const SectionTitle(title: 'Our Services', subtitle: 'Services are loaded from the RANL PRINT website.'),
    const SizedBox(height: 16),
    FutureBuilder<List<PrintProduct>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
        if (snapshot.hasError) return ErrorCard(message: 'Could not load services. Please check the internet connection and API settings.', onRetry: () => setState(() => future = RanlApi.instance.products()));
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const InfoBanner();
        return Column(children: items.map((p) => Container(
          margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE8ECF3))),
          child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFE9EEFF), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.print_outlined, color: brandBlue)),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, color: brandNavy, fontSize: 15)),
              if (p.description.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 5), child: Text(p.description, style: const TextStyle(color: Color(0xFF7B8598), fontSize: 12))),
              const SizedBox(height: 6),
              const Text('Price on request', style: TextStyle(color: brandBlue, fontWeight: FontWeight.w700, fontSize: 12)),
            ])),
          ]),
        )).toList());
      },
    ),
  ]);
}

class QuoteScreen extends StatefulWidget {
  const QuoteScreen({super.key});
  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}
class _QuoteScreenState extends State<QuoteScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(), phone = TextEditingController(), email = TextEditingController();
  final quantity = TextEditingController(text: '100'), notes = TextEditingController();
  List<PrintProduct> products = [];
  PrintProduct? selected;
  String size = '', paper = '', printing = '';
  final List<String> finishes = [];
  bool loading = true, sending = false;
  String? loadError;

  @override
  void initState() { super.initState(); loadProducts(); }
  Future<void> loadProducts() async {
    try {
      final p = await RanlApi.instance.products();
      if (!mounted) return;
      setState(() { products = p; selected = p.isNotEmpty ? p.first : null; loading = false; loadError = null; });
    } catch (_) {
      if (mounted) setState(() { loading = false; loadError = 'Could not load products. Please try again.'; });
    }
  }
  @override
  void dispose() { name.dispose(); phone.dispose(); email.dispose(); quantity.dispose(); notes.dispose(); super.dispose(); }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (selected == null) { showMessage('No active services are available yet.'); return; }
    setState(() => sending = true);
    try {
      final quoteNo = await RanlApi.instance.submitQuote(
        name: name.text.trim(), phone: phone.text.trim(), email: email.text.trim(),
        product: selected!, quantity: quantity.text.trim(), size: size, paper: paper,
        printing: printing, finishingIds: finishes, notes: notes.text.trim(),
      );
      if (!mounted) return;
      showMessage('Request sent! Reference: $quoteNo');
      formKey.currentState?.reset();
      name.clear(); phone.clear(); email.clear(); quantity.text = '100'; notes.clear();
      setState(() { size = ''; paper = ''; printing = ''; finishes.clear(); });
    } catch (e) {
      showMessage('Could not submit request. Please check the server/API configuration.');
    } finally { if (mounted) setState(() => sending = false); }
  }

  void showMessage(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    const BrandHeader(), const SizedBox(height: 24),
    const SectionTitle(title: 'Get a Quote', subtitle: 'Tell us what you need. Our team will contact you with a price.'),
    const SizedBox(height: 18),
    if (loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
    if (loadError != null) ErrorCard(message: loadError!, onRetry: loadProducts),
    if (!loading && loadError == null) Form(
      key: formKey,
      child: Column(children: [
        _field(name, 'Your name', validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your name' : null),
        _field(phone, 'Phone number', keyboard: TextInputType.phone, validator: (v) => (v == null || v.trim().length < 6) ? 'Enter a valid phone number' : null),
        _field(email, 'Email (optional)', keyboard: TextInputType.emailAddress),
        _dropdown<PrintProduct>(label: 'Printing service', value: selected, items: products.map((p) => DropdownMenuItem(value: p, child: Text(p.name, overflow: TextOverflow.ellipsis))).toList(), onChanged: (v) => setState(() { selected = v; size = ''; paper = ''; printing = ''; finishes.clear(); })),
        _field(quantity, 'Quantity', keyboard: TextInputType.number, validator: (v) => (int.tryParse(v ?? '') == null || int.parse(v!) < 1) ? 'Enter quantity (minimum 1)' : null),
        if (selected != null && selected!.sizes.isNotEmpty)
          _dropdown<String>(label: 'Size', value: selected!.sizes.any((e) => e['name'] == size) ? size : null, items: selected!.sizes.map((e) => DropdownMenuItem(value: '${e['name']}', child: Text('${e['name']}'))).toList(), onChanged: (v) => setState(() => size = v ?? '')),
        if (selected != null && selected!.papers.isNotEmpty)
          _dropdown<String>(label: 'Paper / GSM', value: selected!.papers.any((e) => e['name'] == paper) ? paper : null, items: selected!.papers.map((e) => DropdownMenuItem(value: '${e['name']}', child: Text('${e['name']}'))).toList(), onChanged: (v) => setState(() => paper = v ?? '')),
        if (selected != null && selected!.printing.isNotEmpty)
          _dropdown<String>(label: 'Printing type', value: selected!.printing.any((e) => e['name'] == printing) ? printing : null, items: selected!.printing.map((e) => DropdownMenuItem(value: '${e['name']}', child: Text('${e['name']}'))).toList(), onChanged: (v) => setState(() => printing = v ?? '')),
        if (selected != null && selected!.finishing.isNotEmpty)
          Container(
            width: double.infinity, margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE3E8F1))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Finishing options', style: TextStyle(fontWeight: FontWeight.w700, color: brandNavy)),
              ...selected!.finishing.map((e) => CheckboxListTile(
                contentPadding: EdgeInsets.zero, dense: true, title: Text('${e['name']}'),
                value: finishes.contains('${e['id']}'),
                onChanged: (v) => setState(() { if (v == true) { finishes.add('${e['id']}'); } else { finishes.remove('${e['id']}'); } }),
              )),
            ]),
          ),
        _field(notes, 'Project details (optional)', maxLines: 4),
        const SizedBox(height: 6),
        SizedBox(width: double.infinity, child: FilledButton(
          onPressed: sending ? null : submit,
          style: FilledButton.styleFrom(backgroundColor: brandBlue, padding: const EdgeInsets.symmetric(vertical: 17), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Send Quote Request', style: TextStyle(fontWeight: FontWeight.w800)),
        )),
        const SizedBox(height: 12),
        const Text('No online price is shown. RANL PRINT will contact you.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF7C879B), fontSize: 12)),
      ]),
    ),
  ]);

  Widget _field(TextEditingController c, String label, {TextInputType? keyboard, String? Function(String?)? validator, int maxLines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(controller: c, keyboardType: keyboard, validator: validator, maxLines: maxLines, decoration: InputDecoration(labelText: label)),
  );

  Widget _dropdown<T>({required String label, required T? value, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<T>(
      value: value, isExpanded: true, decoration: InputDecoration(labelText: label),
      items: items, onChanged: onChanged,
    ),
  );
}

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});
  @override
  State<ContactScreen> createState() => _ContactScreenState();
}
class _ContactScreenState extends State<ContactScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(), phone = TextEditingController(), email = TextEditingController(), message = TextEditingController();
  bool sending = false;
  @override
  void dispose() { name.dispose(); phone.dispose(); email.dispose(); message.dispose(); super.dispose(); }
  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => sending = true);
    try {
      await RanlApi.instance.submitContact(name: name.text.trim(), phone: phone.text.trim(), email: email.text.trim(), message: message.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message sent successfully.')));
      name.clear(); phone.clear(); email.clear(); message.clear();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message could not be sent. Please try again.')));
    } finally { if (mounted) setState(() => sending = false); }
  }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    const BrandHeader(), const SizedBox(height: 24),
    const SectionTitle(title: 'Contact Us', subtitle: 'We are happy to help with your next print project.'),
    const SizedBox(height: 16),
    const _ContactCard(icon: Icons.phone_outlined, title: 'Call us', value: '01568 768671'),
    const _ContactCard(icon: Icons.email_outlined, title: 'Email', value: 'RANLPrintBD@gmail.com'),
    const _ContactCard(icon: Icons.location_on_outlined, title: 'Visit us', value: 'Sajborkhila, Sherpur 2100, Bangladesh'),
    const SizedBox(height: 12),
    Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Form(
      key: formKey,
      child: Column(children: [
        const Align(alignment: Alignment.centerLeft, child: Text('Send a message', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: brandNavy))),
        const SizedBox(height: 14),
        TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Your name'), validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your name' : null),
        const SizedBox(height: 12),
        TextFormField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone number'), validator: (v) => (v == null || v.trim().length < 6) ? 'Enter a valid phone number' : null),
        const SizedBox(height: 12),
        TextFormField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email (optional)')),
        const SizedBox(height: 12),
        TextFormField(controller: message, maxLines: 4, decoration: const InputDecoration(labelText: 'How can we help?'), validator: (v) => (v == null || v.trim().length < 5) ? 'Please enter a message' : null),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: sending ? null : submit, style: FilledButton.styleFrom(backgroundColor: brandBlue, padding: const EdgeInsets.symmetric(vertical: 16)), child: sending ? const CircularProgressIndicator(color: Colors.white) : const Text('Send Message'))),
      ]),
    )),
  ]);
}

class _ContactCard extends StatelessWidget {
  final IconData icon; final String title; final String value;
  const _ContactCard({required this.icon, required this.title, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFFE8ECF3))),
    child: Row(children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFE9EEFF), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: brandBlue)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Color(0xFF7B8598), fontSize: 12)),
        const SizedBox(height: 3), Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: brandNavy)),
      ])),
    ]),
  );
}

class ErrorCard extends StatelessWidget {
  final String message; final VoidCallback onRetry;
  const ErrorCard({super.key, required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
    child: Column(children: [
      const Icon(Icons.wifi_off_rounded, size: 34, color: Color(0xFF7B8598)),
      const SizedBox(height: 8), Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 10), OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
    ]),
  );
}
