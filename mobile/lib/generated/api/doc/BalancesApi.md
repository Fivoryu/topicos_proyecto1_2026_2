# openapi.api.BalancesApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getBalancesApiV1GroupsGroupIdBalancesGet**](BalancesApi.md#getbalancesapiv1groupsgroupidbalancesget) | **GET** /api/v1/groups/{group_id}/balances | Get Balances


# **getBalancesApiV1GroupsGroupIdBalancesGet**
> BalancesResponse getBalancesApiV1GroupsGroupIdBalancesGet(groupId)

Get Balances

Compute balances from source expenses in stable participant order.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getBalancesApi();
final String groupId = groupId_example; // String | 

try {
    final response = api.getBalancesApiV1GroupsGroupIdBalancesGet(groupId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling BalancesApi->getBalancesApiV1GroupsGroupIdBalancesGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 

### Return type

[**BalancesResponse**](BalancesResponse.md)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

