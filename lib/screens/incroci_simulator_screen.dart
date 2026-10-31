import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/language_provider.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class IncrocioScenario {
  final String id;
  final String figureNumber;
  final String titleIt;
  final String titleUr;
  final List<String> correctOrder; // e.g. ["R", "A", "C"]
  final Map<String, String> vehicleNamesIt;
  final Map<String, String> vehicleNamesUr;
  final Map<String, Color> vehicleColors;
  final String explanationIt;
  final String explanationUr;

  const IncrocioScenario({
    required this.id,
    required this.figureNumber,
    required this.titleIt,
    required this.titleUr,
    required this.correctOrder,
    required this.vehicleNamesIt,
    required this.vehicleNamesUr,
    required this.vehicleColors,
    required this.explanationIt,
    required this.explanationUr,
  });
}

class IncrociSimulatorScreen extends StatefulWidget {
  const IncrociSimulatorScreen({super.key});

  @override
  State<IncrociSimulatorScreen> createState() => _IncrociSimulatorScreenState();
}

class _IncrociSimulatorScreenState extends State<IncrociSimulatorScreen> {
  final List<IncrocioScenario> _scenarios = const [
    IncrocioScenario(
      id: "inc_614",
      figureNumber: "Fig. 614",
      titleIt: "Incrocio con svolta e precedenza da destra",
      titleUr: "چوراہا نمبر 614: دائیں ہاتھ کی ترجیح",
      correctOrder: ["R", "A", "C"],
      vehicleNamesIt: {
        "R": "Filobus / Veicolo R (Rosso)",
        "A": "Veicolo A (Azzurro)",
        "C": "Veicolo C (Giallo)",
      },
      vehicleNamesUr: {
        "R": "گاڑی R (سرخ گاڑی)",
        "A": "گاڑی A (نیلی گاڑی)",
        "C": "گاڑی C (پیلی گاڑی)",
      },
      vehicleColors: {
        "R": Colors.red,
        "A": Colors.blue,
        "C": Colors.amber,
      },
      explanationIt: "1° R ha la destra libera e passa per primo.\n2° A passa subito dopo perché la sua destra è liberata da R.\n3° C passa per ultimo dopo il transito di A.",
      explanationUr: "1° گاڑی R کا دایاں راستہ بالکل صاف ہے، لہٰذا وہ سب سے پہلے گزرے گی۔\n2° گاڑی R کے گزرنے کے بعد گاڑی A کا دایاں راستہ کھل جائے گا، وہ دوسرے نمبر پر گزرے گی۔\n3° گاڑی C سب سے آخر میں گزرے گی کیونکہ اسے A کا انتظار کرنا تھا۔",
    ),
    IncrocioScenario(
      id: "inc_624",
      figureNumber: "Fig. 624",
      titleIt: "Incrocio a quattro veicoli con svolta a sinistra",
      titleUr: "چوراہا نمبر 624: چار گاڑیوں کا چوک",
      correctOrder: ["T", "P", "B", "C"],
      vehicleNamesIt: {
        "T": "Tram / Veicolo T",
        "P": "Veicolo P (Verde)",
        "B": "Veicolo B (Blu)",
        "C": "Veicolo C (Arancione)",
      },
      vehicleNamesUr: {
        "T": "ٹرام T (ٹرام کو حقِ فائقیت ہے)",
        "P": "گاڑی P (سبز گاڑی)",
        "B": "گاڑی B (نیلی گاڑی)",
        "C": "گاڑی C (نارنجی گاڑی)",
      },
      vehicleColors: {
        "T": Colors.purple,
        "P": Colors.green,
        "B": Colors.blue,
        "C": Colors.deepOrange,
      },
      explanationIt: "1° T (Tram) ha sempre la precedenza su tutti.\n2° P ha la destra libera rispetto agli altri autoveicoli.\n3° B passa dopo P.\n4° C passa per ultimo.",
      explanationUr: "1° ٹرام T کو ہمیشہ دیگر تمام گاڑیوں پر فوقیت حاصل ہے، وہ پہلے گزرے گی۔\n2° گاڑیوں میں P کا دایاں حصہ صاف ہے، وہ ٹرام کے بعد گزرے گی۔\n3° گاڑی P کے بعد B کا راستہ کھلے گا۔\n4° گاڑی C سب سے آخر میں جائے گی۔",
    ),
    IncrocioScenario(
      id: "inc_638",
      figureNumber: "Fig. 638",
      titleIt: "Incrocio complesso: Veicolo che impegna il centro",
      titleUr: "چوراہا نمبر 638: چوک کے درمیان رکنے والی گاڑی",
      correctOrder: ["E", "C", "L"],
      vehicleNamesIt: {
        "E": "Veicolo E (Verde)",
        "C": "Veicolo C (Giallo)",
        "L": "Veicolo L (Blu)",
      },
      vehicleNamesUr: {
        "E": "گاڑی E (سبز گاڑی)",
        "C": "گاڑی C (پیلی گاڑی)",
        "L": "گاڑی L (نیلی گاڑی)",
      },
      vehicleColors: {
        "E": Colors.green,
        "C": Colors.amber,
        "L": Colors.blue,
      },
      explanationIt: "1° E si muove per primo perché ha la destra libera da veicoli in traiettoria diretta.\n2° C passa liberato da E.\n3° L conclude la manovra per ultimo.",
      explanationUr: "1° گاڑی E کا دایاں حصہ ٹریفک سے خالی ہے، وہ سب سے پہلے چوک عبور کرے گی۔\n2° E کے بعد گاڑی C گزرے گی۔\n3° گاڑی L سب سے آخر میں چوک پار کرے گی۔",
    ),
  ];

