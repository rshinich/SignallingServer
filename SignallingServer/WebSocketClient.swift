//
//  WebSocketClient.swift
//  SignallingServer
//
//  Created by 张忠瑞 on 2020/6/10.
//  Copyright © 2020 张忠瑞. All rights reserved.
//

import Foundation
import Network

final class WebSocketClient: Hashable, Equatable {

    let id: String
    let connection: NWConnection

    init(connection: NWConnection) {
        self.connection = connection
        self.id = UUID().uuidString //创建随机UUID
    }

    //MARK: - 判断灯脚条件 Equable协议
    ///Returns a Boolean value indicating whether two values are equal.
    static func == (lhs: WebSocketClient, rhs: WebSocketClient) -> Bool {
        lhs.id == rhs.id
    }
    // MARK:- 提供一个哈希标识
    /// Hashes the essential components of this value by feeding them into the given hasher.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
