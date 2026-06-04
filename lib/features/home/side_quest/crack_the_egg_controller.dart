// lib/features/home/side_quest/crack_the_egg_controller.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../../data/local/database_helper.dart';
import '../../../data/local/quest_data.dart';
import '../../../data/models/quest_model.dart';
import '../main_quest/quest_provider.dart';

enum EggState { whole, cracked, broken }

class CrackTheEggController extends GetxController {
  final QuestProvider questProvider;
  final int userId;

  // ── Constants ────────────────────────────────────────────
  static const int shakesToCrack = 3;
  static const int shakesToBreak = 6;
  static const int maxEggs = 3;
  static const double shakeThreshold = 12.0;

  // ── State Variables (Rx) ─────────────────────────────────
  final eggState = Rx<EggState>(EggState.whole);
  final shakeCount = RxInt(0);
  final eggsOpened = RxInt(0);
  final totalXp = RxInt(0);
  final isLoadingAttempts = RxBool(true);
  final limitReached = RxBool(false);
  final sessionDone = RxBool(false);
  final showingReward = RxBool(false);
  final rewardVocab = Rx<VocabItem?>(null);
  final rewardXp = RxInt(0);

  // ── Sensor & Timing ──────────────────────────────────────
  StreamSubscription<AccelerometerEvent>? _sub;
  double _lastX = 0, _lastY = 0, _lastZ = 0;
  DateTime _lastShake = DateTime.now();
  final _rand = Random();

  // ── Animation Callbacks ──────────────────────────────────
  late VoidCallback onWobbleTrigger;
  late VoidCallback onBurstTrigger;
  late VoidCallback onRewardTrigger;

  CrackTheEggController({required this.questProvider, required this.userId});

  @override
  void onInit() {
    super.onInit();
    _checkDailyLimit();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  // ── Daily Limit Check ────────────────────────────────────
  Future<void> _checkDailyLimit() async {
    try {
      final db = DatabaseHelper.instance;
      final count = await db.getDailyAttempts(userId, 'crack_the_egg');
      debugPrint('_checkDailyLimit: userId=$userId, count=$count');

      eggsOpened.value = count;
      limitReached.value = count >= maxEggs;

      if (!limitReached.value) {
        _startListening();
      }
    } catch (e) {
      debugPrint('_checkDailyLimit error: $e');
    } finally {
      isLoadingAttempts.value = false;
    }
  }

  // ── Sensor Listening ─────────────────────────────────────
  void _startListening() {
    _sub = accelerometerEventStream().listen((event) {
      if (showingReward.value || sessionDone.value) return;
      if (eggState.value == EggState.broken) return;

      final now = DateTime.now();
      if (now.difference(_lastShake).inMilliseconds < 400) return;

      final dx = (event.x - _lastX).abs();
      final dy = (event.y - _lastY).abs();
      final dz = (event.z - _lastZ).abs();

      if ((dx + dy + dz) > shakeThreshold) {
        _lastShake = now;
        onShake();
      }

      _lastX = event.x;
      _lastY = event.y;
      _lastZ = event.z;
    });
  }

  // ── Game Logic ───────────────────────────────────────────
  void onShake() {
    try {
      onWobbleTrigger();
      shakeCount.value++;

      if (shakeCount.value >= shakesToBreak) {
        _breakEgg();
      } else if (shakeCount.value >= shakesToCrack) {
        eggState.value = EggState.cracked;
      }
    } catch (e) {
      debugPrint('onShake error: $e');
    }
  }

  void _breakEgg() {
    eggState.value = EggState.broken;
    onBurstTrigger();

    final allVocabs = QuestData.levels.expand((l) => l.vocabs).toList();
    allVocabs.shuffle();
    rewardVocab.value = allVocabs.first;
    rewardXp.value = 10 + _rand.nextInt(41);

    Future.delayed(const Duration(milliseconds: 700), () {
      showingReward.value = true;
      onRewardTrigger();
    });
  }

  Future<void> collectReward() async {
    try {
      final newEggsOpened = eggsOpened.value + 1;
      final isDone = newEggsOpened >= maxEggs;
      final xpToAdd = rewardXp.value;

      showingReward.value = false;
      totalXp.value += xpToAdd;
      eggsOpened.value = newEggsOpened;

      if (!isDone) {
        eggState.value = EggState.whole;
        shakeCount.value = 0;
        rewardVocab.value = null;
        rewardXp.value = 0;
      }

      debugPrint('incrementDailyAttempt: userId=$userId');
      await DatabaseHelper.instance.incrementDailyAttempt(
        userId,
        'crack_the_egg',
      );

      debugPrint('addXp: xp=$xpToAdd');
      await questProvider.addXp(xpToAdd);
      debugPrint('addXp done, currentXp=${questProvider.currentXp}');

      if (isDone) {
        sessionDone.value = true;
      }
    } catch (e) {
      debugPrint('collectReward error: $e');
    }
  }
}
