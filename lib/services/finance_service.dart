import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';

final financeServiceProvider = Provider<FinanceService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return FinanceService(dioClient.dio);
});

class FinanceService {
  final Dio _dio;

  FinanceService(this._dio);

  /// Get all charges for a student with summary
  Future<StudentCharges> getStudentCharges(int studentId) async {
    final response =
        await _dio.get('/finance/charges/student/$studentId');
    final data = response.data as Map<String, dynamic>;
    return StudentCharges.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// Get only pending charges for a student
  Future<StudentCharges> getStudentPendingCharges(int studentId) async {
    final response =
        await _dio.get('/finance/charges/student/$studentId/pending');
    final data = response.data as Map<String, dynamic>;
    return StudentCharges.fromJson(data['data'] as Map<String, dynamic>);
  }
}

// ── Models ──

class StudentCharges {
  final List<Charge> charges;
  final ChargeSummary summary;

  const StudentCharges({required this.charges, required this.summary});

  factory StudentCharges.fromJson(Map<String, dynamic> json) {
    return StudentCharges(
      charges: (json['charges'] as List<dynamic>?)
              ?.map((e) => Charge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      summary: json['summary'] != null
          ? ChargeSummary.fromJson(json['summary'] as Map<String, dynamic>)
          : const ChargeSummary(
              totalCharged: 0, totalPaid: 0, totalPending: 0),
    );
  }
}

class Charge {
  final int id;
  final int conceptId;
  final String description;
  final double originalAmount;
  final double discountAmount;
  final double amountDue;
  final double amountPaid;
  final double balance;
  final String? dueDate;
  final String status;
  final int? installmentNumber;
  final String? conceptName;
  final String? conceptCode;

  const Charge({
    required this.id,
    required this.conceptId,
    required this.description,
    this.originalAmount = 0,
    this.discountAmount = 0,
    this.amountDue = 0,
    this.amountPaid = 0,
    this.balance = 0,
    this.dueDate,
    this.status = 'pending',
    this.installmentNumber,
    this.conceptName,
    this.conceptCode,
  });

  static int _toInt(dynamic v, [int fallback = 0]) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? fallback;
  static int? _toIntNullable(dynamic v) =>
      v == null ? null : (v is int ? v : int.tryParse(v.toString()));

  factory Charge.fromJson(Map<String, dynamic> json) {
    return Charge(
      id: _toInt(json['id']),
      conceptId: _toInt(json['concept_id']),
      description: json['description'] as String? ?? '',
      originalAmount: (json['original_amount'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      amountDue: (json['amount_due'] as num?)?.toDouble() ?? 0,
      amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      dueDate: json['due_date'] as String?,
      status: json['status'] as String? ?? 'pending',
      installmentNumber: _toIntNullable(json['installment_number']),
      conceptName: json['concept_name'] as String?,
      conceptCode: json['concept_code'] as String?,
    );
  }
}

class ChargeSummary {
  final double totalCharged;
  final double totalPaid;
  final double totalPending;

  const ChargeSummary({
    required this.totalCharged,
    required this.totalPaid,
    required this.totalPending,
  });

  factory ChargeSummary.fromJson(Map<String, dynamic> json) {
    return ChargeSummary(
      totalCharged: (json['total_charged'] as num?)?.toDouble() ?? 0,
      totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0,
      totalPending: (json['total_pending'] as num?)?.toDouble() ?? 0,
    );
  }
}
