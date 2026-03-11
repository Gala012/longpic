import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'long_pic_user_preferences.dart';
class GuideService extends GetxService {
  static GuideService get to => Get.find();
  bool shouldShowGuide() {
    return !UserPreferences.to.hasCompletedGuide;
  }
  Future<void> completeGuide() async {
    await UserPreferences.to.markGuideCompleted();
  }
  void showHomeGuide(BuildContext context) {
    if (!shouldShowGuide()) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showGuideOverlay(
        context: context,
        steps: _homeGuideSteps,
        onComplete: () async {
          await completeGuide();
        },
      );
    });
  }
  void showEditGuide(BuildContext context, String mode) {
    if (UserPreferences.to.hasCompletedGuide) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showGuideOverlay(
        context: context,
        steps: _getEditGuideSteps(mode),
        onComplete: () {
        },
      );
    });
  }
  void _showGuideOverlay({
    required BuildContext context,
    required List<GuideStep> steps,
    required VoidCallback onComplete,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => GuideOverlay(
        steps: steps,
        onComplete: onComplete,
      ),
    );
  }
  List<GuideStep> get _homeGuideSteps => [
        GuideStep(
          title: 'Welcome to LongPic!',
          description:
              'Create beautiful long images by stitching multiple photos together.',
          icon: Icons.photo_library,
        ),
        GuideStep(
          title: 'Choose Your Mode',
          description:
              'Select from vertical stitch, horizontal stitch, grid collage, or poster templates.',
          icon: Icons.grid_view,
        ),
        GuideStep(
          title: 'Edit & Customize',
          description:
              'Add borders, crop images, adjust spacing, and apply various effects.',
          icon: Icons.edit,
        ),
        GuideStep(
          title: 'Save & Share',
          description:
              'Save your creations to your photo library and share them with the world!',
          icon: Icons.share,
        ),
      ];
  List<GuideStep> _getEditGuideSteps(String mode) {
    if (mode == 'vertical' || mode == 'smart') {
      return [
        GuideStep(
          title: 'Tap to Select Image',
          description: 'Tap any image to see editing options.',
          icon: Icons.touch_app,
        ),
        GuideStep(
          title: 'Edit Tools',
          description: 'Crop, rotate, add mosaic, replace, or remove images.',
          icon: Icons.build,
        ),
        GuideStep(
          title: 'Borders & Sorting',
          description:
              'Use bottom buttons to adjust borders and reorder images.',
          icon: Icons.border_outer,
        ),
        GuideStep(
          title: 'Save Template',
          description:
              'Save your settings as a template for quick reuse next time!',
          icon: Icons.bookmark,
        ),
      ];
    } else if (mode == 'grid') {
      return [
        GuideStep(
          title: 'Adjust Layout',
          description: 'Use the slider to change how many pics per row.',
          icon: Icons.view_module,
        ),
        GuideStep(
          title: 'Aspect Ratio',
          description: 'Choose different aspect ratios for your grid.',
          icon: Icons.aspect_ratio,
        ),
        GuideStep(
          title: 'Auto Fill & Shuffle',
          description: 'Fill empty spaces or randomize image order.',
          icon: Icons.shuffle,
        ),
      ];
    } else {
      return [
        GuideStep(
          title: 'Border Settings',
          description: 'Tap the border button to customize colors and spacing.',
          icon: Icons.border_all,
        ),
        GuideStep(
          title: 'Add More Photos',
          description: 'Use the add photo button to append more images.',
          icon: Icons.add_photo_alternate,
        ),
      ];
    }
  }
}
class GuideStep {
  final String title;
  final String description;
  final IconData icon;
  GuideStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}
class GuideOverlay extends StatefulWidget {
  final List<GuideStep> steps;
  final VoidCallback onComplete;
  const GuideOverlay({
    Key? key,
    required this.steps,
    required this.onComplete,
  }) : super(key: key);
  @override
  State<GuideOverlay> createState() => _GuideOverlayState();
}
class _GuideOverlayState extends State<GuideOverlay> {
  int _currentStep = 0;
  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      _complete();
    }
  }
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }
  void _skip() {
    _complete();
  }
  void _complete() {
    Navigator.of(context).pop();
    widget.onComplete();
  }
  @override
  Widget build(BuildContext context) {
    final currentGuide = widget.steps[_currentStep];
    final isLastStep = _currentStep == widget.steps.length - 1;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isLastStep)
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skip,
                  child: const Text(
                    'Skip',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Column(
                key: ValueKey<int>(_currentStep),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF13ec37).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      currentGuide.icon,
                      size: 40,
                      color: const Color(0xFF13ec37),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    currentGuide.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentGuide.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.steps.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == _currentStep ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index == _currentStep
                        ? const Color(0xFF13ec37)
                        : Colors.white30,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white30),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF13ec37),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(isLastStep ? 'Get Started' : 'Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
