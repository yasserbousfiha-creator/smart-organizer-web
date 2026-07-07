import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'portal/supabase_config.dart';
import 'portal/login_screen.dart';
import 'portal/home_screen.dart';
import 'theme/app_colors.dart';
import 'moon_abaya/moon_abaya_screen.dart';

String? _portalInitError;
bool _supabaseReady = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartOrganizerApp());
  try {
    await Supabase.initialize(
      url: PortalConfig.url,
      publishableKey: PortalConfig.anonKey,
    );
    _supabaseReady = true;
  } catch (e) {
    _portalInitError = e.toString();
  }
}

const double kMobileBreakpoint = 700;
const Color kBg = AppColors.bgDark;
const Color kBlue = AppColors.secondary;
const Color kPurple = AppColors.primary;
const Color kCyan = AppColors.primaryLight;
const LinearGradient kMainGradient = AppColors.mainGradient;

// ── Reveal-on-scroll wrapper ────────────────────────────────────
/// يُظهر [child] بحركة ظهور تدريجي (تلاشي + انزلاق للأعلى) في أول مرة
/// يدخل فيها ضمن نطاق الرؤية أثناء التمرير، ثم يبقى ظاهرًا.
class _RevealOnScroll extends StatefulWidget {
  final Widget child;
  final double triggerOffset;
  const _RevealOnScroll({required this.child, this.triggerOffset = 80});

  @override
  State<_RevealOnScroll> createState() => _RevealOnScrollState();
}

