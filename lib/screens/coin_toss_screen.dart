import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import '../controllers/match_controller.dart';
import '../models/match_model.dart';
import '../theme/app_theme.dart';
import '../widgets/coin_3d_widget.dart';
import '../widgets/made_by_footer.dart';
import 'match_confirmation_screen.dart';

class CoinTossScreen extends StatefulWidget {
  const CoinTossScreen({super.key});

  @override
  State<CoinTossScreen> createState() => _CoinTossScreenState();
}

class _CoinTossScreenState extends State<CoinTossScreen>
    with SingleTickerProviderStateMixin {
  ConfettiController? _confettiController;
  AnimationController? _resultAnimController;
  Animation<double>? _scaleAnim;
  Animation<double>? _fadeAnim;

  String? _callingTeam;
  String _selectedCall = 'HEADS'; // "HEADS" or "TAILS"
  String? _coinResult; // "HEADS" or "TAILS"
  String? _tossWinner;
  String _selectedDecision = 'Bat First'; // "Bat First" or "Bowl First"

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    final animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
          parent: animCtrl, curve: Curves.elasticOut),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: animCtrl, curve: Curves.easeIn),
    );

    _resultAnimController = animCtrl;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final match =
          Provider.of<MatchController>(context, listen: false).currentMatch;
      if (match != null) {
        setState(() {
          _callingTeam = match.teamA;
        });
      }
    });
  }

  @override
  void dispose() {
    _confettiController?.dispose();
    _resultAnimController?.dispose();
    super.dispose();
  }

  void _onFlipCoin() async {
    final controller = Provider.of<MatchController>(context, listen: false);
    MatchModel? match = controller.currentMatch;
    if (match == null || _callingTeam == null) return;

    _resultAnimController?.reset();
    setState(() {
      _coinResult = null;
      _tossWinner = null;
    });

    String result = await controller.flipCoin();

    bool isTeamA = (_callingTeam == match.teamA);
    String otherTeam = isTeamA ? match.teamB : match.teamA;

    bool guessCorrect = (_selectedCall.toUpperCase() == result.toUpperCase());
    String winnerTeam = guessCorrect ? _callingTeam! : otherTeam;

    setState(() {
      _coinResult = result;
      _tossWinner = winnerTeam;
    });

    _resultAnimController?.forward();
    _confettiController?.play();
  }

  void _onProceedToConfirmation() {
    final controller = Provider.of<MatchController>(context, listen: false);
    MatchModel? match = controller.currentMatch;
    if (match == null ||
        _callingTeam == null ||
        _coinResult == null ||
        _tossWinner == null) {
      return;
    }

    controller.finalizeTossDecision(
      callingTeam: _callingTeam!,
      tossCall: _selectedCall,
      coinResult: _coinResult!,
      tossDecision: _selectedDecision,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => const MatchConfirmationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<MatchController>(context);
    MatchModel? match = controller.currentMatch;

    if (match == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Coin Toss')),
        body: const Center(child: Text('No match in progress.')),
      );
    }

    _callingTeam ??= match.teamA;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coin Toss'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20.0, vertical: 16.0),
              child: Column(
                children: [
                  // Match Header Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2E5749)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          match.teamA,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryEmerald,
                          ),
                        ),
                        const Text(
                          'VS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.coinGold,
                          ),
                        ),
                        Text(
                          match.teamB,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.coinGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Step 1: Who is calling the toss?
                  if (_coinResult == null && !controller.isFlipping) ...[
                    const Text(
                      'Which team will call the toss?',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCallingTeamCard(
                            teamName: match.teamA,
                            color: AppTheme.primaryEmerald,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCallingTeamCard(
                            teamName: match.teamB,
                            color: AppTheme.coinGold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Step 2: HEADS / TAILS Selection
                    Text(
                      'Select Call for $_callingTeam:',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCallButton('HEADS', '🪙'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildCallButton('TAILS', '🦅'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Step 3: 3D Animated Coin Widget
                  Coin3DWidget(
                    isFlipping: controller.isFlipping,
                    result: _coinResult,
                  ),

                  const SizedBox(height: 20),

                  // Flipping indicator or Flip Action Button
                  if (controller.isFlipping) ...[
                    const Text(
                      'Flipping Coin...',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.coinGold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppTheme.coinGold,
                      ),
                    ),
                  ] else if (_coinResult == null) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _onFlipCoin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.coinGold,
                          foregroundColor: Colors.black,
                        ),
                        icon: const Icon(Icons.autorenew, color: Colors.black, size: 24),
                        label: Text(
                          'FLIP COIN ($_callingTeam calls $_selectedCall)',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                      ),
                    ),
                  ],

                  // Reveal Result & Winner Glassmorphism Card
                  if (_coinResult != null && !controller.isFlipping && _fadeAnim != null && _scaleAnim != null) ...[
                    FadeTransition(
                      opacity: _fadeAnim!,
                      child: ScaleTransition(
                        scale: _scaleAnim!,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBgLight.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppTheme.coinGold, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.coinGold.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text(
                                '🪙 COIN RESULT',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textMuted,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _coinResult!,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.coinGold,
                                ),
                              ),
                              const Divider(color: Color(0xFF2E5749), height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.emoji_events,
                                      color: AppTheme.primaryEmerald, size: 28),
                                  const SizedBox(width: 8),
                                  Text(
                                    '🏆 $_tossWinner WINS THE TOSS!',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.primaryEmerald,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Toss Decision Selector
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Choose Decision:',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textLight),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildDecisionCard('Bat First', '🏏'),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildDecisionCard('Bowl First', '⚾'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Proceed to Confirmation Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _onProceedToConfirmation,
                        icon: const Icon(Icons.check_circle, color: Colors.black, size: 26),
                        label: const Text('PROCEED TO CONFIRMATION', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Re-flip option
                    TextButton.icon(
                      onPressed: _onFlipCoin,
                      icon: const Icon(Icons.refresh,
                          color: AppTheme.textMuted, size: 18),
                      label: const Text('Re-flip Coin',
                          style: TextStyle(color: AppTheme.textMuted)),
                    ),
                  ],
                  const MadeByFooter(),
                ],
              ),
            ),

            // Top Confetti Celebration Overlay
            if (_confettiController != null)
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController!,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  AppTheme.primaryEmerald,
                  AppTheme.coinGold,
                  Colors.white,
                  Color(0xFF00E5FF),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallingTeamCard({
    required String teamName,
    required Color color,
  }) {
    bool isSelected = _callingTeam == teamName;
    return GestureDetector(
      onTap: () => setState(() => _callingTeam = teamName),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : AppTheme.cardBgLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF2E5749),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            teamName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? color : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCallButton(String option, String iconStr) {
    bool isSelected = _selectedCall == option;
    return GestureDetector(
      onTap: () => setState(() => _selectedCall = option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.coinGold : AppTheme.cardBgLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.coinGold : const Color(0xFF2E5749),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.coinGold.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Text(iconStr, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              option,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionCard(String decision, String emoji) {
    bool isSelected = _selectedDecision == decision;
    return GestureDetector(
      onTap: () => setState(() => _selectedDecision = decision),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryEmerald.withValues(alpha: 0.15)
              : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isSelected ? AppTheme.primaryEmerald : const Color(0xFF2E5749),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              decision,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primaryEmerald : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
