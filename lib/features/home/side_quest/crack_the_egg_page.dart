// lib/features/home/side_quest/crack_the_egg_page.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../main_quest/quest_provider.dart';
import 'crack_the_egg_controller.dart';

class CrackTheEggPage extends StatefulWidget {
  final QuestProvider questProvider;
  final int userId;

  const CrackTheEggPage({
    super.key,
    required this.questProvider,
    required this.userId,
  });

  @override
  State<CrackTheEggPage> createState() => _CrackTheEggPageState();
}

class _CrackTheEggPageState extends State<CrackTheEggPage>
    with TickerProviderStateMixin {
  late CrackTheEggController controller;

  // Animasi tetap di View karena terikat TickerProvider (VSYNC) layar perangkat
  late AnimationController _wobbleCtrl;
  late Animation<double> _wobbleAnim;
  late AnimationController _crackCtrl;
  late AnimationController _burstCtrl;
  late Animation<double> _burstAnim;
  late AnimationController _rewardCtrl;
  late Animation<double> _rewardAnim;

  @override
  void initState() {
    super.initState();

    // Inisialisasi GetX Controller
    controller = Get.put(
      CrackTheEggController(
        questProvider: widget.questProvider,
        userId: widget.userId,
      ),
    );

    // Integrasi Animasi dengan trigger dari Controller
    _wobbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _wobbleAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _wobbleCtrl, curve: Curves.elasticOut));

    _crackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _burstAnim = CurvedAnimation(parent: _burstCtrl, curve: Curves.easeOut);

    _rewardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _rewardAnim = CurvedAnimation(
      parent: _rewardCtrl,
      curve: Curves.elasticOut,
    );

    // Sambungkan fungsi animasi ke controller
    controller.onWobbleTrigger = () => _wobbleCtrl.forward(from: 0);
    controller.onBurstTrigger = () => _burstCtrl.forward(from: 0);
    controller.onRewardTrigger = () => _rewardCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _wobbleCtrl.dispose();
    _crackCtrl.dispose();
    _burstCtrl.dispose();
    _rewardCtrl.dispose();
    Get.delete<CrackTheEggController>(); // Bersihkan controller dari memori
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        title: const Text(
          'Crack the Egg! 🥚',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Obx(
                () => Text(
                  '${controller.eggsOpened.value}/${CrackTheEggController.maxEggs} 🥚',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingAttempts.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.limitReached.value) {
          return _buildLimitReached();
        }
        if (controller.sessionDone.value) {
          return _buildSessionDone();
        }
        return _buildGame();
      }),
    );
  }

  Widget _buildLimitReached() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🥚', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 16),
            const Text(
              'Sudah 3x main hari ini!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Kembali lagi besok untuk main lagi.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Kembali ke Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGame() {
    return Stack(
      children: [
        Column(
          children: [
            _buildXpBar(),
            const SizedBox(height: 20),
            Obx(
              () => Text(
                controller.eggState.value == EggState.whole
                    ? 'Guncang HP untuk memecahkan telur!'
                    : controller.eggState.value == EggState.cracked
                    ? 'Terus guncang... hampir pecah!'
                    : 'Telur pecah!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.brown.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => !controller.showingReward.value
                  ? _buildShakeProgress()
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Obx(
                      () => controller.eggState.value == EggState.broken
                          ? _buildBurst()
                          : const SizedBox.shrink(),
                    ),
                    _buildEgg(),
                  ],
                ),
              ),
            ),
            Obx(
              () => !controller.showingReward.value
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: OutlinedButton.icon(
                        onPressed: controller.eggState.value != EggState.broken
                            ? controller.onShake
                            : null,
                        icon: const Icon(Icons.touch_app),
                        label: const Text('Tap jika sensor tidak berfungsi'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.brown.shade500,
                          side: BorderSide(color: Colors.brown.shade300),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        Obx(
          () => controller.showingReward.value
              ? _buildRewardOverlay()
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildXpBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('⭐', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Obx(
                () => Text(
                  'XP terkumpul: ${controller.totalXp.value}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                ),
              ),
            ],
          ),
          Obx(
            () => Text(
              'Telur ${controller.eggsOpened.value + 1} dari ${CrackTheEggController.maxEggs}',
              style: TextStyle(color: Colors.amber.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShakeProgress() {
    return Obx(() {
      final progress =
          controller.shakeCount.value / CrackTheEggController.shakesToBreak;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: Colors.brown.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress < 0.5
                      ? Colors.amber.shade400
                      : progress < 0.85
                      ? Colors.orange.shade400
                      : Colors.red.shade400,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${controller.shakeCount.value}/${CrackTheEggController.shakesToBreak} guncangan',
              style: TextStyle(fontSize: 12, color: Colors.brown.shade400),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildEgg() {
    return AnimatedBuilder(
      animation: Listenable.merge([_wobbleCtrl, _burstCtrl]),
      builder: (_, child) {
        final wobble = sin(_wobbleAnim.value * pi * 4) * 12;
        final burstScale = controller.eggState.value == EggState.broken
            ? (1.0 + _burstAnim.value * 0.4)
            : 1.0;
        final opacity = controller.eggState.value == EggState.broken
            ? (1.0 - _burstAnim.value).clamp(0.0, 1.0)
            : 1.0;

        return Transform.translate(
          offset: Offset(wobble, 0),
          child: Transform.scale(
            scale: burstScale,
            child: Opacity(opacity: opacity, child: child),
          ),
        );
      },
      child: Obx(() => _EggWidget(state: controller.eggState.value)),
    );
  }

  Widget _buildBurst() {
    return AnimatedBuilder(
      animation: _burstCtrl,
      builder: (_, __) => SizedBox(
        width: 300,
        height: 300,
        child: CustomPaint(painter: _BurstPainter(progress: _burstAnim.value)),
      ),
    );
  }

  Widget _buildRewardOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: AnimatedBuilder(
          animation: _rewardCtrl,
          builder: (_, child) =>
              Transform.scale(scale: _rewardAnim.value, child: child),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🥳 Telur Pecah!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Obx(
                    () => Text(
                      '+${controller.rewardXp.value} XP',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Kamu dapat kata baru:',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade400, Colors.purple.shade400],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        controller.rewardVocab.value?.word ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (controller
                              .rewardVocab
                              .value
                              ?.pronunciation
                              .isNotEmpty ??
                          false)
                        Text(
                          '[${controller.rewardVocab.value!.pronunciation}]',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        controller.rewardVocab.value?.meaning ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (controller.rewardVocab.value?.example.isNotEmpty ?? false)
                  Text(
                    '"${controller.rewardVocab.value!.example}"',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _burstCtrl.reset();
                      _rewardCtrl.reset();
                      _wobbleCtrl.reset();
                      controller.collectReward();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Obx(
                      () => Text(
                        controller.eggsOpened.value + 1 <
                                CrackTheEggController.maxEggs
                            ? 'Ambil & Lanjut! 🥚'
                            : 'Ambil & Selesai! 🎉',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionDone() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎊', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 16),
            const Text(
              'Semua telur terpecahkan!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Total XP didapat',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Obx(
                () => Text(
                  '+${controller.totalXp.value} XP',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Kembali ke Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Egg Widget ──────────────────────────────────────────

class _EggWidget extends StatelessWidget {
  final EggState state;
  const _EggWidget({required this.state});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 220,
      child: CustomPaint(painter: _EggPainter(state: state)),
    );
  }
}

class _EggPainter extends CustomPainter {
  final EggState state;
  _EggPainter({required this.state});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final eggColor = state == EggState.whole
        ? const Color(0xFFFFF3C0)
        : state == EggState.cracked
        ? const Color(0xFFFFE082)
        : const Color(0xFFFFF9C4);

    final paint = Paint()..color = eggColor;
    final strokePaint = Paint()
      ..color = const Color(0xFFD4A017)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final path = Path();
    path.moveTo(cx, cy - size.height * 0.45);
    path.cubicTo(
      cx + size.width * 0.45,
      cy - size.height * 0.45,
      cx + size.width * 0.5,
      cy + size.height * 0.1,
      cx,
      cy + size.height * 0.45,
    );
    path.cubicTo(
      cx - size.width * 0.5,
      cy + size.height * 0.1,
      cx - size.width * 0.45,
      cy - size.height * 0.45,
      cx,
      cy - size.height * 0.45,
    );
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);

    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 25, cy - 40), width: 25, height: 40),
      shinePaint,
    );

    if (state == EggState.cracked || state == EggState.broken) {
      _drawCracks(canvas, cx, cy, size);
    }
  }

  void _drawCracks(Canvas canvas, double cx, double cy, Size size) {
    final crackPaint = Paint()
      ..color = const Color(0xFFB8860B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final crack1 = Path();
    crack1.moveTo(cx - 20, cy - 20);
    crack1.lineTo(cx - 5, cy - 5);
    crack1.lineTo(cx + 15, cy - 15);
    crack1.lineTo(cx + 5, cy + 5);
    crack1.lineTo(cx + 20, cy + 10);
    canvas.drawPath(crack1, crackPaint);

    final crack2 = Path();
    crack2.moveTo(cx - 30, cy + 5);
    crack2.lineTo(cx - 15, cy - 2);
    crack2.lineTo(cx - 25, cy - 15);
    canvas.drawPath(crack2, crackPaint);

    if (state == EggState.broken) {
      final crack3 = Path();
      crack3.moveTo(cx + 10, cy + 20);
      crack3.lineTo(cx + 25, cy + 5);
      crack3.lineTo(cx + 35, cy + 15);
      canvas.drawPath(crack3, crackPaint);

      final crack4 = Path();
      crack4.moveTo(cx - 10, cy + 15);
      crack4.lineTo(cx, cy + 30);
      crack4.lineTo(cx + 10, cy + 20);
      canvas.drawPath(crack4, crackPaint);
    }
  }

  @override
  bool shouldRepaint(_EggPainter old) => old.state != state;
}

// ── Burst Particles ─────────────────────────────────────

class _BurstPainter extends CustomPainter {
  final double progress;
  _BurstPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rand = Random(42);

    final colors = [
      Colors.yellow.shade400,
      Colors.amber.shade300,
      Colors.orange.shade300,
      Colors.amber.shade600,
      Colors.white,
    ];

    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * 2 * pi + rand.nextDouble() * 0.3;
      final speed = 60 + rand.nextDouble() * 60;
      final radius = 4 + rand.nextDouble() * 6;
      final dx = cos(angle) * speed * progress;
      final dy = sin(angle) * speed * progress;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final color = colors[i % colors.length].withOpacity(opacity);
      final paint = Paint()..color = color;
      canvas.drawCircle(
        Offset(cx + dx, cy + dy),
        radius * (1 - progress * 0.5),
        paint,
      );
    }

    if (progress > 0.1) {
      final yolkPaint = Paint()
        ..color = Colors.yellow.shade600.withOpacity(
          (1 - progress).clamp(0, 1),
        );
      canvas.drawCircle(
        Offset(cx + 10 * progress, cy + 20 * progress),
        25 * (1 - progress * 0.3),
        yolkPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.progress != progress;
}
