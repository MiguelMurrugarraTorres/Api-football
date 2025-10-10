// lib/features/home/widgets/stories_button.dart
import 'package:flutter/material.dart';

class StoriesButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const StoriesButton({super.key, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SizedBox(
        height: 86,
        child: Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            onTap: loading ? null : onTap,
            borderRadius: BorderRadius.circular(48),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF2A45F0), Color(0xFF4E95FF)],
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: loading
                        ? const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : const Center(child: Text('🔥', style: TextStyle(fontSize: 26))),
                  ),
                ),
                const SizedBox(height: 6),
                const Text('Stories', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
