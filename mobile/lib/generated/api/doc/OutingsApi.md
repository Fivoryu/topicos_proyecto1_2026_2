# openapi.api.OutingsApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**archiveOutingApiV1GroupsGroupIdOutingsOutingIdArchivePost**](OutingsApi.md#archiveoutingapiv1groupsgroupidoutingsoutingidarchivepost) | **POST** /api/v1/groups/{group_id}/outings/{outing_id}/archive | Archive Outing
[**createOutingApiV1GroupsGroupIdOutingsPost**](OutingsApi.md#createoutingapiv1groupsgroupidoutingspost) | **POST** /api/v1/groups/{group_id}/outings | Create Outing
[**deleteOutingApiV1GroupsGroupIdOutingsOutingIdDelete**](OutingsApi.md#deleteoutingapiv1groupsgroupidoutingsoutingiddelete) | **DELETE** /api/v1/groups/{group_id}/outings/{outing_id} | Delete Outing
[**editOutingApiV1GroupsGroupIdOutingsOutingIdPatch**](OutingsApi.md#editoutingapiv1groupsgroupidoutingsoutingidpatch) | **PATCH** /api/v1/groups/{group_id}/outings/{outing_id} | Edit Outing
[**getOutingApiV1GroupsGroupIdOutingsOutingIdGet**](OutingsApi.md#getoutingapiv1groupsgroupidoutingsoutingidget) | **GET** /api/v1/groups/{group_id}/outings/{outing_id} | Get Outing
[**listOutingsApiV1GroupsGroupIdOutingsGet**](OutingsApi.md#listoutingsapiv1groupsgroupidoutingsget) | **GET** /api/v1/groups/{group_id}/outings | List Outings
[**unarchiveOutingApiV1GroupsGroupIdOutingsOutingIdUnarchivePost**](OutingsApi.md#unarchiveoutingapiv1groupsgroupidoutingsoutingidunarchivepost) | **POST** /api/v1/groups/{group_id}/outings/{outing_id}/unarchive | Unarchive Outing


# **archiveOutingApiV1GroupsGroupIdOutingsOutingIdArchivePost**
> OutingResponse archiveOutingApiV1GroupsGroupIdOutingsOutingIdArchivePost(groupId, outingId, xCSRFToken)

Archive Outing

Archive an outing as a server-authorized owner operation.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getOutingsApi();
final String groupId = groupId_example; // String | 
final String outingId = outingId_example; // String | 
final String xCSRFToken = xCSRFToken_example; // String | Must match the readable cc_csrf cookie.

try {
    final response = api.archiveOutingApiV1GroupsGroupIdOutingsOutingIdArchivePost(groupId, outingId, xCSRFToken);
    print(response);
} catch on DioException (e) {
    print('Exception when calling OutingsApi->archiveOutingApiV1GroupsGroupIdOutingsOutingIdArchivePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 
 **outingId** | **String**|  | 
 **xCSRFToken** | **String**| Must match the readable cc_csrf cookie. | 

### Return type

[**OutingResponse**](OutingResponse.md)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createOutingApiV1GroupsGroupIdOutingsPost**
> OutingResponse createOutingApiV1GroupsGroupIdOutingsPost(groupId, xCSRFToken, outingWriteRequest)

Create Outing

Create an active outing for any active group member.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getOutingsApi();
final String groupId = groupId_example; // String | 
final String xCSRFToken = xCSRFToken_example; // String | Must match the readable cc_csrf cookie.
final OutingWriteRequest outingWriteRequest = ; // OutingWriteRequest | 

try {
    final response = api.createOutingApiV1GroupsGroupIdOutingsPost(groupId, xCSRFToken, outingWriteRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling OutingsApi->createOutingApiV1GroupsGroupIdOutingsPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 
 **xCSRFToken** | **String**| Must match the readable cc_csrf cookie. | 
 **outingWriteRequest** | [**OutingWriteRequest**](OutingWriteRequest.md)|  | 

### Return type

[**OutingResponse**](OutingResponse.md)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteOutingApiV1GroupsGroupIdOutingsOutingIdDelete**
> deleteOutingApiV1GroupsGroupIdOutingsOutingIdDelete(groupId, outingId, xCSRFToken)

Delete Outing

Delete an empty active outing as its server-authorized owner.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getOutingsApi();
final String groupId = groupId_example; // String | 
final String outingId = outingId_example; // String | 
final String xCSRFToken = xCSRFToken_example; // String | Must match the readable cc_csrf cookie.

try {
    api.deleteOutingApiV1GroupsGroupIdOutingsOutingIdDelete(groupId, outingId, xCSRFToken);
} catch on DioException (e) {
    print('Exception when calling OutingsApi->deleteOutingApiV1GroupsGroupIdOutingsOutingIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 
 **outingId** | **String**|  | 
 **xCSRFToken** | **String**| Must match the readable cc_csrf cookie. | 

### Return type

void (empty response body)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **editOutingApiV1GroupsGroupIdOutingsOutingIdPatch**
> OutingResponse editOutingApiV1GroupsGroupIdOutingsOutingIdPatch(groupId, outingId, xCSRFToken, outingWriteRequest)

Edit Outing

Edit only the name of an active outing.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getOutingsApi();
final String groupId = groupId_example; // String | 
final String outingId = outingId_example; // String | 
final String xCSRFToken = xCSRFToken_example; // String | Must match the readable cc_csrf cookie.
final OutingWriteRequest outingWriteRequest = ; // OutingWriteRequest | 

try {
    final response = api.editOutingApiV1GroupsGroupIdOutingsOutingIdPatch(groupId, outingId, xCSRFToken, outingWriteRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling OutingsApi->editOutingApiV1GroupsGroupIdOutingsOutingIdPatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 
 **outingId** | **String**|  | 
 **xCSRFToken** | **String**| Must match the readable cc_csrf cookie. | 
 **outingWriteRequest** | [**OutingWriteRequest**](OutingWriteRequest.md)|  | 

### Return type

[**OutingResponse**](OutingResponse.md)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getOutingApiV1GroupsGroupIdOutingsOutingIdGet**
> OutingResponse getOutingApiV1GroupsGroupIdOutingsOutingIdGet(groupId, outingId)

Get Outing

Read an active or archived outing in the requested group.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getOutingsApi();
final String groupId = groupId_example; // String | 
final String outingId = outingId_example; // String | 

try {
    final response = api.getOutingApiV1GroupsGroupIdOutingsOutingIdGet(groupId, outingId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling OutingsApi->getOutingApiV1GroupsGroupIdOutingsOutingIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 
 **outingId** | **String**|  | 

### Return type

[**OutingResponse**](OutingResponse.md)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listOutingsApiV1GroupsGroupIdOutingsGet**
> List<OutingResponse> listOutingsApiV1GroupsGroupIdOutingsGet(groupId)

List Outings

List active and archived outings in stable creation order.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getOutingsApi();
final String groupId = groupId_example; // String | 

try {
    final response = api.listOutingsApiV1GroupsGroupIdOutingsGet(groupId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling OutingsApi->listOutingsApiV1GroupsGroupIdOutingsGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 

### Return type

[**List&lt;OutingResponse&gt;**](OutingResponse.md)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **unarchiveOutingApiV1GroupsGroupIdOutingsOutingIdUnarchivePost**
> OutingResponse unarchiveOutingApiV1GroupsGroupIdOutingsOutingIdUnarchivePost(groupId, outingId, xCSRFToken)

Unarchive Outing

Restore an archived outing to active state as its owner.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getOutingsApi();
final String groupId = groupId_example; // String | 
final String outingId = outingId_example; // String | 
final String xCSRFToken = xCSRFToken_example; // String | Must match the readable cc_csrf cookie.

try {
    final response = api.unarchiveOutingApiV1GroupsGroupIdOutingsOutingIdUnarchivePost(groupId, outingId, xCSRFToken);
    print(response);
} catch on DioException (e) {
    print('Exception when calling OutingsApi->unarchiveOutingApiV1GroupsGroupIdOutingsOutingIdUnarchivePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 
 **outingId** | **String**|  | 
 **xCSRFToken** | **String**| Must match the readable cc_csrf cookie. | 

### Return type

[**OutingResponse**](OutingResponse.md)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

