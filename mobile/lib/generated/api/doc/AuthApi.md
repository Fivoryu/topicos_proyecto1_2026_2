# openapi.api.AuthApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**loginApiV1AuthLoginPost**](AuthApi.md#loginapiv1authloginpost) | **POST** /api/v1/auth/login | Login
[**logoutApiV1AuthLogoutPost**](AuthApi.md#logoutapiv1authlogoutpost) | **POST** /api/v1/auth/logout | Logout
[**sessionApiV1AuthSessionGet**](AuthApi.md#sessionapiv1authsessionget) | **GET** /api/v1/auth/session | Session


# **loginApiV1AuthLoginPost**
> SessionIdentityResponse loginApiV1AuthLoginPost(xCSRFToken, loginRequest)

Login

Authenticate seeded credentials and establish both transport cookies.

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getAuthApi();
final String xCSRFToken = xCSRFToken_example; // String | Must match the readable cc_csrf cookie.
final LoginRequest loginRequest = ; // LoginRequest | 

try {
    final response = api.loginApiV1AuthLoginPost(xCSRFToken, loginRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthApi->loginApiV1AuthLoginPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xCSRFToken** | **String**| Must match the readable cc_csrf cookie. | 
 **loginRequest** | [**LoginRequest**](LoginRequest.md)|  | 

### Return type

[**SessionIdentityResponse**](SessionIdentityResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **logoutApiV1AuthLogoutPost**
> logoutApiV1AuthLogoutPost(xCSRFToken)

Logout

Revoke the current session and expire both browser-visible cookies.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure API key authorization: cc_session
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cc_session').apiKeyPrefix = 'Bearer';

final api = Openapi().getAuthApi();
final String xCSRFToken = xCSRFToken_example; // String | Must match the readable cc_csrf cookie.

try {
    api.logoutApiV1AuthLogoutPost(xCSRFToken);
} catch on DioException (e) {
    print('Exception when calling AuthApi->logoutApiV1AuthLogoutPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xCSRFToken** | **String**| Must match the readable cc_csrf cookie. | 

### Return type

void (empty response body)

### Authorization

[cc_session](../README.md#cc_session)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **sessionApiV1AuthSessionGet**
> SessionIdentityResponse sessionApiV1AuthSessionGet()

Session

Return server identity and initialize CSRF even for an anonymous probe.

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getAuthApi();

try {
    final response = api.sessionApiV1AuthSessionGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthApi->sessionApiV1AuthSessionGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**SessionIdentityResponse**](SessionIdentityResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

