-- a simple tcp server

-- restart server if needed
if tcp_srv ~= nil then
    tcp_srv:close()
end
tcp_srv = net.createServer(net.TCP, 180)

tcp_srv:listen(54321, function(socket)
    local fifo = {}
    local fifo_drained = true

    local function tcpsend(conn)
        if #fifo > 0 then
            conn:send(table.remove(fifo, 1))
        else
            fifo_drained = true
        end
    end

    local function s_output(str)
        table.insert(fifo, str)
        if socket ~= nil and fifo_drained then
            fifo_drained = false
            tcpsend(socket)
        end
    end

    node.output(s_output, 0)   -- re-direct output to function s_ouput.

    socket:on("receive", function(c, payload)
        print(payload)
    end)
    
    socket:on("disconnection", function(c)
        node.output(nil)        -- unregist the redirect output function, output goes to serial
    end)
    
    socket:on("sent", tcpsend)

    --socket:on("connection", function(c)
      -- send ACK
    --end)

    uart.on("data", function(data)
      tcpsend(data)
    end, 0)

end)
