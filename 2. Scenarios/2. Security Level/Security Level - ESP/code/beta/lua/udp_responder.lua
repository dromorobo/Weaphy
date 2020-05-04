-- udp_responder.lua
-- Responds to packets received on port 54321 (mBlock) by sending 'myname'

udppartnerport = 54321
myname = "weaphy_"..node.chipid()

udpSocket = net.createUDPSocket()
udpSocket:listen(54321)

udpSocket:on("receive", function(s, data, port, ip)
    print(data)
    -- Announce myself back to 'ip'
    udpSocket:send(udppartnerport, ip, myname)
end)

