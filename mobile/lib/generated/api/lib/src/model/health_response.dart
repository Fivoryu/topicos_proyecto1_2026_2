//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:openapi/src/model/database_status.dart';
import 'package:openapi/src/model/health_status.dart';
import 'package:json_annotation/json_annotation.dart';

part 'health_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HealthResponse {
  /// Returns a new [HealthResponse] instance.
  HealthResponse({

    required  this.database,

    required  this.status,
  });

  @JsonKey(
    
    name: r'database',
    required: true,
    includeIfNull: false,
  )


  final DatabaseStatus database;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final HealthStatus status;





    @override
    bool operator ==(Object other) => identical(this, other) || other is HealthResponse &&
      other.database == database &&
      other.status == status;

    @override
    int get hashCode =>
        database.hashCode +
        status.hashCode;

  factory HealthResponse.fromJson(Map<String, dynamic> json) => _$HealthResponseFromJson(json);

  Map<String, dynamic> toJson() => _$HealthResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

