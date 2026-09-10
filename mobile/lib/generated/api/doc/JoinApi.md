# openapi.api.JoinApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**consumeJoinCodeApiV1GroupsJoinPost**](JoinApi.md#consumejoincodeapiv1groupsjoinpost) | **POST** /api/v1/groups/join | Consume Join Code
[**generateJoinCodeApiV1GroupsGroupIdJoinCodePost**](JoinApi.md#generatejoincodeapiv1groupsgroupidjoincodepost) | **POST** /api/v1/groups/{group_id}/join-code | Generate Join Code
[**getJoinCodeStatusApiV1GroupsGroupIdJoinCodeGet**](JoinApi.md#getjoincodestatusapiv1groupsgroupidjoincodeget) | **GET** /api/v1/groups/{group_id}/join-code | Get Join Code Status
[**regenerateJoinCodeApiV1GroupsGroupIdJoinCodeRegeneratePost**](JoinApi.md#regeneratejoincodeapiv1groupsgroupidjoincoderegeneratepost) | **POST** /api/v1/groups/{group_id}/join-code/regenerate | Regenerate Join Code
[**revokeJoinCodeApiV1GroupsGroupIdJoinCodeDelete**](JoinApi.md#revokejoincodeapiv1groupsgroupidjoincodedelete) | **DELETE** /api/v1/groups/{group_id}/join-code | Revoke Join Code


# **consumeJoinCodeApiV1GroupsJoinPost**
> JoinResponse consumeJoinCodeApiV1GroupsJoinPost(xCSRFToken, joinCodeConsumeRequest)

Consume Join Code

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getJoinApi();
final String xCSRFToken = xCSRFToken_example; // String | Must match the readable cc_csrf cookie.
final JoinCodeConsumeRequest joinCodeConsumeRequest = ; // JoinCodeConsumeRequest | 

try {
    final response = api.consumeJoinCodeApiV1GroupsJoinPost(xCSRFToken, joinCodeConsumeRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling JoinApi->consumeJoinCodeApiV1GroupsJoinPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xCSRFToken** | **String**| Must match the readable cc_csrf cookie. | 
 **joinCodeConsumeRequest** | [**JoinCodeConsumeRequest**](JoinCodeConsumeRequest.md)|  | 

### Return type

[**JoinResponse**](JoinResponse.md)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **generateJoinCodeApiV1GroupsGroupIdJoinCodePost**
> JoinCodeResponse generateJoinCodeApiV1GroupsGroupIdJoinCodePost(groupId, xCSRFToken)

Generate Join Code

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getJoinApi();
final String groupId = groupId_example; // String | 
final String xCSRFToken = xCSRFToken_example; // String | Must match the readable cc_csrf cookie.

try {
    final response = api.generateJoinCodeApiV1GroupsGroupIdJoinCodePost(groupId, xCSRFToken);
    print(response);
} catch on DioException (e) {
    print('Exception when calling JoinApi->generateJoinCodeApiV1GroupsGroupIdJoinCodePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 
 **xCSRFToken** | **String**| Must match the readable cc_csrf cookie. | 

### Return type

[**JoinCodeResponse**](JoinCodeResponse.md)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getJoinCodeStatusApiV1GroupsGroupIdJoinCodeGet**
> JoinCodeStatus getJoinCodeStatusApiV1GroupsGroupIdJoinCodeGet(groupId)

Get Join Code Status

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getJoinApi();
final String groupId = groupId_example; // String | 

try {
    final response = api.getJoinCodeStatusApiV1GroupsGroupIdJoinCodeGet(groupId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling JoinApi->getJoinCodeStatusApiV1GroupsGroupIdJoinCodeGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 

### Return type

[**JoinCodeStatus**](JoinCodeStatus.md)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **regenerateJoinCodeApiV1GroupsGroupIdJoinCodeRegeneratePost**
> JoinCodeResponse regenerateJoinCodeApiV1GroupsGroupIdJoinCodeRegeneratePost(groupId, xCSRFToken)

Regenerate Join Code

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getJoinApi();
final String groupId = groupId_example; // String | 
final String xCSRFToken = xCSRFToken_example; // String | Must match the readable cc_csrf cookie.

try {
    final response = api.regenerateJoinCodeApiV1GroupsGroupIdJoinCodeRegeneratePost(groupId, xCSRFToken);
    print(response);
} catch on DioException (e) {
    print('Exception when calling JoinApi->regenerateJoinCodeApiV1GroupsGroupIdJoinCodeRegeneratePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 
 **xCSRFToken** | **String**| Must match the readable cc_csrf cookie. | 

### Return type

[**JoinCodeResponse**](JoinCodeResponse.md)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **revokeJoinCodeApiV1GroupsGroupIdJoinCodeDelete**
> JoinCodeStatus revokeJoinCodeApiV1GroupsGroupIdJoinCodeDelete(groupId, xCSRFToken)

Revoke Join Code

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getJoinApi();
final String groupId = groupId_example; // String | 
final String xCSRFToken = xCSRFToken_example; // String | Must match the readable cc_csrf cookie.

try {
    final response = api.revokeJoinCodeApiV1GroupsGroupIdJoinCodeDelete(groupId, xCSRFToken);
    print(response);
} catch on DioException (e) {
    print('Exception when calling JoinApi->revokeJoinCodeApiV1GroupsGroupIdJoinCodeDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 
 **xCSRFToken** | **String**| Must match the readable cc_csrf cookie. | 

### Return type

[**JoinCodeStatus**](JoinCodeStatus.md)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

