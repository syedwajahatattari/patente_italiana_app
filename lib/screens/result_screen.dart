import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/quiz_provider.dart';
import '../providers/language_provider.dart';
import '../models/exam_result.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../providers/subscription_provider.dart';
import 'exam_simulation_screen.dart';
import 'home_screen.dart';
import 'premium_paywall_screen.dart';
import 'error_review_screen.dart';
import '../widgets/ai_smart_explanation_sheet.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _animController.forward();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final lang = langProvider.langCode;
    final isUrdu = lang == 'ur';
    final ExamResult? result = quizProvider.lastExamResult;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Risultato Esame")),
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
            child: const Text("Torna alla Home"),
          ),
        ),
      );
    }

    final bool isPassed = result.isPassed;
    final int mins = result.timeSpentSeconds ~/ 60;
    final int secs = result.timeSpentSeconds % 60;
    final int avgSecondsPerQ = result.totalQuestions > 0 ? (result.timeSpentSeconds / result.totalQuestions).round() : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isUrdu ? "ایگزام کا نتیجہ" : (lang == 'en' ? "EXAM RESULT" : "ESITO SCHEDA ESAME"),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status Hero Banner with Animated Icon
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPassed
                      ? [AppColors.passedGreen, const Color(0xFF047857)]
                      : [AppColors.failedRed, const Color(0xFFB91C1C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: (isPassed ? AppColors.passedGreen : AppColors.failedRed).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPassed ? Icons.emoji_events_rounded : Icons.highlight_off_rounded,
                        size: 72,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isPassed
                        ? (isUrdu ? "پاس! مبارک ہو 🎉" : (lang == 'en' ? "PASSED! 🎉" : "PROMOSSO! 🎉"))
                        : (isUrdu ? "فیل ❌" : (lang == 'en' ? "BOCCIATO ❌" : "BOCCIATO ❌")),
                    style: GoogleFonts.outfit(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPassed
                        ? (isUrdu
                            ? "شاباش! آپ نے منسٹریل امتحان کے معیارات پاس کر لیے ہیں"
                            : (lang == 'en' ? "Great job! You passed ministerial standards" : "Ottimo lavoro! Rientri nel limite ministeriale (max 3 errori)"))
                        : (isUrdu
                            ? "امتحان میں 3 سے زیادہ غلطیاں ہو گئی ہیں۔ مشق جاری رکھیں!"
                            : (lang == 'en' ? "More than 3 errors in the exam. Keep practicing!" : "Hai fatto più di 3 errori. Non mollare, continua ad esercitarti!")),
                    style: isUrdu
                        ? AppTheme.urduStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.95))
                        : GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(color: Colors.white30, height: 26),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricStat(
                        isUrdu ? "غلطیاں" : (lang == 'en' ? "ERRORS" : "ERRORI"),
                        "${result.errors}",
                        "(Max 3)",
                      ),
                      _buildMetricStat(
                        isUrdu ? "صحیح" : (lang == 'en' ? "CORRECT" : "CORRETTE"),
                        "${result.correctAnswers}",
                        "/${result.totalQuestions}",
                      ),
                      _buildMetricStat(
                        isUrdu ? "وقت" : (lang == 'en' ? "TIME" : "TEMPO"),
                        "${mins}m ${secs}s",
                        "~${avgSecondsPerQ}s/q",
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Streak & Performance Pills
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("🔥", style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          isUrdu ? "${quizProvider.dailyStreak} دن کا سٹریک" : "Serie: ${quizProvider.dailyStreak} gg",
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.speed_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          isUrdu ? "~$avgSecondsPerQ سیکنڈ/سوال" : "~$avgSecondsPerQ s per quiz",
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // When Failed: Smart Prompt to Review Errors + PRO Upsell
            if (!isPassed) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade900.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.amber.shade700, width: 1.2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.assignment_late_rounded, color: Colors.amber.shade800, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isUrdu
                                ? "اپنی ${result.errors} غلطیوں کی اصلاح کریں"
                                : (lang == 'en' ? "Review your ${result.errors} errors" : "Ripassa i tuoi ${result.errors} errori"),
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            isUrdu
                                ? "غلط ہونے والے سوالات ایرر بینک میں محفوظ ہو چکے ہیں"
                                : "Tutti gli errori sono stati salvati nella tua Banca Errori per non ripeterli.",
                            style: isUrdu
                                ? AppTheme.urduStyle(fontSize: 12, color: Colors.grey.shade600)
                                : TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade800,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ErrorReviewScreen()));
                      },
                      child: Text(
                        isUrdu ? "ریویو" : "Ripassa",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // PRO upsell banner on failure if not premium
              if (!subProvider.isPremium) ...[
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumPaywallScreen()));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade900.withValues(alpha: 0.8), Colors.indigo.shade900.withValues(alpha: 0.8)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.purple.shade400, width: 1.2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_rounded, color: AppColors.accentGold, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isUrdu ? "💡 امتحانی خفیہ ٹوٹکے حاصل کریں" : "💡 Supera l'esame con i Trucchi PRO",
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                              ),
                              Text(
                                isUrdu
                                    ? "PRO ممبرز وہ الفاظ سیکھتے ہیں جو 99% ہمیشہ VERO یا FALSO ہوتے ہیں"
                                    : "Sblocca le parole magiche e il ripasso intelligente Zero Errori.",
                                style: isUrdu
                                    ? AppTheme.urduStyle(fontSize: 12, color: Colors.white70)
                                    : const TextStyle(fontSize: 11, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ],

            // Itemized Questions Review Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isUrdu ? "تمام 30 سوالات کا جائزہ" : (lang == 'en' ? "Question Review" : "Revisione Dettagliata Scheda"),
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "${result.totalQuestions} ${isUrdu ? 'سوالات' : (lang == 'en' ? 'Questions' : 'Quiz')}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Itemized Questions List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quizProvider.activeExamQuestions.length,
              itemBuilder: (context, index) {
                final q = quizProvider.activeExamQuestions[index];
                final userAns = result.userAnswers[q.id];
                final bool isCorrect = userAns != null && userAns == q.isTrue;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCorrect ? AppColors.passedGreen.withValues(alpha: 0.3) : AppColors.failedRed.withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (isCorrect ? AppColors.passedGreen : AppColors.failedRed).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCorrect ? Icons.check_rounded : Icons.close_rounded,
                              color: isCorrect ? AppColors.passedGreen : AppColors.failedRed,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${index + 1}. ${q.questionIt}",
                                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${isUrdu ? 'اصل جواب' : (lang == 'en' ? 'Correct' : 'Corretta')}: ${q.isTrue ? 'VERO' : 'FALSO'}  •  ${isUrdu ? 'آپ کا' : (lang == 'en' ? 'Yours' : 'Tua')}: ${userAns == null ? (isUrdu ? 'کوئی نہیں' : 'Nessuna') : (userAns ? 'VERO' : 'FALSO')}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isCorrect ? AppColors.passedGreen : AppColors.failedRed,
                                  ),
                                ),
                                if (lang != 'it') ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Directionality(
                                      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                                      child: Text(
                                        "${isUrdu ? '🇵🇰 ' : '🇬🇧 '}${lang == 'en' ? q.explanationEn : q.explanationUr}",
                                        style: isUrdu
                                            ? AppTheme.urduStyle(fontSize: 15, color: Colors.grey.shade800)
                                            : const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF6366F1),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () {
                                      AiSmartExplanationSheet.show(
                                        context,
                                        question: q,
                                        langCode: lang,
                                        userChoice: userAns,
                                      );
                                    },
                                    icon: const Icon(Icons.psychology_rounded, size: 15),
                                    label: Text(
                                      isUrdu ? "🤖 AI اسمارٹ تجزیہ" : "🤖 Analisi Smart AI",
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    ),
                    child: Text(isUrdu ? "ہوم ڈیش بورڈ" : (lang == 'en' ? "HOME" : "HOME")),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!subProvider.canTakeExam) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                            title: Row(
                              children: [
                                const Icon(Icons.lock_clock_rounded, color: Colors.amber, size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  isUrdu ? "روزانہ کی حد مکمل!" : "Limite Giornaliero!",
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            content: Text(
                              isUrdu
                                  ? "آپ آج کے 3 مفت امتحانی شیٹس مکمل کر چکے ہیں۔ بغیر کسی حد کے لامحدود امتحانات دینے کے لیے PRO ایکٹیویٹ کریں۔"
                                  : "Hai utilizzato le 3 schede gratuite per oggi. Passa a PRO per esercitarti senza limiti!",
                              style: isUrdu ? AppTheme.urduStyle(fontSize: 15, height: 1.5) : const TextStyle(fontSize: 14),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(isUrdu ? "بعد میں" : "Più Tardi"),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentGold,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumPaywallScreen()));
                                },
                                child: Text(
                                  isUrdu ? "PRO حاصل کریں 👑" : "Passa a PRO 👑",
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        );
                        return;
                      }

                      // Deduct attempt only upon completion in submitExam()
                      quizProvider.startMinisterialExam(subProvider: subProvider);
                      if (context.mounted) {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ExamSimulationScreen()));
                      }
                    },
                    child: Text(isUrdu ? "نئی شیٹ شروع" : (lang == 'en' ? "NEW EXAM" : "NUOVA SCHEDA")),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricStat(String label, String val, String sub) {
    return Column(
      children: [
        Text(val, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
        Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
        if (sub.isNotEmpty) Text(sub, style: const TextStyle(fontSize: 10, color: Colors.white60)),
      ],
    );
  }
}
