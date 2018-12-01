--------------
--- Save module
-- @module save


-- Used to load and write data to files.
-- Stores user configs and game states

local sep = package.config:sub(1, 1) -- determines os directory separator (i.e. "/" or "\")

log = require("log")

--- Write data in a file and return status of pcall
-- @function 
-- @param file_name name of the file
-- @param data data to be write in file
-- @return boolean 
function write_file(file_name, data)

    local status , err = pcall(function()
        local file = love.filesystem.newFile(file_name)

        file:open("w")
        file:write(data)
        file:close()
    end)

    if status then
        logging.error("Error when whiting file: " .. file_name)
    end 

end

--- return the file size
-- @function read_file
-- @param file_name name of the file in persistence
-- @return nil
function get_file_size(file_name)
    
    local file_size

    local status, err = pcall(function()
        local file = love.filesystem.newFile(file_name)
        file:open("r")
        file_size = file:read(file:getSize())
        file:close()
    end)

    if status then
        log.error("Error when getting size of the file: " .. file_name)
    end

    return file_size

end


--- write kyes.txt file
-- @function write_key_file
-- @param nil 
-- @return nil
function write_key_file() 

    save_file("keys.txt", json.encode(K))

end

--- read keys.txt file
-- @function read_key_file
-- @param nil
-- @return nil
function read_key_file()
    
    status, err = pcall(function()
        local K=K

        local teh_json = get_file_size("keys.txt")
        local user_conf = json.decode(teh_json)

        -- TODO: remove this later, it just converts the old format.
        if #user_conf == 0 then
            local new_conf = {}

            for k,v in pairs(user_conf) do
                new_conf[k:sub(3)] = v
            end
            user_conf = {new_conf, {}, {}, {}}
        end

        for k,v in ipairs(user_conf) do
            keyboard[k]=v
        end
    end)

    if not status then
        log.error("Error when you read the key files "..err)
    end
end

--- read given txt file
-- @function read_txt_file
-- @param nil
-- @return string return a string with file size message
function read_txt_file(path_and_filename)
    assert(path_and_filename)

    local file_size
  
    file_size = get_file_size(path_and_filename)

    if not file_size then
        file_size  = "Failed to read file"..path_and_filename
    else
        -- substitute multiple newlines for one newline
        file_size = file_size:gsub('\r\n?', '\n')
    end

    if file_size == 0 then
        log.error("Failed to read file")
    end

    return file_size or "Failed to read file"
 end

--- write configuration to JSON file
-- @function write_conf_file
-- @param nil
-- @return nil
function write_conf_file()
  
    write_file("conf.json", config)

end

--- read configuration from JSON file
-- @function read_conf_file
-- @param nil
-- @return nil
function read_conf_file()
    
    status, err = pcall(function()

        local teh_json = get_file_size("conf.json")

        for k,v in pairs(json.decode(teh_json)) do
            config[k] = v
        end
    end)

    if not status then
        log.error(err)
    end
end

--- read replay file
-- @function read_replay_file
-- @param nil
-- @return nil
function read_replay_file()

    status, err = pcall(function()

        local teh_json = get_file_size("replay.txt")

        replay = json.decode(teh_json)

        if type(replay.in_buf) == "table" then
            replay.in_buf=table.concat(replay.in_buf)
            write_replay_file()
        end
    end)

    if not status then
        log.error(err)
    end

end

--- write replay file to default path
-- @function write_replay_file
-- @param nil
-- @return nil
function write_replay_file()

    local encoded_data = json.encode(replay)
    write_file("replay.txt", encoded_data)

end

--- Override function to write replay file to specific path
-- @function write_replay_file
-- @param nil
-- @return nil
function write_replay_file(path, filename) 

    pcall(function()

        assert(path)
        assert(filename)
        love.filesystem.createDirectory(path)

        local encoded_data = json.encode(replay)
        write_file(path.."/"..filename, encoded_data)

    end)

    if not status then
        log.error(err)
    end

end

--- write user id file
-- @function write_user_id_file
-- @param nil
-- @return nil
function write_user_id_file()

    status, err = pcall(function()
        love.filesystem.createDirectory("servers/"..connected_server_ip)

        write_file("servers/"..connected_server_ip.."/user_id.txt", tostring(my_user_id))
    end)

    if not status then
        log.error(err)
    end

end

--- read user id file
-- @function read_user_id_file
-- @param nil
-- @return nil
function read_user_id_file()

    status, err =  pcall(function()

        local file = love.filesystem.newFile("servers/"..connected_server_ip.."/user_id.txt")
        file:open("r")
        my_user_id = file:read()
        file:close()

    end)

    if not status then
        log.error(err)
    end

end

--- this function is never called
-- @function print_list
-- @param t input list
-- @return nil
function print_list(t)
    assert(t)
    for i, v in ipairs(t) do
        log.debug(v)
    end
end

-- copy recursively from files in source
function recursive_copy(source, destination)

    assert(source)
    assert(destination)

    local lfs = love.filesystem
    local names = lfs.getDirectoryItems(source)
    local temp
  
    for i, name in ipairs(names) do
        if lfs.isDirectory(source.."/"..name) then
            log.debug("calling recursive_copy(source".."/"..name..", ".. destination.."/"..name..")")
            recursive_copy(source.."/"..name, destination.."/"..name)

    elseif lfs.isFile(source.."/"..name) then
        if not lfs.isDirectory(destination) then
            love.filesystem.createDirectory(destination)
        end
        log.debug("copying file:  "..source.."/"..name.." to "..destination.."/"..name)

        local source_file = lfs.newFile(source.."/"..name)
        source_file:open("r")
      
        local source_size = source_file:getSize()
        temp = source_file:read(source_size)
        source_file:close()

        local new_file = lfs.newFile(destination.."/"..name)
        new_file:open("w")
        
        local success, message =  new_file:write(temp, source_size)
        new_file:close()

        log.debug(message)
    else
        log.debug("name:  "..name.." isn't a directory or file?")
    end
  end
end