  int _currentScenarioIndex = 0;
  List<String> _selectedOrder = [];
  bool? _isCorrect;
  String? _errorMessage;

  @override
  void dispose() {
    TTSService.stop();
    super.dispose();
  }

  void _onVehicleTap(String vehicle) {
    if (_selectedOrder.contains(vehicle)) return;

    final scenario = _scenarios[_currentScenarioIndex];
    final nextExpected = scenario.correctOrder[_selectedOrder.length];

    HapticFeedback.lightImpact();

    if (vehicle == nextExpected) {
      setState(() {
        _selectedOrder.add(vehicle);
        _errorMessage = null;
        if (_selectedOrder.length == scenario.correctOrder.length) {
          _isCorrect = true;
          HapticFeedback.heavyImpact();
        }
      });
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _errorMessage = "Attenzione! Il veicolo $vehicle non può passare ora: ha la destra occupata dal veicolo $nextExpected!";
      });
    }
  }

  void _resetCurrent() {
    setState(() {
      _selectedOrder.clear();
      _isCorrect = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final lang = langProvider.langCode;
    final isUrdu = lang == 'ur';
    final scenario = _scenarios[_currentScenarioIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isUrdu ? "🚗 چوراہوں کا اینیمیٹر (Incroci)" : (lang == 'en' ? "🚗 Intersections Simulator" : "🚗 Simulatore Incroci & Precedenze"),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Scenario Navigator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _currentScenarioIndex > 0
                      ? () {
                          setState(() {
                            _currentScenarioIndex--;
                            _resetCurrent();
                          });
                        }
                      : null,
                  icon: const Icon(Icons.arrow_back_ios_rounded),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    "${scenario.figureNumber} (${_currentScenarioIndex + 1}/${_scenarios.length})",
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                IconButton(
                  onPressed: _currentScenarioIndex < _scenarios.length - 1
                      ? () {
                          setState(() {
                            _currentScenarioIndex++;
                            _resetCurrent();
                          });
                        }
                      : null,
                  icon: const Icon(Icons.arrow_forward_ios_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Intersection Title & Instruction
            Text(
              isUrdu ? scenario.titleUr : scenario.titleIt,
              textAlign: TextAlign.center,
              style: isUrdu
                  ? AppTheme.urduStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  : GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              isUrdu
                  ? "گاڑیوں پر ان کے گزرنے کی درست ترتیب کے مطابق کلک کریں:"
                  : "Tocca i veicoli nell'ordine esatto di transito:",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),

            // Visual Interactive Simulation Canvas
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.withOpacity(0.25)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Road Cross Lines
                  Container(
                    width: 70,
                    height: double.infinity,
                    color: const Color(0xFF334155),
                  ),
                  Container(
                    width: double.infinity,
                    height: 70,
                    color: const Color(0xFF334155),
                  ),
                  // Center intersection circle
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 2, style: BorderStyle.solid),
                    ),
                  ),

                  // Vehicles placed on roads
                  ...scenario.correctOrder.map((code) {
                    final isSelected = _selectedOrder.contains(code);
                    final orderIndex = _selectedOrder.indexOf(code);
                    final color = scenario.vehicleColors[code] ?? Colors.white;

                    // Place vehicle around the cross
                    Alignment align = Alignment.center;
                    if (code == "R" || code == "T") align = const Alignment(-0.6, -0.6);
                    if (code == "A" || code == "P") align = const Alignment(0.6, -0.6);
                    if (code == "C" || code == "B") align = const Alignment(-0.6, 0.6);
                    if (code == "L") align = const Alignment(0.6, 0.6);

                    return Align(
                      alignment: align,
                      child: GestureDetector(
                        onTap: () => _onVehicleTap(code),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.passedGreen : color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(color: color.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Text(
                            isSelected ? "${orderIndex + 1}° ($code)" : code,
                            style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live Selected Order Chips
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isUrdu ? "آپ کی ترتیب: " : "Ordine scelto: ",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                if (_selectedOrder.isEmpty)
                  Text(isUrdu ? "(کوئی نہیں)" : "(nessuno)", style: const TextStyle(color: Colors.grey, fontSize: 12))
                else
                  ..._selectedOrder.asMap().entries.map((e) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.passedGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.passedGreen),
                      ),
                      child: Text(
                        "${e.key + 1}° ${e.value}",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.passedGreen, fontSize: 13),
                      ),
                    );
                  }),
                if (_selectedOrder.isNotEmpty && _isCorrect != true) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.grey),
                    onPressed: _resetCurrent,
                    tooltip: "Ricomincia",
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Error Message Alert
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.failedRed.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.failedRed),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.failedRed),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.failedRed, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Success & Detailed Explanation
            if (_isCorrect == true) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.passedGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.passedGreen, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.passedGreen, size: 26),
                        const SizedBox(width: 8),
                        Text(
                          isUrdu ? "بہترین! بالکل درست ترتیب 🎉" : "ESATTO! Ordine di transito corretto 🎉",
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.passedGreen),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isUrdu ? "وضاحت و اصول:" : "Spiegazione passo-passo:",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                        ),
                        InkWell(
                          onTap: () => TTSService.toggleSpeak(
                            id: "${scenario.id}_inc_it",
                            text: scenario.explanationIt,
                            langCode: 'it',
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.volume_up_rounded, size: 13, color: AppColors.primary),
                                SizedBox(width: 3),
                                Text("IT 🇮🇹", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scenario.explanationIt,
                      style: GoogleFonts.outfit(fontSize: 13, height: 1.4),
                    ),
                    if (lang != 'it') ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isUrdu ? "اردو وضاحت:" : "English Explanation:",
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A)),
                          ),
                          InkWell(
                            onTap: () => TTSService.toggleSpeak(
                              id: "${scenario.id}_inc_ur",
                              text: scenario.explanationUr,
                              langCode: 'ur',
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.volume_up_rounded, size: 13, color: Color(0xFF16A34A)),
                                  SizedBox(width: 3),
                                  Text("اردو 🇵🇰", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Directionality(
                        textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                        child: Text(
                          scenario.explanationUr,
                          style: isUrdu
                              ? AppTheme.urduStyle(fontSize: 15, color: AppColors.primaryDark, height: 1.6)
                              : const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Golden Rules for Incroci Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_rounded, color: AppColors.accentGold, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isUrdu ? "💡 چوراہوں کا سنہری اصول (Regola d'Oro)" : "💡 Regola fondamentale degli Incroci",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isUrdu
                        ? "1. جس گاڑی کا دایاں ہاتھ (Right side) بالکل خالی ہو وہ پہلے گزرے گی۔\n2. ٹرام (Tram) کو عام گاڑیوں پر ہمیشہ فوقیت ہوتی ہے۔\n3. ایمرجنسی گاڑیاں (سائرن کے ساتھ) سب سے پہلے گزرتی ہیں۔"
                        : "1. Chi ha la destra libera passa per primo.\n2. Il tram ha sempre la precedenza sui veicoli normali.\n3. I veicoli di emergenza con sirena attiva passano prima di tutti.",
                    style: isUrdu ? AppTheme.urduStyle(fontSize: 14, height: 1.5) : const TextStyle(fontSize: 12, height: 1.4),
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

