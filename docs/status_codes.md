## HTTP Status Codes

Libraries.io will return the following HTTP Status Codes as intended responses.


#### Successful Response:

`Status: 200 OK`

The API will return a successful status code if the request is processed successfully.


#### Forbidden

`Status: 403 Forbidden`

A forbidden status code will be returned if a valid API key is not passed with the request.


#### Not Found

`Status: 404 Not Found`

The most common use case for a not found status is when ActiveRecord cannot find the intended request in the database.


#### Unprocessable Entity

`Status: 422 Unprocessable Entity`

The API will error catch for ActiveRecord errors. If ActiveRecord raises an error on either the #create! or #save! methods, the API will return an unprocessable entity status code.


### Internal Service

`Status: 500 Internal Service Error`

The API will return a response code of 500 when the user tries to use the API endpoints in some way that Libraries.io hasn't yet anticipated. We will record the error and will use it for further feature development.
