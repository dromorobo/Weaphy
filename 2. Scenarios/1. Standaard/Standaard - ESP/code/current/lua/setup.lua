-- setup.lua (init.lua)

-- Setup uart, make permanent (last '1' makes permanent))
-- (uart,bps,databits,parity,stopbits,echo,permanent = 1)
uart.setup(0,9600,8,0,1,0,1)

SSID   = "weaphy_"..node.chipid()
PWD    = "12345678"
MODE   = "server"

function launch()
  -- Create index.html if it does not yet exist
  if not(file.exists("index.html"))
  then
    fl = file.open("index.html", "w")
    if fl
    then
      file.write('<!DOCTYPE HTML>\n')
      file.write('<html>\n')
      file.write('<head>\n')
      file.write('<meta content="text/html; charset=utf-8">\n')
      file.write('<title>Weaphy</title>\n')
      file.write('<style>table, th, td {text-align: center;}</style>\n')
      file.write('</head>\n')
      file.write('<body><h1>Hello, I am weaphy_' .. node.chipid() .. '</h3>\n')
      file.write('<table style="width:50%">\n')
      file.write('<tr>\n')
      file.write('<tr><td></td>\n')
      file.write('<td><form action="" method="POST"><input type="submit" name="cmd" value="forward"style=" font-size:30px"></form></td>\n')
      file.write('<td></td>')
      file.write('</tr>\n')
      file.write('<tr>\n')
      file.write('<td><form action="" method="POST"><input type="submit" name="cmd" value="left" style="font-size:30px"></form></td>\n')
      file.write('<td><form action="" method="POST"><input type="submit" name="cmd" value="stop" style="font-size:30px"></form></td>\n')
      file.write('<td><form action="" method="POST"><input type="submit" name="cmd" value="right" style="font-size:30px"></form></td>\n')
      file.write('</tr>\n')
      file.write('<tr>\n')
      file.write('<td></td>\n')
      file.write('<td><form action="" method="POST"><input type="submit" name="cmd" value="backward" style="font-size:30px"></form></td>\n')
      file.write('<td></td>\n')
      file.write('</tr>\n')
      file.write('</table>\n')
      file.write('</body></html>\n')
      file.close()
      fl = nil
    end
  end

  -- Launch existing servers
  if file.exists("tcp_srv.lua")
  then
    dofile("tcp_srv.lua")
  end

  if file.exists("udp_responder.lua")
  then
    dofile("udp_responder.lua")
  end
  
  if file.exists("telnet_srv.lua")
  then
    dofile("telnet_srv.lua")
  end

  if file.exists("http_srv.lua")
  then
    dofile("http_srv.lua")
  end
end

function isconnected()
  -- Lets see if we are already connected by getting the IP
  if (MODE == "server")
  then
    ipAddr = wifi.ap.getip()
  else
    ipAddr = wifi.sta.getip()
  end

  return( (ipAddr ~= nil) and (ipAddr ~= "0.0.0.0") ) 
end

-- Let's see if there is a config file for wifi
if file.exists("wifi.cfg")
then
  file.open("wifi.cfg")
  SSID = file.readline()
  PWD  = file.readline()
  MODE = file.readline()
  file.close()
  
  -- Remove eol
  SSID = string.sub(SSID, 1, string.len(SSID)-1)
  PWD  = string.sub(PWD, 1, string.len(PWD)-1)
  MODE = string.sub(MODE, 1, string.len(MODE)-1)
end

-- Setup wifi, and connect
wifi.setphymode(wifi.PHYMODE_N)

if (MODE == "server")
then
  wifi.setmode(wifi.STATIONAP)
  wifi.ap.config({ssid=SSID, pwd=PWD})
else
  wifi.setmode(wifi.STATION)
  wifi.sta.config({ssid=SSID, pwd=PWD})
  wifi.sta.connect()
end

-- Assume we are connected, so just run the launch code.
launch()
