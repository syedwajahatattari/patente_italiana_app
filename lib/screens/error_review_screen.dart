import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/quiz_provider.dart';
import '../providers/language_provider.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'topic_quiz_screen.dart';
import '../widgets/ai_smart_explanation_sheet.dart';

class ErrorReviewScreen extends StatefulWidget {
  const ErrorReviewScreen({super.key});

  @override
  State<ErrorReviewScreen> createState() => _ErrorReviewScreenState();
}

class _ErrorReviewScreenState extends State<ErrorReviewScreen> {
  @override
  void initState() {
    super.initState();
    TTSService.init();
  }

  @override
  void dispose() {
    TTSService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final lang = langProvider.langCode;
    final errorQuestions = quizProvider.errorBankQuestions;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${lang == 'ur' ? 'غلطیوں کی اصلاح' : (lang == 'en' ? 'Error Review' : 'Ripasso Errori')} (${errorQuestions.length})",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: errorQuestions.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 80, color: AppColors.passedGreen),
                    const SizedBox(height: 16),
                    Text(
                      lang == 'ur'
                          ? "کوئی غلطی محفوظ نہیں!"
                          : (lang == 'en' ? "No Saved Errors!" : "Nessun Errore Salvato!"),
                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lang == 'ur'
                          ? "بہت خوب! آپ کا کوئی غلط سوال محفوظ نہیں ہے۔ امتحان دینے کے بعد غلط ہونے والے سوالات یہاں جمع ہوں گے۔"
                          : (lang == 'en'
                              ? "Great! No wrong answers saved yet. Questions you get wrong in exams will appear here."
                              : "Ottimo! Nessuna domanda errata salvata. Le domande sbagliate appariranno qui."),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, height: 1.4),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Top Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade900.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade700),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700, size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${lang == 'ur' ? 'غلطیوں کا ذخیرہ' : (lang == 'en' ? 'Error Bank' : 'Banca Errori')} (${errorQuestions.length} ${lang == 'ur' ? 'سوالات' : (lang == 'en' ? 'questions' : 'domande')})",
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              lang == 'ur'
                                  ? "ان تمام سوالات کی دوبارہ مشق کریں"
                                  : (lang == 'en' ? "Practice all previously wrong questions" : "Ripassa tutte le domande sbagliate"),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800),
                        onPressed: () {
                          quizProvider.startErrorBankQuiz();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TopicQuizScreen(
                                topicTitle: lang == 'ur' ? "غلطیوں کی اصلاح" : (lang == 'en' ? "Error Review" : "Ripasso Errori"),
                              ),
                            ),
                          );
                        },
                        child: Text(lang == 'ur' ? "کوئز شروع" : (lang == 'en' ? "START QUIZ" : "AVVIA QUIZ")),
                      ),
                    ],
                  ),
                ),

                // Question List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: errorQuestions.length,
                    itemBuilder: (context, index) {
                      final q = errorQuestions[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.failedRed.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (q.imageUrl != null && q.imageUrl!.isNotEmpty) ...[
                              Container(
                                height: 130,
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: q.imageUrl!,
                                    key: ValueKey("img_${q.id}"),
                                    fit: BoxFit.contain,
                                    placeholder: (context, url) => const Center(
                                      child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                                    ),
                                    errorWidget: (context, url, error) => Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey.shade400),
                                  ),
                                ),
                              ),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    "${lang == 'ur' ? 'اصل جواب' : (lang == 'en' ? 'Correct answer' : 'Risposta corretta')}: ${q.isTrue ? (lang == 'ur' ? 'VERO (صحیح)' : (lang == 'en' ? 'VERO (True)' : 'VERO')) : (lang == 'ur' ? 'FALSO (غلط)' : (lang == 'en' ? 'FALSO (False)' : 'FALSO'))}",
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: q.isTrue ? AppColors.passedGreen : AppColors.failedRed),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
                                      onPressed: () => TTSService.speak(q.questionIt, langCode: 'it'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
                                      onPressed: () async {
                                        await StorageService.removeErrorQuestionId(q.id);
                                        quizProvider.removeErrorQuestion(q.id);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Text(q.questionIt, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
                            if (lang != 'it') ...[
                              const SizedBox(height: 6),
                              Directionality(
                                textDirection: lang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
                                child: Text(
                                  "${lang == 'ur' ? '🇵🇰 ' : '🇬🇧 '}${lang == 'en' ? q.questionEn : q.questionUr}",
                                  style: lang == 'ur'
                                      ? AppTheme.urduStyle(fontSize: 16, color: AppColors.primaryDark, fontWeight: FontWeight.w600)
                                      : GoogleFonts.inter(fontSize: 13, color: AppColors.primaryDark, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (q.isTrue ? AppColors.passedGreen : AppColors.failedRed).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: (q.isTrue ? AppColors.passedGreen : AppColors.failedRed).withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(q.explanationIt, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                                      ),
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () => TTSService.toggleSpeak(id: "${q.id}_rev_it", text: q.explanationIt, langCode: 'it'),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.volume_up_rounded, size: 13, color: AppColors.primary),
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
                                              lang == 'en' ? q.explanationEn : q.explanationUr,
                                              style: lang == 'ur'
                                                  ? AppTheme.urduStyle(fontSize: 15, color: AppColors.primaryDark)
                                                  : GoogleFonts.inter(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          onTap: () => TTSService.toggleSpeak(
                                            id: "${q.id}_rev_$lang",
                                            text: lang == 'en' ? q.explanationEn : q.explanationUr,
                                            langCode: lang,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: (lang == 'ur' ? const Color(0xFF16A34A) : const Color(0xFF0284C7)).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.volume_up_rounded,
                                                  size: 13,
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
                                  const SizedBox(height: 8),
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
                                        );
                                      },
                                      icon: const Icon(Icons.psychology_rounded, size: 16),
                                      label: Text(
                                        lang == 'ur' ? "🤖 AI تجزیہ اور حل" : "🤖 Spiegazione Approfondita AI",
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
