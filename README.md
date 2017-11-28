# A native iOS-Swift mobile app using a serverless backend in Swift

The application is a feedback app that smartly analyses the Tone of the feedback provided and appropriately acknowledges the customer through a Push Notification.

In this application, the user authenticates against [App ID](https://console.bluemix.net/catalog/services/AppID). App ID provides access and identification tokens. Further calls to the backend API include the access token. The backend is implemented with [Cloud Functions](https://console.bluemix.net/openwhisk). The serverless actions, exposed as Web Actions, expect the token to be sent in the request headers and verify its validity (signature and expiration date) before allowing access to the actual API. When the user submits a feedback, the feedback is stored in [Cloudant](https://console.bluemix.net/catalog/services/cloudantNoSQLDB) and later processed with [Tone Analyzer](https://console.bluemix.net/catalog/services/tone_analyzer). Based on the analysis result, a notification is sent back to the user with [Push Notifications](https://console.bluemix.net/catalog/services/imfpush).

## License

See [License.txt](License.txt) for license information.

