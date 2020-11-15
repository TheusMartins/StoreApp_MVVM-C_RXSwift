//
//  RequestProtocol.swift
//  StoreApp
//
//  Created by Scizor on 15/11/20.
//

import Foundation

protocol RequestProtocol {
    associatedtype
    Target: RequestInfos
    func requestObject<Model: Codable>(model: Model.Type, _ target: Target, completionHandler: @escaping (_ result: Model?, _ error: Error?) -> Void)
    func requestData(target: Target, completionHandler: @escaping (_ data: Data?, _ error: Error?) -> Void)
}

final class Request<Target: RequestInfos> : RequestProtocol {
    //MARK: - Public methods
    func requestObject<Model>(model: Model.Type, _ target: Target, completionHandler: @escaping (Model?, Error?) -> Void) where Model : Codable {
        guard let url = URL(string: "\(target.baseURL)\(target.endpoint.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            completionHandler(nil, NSError())
            return
        }
        
        var request = URLRequest(url: url)
        
        do {
            request = try target.parameterEncoding.encode(request: URLRequest(url: url), parameters: target.parameters)
        } catch {
            completionHandler(nil, NSError())
        }
        
        URLSession.shared.dataTask(with: request) { data, resp, error in
            if let error = error {
                completionHandler(nil, error)
            }
            
            guard let data = data else {
                completionHandler(nil, NSError())
                return
            }
            
            do {
                let modelList = try JSONDecoder().decode(Model.self , from: data)
                completionHandler(modelList, nil)
            } catch {
                completionHandler(nil, NSError())
            }
        }.resume()
    }
    
    func requestData(target: Target, completionHandler: @escaping (_ data: Data?, _ error: Error?) -> Void) {
        guard var url = URLComponents(string: "\(target.baseURL)\(target.endpoint)") else {
            completionHandler(nil, NSError())
            return
        }
        
        var components: [URLQueryItem] = []
        
        target.parameters?.forEach({ key, value in
            guard let stringValue = value as? Int else { return }
            components.append(URLQueryItem(name: key, value: "\(stringValue)"))
        })
        
        url.queryItems = components
        
        guard let request = url.url else {
            completionHandler(nil, NSError())
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, resp, error in
            if let error = error {
                completionHandler(nil, error)
            }
            
            guard let data = data else {
                completionHandler(nil, NSError())
                return
            }
            
            completionHandler(data, nil)

        }.resume()
    }
}

