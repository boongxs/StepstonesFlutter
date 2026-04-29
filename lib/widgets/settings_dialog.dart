import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/settings_controller.dart';
import '../utils/snackbar_helper.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({
    super.key,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  // used to track if user made any changes
  // initially false to disable "Save Changes" button
  bool _hasChanges = false;

  late double _defaultVolume;
  late Color _selectedColor;
  late double _similarityThreshold;

  final ScrollController _scrollController = ScrollController();

  // list of theme colors to choose from
  final List<Color> _availableColors = [
    Colors.tealAccent,
    Colors.blueAccent,
    Colors.deepPurpleAccent,
    Colors.pinkAccent,
    Colors.deepOrangeAccent,
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // grab current values from controller when dialog opens
    final settings = context.read<SettingsController>();
    _defaultVolume = settings.defaultVolume;
    _selectedColor = settings.themeColor;
    _similarityThreshold = settings.similarityThreshold;
  }

  @override
  Widget build(BuildContext context) {
    final localTheme = Theme.of(context).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _selectedColor,
        brightness: Brightness.dark,
      ),
    );

    return Theme(
      data: localTheme,
      child: Dialog(
        backgroundColor: const Color(0xff282828),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 700,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height - 96),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Settings",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
      
                  // "X" button to close
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    tooltip: "Close",
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
      
              const SizedBox(height: 16),
      
              // --- BODY (Placeholder for future settings) ---
              Flexible(
                child: RawScrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  thickness: 8,
                  radius: const Radius.circular(4),
                  thumbColor: const Color(0xFF6f6f6f),
                  trackColor: const Color(0xFF3a3a3a),
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                    child: ListView(
                      controller: _scrollController,
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                      children: [
                      // default volume setting
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xff383838),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.volume_up_rounded, color: Colors.white70, size: 28),
      
                            const SizedBox(width: 16),
      
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Default Volume",
                                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  
                                  SizedBox(height: 4),
      
                                  Text(
                                    "Set the starting volume for video and audio playback",
                                    style: TextStyle(color: Colors.white54, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
      
                            const SizedBox(width: 16),
      
                            // display current value
                            Text(
                              "${_defaultVolume.toInt()}%",
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
      
                            const SizedBox(width: 8),
      
                            // slider
                            SizedBox(
                              width: 150,
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  overlayShape: SliderComponentShape.noOverlay
                                ),
                                child: Slider(
                                  value: _defaultVolume,
                                  min: 0,
                                  max: 100,
                                  divisions: 10,
                                  activeColor: localTheme.colorScheme.primary,
                                  inactiveColor: Colors.white24,
                                  onChanged: (val) {
                                    setState(() {
                                      _defaultVolume = val;
                                      _hasChanges = true;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
      
                      const SizedBox(height: 12),

                      // duplicate sensitivity setting
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xff383838),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.find_replace_rounded, color: Colors.white70, size: 28),

                            const SizedBox(width: 16),

                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Duplicate Sensitivity",
                                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),

                                  SizedBox(height: 4),

                                  Text(
                                    "Minimum similarity for flagging potential duplicates in Review view",
                                    style: TextStyle(color: Colors.white54, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 16),

                            Text(
                              "${_similarityThreshold.toInt()}%",
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),

                            const SizedBox(width: 8),

                            SizedBox(
                              width: 150,
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  overlayShape: SliderComponentShape.noOverlay,
                                ),
                                child: Slider(
                                  value: _similarityThreshold,
                                  min: 75,
                                  max: 95,
                                  divisions: 4,
                                  activeColor: localTheme.colorScheme.primary,
                                  inactiveColor: Colors.white24,
                                  onChanged: (val) {
                                    setState(() {
                                      _similarityThreshold = val;
                                      _hasChanges = true;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // theme color setting
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xff383838),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.palette_rounded, color: Colors.white70, size: 28),
      
                            const SizedBox(width: 16),
      
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Theme Color",
                                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  
                                  SizedBox(height: 4),
      
                                  Text(
                                    "Choose the primary accent color for the application.",
                                    style: TextStyle(color: Colors.white54, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
      
                            const SizedBox(width: 16),
      
                            // color picker row
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: _availableColors.map((color) {
                                final isSelected = _selectedColor.toARGB32() == color.toARGB32();
                                return MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedColor = color;
                                        _hasChanges = true;
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: isSelected ? Border.all(color: Colors.white, width: 2.5) : null,
                                        boxShadow: [
                                          if (isSelected)
                                            const BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))
                                        ]
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

              const SizedBox(height: 24),

              // --- FOOTER BUTTONS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // "Close" button (discard changes)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
      
                  const SizedBox(width: 16),
      
                  // "Save Changes" button
                  FilledButton(
                    onPressed: _hasChanges
                      ? () async {
                        final success = await context.read<SettingsController>().saveSettings(_defaultVolume, _selectedColor, _similarityThreshold);
                        
                        if (context.mounted) {
                          if (success) {
                            context.showStepstonesSnackBar("Settings saved successfully");
                            Navigator.pop(context);
                          } else {
                            context.showStepstonesSnackBar("Failed to save settings", isError: true);
                          }
                        }
                      }
                      : null,
                    child: const Text("Save Changes"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}