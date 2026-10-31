import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/question.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class AiSmartExplanationSheet extends StatefulWidget {
  final Question question;
  final String langCode;
  final bool? userChoice;

  const AiSmartExplanationSheet({
    super.key,
    required this.question,
    required this.langCode,
    this.userChoice,
  });

  static void show(
    BuildContext context, {
    required Question question,
    required String langCode,
    bool? userChoice,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AiSmartExplanationSheet(
        question: question,
        langCode: langCode,
        userChoice: userChoice,
      ),
    ).then((_) {
      // Stop speech when dismissed
      TTSService.stop();
    });
  }

  @override
  State<AiSmartExplanationSheet> createState() => _AiSmartExplanationSheetState();
}

class _AiSmartExplanationSheetState extends State<AiSmartExplanationSheet> {
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

  String _detectTrapKeyword(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('esclusivamente')) return 'esclusivamente (صرف اور صرف)';
    if (lower.contains('soltanto')) return 'soltanto (صرف)';
    if (lower.contains('in ogni caso')) return 'in ogni caso (ہر صورت میں)';
    if (lower.contains('mai')) return 'mai (کبھی نہیں)';
    if (lower.contains('obbligatoriamente')) return 'obbligatoriamente (لازمی طور پر)';
    if (lower.contains('qualsiasi')) return 'qualsiasi (کوئی بھی)';
    if (lower.contains('sempre')) return 'sempre (ہمیشہ)';
    if (lower.contains('tassativamente')) return 'tassativamente (سختی کے ساتھ)';
    return '';
  }

  Widget _buildAudioChip({
    required String id,
    required String text,
    required String langCode,
    required String label,
    required Color color,
  }) {
    return ValueListenableBuilder<String?>(
      valueListenable: TTSService.currentPlayingId,
      builder: (context, playingId, _) {
        final isPlaying = playingId == id;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              TTSService.toggleSpeak(id: id, text: text, langCode: langCode);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isPlaying ? color : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color,
                  width: isPlaying ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded,
                    size: 15,
                    color: isPlaying ? Colors.white : color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isPlaying ? "Stop" : label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isPlaying ? Colors.white : color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    final langCode = widget.langCode;
    final userChoice = widget.userChoice;
    final isUrdu = langCode == 'ur';
    final trap = _detectTrapKeyword(question.questionIt);
    final isCorrect = userChoice != null && userChoice == question.isTrue;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 25, offset: const Offset(0, -6)),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header with AI Icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isUrdu ? "🤖 اسمارٹ AI وضاحت و رہنمائی" : "🤖 Spiegazione Smart & Audio AI",
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isUrdu ? "اطالوی تھیوری امتحان پاس کرنے کا فارمولا" : "Analisi ministeriale dettagliata del quiz",
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Trap Keyword Alert (if found)
            if (trap.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade900.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade700, width: 1.2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isUrdu
                            ? "⚠️ ٹرپ لفظ کا پتہ چلا: \"$trap\" (اکثر FALSO ہوتا ہے!)"
                            : "⚠️ Parola Trabocchetto Rilevata: \"$trap\" (spesso indice di FALSO!)",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Correct Answer Tag
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (question.isTrue ? AppColors.passedGreen : AppColors.failedRed).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (question.isTrue ? AppColors.passedGreen : AppColors.failedRed).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    question.isTrue ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: question.isTrue ? AppColors.passedGreen : AppColors.failedRed,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUrdu
                              ? "سرکاری منسٹریل جواب: ${question.isTrue ? 'VERO (صحیح)' : 'FALSO (غلط)'}"
                              : "Risposta Ministeriale Ufficiale: ${question.isTrue ? 'VERO' : 'FALSO'}",
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: question.isTrue ? AppColors.passedGreen : AppColors.failedRed,
                          ),
                        ),
                        if (userChoice != null)
                          Text(
                            isCorrect
                                ? (isUrdu ? "✅ آپ نے درست جواب چنا تھا!" : "✅ La tua risposta era esatta!")
                                : (isUrdu ? "❌ آپ نے ${userChoice == true ? 'VERO' : 'FALSO'} کا غلط انتخاب کیا تھا۔" : "❌ Hai sbagliato scegliendo ${userChoice == true ? 'VERO' : 'FALSO'}."),
                            style: TextStyle(fontSize: 11, color: isCorrect ? AppColors.passedGreen : AppColors.failedRed),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Italian Highway Code Explanation Header + Audio Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Codice della Strada (Italiano):",
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                _buildAudioChip(
                  id: "${question.id}_exp_it",
                  text: question.explanationIt.isNotEmpty ? question.explanationIt : question.questionIt,
                  langCode: 'it',
                  label: "Ascolta IT 🇮🇹",
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
              ),
              child: Text(
                question.explanationIt.isNotEmpty ? question.explanationIt : "Verifica le norme di circolazione e la segnaletica associata.",
                style: GoogleFonts.outfit(fontSize: 13, height: 1.45),
              ),
            ),
            const SizedBox(height: 16),

            // Urdu Translation & Explanation Header + Audio Button
            if (langCode == 'ur' && question.explanationUr.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "اردو میں جامع وضاحت:",
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A)),
                  ),
                  _buildAudioChip(
                    id: "${question.id}_exp_ur",
                    text: question.explanationUr,
                    langCode: 'ur',
                    label: "اردو آواز 🇵🇰",
                    color: const Color(0xFF16A34A),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.2)),
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    question.explanationUr,
                    style: AppTheme.urduStyle(fontSize: 16, color: const Color(0xFF14532D), height: 1.7),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Roman Urdu Explanation Header + Audio Button
            if (langCode == 'roman' && (question.explanationRomanUrdu.isNotEmpty || question.explanationUr.isNotEmpty)) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Roman Urdu Wazahat:",
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFD97706)),
                  ),
                  _buildAudioChip(
                    id: "${question.id}_exp_roman",
                    text: question.explanationUr.isNotEmpty ? question.explanationUr : question.explanationIt,
                    langCode: 'ur',
                    label: "Urdu Voice 🇵🇰",
                    color: const Color(0xFFD97706),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.2)),
                ),
                child: Text(
                  question.explanationRomanUrdu.isNotEmpty ? question.explanationRomanUrdu : question.explanationUr,
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF78350F), height: 1.5, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // English Explanation Header + Audio Button
            if (langCode == 'en' && question.explanationEn.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "English Explanation:",
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0284C7)),
                  ),
                  _buildAudioChip(
                    id: "${question.id}_exp_en",
                    text: question.explanationEn,
                    langCode: 'en',
                    label: "Listen EN 🇬🇧",
                    color: const Color(0xFF0284C7),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.2)),
                ),
                child: Text(
                  question.explanationEn,
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0C4A6E), height: 1.45),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Pass Exam Pro Tip
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("💡", style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUrdu ? "امتحانی یاد دہانی (Trucco):" : "Consiglio d'Esame:",
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          isUrdu
                              ? "اگر سوال میں انتہائی الفاظ (جیسے صرف، ہر حال میں) ہوں تو 95% چانس ہے کہ وہ فالس ہے۔ سوال کو غور سے پڑھیں!"
                              : "Presta sempre attenzione alle generalizzazioni assolute. Spesso rendono la frase falsa.",
                          style: isUrdu
                              ? AppTheme.urduStyle(fontSize: 13, color: Colors.grey.shade600)
                              : TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
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
}
