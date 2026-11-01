import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/quiz_provider.dart';
import '../providers/language_provider.dart';
import '../providers/subscription_provider.dart';
import '../models/question.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class TimeAttackScreen extends StatefulWidget {
  const TimeAttackScreen({super.key});

  @override
  State<TimeAttackScreen> createState() => _TimeAttackScreenState();
}

class _TimeAttackScreenState extends State<TimeAttackScreen> with SingleTickerProviderStateMixin {
  List<Question> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  int _combo = 0;
  int _maxCombo = 0;
  int _correctCount = 0;
  int _wrongCount = 0;
  int _secondsLeft = 60;
  Timer? _timer;
  bool _isGameOver = false;
  int _highScore = 0;
  bool _isNewHighScore = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    TTSService.init();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 0.9,
      upperBound: 1.1,
    );
    _initGame();
  }

  Future<void> _initGame() async {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    _highScore = await StorageService.getTimeAttackHighScore();
    _questions = List.from(quizProvider.allQuestions)..shuffle();
    if (_questions.isEmpty) {
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }
    if (mounted) {
      setState(() {});
    }
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        _endGame();
      }
    });
  }

  void _endGame() async {
    _timer?.cancel();
    setState(() {
      _secondsLeft = 0;
      _isGameOver = true;
    });

    final isNewHigh = await StorageService.saveTimeAttackScore(_score);
    await StorageService.incrementTimeAttackGamesToday();
    if (mounted) {
      setState(() {
        _isNewHighScore = isNewHigh;
        if (isNewHigh) _highScore = _score;
      });
      HapticFeedback.heavyImpact();
    }
  }

  void _answer(bool userChoice) {
    if (_isGameOver || _questions.isEmpty) return;
    final currentQ = _questions[_currentIndex % _questions.length];
    final bool isCorrect = userChoice == currentQ.isTrue;

    HapticFeedback.lightImpact();

    setState(() {
      if (isCorrect) {
        _correctCount++;
        _combo++;
        if (_combo > _maxCombo) _maxCombo = _combo;
        
        // Multiplier: 1x, 2x at 3+, 3x at 6+
        int multiplier = 1;
        if (_combo >= 6) {
          multiplier = 3;
        } else if (_combo >= 3) {
          multiplier = 2;
        }

        _score += (10 * multiplier);
        _secondsLeft = (_secondsLeft + 1).clamp(0, 99); // +1 second bonus
        _pulseController.forward(from: 0.9).then((_) => _pulseController.reverse());
      } else {
        _wrongCount++;
        _combo = 0;
        _secondsLeft = (_secondsLeft - 2).clamp(0, 99); // -2 seconds penalty
        if (_secondsLeft <= 0) {
          _endGame();
          return;
        }
      }

      _currentIndex++;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    TTSService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final lang = langProvider.langCode;
    final isUrdu = lang == 'ur';

    if (_questions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentQ = _questions[_currentIndex % _questions.length];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isUrdu ? "⚡ ٹائم اٹیک موڈ" : (lang == 'en' ? "⚡ Time Attack Challenge" : "⚡ Sfida Time Attack"),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentGold),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events_rounded, size: 16, color: AppColors.accentGold),
                const SizedBox(width: 4),
                Text(
                  "$_highScore",
                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.accentGold, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isGameOver
            ? _buildGameOverView(context, isUrdu, lang, subProvider)
            : Column(
                children: [
                  // Timer Bar & Score Header
                  _buildGameHeader(isUrdu, lang),

                  // Question Area
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_combo >= 3) ...[
                            ScaleTransition(
                              scale: _pulseController,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(color: Colors.orange.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3)),
                                  ],
                                ),
                                child: Text(
                                  "🔥 $_combo COMBO! (${_combo >= 6 ? '3X' : '2X'} PUNTI)",
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Main Question Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Quiz #${_currentIndex + 1}",
                                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
                                      onPressed: () => TTSService.speak(currentQ.questionIt, langCode: 'it'),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: "Ascolta in Italiano",
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (currentQ.imageUrl != null && currentQ.imageUrl!.isNotEmpty) ...[
                                  Container(
                                    height: 160,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: CachedNetworkImage(
                                            imageUrl: currentQ.imageUrl!,
                                            key: ValueKey("img_${currentQ.id}"),
                                            fit: BoxFit.contain,
                                            placeholder: (context, url) => const Center(
                                              child: SizedBox(
                                                width: 28,
                                                height: 28,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                            ),
                                            errorWidget: (context, url, error) => Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.broken_image_rounded, size: 36, color: Colors.grey.shade400),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Image not available',
                                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                Text(
                                  currentQ.questionIt,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, height: 1.4),
                                ),
                                if (lang != 'it') ...[
                                  const Divider(height: 24),
                                  Directionality(
                                    textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                                    child: Text(
                                      isUrdu
                                          ? currentQ.questionUr
                                          : (lang == 'roman'
                                              ? (currentQ.questionRomanUrdu.isNotEmpty ? currentQ.questionRomanUrdu : currentQ.questionUr)
                                              : currentQ.questionEn),
                                      textAlign: TextAlign.center,
                                      style: isUrdu
                                          ? AppTheme.urduStyle(fontSize: 17, color: AppColors.primaryDark, height: 1.6)
                                          : GoogleFonts.inter(fontSize: 14, color: AppColors.primaryDark, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Rapid Action Buttons (VERO / FALSO)
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 72,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.passedGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                elevation: 4,
                              ),
                              onPressed: () => _answer(true),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("VERO", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                                  Text(isUrdu ? "صحیح (+1s)" : "+1s bonus", style: const TextStyle(fontSize: 11, color: Colors.white70)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: SizedBox(
                            height: 72,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.failedRed,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                elevation: 4,
                              ),
                              onPressed: () => _answer(false),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("FALSO", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                                  Text(isUrdu ? "غلط (+1s)" : "+1s bonus", style: const TextStyle(fontSize: 11, color: Colors.white70)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildGameHeader(bool isUrdu, String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.12))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Timer Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _secondsLeft < 10 ? AppColors.failedRed.withValues(alpha: 0.18) : AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _secondsLeft < 10 ? AppColors.failedRed : AppColors.primary,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_rounded,
                  size: 20,
                  color: _secondsLeft < 10 ? AppColors.failedRed : AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  "$_secondsLeft s",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _secondsLeft < 10 ? AppColors.failedRed : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Live Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$_score",
                style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.accentGold),
              ),
              Text(
                isUrdu ? "اسکور" : "PUNTI",
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverView(
    BuildContext context,
    bool isUrdu,
    String lang,
    SubscriptionProvider subProvider,
  ) {
    final int total = _correctCount + _wrongCount;
    final int accuracy = total > 0 ? ((_correctCount / total) * 100).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isNewHighScore
                    ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                    : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  _isNewHighScore ? Icons.workspace_premium_rounded : Icons.timer_off_rounded,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  _isNewHighScore
                      ? (isUrdu ? "نیا ہائی اسکور! 🏆" : "NUOVO RECORD! 🏆")
                      : (isUrdu ? "وقت ختم! ⏱️" : "TEMPO SCADUTO! ⏱️"),
                  style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  "$_score Punti",
                  style: GoogleFonts.outfit(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const Divider(color: Colors.white24, height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol(isUrdu ? "صحیح" : "Corrette", "$_correctCount", Colors.white),
                    _buildStatCol(isUrdu ? "غلط" : "Errori", "$_wrongCount", Colors.white),
                    _buildStatCol(isUrdu ? "درستگی" : "Precisione", "$accuracy%", Colors.white),
                    _buildStatCol(isUrdu ? "میکس کومبو" : "Max Combo", "$_maxCombo x", Colors.white),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Play Again Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                setState(() {
                  _questions.shuffle();
                  _currentIndex = 0;
                  _score = 0;
                  _combo = 0;
                  _maxCombo = 0;
                  _correctCount = 0;
                  _wrongCount = 0;
                  _secondsLeft = 60;
                  _isGameOver = false;
                  _isNewHighScore = false;
                });
                _startTimer();
              },
              icon: const Icon(Icons.replay_rounded),
              label: Text(
                isUrdu ? "دوبارہ کھیلیں ⚡" : "GIOCA DI NUOVO ⚡",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),

          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(isUrdu ? "ہوم پر واپس جائیں" : "Torna alla Home"),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ],
    );
  }
}

