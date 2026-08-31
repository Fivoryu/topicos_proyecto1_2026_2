# openapi.api.ExpensesApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createExpenseApiV1GroupsGroupIdExpensesPost**](ExpensesApi.md#createexpenseapiv1groupsgroupidexpensespost) | **POST** /api/v1/groups/{group_id}/expenses | Create Expense
[**deleteExpenseApiV1GroupsGroupIdExpensesExpenseIdDelete**](ExpensesApi.md#deleteexpenseapiv1groupsgroupidexpensesexpenseiddelete) | **DELETE** /api/v1/groups/{group_id}/expenses/{expense_id} | Delete Expense
[**editExpenseApiV1GroupsGroupIdExpensesExpenseIdPatch**](ExpensesApi.md#editexpenseapiv1groupsgroupidexpensesexpenseidpatch) | **PATCH** /api/v1/groups/{group_id}/expenses/{expense_id} | Edit Expense
[**getExpenseApiV1GroupsGroupIdExpensesExpenseIdGet**](ExpensesApi.md#getexpenseapiv1groupsgroupidexpensesexpenseidget) | **GET** /api/v1/groups/{group_id}/expenses/{expense_id} | Get Expense
[**listExpensesApiV1GroupsGroupIdExpensesGet**](ExpensesApi.md#listexpensesapiv1groupsgroupidexpensesget) | **GET** /api/v1/groups/{group_id}/expenses | List Expenses


# **createExpenseApiV1GroupsGroupIdExpensesPost**
> ExpenseResponse createExpenseApiV1GroupsGroupIdExpensesPost(groupId, xCSRFToken, expenseWriteRequest)

Create Expense

Parse lexical money and create one complete source expense.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getExpensesApi();
final String groupId = groupId_example; // String | 
final String xCSRFToken = xCSRFToken_example; // String | Must match the readable cc_csrf cookie.
final ExpenseWriteRequest expenseWriteRequest = ; // ExpenseWriteRequest | 

try {
    final response = api.createExpenseApiV1GroupsGroupIdExpensesPost(groupId, xCSRFToken, expenseWriteRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ExpensesApi->createExpenseApiV1GroupsGroupIdExpensesPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 
 **xCSRFToken** | **String**| Must match the readable cc_csrf cookie. | 
 **expenseWriteRequest** | [**ExpenseWriteRequest**](ExpenseWriteRequest.md)|  | 

### Return type

[**ExpenseResponse**](ExpenseResponse.md)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteExpenseApiV1GroupsGroupIdExpensesExpenseIdDelete**
> deleteExpenseApiV1GroupsGroupIdExpensesExpenseIdDelete(groupId, expenseId, xCSRFToken)

Delete Expense

Delete a source expense and all of its derived effect.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getExpensesApi();
final String groupId = groupId_example; // String | 
final String expenseId = expenseId_example; // String | 
final String xCSRFToken = xCSRFToken_example; // String | Must match the readable cc_csrf cookie.

try {
    api.deleteExpenseApiV1GroupsGroupIdExpensesExpenseIdDelete(groupId, expenseId, xCSRFToken);
} catch on DioException (e) {
    print('Exception when calling ExpensesApi->deleteExpenseApiV1GroupsGroupIdExpensesExpenseIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 
 **expenseId** | **String**|  | 
 **xCSRFToken** | **String**| Must match the readable cc_csrf cookie. | 

### Return type

void (empty response body)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **editExpenseApiV1GroupsGroupIdExpensesExpenseIdPatch**
> ExpenseResponse editExpenseApiV1GroupsGroupIdExpensesExpenseIdPatch(groupId, expenseId, xCSRFToken, expenseWriteRequest)

Edit Expense

Validate a full replacement before changing the source expense.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getExpensesApi();
final String groupId = groupId_example; // String | 
final String expenseId = expenseId_example; // String | 
final String xCSRFToken = xCSRFToken_example; // String | Must match the readable cc_csrf cookie.
final ExpenseWriteRequest expenseWriteRequest = ; // ExpenseWriteRequest | 

try {
    final response = api.editExpenseApiV1GroupsGroupIdExpensesExpenseIdPatch(groupId, expenseId, xCSRFToken, expenseWriteRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ExpensesApi->editExpenseApiV1GroupsGroupIdExpensesExpenseIdPatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 
 **expenseId** | **String**|  | 
 **xCSRFToken** | **String**| Must match the readable cc_csrf cookie. | 
 **expenseWriteRequest** | [**ExpenseWriteRequest**](ExpenseWriteRequest.md)|  | 

### Return type

[**ExpenseResponse**](ExpenseResponse.md)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getExpenseApiV1GroupsGroupIdExpensesExpenseIdGet**
> ExpenseResponse getExpenseApiV1GroupsGroupIdExpensesExpenseIdGet(groupId, expenseId)

Get Expense

Read one group-owned source expense.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getExpensesApi();
final String groupId = groupId_example; // String | 
final String expenseId = expenseId_example; // String | 

try {
    final response = api.getExpenseApiV1GroupsGroupIdExpensesExpenseIdGet(groupId, expenseId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ExpensesApi->getExpenseApiV1GroupsGroupIdExpensesExpenseIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 
 **expenseId** | **String**|  | 

### Return type

[**ExpenseResponse**](ExpenseResponse.md)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listExpensesApiV1GroupsGroupIdExpensesGet**
> List<ExpenseResponse> listExpensesApiV1GroupsGroupIdExpensesGet(groupId)

List Expenses

List source expenses in stable creation order with current names.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getExpensesApi();
final String groupId = groupId_example; // String | 

try {
    final response = api.listExpensesApiV1GroupsGroupIdExpensesGet(groupId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ExpensesApi->listExpensesApiV1GroupsGroupIdExpensesGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 

### Return type

[**List&lt;ExpenseResponse&gt;**](ExpenseResponse.md)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

