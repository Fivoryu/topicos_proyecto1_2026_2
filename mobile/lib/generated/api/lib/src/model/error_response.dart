//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:openapi/src/model/field_error.dart';
import 'package:json_annotation/json_annotation.dart';

part 'error_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ErrorResponse {
  /// Returns a new [ErrorResponse] instance.
  ErrorResponse({

    required  this.errorCode,

     this.fieldErrors,

    required  this.message,
  });

  @JsonKey(
    
    name: r'error_code',
    required: true,
    includeIfNull: false,
  )


  final String errorCode;



  @JsonKey(
    
    name: r'field_errors',
    required: false,
    includeIfNull: false,
  )


  final List<FieldError>? fieldErrors;



  @JsonKey(
    
    name: r'message',
    required: true,
    includeIfNull: false,
  )


  final String message;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ErrorResponse &&
      other.errorCode == errorCode &&
      other.fieldErrors == fieldErrors &&
      other.message == message;

    @override
    int get hashCode =>
        errorCode.hashCode +
        fieldErrors.hashCode +
        message.hashCode;

  factory ErrorResponse.fromJson(Map<String, dynamic> json) => _$ErrorResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ErrorResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

