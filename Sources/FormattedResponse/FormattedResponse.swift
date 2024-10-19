import Vapor

public enum FormattedResponseType {
  case json(ResponseEncodable, HTTPResponseStatus = .ok, HTTPHeaders = [:])
  case view(String, any Content, HTTPResponseStatus = .ok, HTTPHeaders = [:])
  case redirect(String, HTTPResponseStatus = .found, HTTPHeaders = [:])
}

public struct FormattedResponse {
    public var type: HTTPMediaType
    public var content: ResponseEncodable?
    public var view: View?
    public var path: String?
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

extension HTTPMediaType: @retroactive Identifiable{
  public var id: Int {
    self.hashValue
  }
}


@resultBuilder public struct FormattedResponseBuilder {
  public static func buildBlock(_ request: Request, _ responseTypes: FormattedResponseType...) -> EventLoopFuture<Response> {
    
    let acceptable = request.headers.accept.map { $0.mediaType }

    let response = responseTypes.first(where: { response in
      switch response {
        case .json:
          return acceptable.contains(.json)
        case .view:
          return true
        case .redirect:
          return true
      }
    })
    
    return request.eventLoop.future(Response(status: .ok))
  }

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
      if [HTTPResponseStatus.permanentRedirect, HTTPResponseStatus.temporaryRedirect].contains(result.status) {
        guard let path = result.path else {
          return request.eventLoop.future(Response(status: .badRequest))
        }

        return request.eventLoop.future(request.redirect(to: path))
      }

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
