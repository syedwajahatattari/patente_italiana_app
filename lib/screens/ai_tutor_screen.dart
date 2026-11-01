import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/language_provider.dart';
import '../providers/subscription_provider.dart';
import '../screens/premium_paywall_screen.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../services/openrouter_service.dart';

class AiTutorMessage {
  final String id;
  final bool isUser;
  final String text;
  final String? ruleIt;
  final String? explanationUr;
  final String? examTip;
  final bool isOfflineRule;
  final String? errorNotice;
  final DateTime timestamp;

  AiTutorMessage({
    required this.id,
    required this.isUser,
    required this.text,
    this.ruleIt,
    this.explanationUr,
    this.examTip,
    this.isOfflineRule = false,
    this.errorNotice,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AiTutorScreen extends StatefulWidget {
  final String? initialQuery;

  /// Optional completer to delay quota loading for deterministic race testing
  @visibleForTesting
  static Completer<void>? testQuotaLoadBlocker;

  const AiTutorScreen({super.key, this.initialQuery});

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _quotaLoaded = false;
  int _queriesAskedToday = 0;
  static const int _freeDailyLimit = 3;
  static const String _prefKeyTutorCount = 'key_ai_tutor_count';
  static const String _prefKeyTutorDate = 'key_ai_tutor_date';

  final List<AiTutorMessage> _messages = [];

  final List<String> _suggestedPrompts = [
    "🚗 Regola generale della precedenza",
    "🛑 STOP vs DARE PRECEDENZA",
    "🏎️ Limiti velocità Neopatentati",
    "📏 Come si calcola la Distanza di Sicurezza?",
    "⚠️ Parole trabocchetto nei quiz",
    "🚦 Semaforo giallo: cosa fare?",
  ];

  @override
  void initState() {
    super.initState();
    TTSService.init();
    _loadDailyQuota();
    _initWelcomeMessage();

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!_quotaLoaded) {
          await _loadDailyQuota();
        }
        if (mounted) {
          _handleSend(widget.initialQuery!);
        }
      });
    }
  }

  @override
  void dispose() {
    TTSService.stop();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDailyQuota() async {
    if (AiTutorScreen.testQuotaLoadBlocker != null) {
      await AiTutorScreen.testQuotaLoadBlocker!.future;
    }
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString(_prefKeyTutorDate) ?? '';
    if (savedDate == today) {
      final count = prefs.getInt(_prefKeyTutorCount) ?? 0;
      if (mounted) {
        setState(() {
          _queriesAskedToday = count;
          _quotaLoaded = true;
        });
      }
    } else {
      await prefs.setString(_prefKeyTutorDate, today);
      await prefs.setInt(_prefKeyTutorCount, 0);
      if (mounted) {
        setState(() {
          _queriesAskedToday = 0;
          _quotaLoaded = true;
        });
      }
    }
  }

  Future<void> _persistDailyQuota() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString(_prefKeyTutorDate, today);
    await prefs.setInt(_prefKeyTutorCount, _queriesAskedToday);
  }

  void _initWelcomeMessage() {
    _messages.add(
      AiTutorMessage(
        id: "msg_welcome",
        isUser: false,
        text: "Ciao! Sono il tuo Istruttore AI per la Patente B 🚗. Chiedimi qualsiasi dubbio su segnali, incroci o regole del Codice della Strada in Italiano o Urdu!",
        ruleIt: "Sono qui per prepararti al meglio per l'esame ministeriale della Motorizzazione.",
        explanationUr: "سلام! میں آپ کا AI ڈرائیونگ انسٹرکٹر ہوں۔ اٹلی کے ڈرائیونگ لائسنس کے کسی بھی اشارے، چوراہے یا قانون کے متعلق مجھ سے اردو یا اطالوی میں سوال پوچھیں!",
        examTip: "امتحان میں جلدی مت کریں، ٹرپ الفاظ (Sempre, Mai, Esclusivamente) کا خاص دھیان رکھیں۔",
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend(String input) async {
    if (!_quotaLoaded) return;
    final query = input.trim();
    if (query.isEmpty) return;

    final subProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    if (!subProvider.isPremium && _queriesAskedToday >= _freeDailyLimit) {
      _showUpgradeDialog();
      return;
    }

    setState(() {
      _messages.add(
        AiTutorMessage(
          id: "usr_${DateTime.now().millisecondsSinceEpoch}",
          isUser: true,
          text: query,
        ),
      );
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Setup prompt for driving license context
    const String prompt = '''
Sei un istruttore esperto di teoria della patente B italiana.
Rispondi in modo conciso ma molto chiaro e accurato (massimo 4-5 frasi).
Fornisci la regola ufficiale del Codice della Strada se pertinente.
Dopo la spiegazione in italiano, fornisci OBBLIGATORIAMENTE una breve traduzione/spiegazione in lingua URDU (con alfabeto urdu) per aiutare gli studenti pachistani.
Formatta la risposta esattamente così:
ITA: [La tua risposta in italiano]
URDU: [La tua spiegazione in urdu]
''';

    try {
      if (!OpenRouterService.isConfigured) {
        // AI is not configured. Provide offline rule response without returning missing-key fake chat text.
        // Failed / key-missing attempts must NOT burn quota!
        final offlineRule = _generateAiAnswer(query);
        final id = "ai_${DateTime.now().millisecondsSinceEpoch}";
        final aiResponse = AiTutorMessage(
          id: id,
          isUser: false,
          text: offlineRule.text,
          ruleIt: offlineRule.ruleIt,
          explanationUr: offlineRule.explanationUr,
          examTip: offlineRule.examTip,
          isOfflineRule: true,
        );

        if (mounted) {
          setState(() {
            _messages.add(aiResponse);
            // DO NOT increment _queriesAskedToday when key is missing!
          });
        }
        return;
      }

      final result = await OpenRouterService.getAiResponseDetailed(prompt, query);

      if (result.success && result.text != null) {
        final responseText = result.text!;
        String itaText = "Spiegazione completata.";
        String? urduText;

        if (responseText.contains("ITA:") && responseText.contains("URDU:")) {
          final parts = responseText.split("URDU:");
          itaText = parts[0].replaceAll("ITA:", "").trim();
          urduText = parts[1].trim();
        } else {
          itaText = responseText;
        }

        final id = "ai_${DateTime.now().millisecondsSinceEpoch}";
        final aiResponse = AiTutorMessage(
          id: id,
          isUser: false,
          text: itaText,
          explanationUr: urduText,
          isOfflineRule: false,
        );

        if (mounted) {
          setState(() {
            _messages.add(aiResponse);
            // ONLY increment daily quota on actual successful online AI response!
            _queriesAskedToday++;
          });
          await _persistDailyQuota();
        }
      } else {
        // Online call failed (e.g. timeout / network error / rate limit) — fallback to offline rule with real diagnostics!
        final offlineRule = _generateAiAnswer(query);
        final id = "ai_${DateTime.now().millisecondsSinceEpoch}";
        final aiResponse = AiTutorMessage(
          id: id,
          isUser: false,
          text: offlineRule.text,
          ruleIt: offlineRule.ruleIt,
          explanationUr: offlineRule.explanationUr,
          examTip: offlineRule.examTip,
          isOfflineRule: true,
          errorNotice: "${result.errorMessageIt} (${result.errorMessageUr})",
        );

        if (mounted) {
          setState(() {
            _messages.add(aiResponse);
            // DO NOT increment _queriesAskedToday on failed online calls!
          });
        }
      }
    } catch (e) {
      if (mounted) {
        final offlineRule = _generateAiAnswer(query);
        setState(() {
          _messages.add(
            AiTutorMessage(
              id: "err_${DateTime.now().millisecondsSinceEpoch}",
              isUser: false,
              text: offlineRule.text,
              ruleIt: offlineRule.ruleIt,
              explanationUr: offlineRule.explanationUr,
              examTip: offlineRule.examTip,
              isOfflineRule: true,
              errorNotice: "Connessione non disponibile: $e",
            ),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  // Fallback / legacy dummy generator not needed anymore, but keeping structure if OpenRouter fails completely
  AiTutorMessage _generateAiAnswer(String query) {
    final lower = query.toLowerCase();
    final id = "ai_${DateTime.now().millisecondsSinceEpoch}";

    if (lower.contains("precedenz") || lower.contains("حق فائقیت") || lower.contains("incrocio") || lower.contains("چوراہ")) {
      return AiTutorMessage(
        id: id,
        isUser: false,
        text: "Regola fondamentale della Precedenza (Art. 145 CdS):",
        ruleIt: "Negli incroci senza segnaletica specifica, la precedenza spetta sempre ai veicoli provenienti da DESTRA. Se la tua destra è occupata, devi fermarti e dare precedenza.",
        explanationUr: "چوراہے کا سنہری قانون (Art. 145): جب تک کوئی خاص بورڈ نہ ہو، ہمیشہ اپنے دائیں (Right) جانب سے آنے والی گاڑی کو پہلے راستہ دینا ہے۔ جس گاڑی کا دایاں راستہ بالکل خالی ہو، وہ سب سے پہلے نکلتی ہے۔",
        examTip: "Fig. 614 اور Fig. 624 میں ہمیشہ دیکھیں کہ کس گاڑی کا دایاں ہاتھ صاف ہے، وہی گاڑی سب سے پہلے روانہ ہو گی۔",
      );
    } else if (lower.contains("stop") || lower.contains("dare precedenza") || lower.contains("اسٹاپ")) {
      return AiTutorMessage(
        id: id,
        isUser: false,
        text: "Differenza Cruciale tra STOP e DARE PRECEDENZA:",
        ruleIt: "Al segnale di STOP c'è l'obbligo assoluto di ARRESTARE del tutto il veicolo prima della striscia trasversale, anche se non sopraggiungono altri veicoli. Al 'Dare Precedenza', bisogna rallentare e fermarsi solo se necessario.",
        explanationUr: "STOP کے بورڈ پر گاڑی کو لائن سے پہلے 100% مکمل روکنا لازمی ہے، چاہے سڑک بالکل خالی کیوں نہ ہو۔ جبکہ 'Dare Precedenza' (الٹے تکون) پر صرف اسپیڈ کم کرنی ہوتی ہے، گاڑی مکمل روکنا صرف تب ضروری ہے اگر سامنے سے کوئی گاڑی آ رہی ہو۔",
        examTip: "اگر کوئز میں لکھا ہو 'Allo STOP non serve fermarsi se la strada è vuota' تو یہ 100% FALSO ہے!",
      );
    } else if (lower.contains("velocit") || lower.contains("limiti") || lower.contains("neopatentat") || lower.contains("اسپیڈ")) {
      return AiTutorMessage(
        id: id,
        isUser: false,
        text: "Limiti di Velocità per Neopatentati (Primi 3 anni):",
        ruleIt: "Per i primi 3 anni dal conseguimento della Patente B: Massimo 100 km/h in Autostrada (invece di 130) e 90 km/h sulle Extraurbane Principali (invece di 110). Nei centri urbani rimane 50 km/h.",
        explanationUr: "نئے ڈرائیورز (Neopatentati) کے لیے پہلے 3 سال رفتار کی حدیں: موٹروے (Autostrada) پر زیادہ سے زیادہ 100 km/h، اور ایکسٹرا اربانہ مین روڈ پر زیادہ سے زیادہ 90 km/h۔ شہر کے اندر عمومی حد 50 km/h ہے۔",
        examTip: "کوئز میں اکثر 110 یا 130 لکھ کر کنفیوز کیا جاتا ہے، یاد رکھیں موٹروے پر نئے ڈرائیور کے لیے حد 100 km/h ہے۔",
      );
    } else if (lower.contains("distanza") || lower.contains("sicurezza") || lower.contains("فاصلہ")) {
      return AiTutorMessage(
        id: id,
        isUser: false,
        text: "Formula della Distanza di Sicurezza (Spazio di Reazione):",
        ruleIt: "La distanza di sicurezza deve essere almeno pari allo spazio percorso durante il tempo di reazione (circa 1 secondo). Si calcola dividendo la velocità per 10 e moltiplicando per 3. Es: a 100 km/h -> (100 / 10) * 3 = circa 30 metri minimi.",
        explanationUr: "گاڑیوں کے درمیان محفوظ فاصلہ (Distanza di Sicurezza) انسان کے ری ایکشن ٹائم (تقریباً 1 سیکنڈ) کے فاصلے کے برابر ہونا چاہیے۔ آسان فارمولا: اپنی اسپیڈ کو 10 سے تقسیم کر کے 3 سے ضرب دیں۔ مثلاً 100 km/h پر کم از کم 30 میٹر۔ بارش یا برف میں فاصلہ دگنا کر دینا چاہیے۔",
        examTip: "یاد رکھیں: Distanza di sicurezza کبھی بھی فکس نہیں ہوتی، یہ رفتار، سڑک کی حالت اور گاڑی کے بریک پر منحصر ہوتی ہے۔",
      );
    } else if (lower.contains("trabocchett") || lower.contains("ٹوٹک") || lower.contains("فارمولا")) {
      return AiTutorMessage(
        id: id,
        isUser: false,
        text: "I Magici Trabocchetti Ministeriali:",
        ruleIt: "Le parole assolute come 'Esclusivamente', 'Soltanto', 'In ogni caso', 'Mai', 'Tassativamente' sono quasi sempre indice di quiz FALSO.",
        explanationUr: "امتحان کے جادوئی ٹرپ الفاظ: جب بھی سوال میں 'صرف اور صرف' (Esclusivamente)، 'ہر صورت میں' (In ogni caso)، یا 'کبھی نہیں' (Mai) آئے تو 95% چانس ہے کہ وہ FALSO ہے۔ قانون میں ہمیشہ استثنا (Exceptions) ہوتے ہیں۔",
        examTip: "سوال کو 2 بار غور سے پڑھیں تاکہ کوئی چھپا ہوا لفظ مِس نہ ہو۔",
      );
    } else {
      return AiTutorMessage(
        id: id,
        isUser: false,
        text: "Analisi dell'Istruttore per la tua domanda:",
        ruleIt: "In base al Codice della Strada italiano, ogni manovra deve essere eseguita con prudenza senza recare intralcio o pericolo alla circolazione.",
        explanationUr: "اطالوی ٹریفک قوانین کے مطابق سڑک پر ہر موڑ، اوورٹیکنگ اور رکنے کا عمل ہمیشہ دوسرے ڈرائیورز کی حفاظت اور بغیر رکاوٹ ڈالے انجام دیا جانا چاہیے۔ سوال میں دی گئی مخصوص شرائط پر دھیان دیں۔",
        examTip: "اگر اس سوال میں تصویر شامل ہے تو ہمیشہ بورڈ کی شکل (گول یعنی حکم/پابندی، تکون یعنی خطرہ) کو ذہن میں رکھیں۔",
      );
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: AppColors.accentGold, size: 28),
            SizedBox(width: 8),
            Text("Passa a PRO 👑"),
          ],
        ),
        content: const Text(
          "Hai raggiunto il limite di 3 domande giornaliere per il piano Free. Sblocca l'Istruttore AI illimitato 24/7 con il piano PRO!",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Più tardi"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumPaywallScreen()));
            },
            child: const Text("Sblocca PRO"),
          ),
        ],
      ),
    );
  }

  void _showConfigHelpDialog(BuildContext context) {
    final isConfigured = OpenRouterService.isConfigured;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isConfigured ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              color: isConfigured ? AppColors.passedGreen : Colors.amber.shade800,
            ),
            const SizedBox(width: 8),
            Text(
              isConfigured ? "Stato Servizio AI" : "Configurazione AI",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isConfigured
                  ? "✅ L'API Key di OpenRouter è configurata correttamente.\n\nLe risposte vengono generate in tempo reale tramite i modelli AI."
                  : "⚠️ Nessuna chiave API configurata.\n\nIn questa modalità, l'assistente risponde utilizzando il motore offline basato sulle regole ufficiali del Codice della Strada.\n\nPer abilitare l'AI online, avvia l'app con:\nflutter run --dart-define=OPENROUTER_API_KEY=tua_chiave\noppure seleziona 'Patente App (with OPENROUTER_API_KEY)' in VS Code.",
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
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
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              TTSService.toggleSpeak(id: id, text: text, langCode: langCode);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isPlaying ? color : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color, width: isPlaying ? 1.5 : 1.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded,
                    size: 14,
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
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final isUrdu = langProvider.langCode == 'ur';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Istruttore AI Patente", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  subProvider.isPremium ? "Illimitato 24/7 (PRO 👑)" : "Domande oggi: $_queriesAskedToday/$_freeDailyLimit",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // In-App Diagnostic Badge: AI: Configured / AI: Not Configured
          Center(
            child: InkWell(
              onTap: () => _showConfigHelpDialog(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: OpenRouterService.isConfigured
                      ? AppColors.passedGreen.withValues(alpha: 0.12)
                      : (isDark ? const Color(0xFF451A03) : Colors.amber.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: OpenRouterService.isConfigured
                        ? AppColors.passedGreen.withValues(alpha: 0.4)
                        : (isDark ? const Color(0xFFB45309) : Colors.amber.shade700.withValues(alpha: 0.4)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      OpenRouterService.isConfigured
                          ? Icons.check_circle_rounded
                          : Icons.warning_amber_rounded,
                      size: 13,
                      color: OpenRouterService.isConfigured
                          ? AppColors.passedGreen
                          : (isDark ? const Color(0xFFFBBF24) : Colors.amber.shade800),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      OpenRouterService.isConfigured ? "AI: Configured" : "AI: Not Configured",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: OpenRouterService.isConfigured
                            ? AppColors.passedGreen
                            : (isDark ? const Color(0xFFFDE68A) : Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!subProvider.isPremium)
            TextButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumPaywallScreen()));
              },
              icon: const Icon(Icons.workspace_premium_rounded, color: AppColors.accentGold, size: 18),
              label: const Text("PRO", style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Notice banner when API key is missing
          if (!OpenRouterService.isConfigured)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 2),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFFB45309) : const Color(0xFFF59E0B),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isUrdu
                          ? "AI کنفیگر نہیں: جوابات لوکل ڈرائیونگ رولز کے ذریعے دیے جا رہے ہیں۔"
                          : "AI: Not Configured (--dart-define=OPENROUTER_API_KEY=...)",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Suggested prompts carousel (height 50, shrinkWrap, no vertical clipping)
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _suggestedPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = _suggestedPrompts[index];
                return ActionChip(
                  backgroundColor: Theme.of(context).cardColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
                  ),
                  label: Text(
                    prompt,
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  onPressed: _quotaLoaded ? () => _handleSend(prompt) : null,
                );
              },
            ),
          ),

          // Message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                if (msg.isUser) {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(14),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                        ),
                      ),
                      child: Text(
                        msg.text,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  );
                } else {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.25), width: 1.2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bot title & avatar
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.psychology_rounded, color: Color(0xFF6366F1), size: 18),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Istruttore AI",
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF6366F1)),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: msg.isOfflineRule
                                    ? (isDark ? const Color(0xFF451A03) : Colors.amber.shade800.withValues(alpha: 0.12))
                                    : AppColors.passedGreen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                msg.isOfflineRule ? "Regola CdS" : "AI Live ⚡",
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: msg.isOfflineRule
                                      ? (isDark ? const Color(0xFFFDE68A) : Colors.amber.shade900)
                                      : AppColors.passedGreen,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (msg.ruleIt != null)
                              _buildAudioChip(
                                id: "${msg.id}_it",
                                text: msg.ruleIt!,
                                langCode: 'it',
                                label: "Ascolta IT 🇮🇹",
                                color: AppColors.primary,
                              ),
                          ],
                        ),
                        if (msg.errorNotice != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.red.shade900.withValues(alpha: 0.25) : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.shade700.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline_rounded, size: 14, color: isDark ? Colors.red.shade300 : Colors.red.shade700),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "Server AI: ${msg.errorNotice!}",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.red.shade200 : Colors.red.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),

                        // Main text
                        Text(
                          msg.text,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
                        ),

                        // Italian Regulation Rule
                        if (msg.ruleIt != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              msg.ruleIt!,
                              style: const TextStyle(fontSize: 13, height: 1.4),
                            ),
                          ),
                        ],

                        // Urdu Explanation + Audio Button
                        if (msg.explanationUr != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "اردو میں رہنمائی:",
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                                ),
                              ),
                              _buildAudioChip(
                                id: "${msg.id}_ur",
                                text: msg.explanationUr!,
                                langCode: 'ur',
                                label: "اردو آواز 🇵🇰",
                                color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF14532D).withValues(alpha: 0.35)
                                  : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF22C55E).withValues(alpha: 0.4)
                                    : const Color(0xFF86EFAC),
                              ),
                            ),
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                msg.explanationUr!,
                                style: AppTheme.urduStyle(
                                  fontSize: 16,
                                  color: isDark ? const Color(0xFFF0FDF4) : const Color(0xFF0F172A),
                                  height: 1.7,
                                ),
                              ),
                            ),
                          ),
                        ],

                        // Exam Memory Tip
                        if (msg.examTip != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF78350F).withValues(alpha: 0.25)
                                  : Colors.amber.shade900.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                                    : Colors.amber.shade700.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("💡", style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Trucco d'esame: ${msg.examTip!}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFFFDE68A) : Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }
              },
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text("L'Istruttore AI sta analizzando il Codice della Strada...", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),

          // Bottom Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -3)),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Chiedi all'AI (Italiano o اردو)...",
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: _quotaLoaded ? _handleSend : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: _quotaLoaded
                          ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)])
                          : LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade500]),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _quotaLoaded
                          ? const Icon(Icons.send_rounded, color: Colors.white, size: 20)
                          : const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                              ),
                            ),
                      onPressed: _quotaLoaded ? () => _handleSend(_controller.text) : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

