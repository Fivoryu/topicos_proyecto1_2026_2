//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:openapi/src/model/balance_participant_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'balances_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BalancesResponse {
  /// Returns a new [BalancesResponse] instance.
  BalancesResponse({

    required  this.groupId,

    required  this.participants,
  });

  @JsonKey(
    
    name: r'group_id',
    required: true,
    includeIfNull: false,
  )


  final String groupId;



  @JsonKey(
    
    name: r'participants',
    required: true,
    includeIfNull: false,
  )


  final List<BalanceParticipantResponse> participants;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BalancesResponse &&
      other.groupId == groupId &&
      other.participants == participants;

    @override
    int get hashCode =>
        groupId.hashCode +
        participants.hashCode;

  factory BalancesResponse.fromJson(Map<String, dynamic> json) => _$BalancesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BalancesResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