class _RevealOnScrollState extends State<_RevealOnScroll> {
  bool _visible = false;
  ScrollPosition? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newPosition = Scrollable.maybeOf(context)?.position;
    if (newPosition != _position) {
      _position?.removeListener(_checkVisibility);
      _position = newPosition;
      _position?.addListener(_checkVisibility);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  void _checkVisibility() {
    if (_visible || !mounted) return;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) return;
    final viewportHeight = MediaQuery.of(context).size.height;
    final position = renderObject.localToGlobal(Offset.zero);
    if (position.dy < viewportHeight - widget.triggerOffset) {
      setState(() => _visible = true);
      _position?.removeListener(_checkVisibility);
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_checkVisibility);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.06),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ── Dashed Circle Painter ─────────────────────────────────────
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  const _DashedCirclePainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    const totalDashes = 24;
    final stepArc = 2 * math.pi / totalDashes;
    final dashArc = stepArc * 0.55;
    for (int i = 0; i < totalDashes; i++) {
      final startAngle = -math.pi / 2 + i * stepArc;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashArc,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

// ── Grid Icon ─────────────────────────────────────────────────
class GridIconWidget extends StatefulWidget {
  final double size;
  final bool showSpark;
  const GridIconWidget({super.key, this.size = 100, this.showSpark = true});

  @override
  State<GridIconWidget> createState() => _GridIconWidgetState();
}

class _GridIconWidgetState extends State<GridIconWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _rotAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _rotAnim = Tween<double>(
      begin: 0,
      end: math.pi,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final gap = s * 0.055;
    final cellSz = (s - gap * 2) / 3;
    final cellR = s * 0.075;
    final sparkSz = s * 0.27;

    const cells = [
      'active',
      'bright',
      'none',
      'bright',
      'active',
      'active',
      'none',
      'active',
      'bright',
    ];

    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (row) => Padding(
                padding: EdgeInsets.only(top: row > 0 ? gap : 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (col) => Padding(
                      padding: EdgeInsets.only(left: col > 0 ? gap : 0),
                      child: _cell(cells[row * 3 + col], cellSz, cellR),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.showSpark)
            Positioned(
              top: -sparkSz * 0.3,
              right: -sparkSz * 0.3,
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, child) => Transform.rotate(
                  angle: _rotAnim.value,
                  child: Transform.scale(scale: _scaleAnim.value, child: child),
                ),
                child: Container(
                  width: sparkSz,
                  height: sparkSz,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF22D3EE), Color(0xFF0E7490)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF67E8F9).withValues(alpha: 0.65),
                        blurRadius: sparkSz * 0.5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '✦',
                      style: TextStyle(
                        fontSize: sparkSz * 0.45,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(String type, double sz, double r) {
    Gradient gradient;
    Color border;
    List<BoxShadow> shadows = const [];

    switch (type) {
      case 'bright':
        gradient = const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF67E8F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        border = const Color(0xFF22D3EE);
        shadows = [
          BoxShadow(
            color: const Color(0xFF67E8F9).withValues(alpha: 0.55),
            blurRadius: sz * 0.16,
          ),
          BoxShadow(
            color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
            blurRadius: sz * 0.32,
          ),
        ];
        break;
      case 'active':
        gradient = LinearGradient(
          colors: [
            const Color(0xFF06B6D4).withValues(alpha: 0.3),
            const Color(0xFF67E8F9).withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        border = const Color(0xFF22D3EE).withValues(alpha: 0.5);
        break;
      default:
        gradient = LinearGradient(
          colors: [
            const Color(0xFF0E7490).withValues(alpha: 0.08),
            const Color(0xFF0E7490).withValues(alpha: 0.08),
          ],
        );
        border = const Color(0xFF06B6D4).withValues(alpha: 0.14);
    }

    return Container(
      width: sz,
      height: sz,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: border, width: 1),
        boxShadow: shadows,
      ),
    );
  }
}

// ── Circle Logo ───────────────────────────────────────────────
class CircleLogoWidget extends StatefulWidget {
  final double size;
  const CircleLogoWidget({super.key, this.size = 220});

  @override
  State<CircleLogoWidget> createState() => _CircleLogoWidgetState();
}

class _CircleLogoWidgetState extends State<CircleLogoWidget>
    with TickerProviderStateMixin {
  late final AnimationController _glow;
  late final AnimationController _ring;
  late final AnimationController _orbit;
  late final AnimationController _float;
  late final Animation<double> _glowAnim;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glow, curve: Curves.easeInOut));
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(
      begin: 0,
      end: -8,
    ).animate(CurvedAnimation(parent: _float, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _glow.dispose();
    _ring.dispose();
    _orbit.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final iconSz = s * 0.38;
    final ringW = s * 0.018;
    final dotSz = s * 0.06;
    final outerSz = s * 1.14;

    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _floatAnim.value),
        child: child,
      ),
      child: SizedBox(
        width: outerSz,
        height: outerSz,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Outer glow ring
            AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, child) => Opacity(
                opacity: _glowAnim.value,
                child: Container(
                  width: outerSz,
                  height: outerSz,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF06B6D4).withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                      stops: const [0.6, 0.75],
                    ),
                  ),
                ),
              ),
            ),

            // Dashed spinning ring
            AnimatedBuilder(
              animation: _ring,
              builder: (_, child) => Transform.rotate(
                angle: _ring.value * 2 * math.pi,
                child: child,
              ),
              child: SizedBox(
                width: s * 1.05,
                height: s * 1.05,
                child: CustomPaint(
                  painter: _DashedCirclePainter(
                    color: const Color(0xFF22D3EE).withValues(alpha: 0.22),
                    strokeWidth: ringW,
                  ),
                ),
              ),
            ),

            // Solid ring
            Container(
              width: s,
              height: s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.18),
                  width: ringW * 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                    blurRadius: s * 0.12,
                  ),
                ],
              ),
            ),

            // Main circle
            Container(
              width: s,
              height: s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0D1B2E),
                    Color(0xFF0A1628),
                    Color(0xFF071020),
                  ],
                  stops: [0.0, 0.55, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.65),
                    blurRadius: s * 0.28,
                    offset: Offset(0, s * 0.12),
                  ),
                  BoxShadow(
                    color: const Color(0xFF0E7490).withValues(alpha: 0.09),
                    spreadRadius: 1,
                    blurRadius: 0,
                  ),
                ],
              ),
              child: ClipOval(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: -s * 0.2,
                      left: -s * 0.2,
                      child: Container(
                        width: s * 0.6,
                        height: s * 0.6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF06B6D4).withValues(alpha: 0.12),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -s * 0.15,
                      right: -s * 0.15,
                      child: Container(
                        width: s * 0.5,
                        height: s * 0.5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF67E8F9).withValues(alpha: 0.07),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GridIconWidget(size: iconSz),
                          SizedBox(height: s * 0.055),
                          ShaderMask(
                            shaderCallback: (b) => const LinearGradient(
                              colors: [Colors.white, Color(0xFF67E8F9)],
                              stops: [0.3, 1.0],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(b),
                            child: Text(
                              'منظمك الذكي',
                              style: TextStyle(fontFamily: 'Cairo',
                                fontWeight: FontWeight.w900,
                                fontSize: s * 0.088,
                                color: Colors.white,
                                height: 1.15,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          SizedBox(height: s * 0.018),
                          Text(
                            'SMART ORGANIZER',
                            style: TextStyle(fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w300,
                              fontSize: s * 0.036,
                              letterSpacing: 2,
                              color: const Color(
                                0xFF67E8F9,
                              ).withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Orbit dot
            AnimatedBuilder(
              animation: _orbit,
              builder: (_, child) {
                final angle = _orbit.value * 2 * math.pi - math.pi / 2;
                return Transform.translate(
                  offset: Offset(
                    math.cos(angle) * s / 2,
                    math.sin(angle) * s / 2,
                  ),
                  child: child,
                );
              },
              child: Container(
                width: dotSz,
                height: dotSz,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22D3EE), Color(0xFF0E7490)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22D3EE).withValues(alpha: 0.7),
                      blurRadius: s * 0.05,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small Logo (navbar / footer) ──────────────────────────────
class SmallLogoWidget extends StatelessWidget {
  final double size;
  const SmallLogoWidget({super.key, this.size = 38});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1B2E), Color(0xFF071020)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFF06B6D4).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E7490).withValues(alpha: 0.4),
            blurRadius: size * 0.3,
          ),
        ],
      ),
      child: ClipOval(
        child: Center(
          child: GridIconWidget(size: size * 0.58, showSpark: false),
        ),
      ),
    );
  }
}

