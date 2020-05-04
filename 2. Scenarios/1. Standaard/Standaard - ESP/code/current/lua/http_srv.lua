-- Basic HTTP server for Weaphy 2.0, fetching user commands using 
-- a simple webpage.

-- Leaphy L298P Motor A/B
-- Motor Shield    NodeMCU GPIO Purpose
-- PWMA (Motor A)   D1      5   Speed
-- DIRA (Motor A)   D3      0   Direction
-- PWMA (Motor B)   D2      4   Speed
-- DIRB (Motor B)   D4      2   Direction
MA_SPEED = 1
MA_DIR   = 3
MB_SPEED = 2
MB_DIR   = 4

-- restart server if needed
if http_srv ~= nil then
    http_srv:close()
end

http_srv=net.createServer(net.TCP)
http_srv:listen(80,function(conn)

-- function initGPIO()
  gpio.mode(0,gpio.OUTPUT);--LED Light on
  gpio.write(0,gpio.LOW);
    
  gpio.mode(MA_SPEED,gpio.OUTPUT);
  gpio.write(MA_SPEED,gpio.LOW);
  gpio.mode(MB_SPEED,gpio.OUTPUT);
  gpio.write(MB_SPEED,gpio.LOW);
     
  gpio.mode(MA_DIR,gpio.OUTPUT);
  gpio.write(MA_DIR,gpio.HIGH);
  gpio.mode(MB_DIR,gpio.OUTPUT);
  gpio.write(MB_DIR,gpio.HIGH);
     
  pwm.setup(MA_SPEED,1000,1023);--PWM 1KHz, Duty 1023
  pwm.start(MA_SPEED);pwm.setduty(MA_SPEED,0);
  pwm.setup(MB_SPEED,1000,1023);
  pwm.start(MB_SPEED);pwm.setduty(MB_SPEED,0);
-- end function InitGPIO

function doit(command)
  if string.find(command,"stop")
  then
    pwm.setduty(MA_SPEED,0)
    pwm.setduty(MB_SPEED,0)
  end

  if string.find(command,"forward")
  then
    gpio.write(MA_DIR,gpio.HIGH)
    gpio.write(MB_DIR,gpio.HIGH)
    pwm.setduty(MA_SPEED,1023)
    pwm.setduty(MB_SPEED,1023)
  end

  if string.find(command, "backward")
  then
    gpio.write(MA_DIR,gpio.LOW)
    gpio.write(MB_DIR,gpio.LOW)
    pwm.setduty(MA_SPEED,1023)
    pwm.setduty(MB_SPEED,1023)
  end

  if string.find(command, "left")
  then
    gpio.write(MA_DIR,gpio.LOW)
    gpio.write(MB_DIR,gpio.HIGH)
    pwm.setduty(MA_SPEED,1023)
    pwm.setduty(MB_SPEED,1023)
  end

  if string.find(command, "right")
  then 
    gpio.write(MA_DIR,gpio.HIGH);
    gpio.write(MB_DIR,gpio.LOW);
    pwm.setduty(MA_SPEED,1023)
    pwm.setduty(MB_SPEED,1023)
  end

end -- function doit()

  conn:on("receive", function(client,payload) 
    -- first find GET or POST
    if string.find(payload, "GET")
    then
      -- method is GET, extract uri, and be sure to check syntax
      uri = ""
      if string.find(payload, "GET /")
      then
        if string.find(payload, "HTTP/")
        then
          uri = string.sub(payload,string.find(payload,"GET /")
                  +5,string.find(payload,"HTTP/")-2)
        end
      end
      
      if uri == "" 
      then 
        -- nothing found, assume default = index.html
        tgtfile = "index.html" 
      else
        tgtfile = uri
      end
       
      -- Check for .html or .ico or .png
      if (string.find(tgtfile, ".html")
          or string.find(tgtfile, ".ico")
          or string.find(tgtfile, ".png") ~= nil)
      then
        local f = file.open(tgtfile,"r")
        if f ~= nil 
        then
          client:send(file.read())
          file.close()
        end
      else
        client:send("<html>"..tgtfile.." not found - 404 error.<BR><a href='index.html'>Home</a><BR>")
      end

    else
      -- no GET so assume POST, find parameters
      -- expected parameters are [cmd] or [ssid] and [password]        
      fssid={string.find(payload,"ssid=")}
      fcmd={string.find(payload,"cmd=")}

      if fcmd[2]~=nil
      then
        foundcmd=string.sub(payload,string.find(payload,"cmd=")
            +4,#payload)
        print(foundcmd) -- show what has been received
        doit(foundcmd)
        
        -- Assume the request can be OK-ed
        conn:send('HTTP/1.0 200 OK\n')
        conn:send('Server: Weaphy HTTP\n')
        conn:send('\n')
        conn:send('\n')
        
        local f = file.open("index.html","r")
        if f ~= nil 
        then
          client:send(file.read())
          file.close()
        end

      end
      
      if fssid[2]~=nil
      then    
        foundssid=string.sub(payload,string.find(payload,"ssid=")
            +5,string.find(payload,"&password=")-1)
        foundpwd=string.sub(payload,string.find(payload,"password=")
            +9,string.find(payload,"&mode=")-1)
        foundmode=string.sub(payload,string.find(payload,"mode=")
            +5)

        -- Write the result in wifi.cfg
        file.open("wifi.cfg","w+")
        file.write(foundssid .. "\n")
        file.write(foundpwd .. "\n")
        if foundmode == "server"
        then
          file.write("server\n")
        else
          file.write("client\n")
        end
        file.close()
        
        -- Assume the request can be OK-ed
        conn:send('HTTP/1.0 200 OK\n')
        conn:send('Server: Weaphy HTTP\n')
        conn:send('\n')
        conn:send('\n')
        
        f = nil
        tgtfile = nil
        collectgarbage()
      end
    end
  end)

  conn:on("sent",function(conn) conn:close() end)

end)
