-- Basic HTTP server for Weaphy 1.0, fetching user commands using 
-- a simple webpage.

-- restart server if needed
if http_srv ~= nil then
    http_srv:close()
end

http_srv=net.createServer(net.TCP)
http_srv:listen(80,function(conn)

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
       
      -- Check scl
      scl=0
      if file.exists("scl.cfg")
      then
        file.open("scl.cfg")
        line = file.readline()
        scl = tonumber(string.sub(line, 1, string.len(line)-1))
        file.close()
      end

      -- If scl ~= 0 then add scl to uri
      if scl ~= 0
      then
        tgtfile = (tostring(scl) .. tgtfile)
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
      -- expected parameters are 
      -- 1. [cmd] 
      -- 2. [ssid] and [password]
      -- 3. [secret]
        
      fssid={string.find(payload,"ssid=")}
      fcmd={string.find(payload,"cmd=")}
      fsecret={string.find(payload,"secret=")}

      -- 1. [cmd]
      if fcmd[2]~=nil
      then
        foundcmd=string.sub(payload,string.find(payload,"cmd=")
            +4,#payload)
        print(foundcmd)
        
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
      
      -- 2. [ssid] and [password]
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

      -- 3. [secret]
      if fsecret[2]~=nil
      then    
        foundsecret=string.sub(payload,string.find(payload,"secret=")
            +7)

        -- Read security clearance level from scl.cfg
        if file.exists("scl.cfg")
        then
          -- Read security clearance level
          file.open("scl.cfg")
          line = file.readline()
          scl = tonumber(string.sub(line, 1, string.len(line)-1))
          file.close()
        else
          -- assume security clearance level is 0
          scl = 0
        end
        
        -- Compare answer to that in secret.cfg (depending on security clearance level)
        if (scl ~= 0 and file.exists("secrets.cfg"))
        then
          file.open("secrets.cfg")
          correctanswer = false
          repeat
            line = file.readline()
            if line ~= nil
            then 
              sclindex = tonumber(string.sub(line, 1, string.find(line,":")-1))
              
              if (scl == sclindex)
              then
                sclanswer = string.sub(line, string.find(line,"=")+1) 
                -- remove eol before compare
                sclanswer = string.sub(sclanswer, 1, string.len(sclanswer)-1)
                correctanswer = (sclanswer == foundsecret)
              end
            else eol = true
            end
          until (eol or correctanswer)
          file.close()

          print(sclindex, foundsecret, string.len(foundsecret), sclanswer, string.len(sclanswer), correctanswer)

          -- If answer is correct, write the new security clearance level in scl.cfg
          if (correctanswer)
          then
            scl = scl - 1
            file.open("scl.cfg","w+")
            file.write(tostring(scl) .. "\n")
            file.close()
          end
        end

        -- Assume the request can be OK-ed
        conn:send('HTTP/1.0 200 OK\n')
        conn:send('Server: Weaphy HTTP\n')
        conn:send('\n')
        conn:send('\n')

      end
    end
  end)

  conn:on("sent",function(conn) conn:close() end)

end)
