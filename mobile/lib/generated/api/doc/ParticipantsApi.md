# openapi.api.ParticipantsApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**addParticipantApiV1GroupsGroupIdParticipantsPost**](ParticipantsApi.md#addparticipantapiv1groupsgroupidparticipantspost) | **POST** /api/v1/groups/{group_id}/participants | Add Participant
[**archiveParticipantApiV1GroupsGroupIdParticipantsParticipantIdArchivePost**](ParticipantsApi.md#archiveparticipantapiv1groupsgroupidparticipantsparticipantidarchivepost) | **POST** /api/v1/groups/{group_id}/participants/{participant_id}/archive | Archive Participant
[**deleteParticipantApiV1GroupsGroupIdParticipantsParticipantIdDelete**](ParticipantsApi.md#deleteparticipantapiv1groupsgroupidparticipantsparticipantiddelete) | **DELETE** /api/v1/groups/{group_id}/participants/{participant_id} | Delete Participant
[**listParticipantsApiV1GroupsGroupIdParticipantsGet**](ParticipantsApi.md#listparticipantsapiv1groupsgroupidparticipantsget) | **GET** /api/v1/groups/{group_id}/participants | List Participants
[**reactivateParticipantApiV1GroupsGroupIdParticipantsParticipantIdReactivatePost**](ParticipantsApi.md#reactivateparticipantapiv1groupsgroupidparticipantsparticipantidreactivatepost) | **POST** /api/v1/groups/{group_id}/participants/{participant_id}/reactivate | Reactivate Participant
[**renameParticipantApiV1GroupsGroupIdParticipantsParticipantIdPatch**](ParticipantsApi.md#renameparticipantapiv1groupsgroupidparticipantsparticipantidpatch) | **PATCH** /api/v1/groups/{group_id}/participants/{participant_id} | Rename Participant


# **addParticipantApiV1GroupsGroupIdParticipantsPost**
> ParticipantResponse addParticipantApiV1GroupsGroupIdParticipantsPost(groupId, xCSRFToken, participantWriteRequest)

Add Participant

Add a normalized, group-scoped participant.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getParticipantsApi();
final String groupId = groupId_example; // String | 
final String xCSRFToken = xCSRFToken_example; // String | Must match the readable cc_csrf cookie.
final ParticipantWriteRequest participantWriteRequest = ; // ParticipantWriteRequest | 

try {
    final response = api.addParticipantApiV1GroupsGroupIdParticipantsPost(groupId, xCSRFToken, participantWriteRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ParticipantsApi->addParticipantApiV1GroupsGroupIdParticipantsPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 
 **xCSRFToken** | **String**| Must match the readable cc_csrf cookie. | 
 **participantWriteRequest** | [**ParticipantWriteRequest**](ParticipantWriteRequest.md)|  | 

### Return type

[**ParticipantResponse**](ParticipantResponse.md)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **archiveParticipantApiV1GroupsGroupIdParticipantsParticipantIdArchivePost**
> ParticipantResponse archiveParticipantApiV1GroupsGroupIdParticipantsParticipantIdArchivePost(groupId, participantId, xCSRFToken)

Archive Participant

Archive a participant without deleting historical references.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getParticipantsApi();
final String groupId = groupId_example; // String | 
final String participantId = participantId_example; // String | 
final String xCSRFToken = xCSRFToken_example; // String | Must match the readable cc_csrf cookie.

try {
    final response = api.archiveParticipantApiV1GroupsGroupIdParticipantsParticipantIdArchivePost(groupId, participantId, xCSRFToken);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ParticipantsApi->archiveParticipantApiV1GroupsGroupIdParticipantsParticipantIdArchivePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 
 **participantId** | **String**|  | 
 **xCSRFToken** | **String**| Must match the readable cc_csrf cookie. | 

### Return type

[**ParticipantResponse**](ParticipantResponse.md)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteParticipantApiV1GroupsGroupIdParticipantsParticipantIdDelete**
> deleteParticipantApiV1GroupsGroupIdParticipantsParticipantIdDelete(groupId, participantId, xCSRFToken)

Delete Participant

Physically delete only a never-referenced participant.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getParticipantsApi();
final String groupId = groupId_example; // String | 
final String participantId = participantId_example; // String | 
final String xCSRFToken = xCSRFToken_example; // String | Must match the readable cc_csrf cookie.

try {
    api.deleteParticipantApiV1GroupsGroupIdParticipantsParticipantIdDelete(groupId, participantId, xCSRFToken);
} catch on DioException (e) {
    print('Exception when calling ParticipantsApi->deleteParticipantApiV1GroupsGroupIdParticipantsParticipantIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 
 **participantId** | **String**|  | 
 **xCSRFToken** | **String**| Must match the readable cc_csrf cookie. | 

### Return type

void (empty response body)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listParticipantsApiV1GroupsGroupIdParticipantsGet**
> List<ParticipantResponse> listParticipantsApiV1GroupsGroupIdParticipantsGet(groupId)

List Participants

List active and archived participants in stable creation order.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getParticipantsApi();
final String groupId = groupId_example; // String | 

try {
    final response = api.listParticipantsApiV1GroupsGroupIdParticipantsGet(groupId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ParticipantsApi->listParticipantsApiV1GroupsGroupIdParticipantsGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 

### Return type

[**List&lt;ParticipantResponse&gt;**](ParticipantResponse.md)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **reactivateParticipantApiV1GroupsGroupIdParticipantsParticipantIdReactivatePost**
> ParticipantResponse reactivateParticipantApiV1GroupsGroupIdParticipantsParticipantIdReactivatePost(groupId, participantId, xCSRFToken)

Reactivate Participant

Reactivate an archived participant.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getParticipantsApi();
final String groupId = groupId_example; // String | 
final String participantId = participantId_example; // String | 
final String xCSRFToken = xCSRFToken_example; // String | Must match the readable cc_csrf cookie.

try {
    final response = api.reactivateParticipantApiV1GroupsGroupIdParticipantsParticipantIdReactivatePost(groupId, participantId, xCSRFToken);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ParticipantsApi->reactivateParticipantApiV1GroupsGroupIdParticipantsParticipantIdReactivatePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 
 **participantId** | **String**|  | 
 **xCSRFToken** | **String**| Must match the readable cc_csrf cookie. | 

### Return type

[**ParticipantResponse**](ParticipantResponse.md)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **renameParticipantApiV1GroupsGroupIdParticipantsParticipantIdPatch**
> ParticipantResponse renameParticipantApiV1GroupsGroupIdParticipantsParticipantIdPatch(groupId, participantId, xCSRFToken, renameParticipantRequest)

Rename Participant

Rename only the participant display identity.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getParticipantsApi();
final String groupId = groupId_example; // String | 
final String participantId = participantId_example; // String | 
final String xCSRFToken = xCSRFToken_example; // String | Must match the readable cc_csrf cookie.
final RenameParticipantRequest renameParticipantRequest = ; // RenameParticipantRequest | 

try {
    final response = api.renameParticipantApiV1GroupsGroupIdParticipantsParticipantIdPatch(groupId, participantId, xCSRFToken, renameParticipantRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ParticipantsApi->renameParticipantApiV1GroupsGroupIdParticipantsParticipantIdPatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 
 **participantId** | **String**|  | 
 **xCSRFToken** | **String**| Must match the readable cc_csrf cookie. | 
 **renameParticipantRequest** | [**RenameParticipantRequest**](RenameParticipantRequest.md)|  | 

### Return type

[**ParticipantResponse**](ParticipantResponse.md)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

