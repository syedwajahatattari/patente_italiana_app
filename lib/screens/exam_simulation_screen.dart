import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/quiz_provider.dart';
import '../providers/language_provider.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'result_screen.dart';

class ExamSimulationScreen extends StatefulWidget {
  const ExamSimulationScreen({super.key});

  @override
  State<ExamSimulationScreen> createState() => _ExamSimulationScreenState();
}

class _ExamSimulationScreenState extends State<ExamSimulationScreen> {
  bool _showTranslation = true;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    TTSService.init();
  }

  @override
  void dispose() {
    TTSService.stop();
    // Cancel the timer directly — safe to call during dispose
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    quizProvider.stopTimer();
    super.dispose();
  }

  String _formatTimer(int seconds) {
    final int mins = seconds ~/ 60;
    final int secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  /// Get question text in user's selected language
  String _getTranslation(question, String langCode) {
    if (langCode == 'en') return question.questionEn;
    if (langCode == 'ur') return question.questionUr;
    return ''; // Italian-only mode
  }

  /// Get explanation text in user's selected language
  String _getExplanation(question, String langCode) {
    if (langCode == 'en') return question.explanationEn;
    if (langCode == 'ur') return question.explanationUr;
    return ''; // Italian-only mode
  }

  /// Get language flag + label
  String _getTranslationLabel(String langCode) {
    if (langCode == 'en') return "🇬🇧 English Translation";
    if (langCode == 'ur') return "🇵🇰 اردو ترجمہ (جمیل نوری نستعلیق)";
    return "";
  }

  /// Get "correct answer" text
  String _getCorrectAnswerText(bool isTrue, String langCode) {
    if (langCode == 'ur') return isTrue ? 'VERO (صحیح)' : 'FALSO (غلط)';
    if (langCode == 'en') return isTrue ? 'VERO (TRUE)' : 'FALSO (FALSE)';
    return isTrue ? 'VERO' : 'FALSO';
  }

  /// Get user answer result text
  String _getUserResultText(bool isCorrect, bool? userChoice, String langCode) {
    if (langCode == 'ur') {
      if (isCorrect) return "✅ آپ کا انتخاب بالکل درست (ESATTO) ہے!";
      return "❌ آپ کا جواب غلط (SBAGLIATO) ہے! آپ نے ${userChoice == true ? 'VERO' : 'FALSO'} منتخب کیا۔";
    }
    if (langCode == 'en') {
      if (isCorrect) return "✅ Your answer is correct (ESATTO)!";
      return "❌ Your answer is wrong (SBAGLIATO)! You selected ${userChoice == true ? 'VERO' : 'FALSO'}.";
    }
    if (isCorrect) return "✅ ESATTO!";
    return "❌ SBAGLIATO! Hai selezionato ${userChoice == true ? 'VERO' : 'FALSO'}.";
  }

  void _confirmExitExam(BuildContext context, String lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          lang == 'ur' ? "امتحان سے باہر نکلیں؟" : (lang == 'en' ? "Exit Exam?" : "Abbandonare l'esame?"),
          style: lang == 'ur'
              ? AppTheme.urduStyle(fontSize: 20, fontWeight: FontWeight.bold)
              : GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          lang == 'ur'
              ? "اگر آپ اب باہر نکلتے ہیں تو موجودہ امتحان کی تمام پیش رفت ضائع ہو جائے گی۔ کیا آپ واقعی منسوخ کرنا چاہتے ہیں؟"
              : (lang == 'en'
                  ? "If you exit now, your current exam progress will be lost. Are you sure?"
                  : "Se esci adesso, tutti i progressi della scheda corrente andranno persi. Sei sicuro?"),
          style: lang == 'ur' ? AppTheme.urduStyle(fontSize: 16) : null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lang == 'ur' ? "جاری رکھیں" : "Continua"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.failedRed),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _allowPop = true;
              });
              Navigator.pop(context);
            },
            child: Text(lang == 'ur' ? "باہر نکلیں" : "Esci"),
          ),
        ],
      ),
    );
  }

  void _showAllQuestionsModal(BuildContext context, QuizProvider quizProvider, String lang) {
    final isUrdu = lang == 'ur';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isUrdu ? "تمام 30 سوالات کا جائزہ" : "Tutte le 30 Domande",
                  style: isUrdu
                      ? AppTheme.urduStyle(fontSize: 20, fontWeight: FontWeight.bold)
                      : GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(AppColors.primary, isUrdu ? "حل شدہ" : "Risposta"),
                const SizedBox(width: 14),
                _buildLegendItem(AppColors.accentGold, isUrdu ? "نشان زدہ" : "Segnata"),
                const SizedBox(width: 14),
                _buildLegendItem(Colors.grey.shade400, isUrdu ? "باقی" : "Da fare"),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.0,
                ),
                itemCount: quizProvider.activeExamQuestions.length,
                itemBuilder: (context, idx) {
                  final q = quizProvider.activeExamQuestions[idx];
                  final answered = quizProvider.userAnswers.containsKey(q.id);
                  final flagged = quizProvider.flaggedQuestionIds.contains(q.id);
                  final isCurrent = quizProvider.currentQuestionIndex == idx;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(ctx);
                      quizProvider.goToQuestion(idx);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.primary
                            : (answered ? AppColors.primary.withOpacity(0.25) : Colors.transparent),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: flagged
                              ? AppColors.accentGold
                              : (isCurrent ? AppColors.primary : Colors.grey.withOpacity(0.35)),
                          width: flagged ? 2.5 : 1.2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "${idx + 1}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isCurrent
                                ? Colors.white
                                : (answered ? AppColors.primaryDark : Colors.grey.shade500),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final lang = langProvider.langCode;
    final isUrdu = lang == 'ur';

    if (quizProvider.activeExamQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Simulazione Esame")),
        body: const Center(child: Text("Nessuna domanda disponibile")),
      );
    }

    final currentQuestion = quizProvider.activeExamQuestions[quizProvider.currentQuestionIndex];
    final userChoice = quizProvider.userAnswers[currentQuestion.id];
    final isFlagged = quizProvider.flaggedQuestionIds.contains(currentQuestion.id);

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmExitExam(context, lang);
      },
      child: Scaffold(
        appBar: AppBar(
          title: GestureDetector(
            onTap: () => _showAllQuestionsModal(context, quizProvider, lang),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "SCHEDA ESAME MINISTERIALE",
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.grid_view_rounded, size: 14, color: AppColors.primary),
                  ],
                ),
                Text(
                  "Domanda ${quizProvider.currentQuestionIndex + 1} di ${quizProvider.activeExamQuestions.length}",
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            // Timer Widget
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: quizProvider.timerSecondsRemaining < 300
                    ? AppColors.failedRed.withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: quizProvider.timerSecondsRemaining < 300 ? AppColors.failedRed : AppColors.primary,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: quizProvider.timerSecondsRemaining < 300 ? AppColors.failedRed : AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimer(quizProvider.timerSecondsRemaining),
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: quizProvider.timerSecondsRemaining < 300 ? AppColors.failedRed : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Question Progress Grid Selector Strip
              _buildQuestionIndexBar(context, quizProvider, lang),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image container with Pinch-to-Zoom
                      if (currentQuestion.imageUrl != null && currentQuestion.imageUrl!.isNotEmpty) ...[
                        Container(
                          height: 200,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.withOpacity(0.25)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Center(
                                  child: InteractiveViewer(
                                    minScale: 1.0,
                                    maxScale: 4.0,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: CachedNetworkImage(
                                        imageUrl: currentQuestion.imageUrl!,
                                        key: ValueKey("img_${currentQuestion.id}"),
                                        fit: BoxFit.contain,
                                        placeholder: (context, url) => const Center(
                                          child: SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2)),
                                        ),
                                        errorWidget: (context, url, error) => Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey.shade400),
                                              const SizedBox(height: 4),
                                              Text('Image not available', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.pinch_rounded, color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text("Pinch to zoom", style: TextStyle(color: Colors.white, fontSize: 10)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Question Card
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text("🇮🇹 ITALIANO", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
                                      onPressed: () => TTSService.speak(currentQuestion.questionIt, langCode: 'it'),
                                      tooltip: "Ascolta in Italiano",
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isFlagged ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                        color: isFlagged ? AppColors.accentGold : Colors.grey,
                                      ),
                                      onPressed: () {
                                        HapticFeedback.selectionClick();
                                        quizProvider.toggleFlagCurrentQuestion();
                                      },
                                      tooltip: "Segna domanda",
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              currentQuestion.questionIt,
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, height: 1.35),
                            ),

                            // Translation Section (Urdu using Jameel Noori Nastaleeq & RTL)
                            if (lang != 'it') ...[
                              const Divider(height: 28),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _getTranslationLabel(lang),
                                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                                  ),
                                  Switch(
                                    value: _showTranslation,
                                    onChanged: (val) => setState(() => _showTranslation = val),
                                    activeColor: AppColors.primary,
                                  ),
                                ],
                              ),
                              if (_showTranslation) ...[
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Directionality(
                                    textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                                    child: Text(
                                      _getTranslation(currentQuestion, lang),
                                      style: isUrdu
                                          ? AppTheme.urduStyle(fontSize: 19, color: AppColors.primaryDark, height: 1.8)
                                          : GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.primaryDark),
                                    ),
                                  ),
                                ),
                              ],
                            ],

                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // VERO & FALSO Action Buttons with Haptic Feedback
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                quizProvider.answerCurrentQuestion(true);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                decoration: BoxDecoration(
                                  color: userChoice == true ? AppColors.primary : Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: userChoice == true ? AppColors.primary : Colors.grey.withOpacity(0.3),
                                    width: 2,
                                  ),
                                  boxShadow: userChoice == true
                                      ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
                                      : [],
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: userChoice == true ? Colors.white : AppColors.primary, size: 36),
                                    const SizedBox(height: 6),
                                    Text(
                                      "VERO",
                                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: userChoice == true ? Colors.white : AppColors.primary),
                                    ),
                                    Text(
                                      isUrdu ? "صحیح" : (lang == 'en' ? "True" : ""),
                                      style: isUrdu
                                          ? AppTheme.urduStyle(fontSize: 16, color: userChoice == true ? Colors.white70 : Colors.grey)
                                          : TextStyle(fontSize: 12, color: userChoice == true ? Colors.white70 : Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                quizProvider.answerCurrentQuestion(false);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                decoration: BoxDecoration(
                                  color: userChoice == false ? AppColors.primary : Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: userChoice == false ? AppColors.primary : Colors.grey.withOpacity(0.3),
                                    width: 2,
                                  ),
                                  boxShadow: userChoice == false
                                      ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
                                      : [],
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.cancel_rounded, color: userChoice == false ? Colors.white : AppColors.primary, size: 36),
                                    const SizedBox(height: 6),
                                    Text(
                                      "FALSO",
                                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: userChoice == false ? Colors.white : AppColors.primary),
                                    ),
                                    Text(
                                      isUrdu ? "غلط" : (lang == 'en' ? "False" : ""),
                                      style: isUrdu
                                          ? AppTheme.urduStyle(fontSize: 16, color: userChoice == false ? Colors.white70 : Colors.grey)
                                          : TextStyle(fontSize: 12, color: userChoice == false ? Colors.white70 : Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Navigation Control Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: quizProvider.currentQuestionIndex > 0
                          ? () {
                              HapticFeedback.selectionClick();
                              quizProvider.previousQuestion();
                            }
                          : null,
                      icon: const Icon(Icons.arrow_back_ios_rounded),
                      tooltip: "Precedente",
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.italianRed),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _confirmSubmitExam(context, quizProvider, lang);
                      },
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        isUrdu
                            ? "ایگزام جمع کروائیں"
                            : (lang == 'en' ? "SUBMIT EXAM" : "CONSEGNA ESAME"),
                        style: isUrdu ? AppTheme.urduStyle(fontSize: 17, color: Colors.white) : null,
                      ),
                    ),
                    IconButton(
                      onPressed: quizProvider.currentQuestionIndex < quizProvider.activeExamQuestions.length - 1
                          ? () {
                              HapticFeedback.selectionClick();
                              quizProvider.nextQuestion();
                            }
                          : null,
                      icon: const Icon(Icons.arrow_forward_ios_rounded),
                      tooltip: "Successivo",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionIndexBar(BuildContext context, QuizProvider quizProvider, String lang) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.black.withOpacity(0.04),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.grid_view_rounded, size: 20, color: AppColors.primary),
            onPressed: () => _showAllQuestionsModal(context, quizProvider, lang),
            tooltip: "Vedi tutte le domande",
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: quizProvider.activeExamQuestions.length,
              itemBuilder: (context, index) {
                final q = quizProvider.activeExamQuestions[index];
                final isCurrent = index == quizProvider.currentQuestionIndex;
                final userAns = quizProvider.userAnswers[q.id];
                final isFlagged = quizProvider.flaggedQuestionIds.contains(q.id);

                Color bgColor = Colors.transparent;
                if (userAns != null) {
                  bgColor = AppColors.primary.withOpacity(0.3);
                }

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    quizProvider.goToQuestion(index);
                  },
                  child: Container(
                    width: 38,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.primary : bgColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isFlagged ? AppColors.accentGold : (isCurrent ? AppColors.primary : Colors.grey.withOpacity(0.3)),
                        width: isFlagged ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "${index + 1}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCurrent ? Colors.white : (userAns != null ? AppColors.primaryDark : Colors.grey),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSubmitExam(BuildContext parentContext, QuizProvider quizProvider, String lang) {
    final unanswered = quizProvider.activeExamQuestions.length - quizProvider.userAnswers.length;
    final isUrdu = lang == 'ur';

    showDialog(
      context: parentContext,
      builder: (ctx) => AlertDialog(
        title: Text(
          isUrdu ? "کیا آپ ایگزام جمع کروانا چاہتے ہیں؟" : (lang == 'en' ? "Confirm Submission?" : "Confermi la consegna?"),
          style: isUrdu
              ? AppTheme.urduStyle(fontSize: 20, fontWeight: FontWeight.bold)
              : GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          unanswered > 0
              ? (isUrdu
                  ? "ابھی $unanswered سوالات کا جواب نہیں دیا۔ کیا آپ واقعی جمع کروانا چاہتے ہیں؟"
                  : (lang == 'en'
                      ? "You still have $unanswered unanswered questions. Are you sure?"
                      : "Hai ancora $unanswered domande senza risposta. Sei sicuro di voler consegnare la scheda?"))
              : (isUrdu
                  ? "آپ نے تمام سوالات کے جوابات دے دیے ہیں۔ ایگزام جمع کروائیں؟"
                  : (lang == 'en'
                      ? "You answered all questions. Confirm submission?"
                      : "Hai risposto a tutte le domande. Confermi la consegna dell'esame?")),
          style: isUrdu ? AppTheme.urduStyle(fontSize: 16) : null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isUrdu ? "واپس جائیں" : (lang == 'en' ? "Continue" : "Continua")),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.passedGreen),
            onPressed: () async {
              Navigator.pop(ctx);
              await quizProvider.submitExam();
              if (parentContext.mounted) {
                Navigator.pushReplacement(parentContext, MaterialPageRoute(builder: (_) => const ResultScreen()));
              }
            },
            child: Text(isUrdu ? "ابھی جمع کروائیں" : (lang == 'en' ? "Submit Now" : "Consegna Ora")),
          ),
        ],
      ),
    );
  }
}
