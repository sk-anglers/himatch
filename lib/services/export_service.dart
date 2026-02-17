import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:himatch/models/schedule.dart';
import 'salary_calculator.dart';

/// Export schedules and salary data to various formats.
///
/// Supports iCal (.ics), CSV, and PDF export. Files are written to the
/// application documents directory.
class ExportService {
  static final DateFormat _dateFormat = DateFormat('yyyy/MM/dd');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _icalDateTimeFormat = DateFormat("yyyyMMdd'T'HHmmss");
  static final DateFormat _icalDateFormat = DateFormat('yyyyMMdd');

  /// Export schedules to iCal format string (RFC 5545).
  ///
  /// Returns a valid VCALENDAR string containing VEVENT entries.
  static String toICal(List<Schedule> schedules) {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//Himatch//Schedule//JA');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');
    buffer.writeln('X-WR-TIMEZONE:Asia/Tokyo');

    // Timezone definition
    buffer.writeln('BEGIN:VTIMEZONE');
    buffer.writeln('TZID:Asia/Tokyo');
    buffer.writeln('BEGIN:STANDARD');
    buffer.writeln('DTSTART:19700101T000000');
    buffer.writeln('TZOFFSETFROM:+0900');
    buffer.writeln('TZOFFSETTO:+0900');
    buffer.writeln('END:STANDARD');
    buffer.writeln('END:VTIMEZONE');

    for (final schedule in schedules) {
      buffer.writeln('BEGIN:VEVENT');
      buffer.writeln('UID:${schedule.id}@himatch.app');

      if (schedule.isAllDay) {
        buffer.writeln(
          'DTSTART;VALUE=DATE:${_icalDateFormat.format(schedule.startTime)}',
        );
        // All-day events end on the next day in iCal
        final endDate = schedule.endTime.add(const Duration(days: 1));
        buffer.writeln(
          'DTEND;VALUE=DATE:${_icalDateFormat.format(endDate)}',
        );
      } else {
        buffer.writeln(
          'DTSTART;TZID=Asia/Tokyo:${_icalDateTimeFormat.format(schedule.startTime)}',
        );
        buffer.writeln(
          'DTEND;TZID=Asia/Tokyo:${_icalDateTimeFormat.format(schedule.endTime)}',
        );
      }

      buffer.writeln('SUMMARY:${_escapeIcal(schedule.title)}');

      if (schedule.location != null && schedule.location!.isNotEmpty) {
        buffer.writeln('LOCATION:${_escapeIcal(schedule.location!)}');
      }

      if (schedule.memo != null && schedule.memo!.isNotEmpty) {
        buffer.writeln('DESCRIPTION:${_escapeIcal(schedule.memo!)}');
      }

      if (schedule.recurrenceRule != null &&
          schedule.recurrenceRule!.isNotEmpty) {
        // Ensure RRULE: prefix
        final rrule = schedule.recurrenceRule!.toUpperCase().startsWith('RRULE:')
            ? schedule.recurrenceRule!
            : 'RRULE:${schedule.recurrenceRule!}';
        buffer.writeln(rrule);
      }

      if (schedule.createdAt != null) {
        buffer.writeln(
          'DTSTAMP:${_icalDateTimeFormat.format(schedule.createdAt!)}Z',
        );
      } else {
        buffer.writeln(
          'DTSTAMP:${_icalDateTimeFormat.format(DateTime.now())}Z',
        );
      }

      buffer.writeln('END:VEVENT');
    }

    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  /// Export salary report to CSV file.
  ///
  /// Returns the file path of the generated CSV.
  static Future<String> salaryToCsv(
    SalaryReport report,
    String workplaceName,
    int year,
    int month,
  ) async {
    final rows = <List<dynamic>>[
      // Header
      ['勤務先', '年', '月', '出勤日数'],
      [workplaceName, year, month, report.workDays],
      [],
      // Hours breakdown
      ['項目', '時間', '金額（円）'],
      [
        '通常勤務',
        SalaryReport.formatMinutes(report.regularMinutes),
        report.regularPay,
      ],
      [
        '残業',
        SalaryReport.formatMinutes(report.overtimeMinutes),
        report.overtimePay,
      ],
      [
        '深夜手当',
        SalaryReport.formatMinutes(report.nightMinutes),
        report.nightPay,
      ],
      [
        '休日手当',
        SalaryReport.formatMinutes(report.holidayMinutes),
        report.holidayPay,
      ],
      [
        '交通費',
        '${report.workDays}日分',
        report.transportCost,
      ],
      [],
      ['合計', '', report.totalPay],
    ];

    final csvString = const ListToCsvConverter().convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'salary_${workplaceName}_${year}_${month.toString().padLeft(2, '0')}.csv';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsString(
      '\uFEFF$csvString', // BOM for Excel compatibility
      flush: true,
    );

    return filePath;
  }

  /// Export monthly work report to PDF file.
  ///
  /// Returns the file path of the generated PDF.
  static Future<String> workReportToPdf(
    List<Schedule> shifts,
    SalaryReport report,
    String workplaceName,
    int year,
    int month,
  ) async {
    final pdf = pw.Document();

    // Sort shifts by date
    final sortedShifts = List<Schedule>.from(shifts)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Filter to the target month
    final monthlyShifts = sortedShifts.where((s) {
      return s.startTime.year == year && s.startTime.month == month;
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildPdfHeader(workplaceName, year, month),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          // Shift detail table
          _buildShiftTable(monthlyShifts),
          pw.SizedBox(height: 20),
          // Salary summary
          _buildSalarySummary(report),
        ],
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'report_${workplaceName}_${year}_${month.toString().padLeft(2, '0')}.pdf';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save(), flush: true);

    return filePath;
  }

  // ── PDF building helpers ──

  static pw.Widget _buildPdfHeader(
    String workplaceName,
    int year,
    int month,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$year/$month Work Report',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            workplaceName,
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.Divider(),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Page ${context.pageNumber} / ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  static pw.Widget _buildShiftTable(List<Schedule> shifts) {
    final rows = <pw.TableRow>[
      // Header row
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          color: PdfColor.fromInt(0xFFE0E0E0),
        ),
        children: [
          _tableCell('Date', isHeader: true),
          _tableCell('Start', isHeader: true),
          _tableCell('End', isHeader: true),
          _tableCell('Hours', isHeader: true),
          _tableCell('Title', isHeader: true),
        ],
      ),
    ];

    for (final shift in shifts) {
      final duration = shift.endTime.difference(shift.startTime);
      final hours = duration.inMinutes / 60.0;

      rows.add(
        pw.TableRow(
          children: [
            _tableCell(_dateFormat.format(shift.startTime)),
            _tableCell(
              shift.isAllDay ? 'All Day' : _timeFormat.format(shift.startTime),
            ),
            _tableCell(
              shift.isAllDay ? '' : _timeFormat.format(shift.endTime),
            ),
            _tableCell(
              shift.isAllDay ? '-' : hours.toStringAsFixed(1),
            ),
            _tableCell(shift.title),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColor.fromInt(0xFF999999),
        width: 0.5,
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1.5),
        2: pw.FlexColumnWidth(1.5),
        3: pw.FlexColumnWidth(1),
        4: pw.FlexColumnWidth(3),
      },
      children: rows,
    );
  }

  static pw.Widget _buildSalarySummary(SalaryReport report) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColor.fromInt(0xFF333333),
          width: 1,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Salary Summary',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          _summaryRow(
            'Work Days',
            '${report.workDays} days',
          ),
          _summaryRow(
            'Regular',
            '${SalaryReport.formatMinutes(report.regularMinutes)}  /  ${report.regularPay} yen',
          ),
          _summaryRow(
            'Overtime',
            '${SalaryReport.formatMinutes(report.overtimeMinutes)}  /  ${report.overtimePay} yen',
          ),
          _summaryRow(
            'Night',
            '${SalaryReport.formatMinutes(report.nightMinutes)}  /  ${report.nightPay} yen',
          ),
          _summaryRow(
            'Holiday',
            '${SalaryReport.formatMinutes(report.holidayMinutes)}  /  ${report.holidayPay} yen',
          ),
          _summaryRow(
            'Transport',
            '${report.transportCost} yen',
          ),
          pw.Divider(),
          _summaryRow(
            'TOTAL',
            '${report.totalPay} yen',
            bold: true,
          ),
        ],
      ),
    );
  }

  static pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _summaryRow(
    String label,
    String value, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// Escape special characters for iCal text values.
  static String _escapeIcal(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll(';', '\\;')
        .replaceAll(',', '\\,')
        .replaceAll('\n', '\\n');
  }
}
