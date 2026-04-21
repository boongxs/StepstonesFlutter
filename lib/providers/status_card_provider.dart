import 'dart:async';
import 'package:flutter/material.dart';

class JobEntry {
  final int id;
  String title;
  String subtitle;
  bool isLoading;
  bool isError;
  bool isVisible;
  Timer? hideTimer;

  JobEntry({
    required this.id,
    required this.title,
    this.subtitle = "",
    this.isLoading = true,
    this.isError = false,
    this.isVisible = true,
  });
}

class StatusCardProvider extends ChangeNotifier {
  int _nextId = 0;
  final List<JobEntry> _jobs = [];

  List<JobEntry> get jobs => List.unmodifiable(_jobs);

  /// Starts a new job card and returns its ID for subsequent updates.
  int startJob(String title) {
    final id = _nextId++;
    _jobs.add(JobEntry(id: id, title: title));
    notifyListeners();
    return id;
  }

  /// Updates the title of an active job card (e.g. to reflect a new sync stage).
  void updateJobTitle(int id, String title) {
    _findJob(id)?.title = title;
    notifyListeners();
  }

  /// Updates the subtitle of an active job card (e.g. current filename or queue count).
  void updateProgress(int id, String subtitle) {
    _findJob(id)?.subtitle = subtitle;
    notifyListeners();
  }

  /// Finishes a job: stops the spinner, shows the completion message, then auto-hides after 2s.
  void finishJob(int id, String completionMessage, {bool isError = false}) {
    final job = _findJob(id);
    if (job == null) return;

    job.isLoading = false;
    job.isError = isError;
    job.title = completionMessage;
    job.subtitle = "";
    notifyListeners();

    job.hideTimer = Timer(const Duration(seconds: 2), () {
      job.isVisible = false;
      notifyListeners();

      // Remove entry after the card's fade animation completes (300ms)
      Timer(const Duration(milliseconds: 350), () {
        _jobs.removeWhere((j) => j.id == id);
        notifyListeners();
      });
    });
  }

  JobEntry? _findJob(int id) {
    try {
      return _jobs.firstWhere((j) => j.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    for (final job in _jobs) {
      job.hideTimer?.cancel();
    }
    super.dispose();
  }
}
