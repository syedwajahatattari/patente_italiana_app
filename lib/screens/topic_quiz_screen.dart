import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/quiz_provider.dart';
import '../providers/language_provider.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_smart_explanation_sheet.dart';

class TopicQuizScreen extends StatefulWidget {
  final String topicTitle;
  const TopicQuizScreen({super.key, required this.topicTitle});

  @override
  State<TopicQuizScreen> createState() => _TopicQuizScreenState();
}

class _TopicQuizScreenState extends State<TopicQuizScreen> {
  bool _showExplanation = false;
  bool _isFinishDialogShowing = false;

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

  String _getTranslation(question, String langCode) {
    if (langCode == 'en') return question.questionEn.isNotEmpty ? question.questionEn : question.questionIt;
    if (langCode == 'ur') return question.questionUr.isNotEmpty ? question.questionUr : question.questionIt;
    return question.questionIt;
  }

  String _getExplanation(question, String langCode) {
    if (langCode == 'en') return question.explanationEn.isNotEmpty ? question.explanationEn : question.explanationIt;
    if (langCode == 'ur') return question.explanationUr.isNotEmpty ? question.explanationUr : question.explanationIt;
    return question.explanationIt;
  }

  String _getCorrectAnswerText(bool isTrue, String langCode) {
    if (langCode == 'ur') return isTrue ? 'VERO (صحیح)' : 'FALSO (غلط)';
    if (langCode == 'en') return isTrue ? 'VERO (TRUE)' : 'FALSO (FALSE)';
    return isTrue ? 'VERO' : 'FALSO';
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final lang = langProvider.langCode;

    // Handle timer timeout for practice quiz
    if (quizProvider.isAutoSubmitted && !_isFinishDialogShowing) {
      _isFinishDialogShowing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        quizProvider.clearAutoSubmitted();
        _showFinishDialog(context, quizProvider, lang, isTimeout: true);
      });
    }

    if (quizProvider.activeExamQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.topicTitle)),
        body: const Center(child: Text("Nessuna domanda trovata")),
      );
    }

    final q = quizProvider.activeExamQuestions[quizProvider.currentQuestionIndex];
    final userChoice = quizProvider.userAnswers[q.id];

    final timerMins = (quizProvider.timerSecondsRemaining ~/ 60).toString().padLeft(2, '0');
    final timerSecs = (quizProvider.timerSecondsRemaining % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topicTitle, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    "$timerMins:$timerSecs",
                    style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => _showFinishDialog(context, quizProvider, lang),
            icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.passedGreen, size: 18),
            label: Text(
              lang == 'ur' ? "مکمل" : (lang == 'en' ? "Finish" : "Termina"),
              style: const TextStyle(color: AppColors.passedGreen, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: (quizProvider.currentQuestionIndex + 1) / quizProvider.activeExamQuestions.length,
                color: AppColors.primary,
                backgroundColor: AppColors.primary.withOpacity(0.2),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Domanda ${quizProvider.currentQuestionIndex + 1} / ${quizProvider.activeExamQuestions.length}",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
                    onPressed: () => TTSService.speak(q.questionIt, langCode: 'it'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Question Card
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (q.imageUrl != null && q.imageUrl!.isNotEmpty) ...[
                        Container(
                          height: 180,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey.withOpacity(0.2)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Center(
                                  child: InteractiveViewer(
                                    minScale: 1.0,
                                    maxScale: 3.5,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: CachedNetworkImage(
                                        imageUrl: q.imageUrl!,
                                        key: ValueKey("img_${q.id}"),
                                        fit: BoxFit.contain,
                                        placeholder: (context, url) => const Center(
                                          child: SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 2)),
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
                                    color: Colors.black.withOpacity(0.55),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        lang == 'ur' ? 'زوم کریں' : 'Pinch to zoom',
                                        style: lang == 'ur'
                                            ? AppTheme.urduStyle(fontSize: 11, color: Colors.white)
                                            : const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              q.questionIt,
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            // Show translation only if not Italian-only
                            if (lang != 'it') ...[
                              const Divider(height: 24),
                              Directionality(
                                textDirection: lang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
                                child: Text(
                                  "${lang == 'ur' ? '🇵🇰 ' : '🇬🇧 '}${_getTranslation(q, lang)}",
                                  style: lang == 'ur'
                                      ? AppTheme.urduStyle(fontSize: 18, color: AppColors.primaryDark, fontWeight: FontWeight.w600)
                                      : GoogleFonts.inter(fontSize: 14, color: AppColors.primaryDark, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                            if (userChoice != null || _showExplanation) ...[
                              const SizedBox(height: 20),
                              Builder(
                                builder: (context) {
                                  final bool isUserCorrect = userChoice == q.isTrue;
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: (userChoice == null ? (q.isTrue ? AppColors.passedGreen : AppColors.failedRed) : (isUserCorrect ? AppColors.passedGreen : AppColors.failedRed)).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: userChoice == null ? (q.isTrue ? AppColors.passedGreen : AppColors.failedRed) : (isUserCorrect ? AppColors.passedGreen : AppColors.failedRed), width: 1.5),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (userChoice != null) ...[
                                          Row(
                                            children: [
                                              Icon(
                                                isUserCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                                color: isUserCorrect ? AppColors.passedGreen : AppColors.failedRed,
                                                size: 24,
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  isUserCorrect
                                                      ? (lang == 'ur' ? "ESATTO! ✅ آپ کا جواب صحیح ہے" : (lang == 'en' ? "CORRECT! ✅" : "ESATTO! ✅"))
                                                      : (lang == 'ur' ? "SBAGLIATO! ❌ آپ کا جواب غلط ہے" : (lang == 'en' ? "WRONG! ❌" : "SBAGLIATO! ❌")),
                                                  style: lang == 'ur'
                                                      ? AppTheme.urduStyle(fontSize: 17, fontWeight: FontWeight.bold, color: isUserCorrect ? AppColors.passedGreen : AppColors.failedRed)
                                                      : GoogleFonts.outfit(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                          color: isUserCorrect ? AppColors.passedGreen : AppColors.failedRed,
                                                        ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                        Text(
                                          "${lang == 'ur' ? 'اصل جواب' : (lang == 'en' ? 'Correct answer' : 'Risposta corretta')}: ${_getCorrectAnswerText(q.isTrue, lang)}",
                                          style: lang == 'ur'
                                              ? AppTheme.urduStyle(fontSize: 15, fontWeight: FontWeight.bold)
                                              : GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                        if (userChoice != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            "${lang == 'ur' ? 'آپ کا جواب' : (lang == 'en' ? 'Your answer' : 'Tua risposta')}: ${_getCorrectAnswerText(userChoice, lang)}",
                                            style: lang == 'ur'
                                                ? AppTheme.urduStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isUserCorrect ? AppColors.passedGreen : AppColors.failedRed)
                                                : TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: isUserCorrect ? AppColors.passedGreen : AppColors.failedRed,
                                                  ),
                                          ),
                                        ],
                                        const Divider(height: 16),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(q.explanationIt, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                                            ),
                                            const SizedBox(width: 6),
                                            InkWell(
                                              onTap: () => TTSService.toggleSpeak(id: "${q.id}_exp_it", text: q.explanationIt, langCode: 'it'),
                                              borderRadius: BorderRadius.circular(12),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.volume_up_rounded, size: 14, color: AppColors.primary),
                                                    SizedBox(width: 2),
                                                    Text("IT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (lang != 'it') ...[
                                          const SizedBox(height: 6),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Directionality(
                                                  textDirection: lang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
                                                  child: Text(
                                                    _getExplanation(q, lang),
                                                    style: lang == 'ur'
                                                        ? AppTheme.urduStyle(fontSize: 16, color: AppColors.primaryDark)
                                                        : GoogleFonts.inter(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w500),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              InkWell(
                                                onTap: () => TTSService.toggleSpeak(
                                                  id: "${q.id}_exp_$lang",
                                                  text: _getExplanation(q, lang),
                                                  langCode: lang,
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: (lang == 'ur' ? const Color(0xFF16A34A) : const Color(0xFF0284C7)).withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.volume_up_rounded,
                                                        size: 14,
                                                        color: lang == 'ur' ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
                                                      ),
                                                      const SizedBox(width: 2),
                                                      Text(
                                                        lang == 'ur' ? "اردو" : "EN",
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          color: lang == 'ur' ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF6366F1),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            onPressed: () {
                                              AiSmartExplanationSheet.show(
                                                context,
                                                question: q,
                                                langCode: lang,
                                                userChoice: userChoice,
                                              );
                                            },
                                            icon: const Icon(Icons.psychology_rounded, size: 18),
                                            label: Text(
                                              lang == 'ur' ? "🤖 AI اسمارٹ تجزیہ و امتحانی فارمولا" : "🤖 Spiegazione Approfondita AI",
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // True False Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: userChoice == true ? AppColors.passedGreen : Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      onPressed: () {
                        quizProvider.answerCurrentQuestion(true);
                        setState(() => _showExplanation = true);
                      },
                      child: Text(
                        lang == 'ur' ? "VERO (صحیح)" : (lang == 'en' ? "VERO (True)" : "VERO"),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: userChoice == false ? AppColors.failedRed : Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      onPressed: () {
                        quizProvider.answerCurrentQuestion(false);
                        setState(() => _showExplanation = true);
                      },
                      child: Text(
                        lang == 'ur' ? "FALSO (غلط)" : (lang == 'en' ? "FALSO (False)" : "FALSO"),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Nav Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: quizProvider.currentQuestionIndex > 0
                        ? () {
                            quizProvider.previousQuestion();
                            setState(() => _showExplanation = false);
                          }
                        : null,
                    icon: const Icon(Icons.arrow_back),
                    label: Text(lang == 'ur' ? "پچھلا" : (lang == 'en' ? "Previous" : "Indietro")),
                  ),
                  if (quizProvider.currentQuestionIndex < quizProvider.activeExamQuestions.length - 1)
                    TextButton.icon(
                      onPressed: () {
                        quizProvider.nextQuestion();
                        setState(() => _showExplanation = false);
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(lang == 'ur' ? "اگلا" : (lang == 'en' ? "Next" : "Avanti")),
                    )
                  else
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.passedGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onPressed: () => _showFinishDialog(context, quizProvider, lang),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        lang == 'ur' ? "مکمل کریں" : (lang == 'en' ? "Finish" : "Termina"),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFinishDialog(BuildContext parentContext, QuizProvider quizProvider, String lang, {bool isTimeout = false}) {
    final isUrdu = lang == 'ur';
    int correct = 0;
    int wrong = 0;
    for (var q in quizProvider.activeExamQuestions) {
      final ans = quizProvider.userAnswers[q.id];
      if (ans != null) {
        if (ans == q.isTrue) {
          correct++;
        } else {
          wrong++;
        }
      }
    }
    final answered = quizProvider.userAnswers.length;
    final total = quizProvider.activeExamQuestions.length;

    showDialog(
      context: parentContext,
      barrierDismissible: !isTimeout,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isTimeout
              ? (isUrdu ? "⏰ وقت ختم ہو گیا!" : (lang == 'en' ? "⏰ Time Expired!" : "⏰ Tempo Scaduto!"))
              : (isUrdu ? "🎯 پریکٹس کا نتیجہ" : (lang == 'en' ? "🎯 Practice Summary" : "🎯 Riepilogo Esercitazione")),
          style: isUrdu
              ? AppTheme.urduStyle(fontSize: 20, fontWeight: FontWeight.bold)
              : GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isTimeout) ...[
              Text(
                isUrdu
                    ? "پریکٹس کا وقت ختم ہو چکا ہے۔ آپ کے جوابات محفوظ کر لیے گئے ہیں۔"
                    : (lang == 'en'
                        ? "Practice time has expired. Your progress has been saved."
                        : "Il tempo per questa esercitazione è scaduto. I tuoi progressi sono stati salvati."),
                style: isUrdu
                    ? AppTheme.urduStyle(fontSize: 14, color: AppColors.failedRed)
                    : const TextStyle(fontSize: 13, color: AppColors.failedRed, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              isUrdu
                  ? "کل سوالات: $total | حل کیے: $answered\nدرست: $correct | غلطیاں: $wrong"
                  : (lang == 'en'
                      ? "Total: $total | Answered: $answered\nCorrect: $correct | Errors: $wrong"
                      : "Domande totali: $total | Risposte: $answered\nCorrette: $correct | Errori: $wrong"),
              style: isUrdu ? AppTheme.urduStyle(fontSize: 15, height: 1.6) : const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
        actions: [
          if (!isTimeout)
            TextButton(
              onPressed: () {
                _isFinishDialogShowing = false;
                Navigator.pop(ctx);
              },
              child: Text(isUrdu ? "جاری رکھیں" : (lang == 'en' ? "Continue" : "Continua")),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              _isFinishDialogShowing = false;
              Navigator.pop(ctx);
              await quizProvider.submitPractice();
              if (parentContext.mounted) {
                Navigator.pop(parentContext);
              }
            },
            child: Text(
              isTimeout
                  ? (isUrdu ? "ٹھیک ہے / بند کریں" : (lang == 'en' ? "OK / Exit" : "OK / Esci"))
                  : (isUrdu ? "مکمل کریں اور نکلیں" : (lang == 'en' ? "Finish & Exit" : "Termina ed Esci")),
            ),
          ),
        ],
      ),
    ).then((_) {
      _isFinishDialogShowing = false;
    });
  }
}