// ── App ───────────────────────────────────────────────────────
class SmartOrganizerApp extends StatelessWidget {
  const SmartOrganizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Organizer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: kBg,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.danger,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        textTheme: ThemeData.dark().textTheme
            .apply(fontFamily: 'Tajawal', bodyColor: Colors.white),
      ),
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      home: const LandingPage(),
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;
  final GlobalKey _supportKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  bool _showScrollTop = false;

  void _scrollToSupport() {
    final ctx = _supportKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onScroll() {
    final show = _scrollController.offset > 400;
    if (show != _showScrollTop) setState(() => _showScrollTop = show);
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _heroFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0, 0.7, curve: Curves.easeOut),
      ),
    );
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroController, curve: Curves.easeOut));
    _heroController.forward();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _heroController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      floatingActionButton: _showScrollTop
          ? FloatingActionButton(
              heroTag: 'landingScrollTop',
              mini: true,
              onPressed: _scrollToTop,
              backgroundColor: AppColors.surface,
              foregroundColor: kCyan,
              child: const Icon(Icons.arrow_upward_rounded),
            )
          : null,
      body: Stack(
        children: [
          _buildBackgroundOrbs(),
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                _buildNavBar(context),
                FadeTransition(
                  opacity: _heroFade,
                  child: SlideTransition(
                    position: _heroSlide,
                    child: _buildHeroSection(context),
                  ),
                ),
                _RevealOnScroll(child: _buildFeaturesSection()),
                _RevealOnScroll(child: _buildScreenshotsSection(context)),
                KeyedSubtree(
                  key: _supportKey,
                  child: _RevealOnScroll(child: _buildSupportSection()),
                ),
                _RevealOnScroll(child: _buildEmployeePortalSection(context)),
                _RevealOnScroll(
                  triggerOffset: 40,
                  child: _buildFooter(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundOrbs() {
    return Stack(
      children: [
        Positioned(
          top: -120,
          right: -120,
          child: Container(
            width: 550,
            height: 550,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [kBlue.withValues(alpha: 0.18), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          top: 300,
          left: -160,
          child: Container(
            width: 420,
            height: 420,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [kPurple.withValues(alpha: 0.13), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [kCyan.withValues(alpha: 0.08), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavBar(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < kMobileBreakpoint;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 48,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          SmallLogoWidget(size: 38),
          const SizedBox(width: 12),
          ShaderMask(
            shaderCallback: (b) => kMainGradient.createShader(b),
            child: Text(
              'Smart Organizer',
              style: TextStyle(fontFamily: 'Tajawal',
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 6),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _openMoonAbaya(context),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.circle,
                  size: 4,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
          const Spacer(),
          if (isMobile)
            IconButton(
              onPressed: () => _showMobileMenu(context),
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
            )
          else ...[
            _navLink('التطبيق', () {}),
            const SizedBox(width: 4),
            _navLink('الدعم الفني', _scrollToSupport),
            const SizedBox(width: 16),
          ],
          _employeePortalButton(),
        ],
      ),
    );
  }

  Widget _navLink(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white60,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.apps_rounded, color: Colors.white70),
                  title: const Text(
                    'التطبيق',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  onTap: () => Navigator.pop(sheetContext),
                ),
                ListTile(
                  leading: const Icon(Icons.support_agent_rounded, color: Colors.white70),
                  title: const Text(
                    'الدعم الفني',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _scrollToSupport();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.lock_person_rounded, color: kPurple),
                  title: const Text(
                    'بوابة الموظفين',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openPortal(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < kMobileBreakpoint;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 80,
        vertical: isMobile ? 60 : 110,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 70,
        runSpacing: 60,
        children: [
          SizedBox(
            width: isMobile ? double.infinity : 560,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heroBadge(),
                const SizedBox(height: 30),
                ShaderMask(
                  shaderCallback: (b) => kMainGradient.createShader(b),
                  child: Text(
                    'نظّم حياتك ومهامك',
                    style: TextStyle(fontFamily: 'Tajawal',
                      fontSize: isMobile ? 40 : 62,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                ),
                Text(
                  'بذكاء وسهولة',
                  style: TextStyle(fontFamily: 'Tajawal',
                    fontSize: isMobile ? 40 : 62,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  'تطبيق Smart Organizer هو رفيقك اليومي لإدارة مهامك وترتيب أفكارك بكفاءة. يتطلب التحميل أو الدخول باستخدام رمز المرور الخاص بك.',
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.white.withValues(alpha: 0.6),
                    height: 1.75,
                  ),
                ),
                const SizedBox(height: 50),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildGradientButton(
                      context: context,
                      icon: Icons.android_rounded,
                      title: 'تحميل التطبيق',
                      subtitle: 'تنزيل مباشر للأندرويد',
                      gradient: kMainGradient,
                      url:
                          'https://raw.githubusercontent.com/yasserbousfiha-creator/smart-organizer-web/main/apk/smart-organizer.zip',
                    ),
                    _buildOutlineButton(
                      context: context,
                      icon: Icons.language_rounded,
                      title: 'تشغيل في المتصفح',
                      subtitle: 'للايفون والمنصات الأخرى',
                      url: 'https://celebrated-chimera-576e3d.netlify.app/',
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildHeroVisual(isMobile),
        ],
      ),
    );
  }

  Widget _heroBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kBlue.withValues(alpha: 0.18),
            kPurple.withValues(alpha: 0.18),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: kBlue.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: kCyan,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'وصول خاص للمدعوين فقط',
            style: TextStyle(
              color: kCyan,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroVisual(bool isMobile) {
    return CircleLogoWidget(size: isMobile ? 260 : 320);
  }

  Widget _buildFeaturesSection() {
    final features = [
      {
        'icon': Icons.checklist_rounded,
        'title': 'إدارة المهام',
        'desc': 'رتّب مهامك اليومية بسهولة وتابع تقدمك بشكل مرئي وواضح.',
        'color': kBlue,
      },
      {
        'icon': Icons.notifications_active_rounded,
        'title': 'تذكيرات ذكية',
        'desc': 'لن تنسى موعداً أو مهمة مع نظام التذكير الذكي التلقائي.',
        'color': kPurple,
      },
      {
        'icon': Icons.bar_chart_rounded,
        'title': 'إحصائيات وتقارير',
        'desc': 'تابع إنتاجيتك عبر تقارير مفصّلة وسهلة الفهم في لحظة.',
        'color': kCyan,
      },
      {
        'icon': Icons.lock_rounded,
        'title': 'خصوصية تامة',
        'desc': 'وصول مؤمَّن بكلمة مرور خاصة لحماية بياناتك الشخصية.',
        'color': AppColors.info,
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 40),
      child: Column(
        children: [
          _sectionBadge('المميزات الرئيسية'),
          const SizedBox(height: 18),
          _sectionTitle('كل ما تحتاجه في مكان واحد'),
          const SizedBox(height: 14),
          _sectionSubtitle(
            'مصمم خصيصاً لمساعدتك على تحقيق أقصى إنتاجية يومياً',
          ),
          const SizedBox(height: 68),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: features
                .map(
                  (f) => _buildFeatureCard(
                    icon: f['icon'] as IconData,
                    title: f['title'] as String,
                    desc: f['desc'] as String,
                    color: f['color'] as Color,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.55),
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenshotsSection(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < kMobileBreakpoint;
    final screenshots = [
      'assets/screenshots/sc1.jpg',
      'assets/screenshots/sc2.jpg',
      'assets/screenshots/sc3.jpg',
      'assets/screenshots/sc4.jpg',
      'assets/screenshots/sc5.jpg',
      'assets/screenshots/sc6.jpg',
      'assets/screenshots/sc7.jpg',
      'assets/screenshots/sc8.jpg',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kBg, AppColors.surface, kBg],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          _sectionBadge('معاينة التطبيق'),
          const SizedBox(height: 18),
          _sectionTitle('واجهات التطبيق'),
          const SizedBox(height: 14),
          _sectionSubtitle('تصميم عصري يركز على سهولة الاستخدام والجمالية'),
          const SizedBox(height: 68),
          CarouselSlider.builder(
            itemCount: screenshots.length,
            options: CarouselOptions(
              height: isMobile ? 420 : 520,
              viewportFraction: isMobile ? 0.85 : 0.28,
              initialPage: 1,
              enableInfiniteScroll: true,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 3),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
              enlargeCenterPage: !isMobile,
              enlargeFactor: 0.25,
            ),
            itemBuilder: (context, index, _) {
              return _buildScreenshotCard(screenshots[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScreenshotCard(String imagePath) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white, width: 6),
        boxShadow: [
          BoxShadow(
            color: kBlue.withValues(alpha: 0.35),
            blurRadius: 35,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (_, error, stack) => Container(
            color: AppColors.surface,
            child: Icon(
              Icons.phone_android,
              color: Colors.white.withValues(alpha: 0.2),
              size: 50,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 40),
      child: Column(
        children: [
          _sectionBadge('تواصل معنا'),
          const SizedBox(height: 18),
          _sectionTitle('الدعم الفني والمساندة'),
          const SizedBox(height: 14),
          _sectionSubtitle(
            'فريقنا جاهز للرد على استفساراتك ومساعدتك في أي وقت',
          ),
          const SizedBox(height: 68),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _buildContactCard(
                icon: Icons.wechat_rounded,
                title: 'واتساب',
                subtitle: '+966 50 015 0309',
                gradient: const LinearGradient(
                  colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                ),
                onTap: () => _launchURL('https://wa.me/966500150309'),
              ),
              _buildContactCard(
                icon: Icons.email_rounded,
                title: 'البريد الإلكتروني',
                subtitle: 'yasserbousfiha@gmail.com',
                gradient: kMainGradient,
                onTap: () => _launchURL('mailto:yasserbousfiha@gmail.com'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(34),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withValues(alpha: 0.35),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, size: 30, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _openPortal(BuildContext context) {
    if (!_supabaseReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_portalInitError != null
              ? 'خطأ في الاتصال: $_portalInitError'
              : 'جاري الاتصال بالخادم، حاول مرة أخرى...'),
          backgroundColor: _portalInitError != null
              ? Colors.red.shade700
              : Colors.orange.shade700,
        ),
      );
      return;
    }
    final session = Supabase.instance.client.auth.currentSession;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: session != null
              ? const PortalHomeScreen()
              : const PortalLoginScreen(),
        ),
      ),
    );
  }

  Widget _employeePortalButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openPortal(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            color: Colors.white.withValues(alpha: 0.05),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_rounded,
                size: 17,
                color: Colors.white.withValues(alpha: 0.75),
              ),
              const SizedBox(width: 8),
              Text(
                'بوابة الموظفين',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeePortalSection(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < kMobileBreakpoint;

    final badge = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: kPurple.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kPurple.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_person_rounded,
                size: 13,
                color: kPurple.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 6),
              Text(
                'للموظفين فقط',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kPurple.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        badge,
        const SizedBox(height: 18),
        ShaderMask(
          shaderCallback: (b) =>
              LinearGradient(colors: [kPurple, kBlue]).createShader(b),
          child: Text(
            'بوابة الموظفين',
            style: TextStyle(fontFamily: 'Tajawal',
              fontSize: isMobile ? 26 : 30,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'تحقق من إجازاتك، راتبك، سلفك، وبياناتك الشخصية\nمن أي مكان وفي أي وقت.',
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withValues(alpha: 0.55),
            height: 1.7,
          ),
        ),
      ],
    );

    final loginButton = GestureDetector(
      onTap: () => _openPortal(context),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: isMobile ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kPurple, kBlue],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: kPurple.withValues(alpha: 0.45),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.login_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                'تسجيل الدخول',
                style: TextStyle(fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: 20,
      ),
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 32 : 48,
        horizontal: isMobile ? 24 : 40,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [kPurple.withValues(alpha: 0.12), kBlue.withValues(alpha: 0.12)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        border: Border.all(color: kPurple.withValues(alpha: 0.25)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                textColumn,
                const SizedBox(height: 28),
                loginButton,
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: textColumn),
                const SizedBox(width: 40),
                loginButton,
              ],
            ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 44),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SmallLogoWidget(size: 28),
              const SizedBox(width: 10),
              ShaderMask(
                shaderCallback: (b) => kMainGradient.createShader(b),
                child: const Text(
                  'Smart Organizer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'جميع الحقوق محفوظة By YASSER BOUSFIHA © 2026 — Smart Organizer',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.28),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool> _isMoonAbayaAdmin() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      final data = await Supabase.instance.client
          .from('moon_abaya_admins')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();
      return data != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> _openMoonAbaya(BuildContext context) async {
    if (!_supabaseReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_portalInitError != null
              ? 'خطأ في الاتصال: $_portalInitError'
              : 'جاري الاتصال بالخادم، حاول مرة أخرى...'),
          backgroundColor: _portalInitError != null
              ? Colors.red.shade700
              : Colors.orange.shade700,
        ),
      );
      return;
    }

    if (Supabase.instance.client.auth.currentSession != null) {
      final isAdmin = await _isMoonAbayaAdmin();
      if (!context.mounted) return;
      if (isAdmin) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MoonAbayaScreen()),
        );
        return;
      }
      // الجلسة الحالية تخص حسابًا آخر (مثلاً حساب HR) — سجّل الخروج منه
      // لأن حساب Moon Abaya مستقل تمامًا وله بيانات دخول خاصة به.
      await Supabase.instance.client.auth.signOut();
    }

    if (!context.mounted) return;
    await _showMoonAbayaLoginDialog(context);
  }

  Future<void> _showMoonAbayaLoginDialog(BuildContext context) async {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    final success = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          String? error;
          bool loading = false;

          Future<void> submit() async {
            if (userCtrl.text.trim().isEmpty) {
              setDialogState(() => error = 'أدخل اسم المستخدم');
              return;
            }
            setDialogState(() { loading = true; error = null; });
            try {
              final email = '${userCtrl.text.trim().toLowerCase()}@moonabaya.local';
              await Supabase.instance.client.auth.signInWithPassword(
                email: email,
                password: passCtrl.text,
              );
              final isAdmin = await _isMoonAbayaAdmin();
              if (!isAdmin) {
                setDialogState(() {
                  loading = false;
                  error = 'هذا الحساب لا يملك صلاحية الوصول';
                });
                return;
              }
              if (ctx.mounted) Navigator.pop(ctx, true);
            } on AuthException catch (e) {
              setDialogState(() {
                loading = false;
                error = e.message.contains('Invalid login')
                    ? 'اسم المستخدم أو كلمة المرور غير صحيحة'
                    : e.message;
              });
            } catch (e) {
              setDialogState(() { loading = false; error = 'خطأ: $e'; });
            }
          }

          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
              title: const Text(
                'وصول مقيّد',
                style: TextStyle(fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: userCtrl,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'اسم المستخدم',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: kBlue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (_) => submit(),
                    decoration: InputDecoration(
                      hintText: 'كلمة المرور',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: kBlue),
                      ),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12.5)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: loading ? null : () => Navigator.pop(ctx),
                  child: Text(
                    'إلغاء',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: kMainGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: loading ? null : submit,
                    child: loading
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('دخول'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (success == true && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MoonAbayaScreen()),
      );
    }
  }

  Widget _sectionBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kBlue.withValues(alpha: 0.15),
            kPurple.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: kBlue.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: kCyan,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return ShaderMask(
      shaderCallback: (b) => kMainGradient.createShader(b),
      child: Text(
        text,
        style: TextStyle(fontFamily: 'Tajawal',
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _sectionSubtitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        color: Colors.white.withValues(alpha: 0.5),
        height: 1.65,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildGradientButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required String url,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.45),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () => _showPasscodeDialog(context, url),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlineButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String url,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white.withValues(alpha: 0.05),
      ),
      onPressed: () => _showPasscodeDialog(context, url),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 26),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showPasscodeDialog(BuildContext context, String url) async {
    final codeController = TextEditingController();
    const correctCode = 'bousfiha';

    return showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          title: Text(
            'وصول مقيّد',
            style: TextStyle(fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'الرجاء إدخال رمز الدخول الخاص بك للمتابعة وفتح الرابط.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: codeController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'أدخل الرمز هنا',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kBlue),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'إلغاء',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: kMainGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: kBlue.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  if (codeController.text == correctCode) {
                    Navigator.pop(ctx);
                    _launchURL(url);
                  } else {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('رمز الدخول غير صحيح!'),
                        backgroundColor: Colors.red.shade700,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                },
                child: const Text('تحقق وافتح'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final uri = Uri.parse(urlString);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $uri');
    }
  }
}
