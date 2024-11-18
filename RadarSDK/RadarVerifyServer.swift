//
//  RadarVerifyServer.swift
//  RadarSDK
//
//  Created by Nick Patrick on 11/11/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import NIO
import NIOSSL
import NIOHTTP1
import UserNotifications

@objc(RadarVerifyServer) class RadarVerifyServer: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    @objc static let sharedInstance = RadarVerifyServer()
    
    private let certificateURL = URL(string: "https://s3.us-east-2.amazonaws.com/app.radar-verify.com/mac/c.pem")!
    private let keyURL = URL(string: "https://s3.us-east-2.amazonaws.com/app.radar-verify.com/mac/k.pem")!
    
    private var locationManager = CLLocationManager()
    private var server: Server?
    
    private let queue = DispatchQueue(label: "RadarVerifyServer")

    override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.distanceFilter = 3000
    }
    
    @objc func startServer() async {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            Task {
                do {
                    let certificateData = try await self.downloadData(from: certificateURL)
                    let keyData = try await self.downloadData(from: keyURL)
                    
                    server = try Server(certificateData: certificateData, keyData: keyData)
                    try server?.start()
                    
                    locationManager.startUpdatingLocation()
                } catch {
                    print("Error starting server: \(error)")
                }
            }
        }
    }
    
    @objc func stopServer() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.server?.stop()
        }
    }
    
    private func downloadData(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return data
    }
}

private class Server {
    let group: MultiThreadedEventLoopGroup
    let bootstrap: ServerBootstrap
    var channel: Channel?
    
    init(certificateData: Data, keyData: Data) throws {
        let certificateChain = try NIOSSLCertificate.fromPEMBytes([UInt8](certificateData))
        let sslContext = try NIOSSLContext(configuration: .makeServerConfiguration(
            certificateChain: certificateChain.map { .certificate($0) },
            privateKey: .privateKey(try NIOSSLPrivateKey(bytes: [UInt8](keyData), format: .pem))
        ))

        group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        
        bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelInitializer { channel in
                let handler = NIOSSLServerHandler(context: sslContext)
                return channel.pipeline.addHandler(handler).flatMap {
                    channel.pipeline.configureHTTPServerPipeline()
                }.flatMap {
                    channel.pipeline.addHandler(HTTPHandler())
                    // channel.pipeline.addHandler(HTTPHandler(viewModel: viewModel))
                }
            }
    }
    
    func start() throws {
        guard let channel = try? bootstrap.bind(host: "127.0.0.1", port: 52516).wait() else {
            fatalError("Failed to bind server")
        }
        self.channel = channel
        try channel.closeFuture.wait()
    }
    
    func stop() {
        try? group.syncShutdownGracefully()
    }
}

class HTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let reqPart = self.unwrapInboundIn(data)
        
        switch reqPart {
        case .head(let reqHeader):
            // *************************************
            // 1. listen for GET /v1/verify requests from web SDK
            // *************************************
            
            var resHeaders = NIOHTTP1.HTTPHeaders()

            resHeaders.add(name: "Access-Control-Allow-Headers", value: "Content-Type, Accept, Authorization, X-Radar-Device-Type, X-Radar-SDK-Version")
            resHeaders.add(name: "Access-Control-Allow-Origin", value: "*")
            resHeaders.add(name: "Access-Control-Allow-Methods", value: "GET, OPTIONS")
            resHeaders.add(name: "Content-Type", value: "application/json")

            if reqHeader.method == .OPTIONS {
                let resHead = HTTPResponseHead(version: reqHeader.version, status: .noContent, headers: resHeaders)
                let resPart = HTTPServerResponsePart.head(resHead)
                context.write(self.wrapOutboundOut(resPart), promise: nil)
                context.writeAndFlush(self.wrapOutboundOut(HTTPServerResponsePart.end(nil)), promise: nil)
                return
            }
            
            guard let publishableKey = reqHeader.headers["Authorization"].first else {
                print("Missing publishableKey")
                
                let resHead = HTTPResponseHead(version: reqHeader.version, status: .forbidden, headers: resHeaders)
                let resPart = HTTPServerResponsePart.head(resHead)
                context.write(self.wrapOutboundOut(resPart), promise: nil)
                context.writeAndFlush(self.wrapOutboundOut(HTTPServerResponsePart.end(nil)), promise: nil)
                return
            }
            
            let reqUri = reqHeader.uri
            
            guard let reqUrlComponents = URLComponents(string: reqUri) else {
                print("Missing URL params")
                
                let resHead = HTTPResponseHead(version: reqHeader.version, status: .badRequest, headers: resHeaders)
                let resPart = HTTPServerResponsePart.head(resHead)
                context.write(self.wrapOutboundOut(resPart), promise: nil)
                context.writeAndFlush(self.wrapOutboundOut(HTTPServerResponsePart.end(nil)), promise: nil)
                return
            }
            
            var userId: String? = nil
            var description: String? = nil
            
            if let queryParams = reqUrlComponents.queryItems {
                for item in queryParams {
                    if item.value == "null" {
                        continue
                    }
                    
                    if item.name == "userId" {
                        userId = item.value
                    } else if item.name == "description" {
                       description = item.value
                    }
                }
            }
            
            let url = URL(string: reqHeader.uri)
            
            if reqHeader.method == .GET, let urlPath = url?.path, urlPath == "/v1/verify" {
                print("Received request")
                
                showNotification()
                
                // DispatchQueue.main.async {
                    Radar.initialize(publishableKey: publishableKey)
                    Radar.setUserId(userId)
                    Radar.setDescription(description)
                    
                    Radar.trackVerified { status, token in
                        // context.eventLoop.execute {
                            if (status == .success && token != nil) {
                                do {
                                    let userData = try JSONSerialization.data(withJSONObject: token!.user!.dictionaryValue(), options: [])
                                    let eventsData = try JSONSerialization.data(withJSONObject: RadarEvent.array(for: token!.events!)!, options: [])
                                    let userStr = String(data: userData, encoding: .utf8)!
                                    let eventsStr = String(data: eventsData, encoding: .utf8)!
                                    
                                    let resStatus: HTTPResponseStatus = .ok
                                    let resStr = "{\"meta\":{\"code\":200},\"user\":\(userStr),\"events\":\(eventsStr)}"
                                    let resBody = context.channel.allocator.buffer(string: resStr)
                                    
                                    let resHead = HTTPResponseHead(version: reqHeader.version, status: resStatus, headers: resHeaders)
                                    context.write(self.wrapOutboundOut(.head(resHead)), promise: nil)
                                    context.write(self.wrapOutboundOut(.body(.byteBuffer(resBody))), promise: nil)
                                    context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
                                } catch {
                                    print("Error serializing response")
                                    
                                    let resHead = HTTPResponseHead(version: reqHeader.version, status: .internalServerError, headers: resHeaders)
                                    let resPart = HTTPServerResponsePart.head(resHead)
                                    context.write(self.wrapOutboundOut(resPart), promise: nil)
                                    context.writeAndFlush(self.wrapOutboundOut(HTTPServerResponsePart.end(nil)), promise: nil)
                                }
                            } else if (status == .errorPermissions) {
                                let resStatus: HTTPResponseStatus = .badRequest
                                let resStr = "{\"meta\":{\"code\":400,\"error\":\"ERROR_PERMISSIONS\"}}"
                                let resBody = context.channel.allocator.buffer(string: resStr)
                                
                                let resHead = HTTPResponseHead(version: reqHeader.version, status: resStatus, headers: resHeaders)
                                context.write(self.wrapOutboundOut(.head(resHead)), promise: nil)
                                context.write(self.wrapOutboundOut(.body(.byteBuffer(resBody))), promise: nil)
                                context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
                            } else if (status == .errorLocation) {
                                let resStatus: HTTPResponseStatus = .badRequest
                                let resStr = "{\"meta\":{\"code\":400,\"error\":\"ERROR_LOCATION\"}}"
                                let resBody = context.channel.allocator.buffer(string: resStr)
                                
                                let resHead = HTTPResponseHead(version: reqHeader.version, status: resStatus, headers: resHeaders)
                                context.write(self.wrapOutboundOut(.head(resHead)), promise: nil)
                                context.write(self.wrapOutboundOut(.body(.byteBuffer(resBody))), promise: nil)
                                context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
                            } else if (status == .errorNetwork) {
                                let resStatus: HTTPResponseStatus = .badRequest
                                let resStr = "{\"meta\":{\"code\":400,\"error\":\"ERROR_NETWORK\"}}"
                                let resBody = context.channel.allocator.buffer(string: resStr)
                                
                                let resHead = HTTPResponseHead(version: reqHeader.version, status: resStatus, headers: resHeaders)
                                context.write(self.wrapOutboundOut(.head(resHead)), promise: nil)
                                context.write(self.wrapOutboundOut(.body(.byteBuffer(resBody))), promise: nil)
                                context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
                            } else {
                                let resHead = HTTPResponseHead(version: reqHeader.version, status: .internalServerError, headers: resHeaders)
                                let resPart = HTTPServerResponsePart.head(resHead)
                                context.write(self.wrapOutboundOut(resPart), promise: nil)
                                context.writeAndFlush(self.wrapOutboundOut(HTTPServerResponsePart.end(nil)), promise: nil)
                            }
                        // }
                    }
                // }
            } else {
                let resHead = HTTPResponseHead(version: reqHeader.version, status: .notFound, headers: resHeaders)
                let resPart = HTTPServerResponsePart.head(resHead)
                context.write(self.wrapOutboundOut(resPart), promise: nil)
                context.writeAndFlush(self.wrapOutboundOut(HTTPServerResponsePart.end(nil)), promise: nil)
            }
            
        default:
            break
        }
    }
    
    func showNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Location check in progress..."
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(identifier: "location", content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            
        }
    }
    
}
