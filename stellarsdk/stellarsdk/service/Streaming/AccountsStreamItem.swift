//
//  AccountsStreamItem.swift
//  stellarsdk
//
//  Created by Kin Foundation on 2020-05-02.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public class AccountsStreamItem: NSObject {
    private var streamingHelper: StreamingHelper
    private var subpath: String
    private let jsonDecoder = JSONDecoder()

    public init(baseURL:String, subpath:String) {
        streamingHelper = StreamingHelper(baseURL: baseURL)
        self.subpath = subpath

        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
    }

    public func onReceive(response:@escaping StreamResponseEnum<AccountResponse>.ResponseClosure) {
        streamingHelper.streamFrom(path:subpath) { [weak self] (helperResponse) -> (Void) in
            switch helperResponse {
            case .open:
                response(.open)
            case .response(let id, let data):
                do {
                    let jsonData = data.data(using: .utf8)!
                    guard let account = try self?.jsonDecoder.decode(AccountResponse.self, from: jsonData) else { return }
                    response(.response(id: id, data: account))
                } catch {
                    response(.error(error: HorizonRequestError.parsingResponseFailed(message: error.localizedDescription)))
                }
            case .error(let error):
                let transactionSubpath = self?.subpath ?? "unknown"
                response(.error(error: HorizonRequestError.errorOnStreamReceive(message: "Error from Horizon on stream with path \(transactionSubpath): \(error?.localizedDescription ?? "nil")")))
            }
        }
    }

    public func closeStream() {
        streamingHelper.close()
    }
}
