import Vapor

public struct FormattedResponse {
	public var type: HTTPMediaType
    public var content: ResponseEncodable?
    public var view: View?
    public var status: HTTPResponseStatus
    public var headers: HTTPHeaders
    
    public init(type: HTTPMediaType, content: ResponseEncodable? = nil, view: View? = nil, status: HTTPResponseStatus = .ok, headers: HTTPHeaders = [:]) {
        self.type = type
        self.content = content
        self.view = view
        self.status = status
        self.headers = headers
    }
}


@resultBuilder public struct FormattedResponseBuilder {
	public static func buildBlock(_ request: Request, _ responses: FormattedResponse...) -> EventLoopFuture<Response> {
		let acceptable = request.headers.accept.map { acceptType -> HTTPMediaType in
			acceptType.mediaType
		}
		
		guard var expectedType = acceptable.first else {
			let response = Response(status: .badRequest)
			return request.eventLoop.future(response)
		}
		
		expectedType = expectedType.hashValue == HTTPMediaType.any.hashValue ? .html : expectedType

		guard let result = responses.first(where: { $0.type == expectedType }) else {
			return request.eventLoop.future(Response(status: .badRequest))
		}
		
		if expectedType == .html {
			guard let view = result.view else {
				return request.eventLoop.future(Response(status: .badRequest))
			}
			
			return view.encodeResponse(status: result.status, headers: result.headers, for: request)
		} else if expectedType == .json || expectedType == .jsonAPI {
			guard let content = result.content else {
				let invalidResponse = ["error": "content missing for response"]
				
				return invalidResponse.encodeResponse(status: .internalServerError, headers: result.headers, for: request)
			}
			
			return content.encodeResponse(status: result.status, headers: result.headers, for: request)
		}
		
		return ["error": "invalid content type"].encodeResponse(status: .badRequest, headers: result.headers, for: request)
	}
}

public func makeResponse(@FormattedResponseBuilder _ content: () -> EventLoopFuture<Response>) async throws -> Response {
	return try await content().get()
}
