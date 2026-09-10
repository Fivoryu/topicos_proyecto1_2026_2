# openapi.api.MembershipsApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**leaveGroupApiV1GroupsGroupIdLeavePost**](MembershipsApi.md#leavegroupapiv1groupsgroupidleavepost) | **POST** /api/v1/groups/{group_id}/leave | Leave Group
[**listMembersApiV1GroupsGroupIdMembersGet**](MembershipsApi.md#listmembersapiv1groupsgroupidmembersget) | **GET** /api/v1/groups/{group_id}/members | List Members
[**removeMemberApiV1GroupsGroupIdMembersAccountIdDelete**](MembershipsApi.md#removememberapiv1groupsgroupidmembersaccountiddelete) | **DELETE** /api/v1/groups/{group_id}/members/{account_id} | Remove Member


# **leaveGroupApiV1GroupsGroupIdLeavePost**
> leaveGroupApiV1GroupsGroupIdLeavePost(groupId, xCSRFToken)

Leave Group

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getMembershipsApi();
final String groupId = groupId_example; // String | 
final String xCSRFToken = xCSRFToken_example; // String | Must match the readable cc_csrf cookie.

try {
    api.leaveGroupApiV1GroupsGroupIdLeavePost(groupId, xCSRFToken);
} catch on DioException (e) {
    print('Exception when calling MembershipsApi->leaveGroupApiV1GroupsGroupIdLeavePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 
 **xCSRFToken** | **String**| Must match the readable cc_csrf cookie. | 

### Return type

void (empty response body)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMembersApiV1GroupsGroupIdMembersGet**
> List<MemberResponse> listMembersApiV1GroupsGroupIdMembersGet(groupId)

List Members

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getMembershipsApi();
final String groupId = groupId_example; // String | 

try {
    final response = api.listMembersApiV1GroupsGroupIdMembersGet(groupId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling MembershipsApi->listMembersApiV1GroupsGroupIdMembersGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 

### Return type

[**List&lt;MemberResponse&gt;**](MemberResponse.md)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **removeMemberApiV1GroupsGroupIdMembersAccountIdDelete**
> removeMemberApiV1GroupsGroupIdMembersAccountIdDelete(groupId, accountId, xCSRFToken)

Remove Member

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getMembershipsApi();
final String groupId = groupId_example; // String | 
final String accountId = accountId_example; // String | 
final String xCSRFToken = xCSRFToken_example; // String | Must match the readable cc_csrf cookie.

try {
    api.removeMemberApiV1GroupsGroupIdMembersAccountIdDelete(groupId, accountId, xCSRFToken);
} catch on DioException (e) {
    print('Exception when calling MembershipsApi->removeMemberApiV1GroupsGroupIdMembersAccountIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 
 **accountId** | **String**|  | 
 **xCSRFToken** | **String**| Must match the readable cc_csrf cookie. | 

### Return type

void (empty response body)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

