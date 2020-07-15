//
//  main.swift
//  SignallingServer
//
//  Created by 张忠瑞 on 2020/6/10.
//  Copyright © 2020 张忠瑞. All rights reserved.
//

import Foundation

let server = try WebSocketServer()
server.start()
RunLoop.main.run()
