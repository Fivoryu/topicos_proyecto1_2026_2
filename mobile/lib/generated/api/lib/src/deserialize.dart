import 'package:openapi/src/model/account_identity_response.dart';
import 'package:openapi/src/model/balance_participant_response.dart';
import 'package:openapi/src/model/balances_response.dart';
import 'package:openapi/src/model/error_response.dart';
import 'package:openapi/src/model/expense_beneficiary_response.dart';
import 'package:openapi/src/model/expense_contributor_request.dart';
import 'package:openapi/src/model/expense_contributor_response.dart';
import 'package:openapi/src/model/expense_response.dart';
import 'package:openapi/src/model/expense_write_request.dart';
import 'package:openapi/src/model/field_error.dart';
import 'package:openapi/src/model/group_response.dart';
import 'package:openapi/src/model/group_update_request.dart';
import 'package:openapi/src/model/health_response.dart';
import 'package:openapi/src/model/login_request.dart';
import 'package:openapi/src/model/participant_response.dart';
import 'package:openapi/src/model/participant_write_request.dart';
import 'package:openapi/src/model/rename_participant_request.dart';
import 'package:openapi/src/model/session_identity_response.dart';
import 'package:openapi/src/model/settlement_response.dart';
import 'package:openapi/src/model/settlement_transfer_response.dart';

final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

  ReturnType deserialize<ReturnType, BaseType>(dynamic value, String targetType, {bool growable= true}) {
      switch (targetType) {
        case 'String':
          return '$value' as ReturnType;
        case 'int':
          return (value is int ? value : int.parse('$value')) as ReturnType;
        case 'bool':
          if (value is bool) {
            return value as ReturnType;
          }
          final valueString = '$value'.toLowerCase();
          return (valueString == 'true' || valueString == '1') as ReturnType;
        case 'double':
          return (value is double ? value : double.parse('$value')) as ReturnType;
        case 'AccountIdentityResponse':
          return AccountIdentityResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BalanceParticipantResponse':
          return BalanceParticipantResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BalancesResponse':
          return BalancesResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DatabaseStatus':
          
          
        case 'ErrorResponse':
          return ErrorResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ExpenseBeneficiaryResponse':
          return ExpenseBeneficiaryResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ExpenseContributorRequest':
          return ExpenseContributorRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ExpenseContributorResponse':
          return ExpenseContributorResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ExpenseResponse':
          return ExpenseResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ExpenseWriteRequest':
          return ExpenseWriteRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'FieldError':
          return FieldError.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GroupResponse':
          return GroupResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GroupUpdateRequest':
          return GroupUpdateRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'HealthResponse':
          return HealthResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'HealthStatus':
          
          
        case 'LoginRequest':
          return LoginRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ParticipantResponse':
          return ParticipantResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ParticipantWriteRequest':
          return ParticipantWriteRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RenameParticipantRequest':
          return RenameParticipantRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SessionIdentityResponse':
          return SessionIdentityResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SettlementResponse':
          return SettlementResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SettlementTransferResponse':
          return SettlementTransferResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        default:
          RegExpMatch? match;

          if (value is List && (match = _regList.firstMatch(targetType)) != null) {
            targetType = match![1]!; // ignore: parameter_assignments
            return value
              .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable))
              .toList(growable: growable) as ReturnType;
          }
          if (value is Set && (match = _regSet.firstMatch(targetType)) != null) {
            targetType = match![1]!; // ignore: parameter_assignments
            return value
              .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable))
              .toSet() as ReturnType;
          }
          if (value is Map && (match = _regMap.firstMatch(targetType)) != null) {
            targetType = match![1]!.trim(); // ignore: parameter_assignments
            return Map<String, BaseType>.fromIterables(
              value.keys as Iterable<String>,
              value.values.map((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable)),
            ) as ReturnType;
          }
          break;
    }
    throw Exception('Cannot deserialize');
  }