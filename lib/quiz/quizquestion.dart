import 'package:flutter/material.dart';

class QuizQuestion extends StatelessWidget {
  final String question;
  final List<String> choices;
  final int index;
  final int selectedValue; // index of selected choice
  final void Function(int index, int value) onChanged;

  const QuizQuestion({
    super.key,
    required this.question,
    required this.choices,
    required this.index,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          textAlign: TextAlign.center,
          question,
          style: const TextStyle(
            fontSize: 20,
            fontFamily: "Voltaire",
          ),
        ),

        const SizedBox(height: 20),

        // Choices
        for (int i = 0; i < choices.length; i++)
          Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  onChanged(index, i);
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: (selectedValue == i)
                      ? const Color(0xFF41BF41)   // selected
                      : const Color(0xFFC0FFC0),  // unselected
                  foregroundColor: Colors.black,
                ),

                child: SizedBox(
                  width: 230,
                  height: 27,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        choices[i],
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
      ],
    );
  }
}
