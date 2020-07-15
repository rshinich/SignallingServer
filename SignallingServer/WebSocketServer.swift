//
//  WebSocketServer.swift
//  SignallingServer
//
//  Created by 张忠瑞 on 2020/6/10.
//  Copyright © 2020 张忠瑞. All rights reserved.
//

import Foundation
import Network

final class WebSocketServer {

    //global线程
    private let queue = DispatchQueue.global()
    //端口号
    private let port: NWEndpoint.Port = 8080
    //网络listener
    private let listener: NWListener
    //使用Set来存放连接进来的客户端
    private var connectedClients = Set<WebSocketClient>()

    //MARK: -
    init() throws {
        //TCP连接方式
        let paramters = NWParameters.tcp
        //连接属性设置
        let webSocketOptions = NWProtocolWebSocket.Options()
        //自动回复ping
        webSocketOptions.autoReplyPing = true
        paramters.defaultProtocolStack.applicationProtocols.append(webSocketOptions)
        self.listener = try NWListener(using: paramters, on: self.port)
    }

    //MARK: - 开始后台服务
    func start() {

        self.listener.newConnectionHandler = self.newConnectionHandler
        self.listener.start(queue: queue)
        print("信令服务器开始监听端口 \(self.port)")
    }

    //MARK: - 接收到一个新的client的处理方法
    private func newConnectionHandler(_ connection: NWConnection) {
        let client = WebSocketClient(connection: connection)    //创建一个客户端对象
        self.connectedClients.insert(client)                    //set里插入一个客户端对象
        client.connection.start(queue: self.queue)              //开始连接
        client.connection.receiveMessage { [weak self] (data, context, isComplete, error) in

            self?.didReceiveMessage(from: client,
                                    data: data,
                                    context: context,
                                    error: error)
        }

        print("接收到新的客户端，已连接客户端数量：\(self.connectedClients.count)")
    }

    //MARK: - 断开Client

    private func didDisconnect(client: WebSocketClient) {
        self.connectedClients.remove(client)
        print("客户端已断开，已连接客户端数量：\(self.connectedClients.count)")
    }

    //MARK: - 接收到client的信息

    private func didReceiveMessage(from client:WebSocketClient,
                                   data: Data?,
                                   context: NWConnection.ContentContext?,
                                   error: NWError?) {

        if let context = context, context.isFinal {     //判断是否为最终的context信息
            client.connection.cancel()                  //取消连接
            self.didDisconnect(client: client)          //断开连接
            return
        }

        if let data = data {
            let otherClients = self.connectedClients.filter{ $0 != client } //实现这个主要是因为实现了equal协议

            self.broadcast(data: data, to: otherClients)

            if let str = String(data: data, encoding: .utf8) {
                print("------------------------------------ 接收到 数据信息 ------------------------------------")
                print(str + "\n")
            }
        }

        //继续接收消息
        client.connection.receiveMessage { [weak self] (data, context, isComplete, error) in
            self?.didReceiveMessage(from: client, data: data, context: context, error: error)
        }
    }

    private func broadcast(data: Data, to clients: Set<WebSocketClient>) {
        clients.forEach {
            let metadata = NWProtocolWebSocket.Metadata(opcode: .binary)//元数据
            let context = NWConnection.ContentContext(identifier: "context", metadata: [metadata])
            //发送数据
            $0.connection.send(content: data,
                               contentContext: context,
                               isComplete: true,
                               completion: .contentProcessed({ _ in }))
        }
    }
}
