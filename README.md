# FormattedResponse

FormattedResponse is a library that makes re-using routes easy in Vapor. It is a convenience method that uses @resultBuilder to allow multiple types of responses to be returned in a single route. When a user requests that route, it uses the `Accept` header to determine the type of content that will be returned. The method then attempts to find the corresponding type that you defined, returning either an error or the default, which for now is the first item, depending on the method used.

## Example code

Let us say there is a route that returns a list of users. This route can be consumed by both a mobile application and a web browser. After querying the data and generating the view, pass in the types of responses that you want to return, along with request. The `makeResponse` handler then determines which to return.

```
func users(request: Request) async throws -> Response {
	let users = try await User.query(on: request.db).paginate(for: request)
	let view = try await request.view.render("User/index", ["users": users.items]).get()
	
	return try await makeResponse {
		request
		FormattedResponse(type: .html, view: view)
		FormattedResponse(type: .json, content: users)
	}
}
```

However, if some routes are only available as JSON routes, or some views are only available on the web, we can omit the responses we do not want. The example below shows only using the .html route. If a user uses `Accept: application/json`, the data will return in the format requested but with an error showing that this type of route is not supported.

```
func profileView(request: Request) async throws -> Response {
	let user = // Do your query here
	let view = try await request.view.render("User/profile", ["user": user]).get()
	return try await makeResponse {
		request
		FormattedResponse(type: .html, view: view)
	}
}
```

## Limitations

This is currently in an alpha phase and will be built out to be easier to use, along with predefined error page paths, different status codes, more formats, etc. Right now, JSON and HTML are the only supported languages, but this should be easy to add on different handlers for each format that can be represented.