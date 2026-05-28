import 'package:flutter/material.dart';
import '../database/hive_service.dart';
import '../models/monthly_report.dart';

class ReportProvider extends ChangeNotifier {
  List<MonthlyReport> _reports = [];

  List<MonthlyReport> get reports => _reports;

  ReportProvider() {
    loadReports();
  }

  void loadReports() {
    _reports = HiveService.getAllReports();
    notifyListeners();
  }

  MonthlyReport? getReportForMonth(int month, int year) {
    return HiveService.getReportForMonth(month, year);
  }
}
