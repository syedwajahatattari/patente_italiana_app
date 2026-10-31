import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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
  final DateTime timestamp;

  AiTutorMessage({
    required this.id,
    required this.isUser,
    required this.text,
    this.ruleIt,
    this.explanationUr,
    this.examTip,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AiTutorScreen extends StatefulWidget {
  final String? initialQuery;

  const AiTutorScreen({super.key, this.initialQuery});

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int _queriesAskedToday = 0;
  static const int _freeDailyLimit = 3;

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
    _initWelcomeMessage();

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSend(widget.initialQuery!);
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
      _queriesAskedToday++;
    });
    _controller.clear();
    _scrollToBottom();

    // Setup prompt for driving license context
    final String prompt = '''
Sei un istruttore esperto di teoria della patente B italiana.
Rispondi in modo conciso ma molto chiaro e accurato (massimo 4-5 frasi).
Fornisci la regola ufficiale del Codice della Strada se pertinente.
Dopo la spiegazione in italiano, fornisci OBBLIGATORIAMENTE una breve traduzione/spiegazione in lingua URDU (con alfabeto urdu) per aiutare gli studenti pachistani.
Formatta la risposta esattamente così:
ITA: [La tua risposta in italiano]
URDU: [La tua spiegazione in urdu]
''';

    try {
      final responseText = await OpenRouterService.getAiResponse(prompt, query);
      
      // Parse response
      String itaText = "Si è verificato un errore, riprova più tardi.";
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
      );

      if (mounted) {
        setState(() {
          _messages.add(aiResponse);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            AiTutorMessage(
              id: "err_${DateTime.now().millisecondsSinceEpoch}",
              isUser: false,
              text: "Errore di connessione. Riprova più tardi.",
              explanationUr: "کنکشن کی خرابی۔ براہ کرم دوبارہ کوشش کریں۔",
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
        title: Row(
          children: const [
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
                color: isPlaying ? color : color.withOpacity(0.12),
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
          // Suggested prompts carousel
          Container(
            height: 44,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _suggestedPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = _suggestedPrompts[index];
                return ActionChip(
                  backgroundColor: Theme.of(context).cardColor,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  label: Text(prompt, style: const TextStyle(fontSize: 12)),
                  onPressed: () => _handleSend(prompt),
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
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: const BorderRadius.only(
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
                      border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.25), width: 1.2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
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
                                color: const Color(0xFF6366F1).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.psychology_rounded, color: Color(0xFF6366F1), size: 18),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Istruttore AI",
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF6366F1)),
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
                              color: Colors.black.withOpacity(0.03),
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
                                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A)),
                              ),
                              _buildAudioChip(
                                id: "${msg.id}_ur",
                                text: msg.explanationUr!,
                                langCode: 'ur',
                                label: "اردو آواز 🇵🇰",
                                color: const Color(0xFF16A34A),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.2)),
                            ),
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                msg.explanationUr!,
                                style: AppTheme.urduStyle(fontSize: 16, color: const Color(0xFF14532D), height: 1.7),
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
                              color: Colors.amber.shade900.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade700.withOpacity(0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("💡", style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Trucco d'esame: ${msg.examTip!}",
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.amber.shade900),
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
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
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -3)),
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
                      onSubmitted: _handleSend,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: () => _handleSend(_controller.text),
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

