import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../portal/portal_client.dart';
import '../widgets/table_lamp.dart';
import 'moon_abaya_models.dart';
import 'moon_abaya_storage.dart';

const Color _kGold = Color(0xFFC9A15A);
const Color _kGoldLight = Color(0xFFE3C486);
const Color _kBg = Color(0xFF0E0E0F);
const Color _kSurface = Color(0xFF191919);
const Color _kSurfaceHi = Color(0xFF222222);

String _money(double v) {
  final isWhole = v == v.roundToDouble();
  final text = isWhole ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  final parts = text.split('.');
  final intPart = parts[0].replaceAll('-', '');
  final sign = v < 0 ? '-' : '';
  final buf = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
  }
  final grouped = '$sign$buf${parts.length > 1 ? '.${parts[1]}' : ''}';
  return '$grouped د.م.';
}

class MoonAbayaScreen extends StatefulWidget {
  const MoonAbayaScreen({super.key});

  @override
  State<MoonAbayaScreen> createState() => _MoonAbayaScreenState();
}

class _MoonAbayaScreenState extends State<MoonAbayaScreen> with TickerProviderStateMixin {
  List<MoonAbayaItem> _items = [];
  bool _loading = true;
  MoonAbayaCategory? _filter;
  String _search = '';
  bool _debtOnly = false;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollTop = false;
  late final RealtimeChannel _channel;

