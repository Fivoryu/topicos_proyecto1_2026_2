# openapi.api.GroupsApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getGroupApiV1GroupsGroupIdGet**](GroupsApi.md#getgroupapiv1groupsgroupidget) | **GET** /api/v1/groups/{group_id} | Get Group
[**updateGroupApiV1GroupsGroupIdPatch**](GroupsApi.md#updategroupapiv1groupsgroupidpatch) | **PATCH** /api/v1/groups/{group_id} | Update Group


# **getGroupApiV1GroupsGroupIdGet**
> GroupResponse getGroupApiV1GroupsGroupIdGet(groupId)

Get Group

Return the authenticated group's server-owned settings.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getGroupsApi();
final String groupId = groupId_example; // String | 

try {
    final response = api.getGroupApiV1GroupsGroupIdGet(groupId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling GroupsApi->getGroupApiV1GroupsGroupIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 

### Return type

[**GroupResponse**](GroupResponse.md)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateGroupApiV1GroupsGroupIdPatch**
> GroupResponse updateGroupApiV1GroupsGroupIdPatch(groupId, xCSRFToken, groupUpdateRequest)

Update Group

Update only settlement policy; authorization remains in GroupService.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getGroupsApi();
final String groupId = groupId_example; // String | 
final String xCSRFToken = xCSRFToken_example; // String | Must match the readable cc_csrf cookie.
final GroupUpdateRequest groupUpdateRequest = ; // GroupUpdateRequest | 

try {
    final response = api.updateGroupApiV1GroupsGroupIdPatch(groupId, xCSRFToken, groupUpdateRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling GroupsApi->updateGroupApiV1GroupsGroupIdPatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 
 **xCSRFToken** | **String**| Must match the readable cc_csrf cookie. | 
 **groupUpdateRequest** | [**GroupUpdateRequest**](GroupUpdateRequest.md)|  | 

### Return type

[**GroupResponse**](GroupResponse.md)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

