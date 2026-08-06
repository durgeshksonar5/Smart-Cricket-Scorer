import 'package:flutter/material.dart';
import '../models/match_model.dart';
import 'match_summary_screen.dart';

class MatchDetailScreen extends StatelessWidget {
  final MatchModel match;

  const MatchDetailScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return MatchSummaryScreen(historicalMatch: match);
  }
}