  /// بوابة المصباح: الشاشة كتبان غير بعد سحب الحبل.
  bool _revealed = false;
  late final AnimationController _welcomeCtrl;
  late final Animation<double> _slideCurve;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
    _welcomeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _slideCurve = CurvedAnimation(parent: _welcomeCtrl, curve: Curves.easeInOutCubic);
    _channel = portalClient
        .channel('moon-abaya-items')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: MoonAbayaStorage.table,
          callback: (_) { if (mounted) _load(); },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: MoonAbayaStorage.paymentsTable,
          callback: (_) { if (mounted) _load(); },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _welcomeCtrl.dispose();
    portalClient.removeChannel(_channel);
    super.dispose();
  }

  void _reveal() {
    if (_revealed) return;
    setState(() => _revealed = true);
    _welcomeCtrl.forward(from: 0);
  }

  void _onScroll() {
    final show = _scrollController.offset > 400;
    if (show != _showScrollTop) setState(() => _showScrollTop = show);
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  Future<void> _load() async {
    try {
      final items = await MoonAbayaStorage.load();
      items.sort((a, b) => b.date.compareTo(a.date));
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر تحميل البيانات السحابية: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  List<MoonAbayaItem> get _visible {
    return _items.where((it) {
      if (_filter != null && it.category != _filter) return false;
      if (_debtOnly && it.isFullyPaid) return false;
      if (_search.trim().isNotEmpty &&
          !it.model.toLowerCase().contains(_search.trim().toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  double get _totalRevenue => _visible.fold(0, (s, e) => s + e.totalRevenue);
  double get _totalCost => _visible.fold(0, (s, e) => s + e.totalCost);
  double get _totalProfit => _visible.fold(0, (s, e) => s + e.totalProfit);
  double get _totalDebt => _visible.fold(0, (s, e) => s + e.remainingDebt);

  Future<void> _openForm({MoonAbayaItem? existing}) async {
    final result = await showModalBottomSheet<_MoonAbayaFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MoonAbayaForm(existing: existing),
    );
    if (result == null) return;
    try {
      await MoonAbayaStorage.upsert(result.item);
      if (result.initialPayment != null) {
        await MoonAbayaStorage.addPayment(result.item.id, result.initialPayment!);
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل الحفظ في السحابة: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _delete(MoonAbayaItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف المنتج', style: TextStyle(color: Colors.white)),
        content: Text(
          'هل تريد حذف "${item.model}" نهائياً؟',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await MoonAbayaStorage.delete(item.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل الحذف من السحابة: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _addPayment(MoonAbayaItem item) async {
    final amountCtrl = TextEditingController();

    final payment = await showDialog<MoonAbayaPayment>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          DateTime date = DateTime.now();
          String? error;

          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: _kSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('تسجيل دفعة', style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('المتبقي حاليًا: ${_money(item.remainingDebt)}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'المبلغ (د.م.)',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: _kSurfaceHi,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: date,
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2100),
                        builder: (c, child) => Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(primary: _kGold, surface: _kSurface),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) setDialogState(() => date = picked);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'التاريخ',
                        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                        filled: true,
                        fillColor: _kSurfaceHi,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      child: Text(
                        '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(amountCtrl.text.trim().replaceAll(',', '.'));
                    if (amount == null || amount <= 0) {
                      setDialogState(() => error = 'أدخل مبلغًا صحيحًا');
                      return;
                    }
                    if (amount > item.remainingDebt + 0.01) {
                      setDialogState(() => error = 'المبلغ أكبر من المتبقي (${_money(item.remainingDebt)})');
                      return;
                    }
                    Navigator.pop(
                      ctx,
                      MoonAbayaPayment(
                        id: '${DateTime.now().microsecondsSinceEpoch}-p',
                        amount: amount,
                        date: date,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _kGold, foregroundColor: Colors.black),
                  child: const Text('تسجيل'),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (payment == null) return;
    try {
      await MoonAbayaStorage.addPayment(item.id, payment);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل تسجيل الدفعة: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _deletePayment(MoonAbayaPayment payment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف الدفعة', style: TextStyle(color: Colors.white)),
        content: Text(
          'هل تريد حذف دفعة بقيمة ${_money(payment.amount)}؟',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await MoonAbayaStorage.deletePayment(payment.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل حذف الدفعة: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    return Scaffold(
      backgroundColor: _kBg,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showScrollTop) ...[
            FloatingActionButton(
              heroTag: 'moonAbayaScrollTop',
              mini: true,
              onPressed: _scrollToTop,
              backgroundColor: _kSurfaceHi,
              foregroundColor: _kGold,
              child: const Icon(Icons.arrow_upward_rounded),
            ),
            const SizedBox(height: 12),
          ],
          FloatingActionButton.extended(
            heroTag: 'moonAbayaAdd',
            onPressed: () => _openForm(),
            backgroundColor: _kGold,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.add_rounded),
            label: const Text('منتج جديد', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── صورة خلفية شفافة (واترمارك) ──
          Positioned.fill(
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(
                'assets/moon_abaya_bg.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // ── بوابة المصباح: نفس فكرة شاشة تسجيل الدخول — المصباح
          // ينسحب يمينا ويختفي، والمحتوى يدخل من اليمين وينسحب يسارا. ──
          AnimatedBuilder(
            animation: _welcomeCtrl,
            builder: (context, child) {
              final t = _slideCurve.value;
              final w = MediaQuery.of(context).size.width;
              return Stack(
                children: [
                  if (t < 1.0)
                    Transform.translate(
                      offset: Offset(t * w, 0),
                      child: Opacity(
                        opacity: (1 - t).clamp(0.0, 1.0),
                        child: _buildLampGate(),
                      ),
                    ),
                  if (_revealed)
                    Transform.translate(
                      offset: Offset((1 - t) * w, 0),
                      child: _loading
                          ? const Center(child: CircularProgressIndicator(color: _kGold))
                          : SafeArea(
                              child: CustomScrollView(
                                controller: _scrollController,
                                slivers: [
                              SliverToBoxAdapter(child: _buildHeader(context, isMobile)),
                              SliverToBoxAdapter(child: _buildStats(isMobile)),
                              SliverToBoxAdapter(child: _buildFilters(isMobile)),
                              if (_visible.isEmpty)
                                SliverToBoxAdapter(child: _buildEmpty())
                              else
                                SliverPadding(
                                  padding: EdgeInsets.fromLTRB(
                                    isMobile ? 16 : 32, 8, isMobile ? 16 : 32, 100,
                                  ),
                                  sliver: SliverList.separated(
                                    itemCount: _visible.length,
                                    separatorBuilder: (_, index) => const SizedBox(height: 12),
                                    itemBuilder: (_, i) => _buildCard(_visible[i]),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLampGate() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TableLamp(
            onPulled: _reveal,
            size: 230,
            shadeColorTop: const Color(0xFFFFF8E8),
            shadeColorBottom: _kGoldLight,
            accentColor: _kGold,
          ),
          const SizedBox(height: 26),
          Image.asset('assets/moon_abaya_logo.png', height: 46),
          const SizedBox(height: 18),
          Text(
            'اسحب الحبل للدخول',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 32, 18, isMobile ? 16 : 32, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x22FFFFFF))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 18),
          ),
          const SizedBox(width: 4),
          Image.asset('assets/moon_abaya_logo.png', height: isMobile ? 34 : 42,
              errorBuilder: (context, error, stack) => const Icon(Icons.nightlight_round, color: _kGold)),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'المبيعات الخاصة',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(bool isMobile) {
    final cards = [
      _statCard('عدد المنتجات', _visible.length.toString(), Icons.inventory_2_rounded, _kGold),
      _statCard('إجمالي المبيعات', _money(_totalRevenue), Icons.point_of_sale_rounded, Colors.tealAccent),
      _statCard('إجمالي التكلفة', _money(_totalCost), Icons.shopping_bag_rounded, Colors.orangeAccent),
      _statCard('صافي الربح', _money(_totalProfit), Icons.trending_up_rounded,
          _totalProfit >= 0 ? Colors.greenAccent : Colors.redAccent),
      _statCard('المديونيات', _money(_totalDebt), Icons.credit_card_off_rounded,
          _totalDebt > 0 ? Colors.orangeAccent : Colors.greenAccent),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 32, 16, isMobile ? 16 : 32, 8),
      child: Wrap(spacing: 12, runSpacing: 12, children: cards),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isMobile) {
    Widget chip(String label, MoonAbayaCategory? cat) {
      final selected = _filter == cat;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = cat),
        backgroundColor: _kSurface,
        selectedColor: _kGold.withValues(alpha: 0.85),
        labelStyle: TextStyle(color: selected ? Colors.black : Colors.white70, fontWeight: FontWeight.w600),
        side: const BorderSide(color: Color(0x22FFFFFF)),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 32, 8, isMobile ? 16 : 32, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            chip('الكل', null),
            chip('عبايات', MoonAbayaCategory.abaya),
            chip('عطور', MoonAbayaCategory.perfume),
            chip('أخرى', MoonAbayaCategory.other),
            FilterChip(
              label: const Text('عليها مديونية'),
              selected: _debtOnly,
              onSelected: (v) => setState(() => _debtOnly = v),
              backgroundColor: _kSurface,
              selectedColor: Colors.orangeAccent.withValues(alpha: 0.85),
              labelStyle: TextStyle(
                color: _debtOnly ? Colors.black : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
              side: const BorderSide(color: Color(0x22FFFFFF)),
            ),
          ]),
          const SizedBox(height: 12),
          TextField(
            style: const TextStyle(color: Colors.white),
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'ابحث عن موديل...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
              filled: true,
              fillColor: _kSurface,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kGold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          Icon(Icons.nightlight_round, color: Colors.white.withValues(alpha: 0.15), size: 56),
          const SizedBox(height: 16),
          const Text('لا توجد منتجات بعد', style: TextStyle(color: Colors.white38)),
          const SizedBox(height: 6),
          const Text('اضغط على "منتج جديد" لإضافة أول عملية بيع',
              style: TextStyle(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCard(MoonAbayaItem item) {
    final profitColor = item.totalProfit >= 0 ? Colors.greenAccent : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kGold.withValues(alpha: 0.4)),
                ),
                child: Text(item.category.label,
                    style: const TextStyle(color: _kGoldLight, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(item.model,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ),
              IconButton(
                onPressed: () => _openForm(existing: item),
                icon: const Icon(Icons.edit_rounded, color: Colors.white38, size: 18),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: () => _delete(item),
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _miniStat('الكمية', '${item.quantity}'),
              _miniStat('سعر الشراء', _money(item.purchasePrice)),
              _miniStat('سعر البيع', _money(item.salePrice)),
              _miniStat('ربح الوحدة', _money(item.unitProfit)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (item.isFullyPaid ? Colors.greenAccent : Colors.orangeAccent)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (item.isFullyPaid ? Colors.greenAccent : Colors.orangeAccent)
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  item.isFullyPaid ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                  size: 15,
                  color: item.isFullyPaid ? Colors.greenAccent : Colors.orangeAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.isFullyPaid
                        ? 'مدفوع بالكامل'
                        : 'متبقي: ${_money(item.remainingDebt)} (مدفوع ${_money(item.amountPaid)} من ${_money(item.totalRevenue)})'
                            '${item.buyerName.trim().isNotEmpty ? ' — الزبون: ${item.buyerName.trim()}' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: item.isFullyPaid ? Colors.greenAccent : Colors.orangeAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!item.isFullyPaid) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _addPayment(item),
                icon: const Icon(Icons.add_card_rounded, size: 16, color: _kGold),
                label: const Text('تسجيل دفعة',
                    style: TextStyle(color: _kGold, fontWeight: FontWeight.w700, fontSize: 12.5)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
          if (item.payments.isNotEmpty) ...[
            const SizedBox(height: 4),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                collapsedIconColor: Colors.white38,
                iconColor: Colors.white54,
                shape: const RoundedRectangleBorder(side: BorderSide.none),
                collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
                title: Text('سجل الدفعات (${item.payments.length})',
                    style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                children: item.payments.reversed.map((p) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            size: 14, color: Colors.greenAccent.withValues(alpha: 0.7)),
                        const SizedBox(width: 8),
                        Text(
                          '${p.date.year}/${p.date.month.toString().padLeft(2, '0')}/${p.date.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_money(p.amount),
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        IconButton(
                          onPressed: () => _deletePayment(p),
                          icon: const Icon(Icons.close_rounded, size: 14, color: Colors.redAccent),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          if (item.isCurrentLoss) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.trending_down_rounded, size: 15, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'خسارة حالياً: المبلغ المستلم لا يغطي تكلفة الشراء',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (item.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(item.notes, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0x14FFFFFF)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${item.date.year}/${item.date.month.toString().padLeft(2, '0')}/${item.date.day.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white24, fontSize: 11),
              ),
              Text('الربح الإجمالي: ${_money(item.totalProfit)}',
                  style: TextStyle(color: profitColor, fontSize: 13, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _MoonAbayaFormResult {
  final MoonAbayaItem item;
  final MoonAbayaPayment? initialPayment;
  _MoonAbayaFormResult(this.item, this.initialPayment);
}

class _MoonAbayaForm extends StatefulWidget {
  final MoonAbayaItem? existing;
  const _MoonAbayaForm({this.existing});

  @override
  State<_MoonAbayaForm> createState() => _MoonAbayaFormState();
}

class _MoonAbayaFormState extends State<_MoonAbayaForm> {
  late MoonAbayaCategory _category;
  late final TextEditingController _model;
  late final TextEditingController _purchase;
  late final TextEditingController _sale;
  late final TextEditingController _qty;
  late final TextEditingController _notes;
  late final TextEditingController _paid;
  late final TextEditingController _buyer;
  late DateTime _date;
  bool _fullyPaid = true;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _category = e?.category ?? MoonAbayaCategory.abaya;
    _model = TextEditingController(text: e?.model ?? '');
    _purchase = TextEditingController(text: e != null ? _plain(e.purchasePrice) : '')
      ..addListener(_onAmountsChanged);
    _sale = TextEditingController(text: e != null ? _plain(e.salePrice) : '')
      ..addListener(_onAmountsChanged);
    _qty = TextEditingController(text: e != null ? '${e.quantity}' : '1')
      ..addListener(_onAmountsChanged);
    _notes = TextEditingController(text: e?.notes ?? '');
    _paid = TextEditingController()..addListener(_onAmountsChanged);
    _buyer = TextEditingController(text: e?.buyerName ?? '');
    _date = e?.date ?? DateTime.now();
  }

  String _plain(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  void _onAmountsChanged() => setState(() {});

  double get _currentTotalCost {
    final purchase = double.tryParse(_purchase.text.trim().replaceAll(',', '.')) ?? 0;
    final qty = int.tryParse(_qty.text.trim()) ?? 0;
    return purchase * qty;
  }

  double get _currentTotalRevenue {
    final sale = double.tryParse(_sale.text.trim().replaceAll(',', '.')) ?? 0;
    final qty = int.tryParse(_qty.text.trim()) ?? 0;
    return sale * qty;
  }

  double get _currentAmountPaid {
    if (_isEdit) return widget.existing!.amountPaid;
    if (_fullyPaid) return _currentTotalRevenue;
    return double.tryParse(_paid.text.trim().replaceAll(',', '.')) ?? 0;
  }

  bool get _isLossWarning => _currentTotalCost > 0 && _currentAmountPaid < _currentTotalCost;

  @override
  void dispose() {
    _model.dispose();
    _purchase.dispose();
    _sale.dispose();
    _qty.dispose();
    _notes.dispose();
    _paid.dispose();
    _buyer.dispose();
    super.dispose();
  }

  void _submit() {
    final model = _model.text.trim();
    final purchase = double.tryParse(_purchase.text.trim().replaceAll(',', '.'));
    final sale = double.tryParse(_sale.text.trim().replaceAll(',', '.'));
    final qty = int.tryParse(_qty.text.trim());

    if (model.isEmpty) { setState(() => _error = 'أدخل اسم الموديل'); return; }
    if (purchase == null || purchase < 0) { setState(() => _error = 'سعر الشراء غير صحيح'); return; }
    if (sale == null || sale < 0) { setState(() => _error = 'سعر البيع غير صحيح'); return; }
    if (qty == null || qty <= 0) { setState(() => _error = 'الكمية غير صحيحة'); return; }

    final buyerName = _buyer.text.trim();
    MoonAbayaPayment? initialPayment;

    if (!_isEdit) {
      final total = sale * qty;
      if (_fullyPaid) {
        if (total > 0) {
          initialPayment = MoonAbayaPayment(
            id: '${DateTime.now().microsecondsSinceEpoch}-p',
            amount: total,
            date: _date,
          );
        }
      } else {
        final parsedPaid = double.tryParse(_paid.text.trim().replaceAll(',', '.'));
        if (parsedPaid == null || parsedPaid < 0) {
          setState(() => _error = 'المبلغ المدفوع غير صحيح');
          return;
        }
        if (parsedPaid > total) {
          setState(() => _error = 'المبلغ المدفوع أكبر من سعر البيع الإجمالي');
          return;
        }
        if (buyerName.isEmpty) {
          setState(() => _error = 'أدخل اسم المشتري لأن المبلغ غير مسدد بالكامل');
          return;
        }
        if (parsedPaid > 0) {
          initialPayment = MoonAbayaPayment(
            id: '${DateTime.now().microsecondsSinceEpoch}-p',
            amount: parsedPaid,
            date: _date,
          );
        }
      }
    }

    final item = MoonAbayaItem(
      id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      category: _category,
      model: model,
      purchasePrice: purchase,
      salePrice: sale,
      quantity: qty,
      notes: _notes.text.trim(),
      date: _date,
      buyerName: buyerName,
    );
    Navigator.pop(context, _MoonAbayaFormResult(item, initialPayment));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: _kGold, surface: _kSurface),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.only(top: 60),
        decoration: const BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              Text(_isEdit ? 'تعديل المنتج' : 'منتج جديد',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),

              Wrap(
                spacing: 8,
                children: MoonAbayaCategory.values.map((c) {
                  final selected = _category == c;
                  return ChoiceChip(
                    label: Text(c.label),
                    selected: selected,
                    onSelected: (_) => setState(() => _category = c),
                    backgroundColor: _kSurfaceHi,
                    selectedColor: _kGold,
                    labelStyle: TextStyle(color: selected ? Colors.black : Colors.white70, fontWeight: FontWeight.w600),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              _field(_model, 'الموديل / النوع', Icons.checkroom_rounded),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _field(_purchase, 'سعر الشراء (د.م.)', Icons.shopping_bag_outlined,
                      keyboard: const TextInputType.numberWithOptions(decimal: true))),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_sale, 'سعر البيع (د.م.)', Icons.sell_outlined,
                      keyboard: const TextInputType.numberWithOptions(decimal: true))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _field(_qty, 'الكمية', Icons.numbers_rounded, keyboard: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: _decoration('التاريخ', Icons.calendar_today_rounded),
                        child: Text(
                          '${_date.year}/${_date.month.toString().padLeft(2, '0')}/${_date.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kSurfaceHi,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _fullyPaid,
                    onChanged: (v) => setState(() => _fullyPaid = v),
                    activeThumbColor: _kGold,
                    title: const Text('تم استلام كامل المبلغ',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
                if (!_fullyPaid) ...[
                  const SizedBox(height: 12),
                  _field(_paid, 'المبلغ المدفوع (د.م.)', Icons.payments_outlined,
                      keyboard: const TextInputType.numberWithOptions(decimal: true)),
                ],
              ] else ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'لتسجيل دفعة جديدة على هذه العملية، استخدم زر "تسجيل دفعة" في البطاقة بعد الحفظ.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _field(_buyer, 'اسم المشتري (اختياري)', Icons.person_outline_rounded),
              if (_isLossWarning) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.trending_down_rounded, size: 16, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'تنبيه: المبلغ المدفوع أقل من تكلفة الشراء — هذه العملية تُعتبر خسارة حالياً',
                          style: TextStyle(color: Colors.redAccent, fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _field(_notes, 'ملاحظات (اختياري)', Icons.notes_rounded, maxLines: 2),

              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                ),
              ],

              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_isEdit ? 'حفظ التعديلات' : 'إضافة المنتج',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.white38, size: 18),
      filled: true,
      fillColor: _kSurfaceHi,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kGold, width: 1.5),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {TextInputType? keyboard, int maxLines = 1}) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: _decoration(label, icon),
    );
  }
}
