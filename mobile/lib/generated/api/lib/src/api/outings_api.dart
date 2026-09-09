//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

// ignore: unused_import
import 'dart:convert';
import 'package:openapi/src/deserialize.dart';
import 'package:dio/dio.dart';

// ignore: unused_import
import 'package:openapi/src/model/error_response.dart';
import 'package:openapi/src/model/outing_response.dart';
import 'package:openapi/src/model/outing_write_request.dart';

class OutingsApi {

  final Dio _dio;

  const OutingsApi(this._dio);

  /// Archive Outing
  /// Archive an outing as a server-authorized owner operation.
  ///
  /// Parameters:
  /// * [groupId] 
  /// * [outingId] 
  /// * [xCSRFToken] - Must match the readable cc_csrf cookie.
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [OutingResponse] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<OutingResponse>> archiveOutingApiV1GroupsGroupIdOutingsOutingIdArchivePost({ 
    required String groupId,
    required String outingId,
    required String xCSRFToken,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/api/v1/groups/{group_id}/outings/{outing_id}/archive'.replaceAll('{' r'group_id' '}', groupId.toString()).replaceAll('{' r'outing_id' '}', outingId.toString());
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{
        r'X-CSRF-Token': xCSRFToken,
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'apiKey',
            'name': 'cc_session',
            'keyName': 'cc_session',
            'where': '',
          },
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    OutingResponse? _responseData;

    try {
final rawData = _response.data;
_responseData = rawData == null ? null : deserialize<OutingResponse, OutingResponse>(rawData, 'OutingResponse', growable: true);
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<OutingResponse>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// Create Outing
  /// Create an active outing for any active group member.
  ///
  /// Parameters:
  /// * [groupId] 
  /// * [xCSRFToken] - Must match the readable cc_csrf cookie.
  /// * [outingWriteRequest] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [OutingResponse] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<OutingResponse>> createOutingApiV1GroupsGroupIdOutingsPost({ 
    required String groupId,
    required String xCSRFToken,
    required OutingWriteRequest outingWriteRequest,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/api/v1/groups/{group_id}/outings'.replaceAll('{' r'group_id' '}', groupId.toString());
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{
        r'X-CSRF-Token': xCSRFToken,
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'apiKey',
            'name': 'cc_session',
            'keyName': 'cc_session',
            'where': '',
          },
        ],
        ...?extra,
      },
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
_bodyData=jsonEncode(outingWriteRequest);
    } catch(error, stackTrace) {
      throw DioException(
         requestOptions: _options.compose(
          _dio.options,
          _path,
        ),
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    final _response = await _dio.request<Object>(
      _path,
      data: _bodyData,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    OutingResponse? _responseData;

    try {
final rawData = _response.data;
_responseData = rawData == null ? null : deserialize<OutingResponse, OutingResponse>(rawData, 'OutingResponse', growable: true);
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<OutingResponse>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// Delete Outing
  /// Delete an empty active outing as its server-authorized owner.
  ///
  /// Parameters:
  /// * [groupId] 
  /// * [outingId] 
  /// * [xCSRFToken] - Must match the readable cc_csrf cookie.
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future]
  /// Throws [DioException] if API call or serialization fails
  Future<Response<void>> deleteOutingApiV1GroupsGroupIdOutingsOutingIdDelete({ 
    required String groupId,
    required String outingId,
    required String xCSRFToken,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/api/v1/groups/{group_id}/outings/{outing_id}'.replaceAll('{' r'group_id' '}', groupId.toString()).replaceAll('{' r'outing_id' '}', outingId.toString());
    final _options = Options(
      method: r'DELETE',
      headers: <String, dynamic>{
        r'X-CSRF-Token': xCSRFToken,
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'apiKey',
            'name': 'cc_session',
            'keyName': 'cc_session',
            'where': '',
          },
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    return _response;
  }

  /// Edit Outing
  /// Edit only the name of an active outing.
  ///
  /// Parameters:
  /// * [groupId] 
  /// * [outingId] 
  /// * [xCSRFToken] - Must match the readable cc_csrf cookie.
  /// * [outingWriteRequest] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [OutingResponse] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<OutingResponse>> editOutingApiV1GroupsGroupIdOutingsOutingIdPatch({ 
    required String groupId,
    required String outingId,
    required String xCSRFToken,
    required OutingWriteRequest outingWriteRequest,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/api/v1/groups/{group_id}/outings/{outing_id}'.replaceAll('{' r'group_id' '}', groupId.toString()).replaceAll('{' r'outing_id' '}', outingId.toString());
    final _options = Options(
      method: r'PATCH',
      headers: <String, dynamic>{
        r'X-CSRF-Token': xCSRFToken,
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'apiKey',
            'name': 'cc_session',
            'keyName': 'cc_session',
            'where': '',
          },
        ],
        ...?extra,
      },
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
_bodyData=jsonEncode(outingWriteRequest);
    } catch(error, stackTrace) {
      throw DioException(
         requestOptions: _options.compose(
          _dio.options,
          _path,
        ),
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    final _response = await _dio.request<Object>(
      _path,
      data: _bodyData,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    OutingResponse? _responseData;

    try {
final rawData = _response.data;
_responseData = rawData == null ? null : deserialize<OutingResponse, OutingResponse>(rawData, 'OutingResponse', growable: true);
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<OutingResponse>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// Get Outing
  /// Read an active or archived outing in the requested group.
  ///
  /// Parameters:
  /// * [groupId] 
  /// * [outingId] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [OutingResponse] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<OutingResponse>> getOutingApiV1GroupsGroupIdOutingsOutingIdGet({ 
    required String groupId,
    required String outingId,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/api/v1/groups/{group_id}/outings/{outing_id}'.replaceAll('{' r'group_id' '}', groupId.toString()).replaceAll('{' r'outing_id' '}', outingId.toString());
    final _options = Options(
      method: r'GET',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'apiKey',
            'name': 'cc_session',
            'keyName': 'cc_session',
            'where': '',
          },
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    OutingResponse? _responseData;

    try {
final rawData = _response.data;
_responseData = rawData == null ? null : deserialize<OutingResponse, OutingResponse>(rawData, 'OutingResponse', growable: true);
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<OutingResponse>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// List Outings
  /// List active and archived outings in stable creation order.
  ///
  /// Parameters:
  /// * [groupId] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [List<OutingResponse>] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<List<OutingResponse>>> listOutingsApiV1GroupsGroupIdOutingsGet({ 
    required String groupId,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/api/v1/groups/{group_id}/outings'.replaceAll('{' r'group_id' '}', groupId.toString());
    final _options = Options(
      method: r'GET',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'apiKey',
            'name': 'cc_session',
            'keyName': 'cc_session',
            'where': '',
          },
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    List<OutingResponse>? _responseData;

    try {
final rawData = _response.data;
_responseData = rawData == null ? null : deserialize<List<OutingResponse>, OutingResponse>(rawData, 'List<OutingResponse>', growable: true);
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<List<OutingResponse>>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// Unarchive Outing
  /// Restore an archived outing to active state as its owner.
  ///
  /// Parameters:
  /// * [groupId] 
  /// * [outingId] 
  /// * [xCSRFToken] - Must match the readable cc_csrf cookie.
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [OutingResponse] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<OutingResponse>> unarchiveOutingApiV1GroupsGroupIdOutingsOutingIdUnarchivePost({ 
    required String groupId,
    required String outingId,
    required String xCSRFToken,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/api/v1/groups/{group_id}/outings/{outing_id}/unarchive'.replaceAll('{' r'group_id' '}', groupId.toString()).replaceAll('{' r'outing_id' '}', outingId.toString());
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{
        r'X-CSRF-Token': xCSRFToken,
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'apiKey',
            'name': 'cc_session',
            'keyName': 'cc_session',
            'where': '',
          },
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    OutingResponse? _responseData;

    try {
final rawData = _response.data;
_responseData = rawData == null ? null : deserialize<OutingResponse, OutingResponse>(rawData, 'OutingResponse', growable: true);
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<OutingResponse>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

}
