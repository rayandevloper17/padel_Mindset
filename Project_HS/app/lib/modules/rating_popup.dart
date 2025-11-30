import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import './rating_controller.dart';

class RatingPopup extends StatelessWidget {
  final RatingController controller = Get.find<RatingController>();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Colors.amber.shade600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.92, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 250),
              child: child,
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      isDark
                          ? [
                            const Color(0xFF0E0E0E).withOpacity(0.85),
                            const Color(0xFF151515).withOpacity(0.75),
                          ]
                          : [
                            scheme.surface.withOpacity(0.95),
                            scheme.surfaceVariant.withOpacity(0.90),
                          ],
                ),
                border: Border.all(color: primary.withOpacity(0.35)),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.30),
                    blurRadius: 24,
                    spreadRadius: 1,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                maxWidth: 640,
                maxHeight: MediaQuery.of(context).size.height * 0.80,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Quel est votre niveau de padel ?',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color:
                                  isDark ? scheme.onSurface : scheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildQuestion(
                              context,
                              scheme,
                              'Q1',
                              'Quelle est ton expérience dans la pratique du padel ?',
                              [
                                'Je découvre tout juste le padel.',
                                'J’ai déjà joué quelques parties.',
                                'Je joue de temps en temps, sans régularité.',
                                'Je joue souvent, au moins une fois par semaine.',
                                'Je pratique régulièrement en club ou en compétition.',
                              ],
                            ),
                            _buildQuestion(
                              context,
                              scheme,
                              'Q2',
                              'Comment décrirais-tu ta maîtrise technique ?',
                              [
                                'Je parviens surtout à renvoyer la balle, sans viser.',
                                'J’arrive parfois à diriger mes frappes.',
                                'Je contrôle correctement les coups de base et les volées.',
                                'Je sais varier mes frappes et construire mes points.',
                                'Je maîtrise les effets, les placements et les coups puissants.',
                              ],
                            ),
                            _buildQuestion(
                              context,
                              scheme,
                              'Q3',
                              'Quelle est ta condition physique sur le terrain ?',
                              [
                                'Je manque d’endurance pour tenir un match complet.',
                                'Je peux jouer un match, mais je fatigue vers la fin.',
                                'Je supporte sans problème l’intensité d’un match complet.',
                                'Je peux enchaîner plusieurs matchs sans difficulté.',
                              ],
                            ),
                            _buildQuestion(
                              context,
                              scheme,
                              'Q4',
                              'Par rapport aux joueurs avec qui tu joues habituellement, tu dirais que :',
                              [
                                'Je perds la majorité de mes matchs.',
                                'Les matchs sont généralement équilibrés.',
                                'Je gagne plus souvent que je ne perds.',
                                'Je gagne la plupart du temps.',
                              ],
                            ),
                            _buildQuestion(
                              context,
                              scheme,
                              'Q5',
                              'As-tu déjà pratiqué d’autres sports de raquette ?',
                              [
                                'Non, c’est mon premier sport de raquette.',
                                'J’ai déjà essayé le tennis, le badminton ou un autre sport similaire.',
                                'J’ai un bon niveau dans un autre sport de raquette.',
                                'J’ai déjà joué en compétition dans un autre sport de raquette.',
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primary,
                              side: BorderSide(color: primary.withOpacity(0.6)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => Get.back(result: 'later'),
                            child: const Text('Plus tard'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              controller.calculateAndSubmitRating();
                              Get.back(result: 'submitted');
                            },
                            child: const Text('Valider'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion(
    BuildContext context,
    ColorScheme scheme,
    String key,
    String question,
    List<String> options,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Colors.amber.shade600;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? scheme.onSurface : scheme.onSurface,
            ),
          ),
          const SizedBox(height: 10.0),
          Obx(() {
            final selected = controller.answers[key]?.value;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(options.length, (index) {
                final label = options[index];
                final value = (index + 1).toString();
                final isSelected = selected == value;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  transform: Matrix4.identity()..scale(isSelected ? 1.02 : 1.0),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) => controller.setAnswer(key, value),
                    labelStyle: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(
                      color: isSelected ? Colors.black : scheme.onSurface,
                    ),
                    selectedColor: primary,
                    backgroundColor:
                        isDark
                            ? scheme.surfaceVariant.withOpacity(0.35)
                            : scheme.surfaceVariant.withOpacity(0.60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color:
                            isSelected
                                ? primary
                                : scheme.outline.withOpacity(0.3),
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }
}
