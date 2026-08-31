//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum HealthStatus {
      @JsonValue(r'ok')
      ok(r'ok'),
      @JsonValue(r'error')
      error(r'error');

  const HealthStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
