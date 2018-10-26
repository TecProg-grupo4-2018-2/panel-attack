-------------
--- Network Module
--- Handle sockets and connection of the game.
-- @module network


--- TCP socket
local TCP_sock = nil

-- 2 << 16 word lenght of json
local WORD_LEN = 65536

--- Save data for socket
local leftovers = ''

--- Flush the buffer from TCP socket variable
-- @function flush_socket
-- @param nil
-- @return nil
function flush_socket()

    local data = TCP_sock:receive('*a')

    --- save data in leftovers
    leftovers = leftovers .. data

end

--- Close the TCP socket global variable
-- @function close_socket
-- @param nil
-- @return nil
function close_socket()

    if TCP_sock then
        TCP_sock:close()
        TCP_sock = nil
    else
        -- nothing to do
    end
end

--- Parse each type of message to game state
-- @function get_message
-- @param nil
-- @return nil
function get_message()

    local kind, gap, length, byte

    function _verify_leftovers()
        if string.len(leftovers) == 0 then
          kind = nil
          devolution = nil
        else
            -- nothing to do
        end
    end

    -- @todo understand all of this lenght parse
    local type_to_length = {G=1,H=1, N=1, E=4, P=121, O=121,
                            I=2, Q=121, R=121, L=2, U=2}

    gap = 0
    length = string.sub(leftovers, 1, 1)
    byte = string.byte

    _verify_leftovers()

    -- "J" represent json in code
    if kind == 'J' then

        if string.len(leftovers) >= 4 then
            length = byte(string.sub(leftovers, 2, 2)) * WORD_LEN +
            byte(string.sub(leftovers, 3, 3)) * BITS_256 +
            byte(string.sub(leftovers, 4, 4))

            print('json message has length '.. length)

            gap = 3
        else
          kind = nil
          devolution = nil
        end
    else
        length = type_to_length[kind] - 1
    end

    -- Verify string length leftovers
    if length + gap + 1 > string.len(leftovers) then
        kind = nil
        devolution = nil
    else

        local devolution = string.sub(leftovers,2+gap,length+gap+1)
        leftovers = string.sub(leftovers,length+gap+2)

        return kind, devolution
    end
end

--- queue of data in connection
local lag_queue = Queue()

--- Send a queue of data in socket
-- @function send_net
-- @param ...
-- @return nil
function send_net(...)

    local MAX_BUFFER = 70

    if not STONER_MODE then
        TCP_sock:send(...)
    else
        lag_queue:push({...})

        -- trick for dont buffer
        -- @todo refactor this
        if lag_queue:len() == MAX_BUFFER then
            local head_queue = lag_queue:pop()
            local unpack_head = unpack(head_queue)
            TCP_sock:send(unpack_head)
        else
            -- nothing to do
        end
    end
end

--- Maximum of 8 bit represetantion
local BITS_256 = 256

--- Send json object using TCP socket
-- @function send_json
-- @param obj
-- @return nil
function send_json(obj)

    local json = json.encode(obj) -- Recieve a object and encode to json
    local json_length = json:len() -- Get json length
    local prefix = 'J' .. char(floor(json_length/WORD_LEN)) ..

    send_net(prefix..json)
end

--- Clean queue sending all the data
-- @function undo_stonermode
-- @param nil
-- @return nil
function undo_stonermode()
    while lag_queue:len() ~= 0 do
        local head_queue = lag_queue:pop()
        local unpack_head = unpack(head_queue)
        TCP_sock:send(unpack_head)
    end
end

local got_H = false

--- map of functions
--- @todo understand this
local process_message = {
    L = function(s)
            P2_level = ({['0']=10})[s] or (s+0)
        end,
    --G=function(s) got_opponent = true end,
    H = function(s)
            got_H = true
        end,
    N = function(s)
          error('Server told us to upgrade the game at ' ..
        'burke.ro/panel.zip (for burke.ro server) or the TetrisAttackOnline ' ..
        "Discord (for Jon's Server)")
        end,
    P = function(s)
            P1.panel_buffer = P1.panel_buffer..s
        end,
    O = function(s)
            P2.panel_buffer = P2.panel_buffer..s
        end,
    -- used for P1's inputs when spectating.
    U = function(s)
            P1.input_buffer = P1.input_buffer..s
        end,
    I = function(s)
            P2.input_buffer = P2.input_buffer..s
        end,
    Q = function(s)
            P1.gpanel_buffer = P1.gpanel_buffer..s
        end,
    R = function(s)
            P2.gpanel_buffer = P2.gpanel_buffer..s
        end,
    --connection_up_time counts 'E' messages, not seconds
    E = function(s)
            send_net('F'..s) connection_up_time = connection_up_time + 1
        end,
    J = function(s)
            local current_message = json.decode(s)
            this_frame_messages[#this_frame_messages+1] = current_message

            print('JSON LOL '..s)

            -- current_message should be false, if not have error
            if not current_message then
                error('Error in network.lua process_message\nMessage: \''..
                (s or 'nil')..'\'\ncould not be decoded')
            elseif current_message.spectators then
                -- Verify if exist spectators
                spectator_list = current_message.spectators
                spectators_string = spectator_list_string(
                    current_message.spectators)
            else
                -- nothing to do
            end
        end
    }

--- Config socket (set timeout, ip, port)
-- @function network_init
-- @param ip init interface with this ip
-- @return nil
-- @raise Failed to connect
function network_init(ip)

    --  Verify json atributes
    function _verify_json()

      assert(config.name, "name atribute in message not found")
      assert(config.level, "levelatribute in message not found")
      assert(config.character, "character atribute in message not found")
      assert(config.save_replays_publicly,
             "save_replays_publicly atribute in message not found")

    end

    local DEFAULT_TIMEOUT = 7

    TCP_sock = socket.tcp()
    TCP_sock:settimeout(DEFAULT_TIMEOUT)
    -- Verify TCP connection

    local SOCKET_PORT = 49569

    if not TCP_sock:connect(ip, SOCKET_PORT) then
        error('Failed to setup the socket')
    else
        -- this timeout is duplicated
        TCP_sock:settimeout(0)
        got_H = false
        send_net('H'..VERSION)

        _verify_json()

        send_json({name=config.name, level=config.level, character=config.character,
                  save_replays_publicly = config.save_replays_publicly})
    end

end

--- Verify if connection is ready
-- @function connection_is_ready
-- @param nil
-- @return nil
function connection_is_ready()
    return got_H and #this_frame_messages > 0
end

--- Get messages and run connection
-- @function do_messages
-- @param nil
-- @return nil
function do_messages()

    flush_socket()

    local kind, data

    while true do

        data = get_message()

        if type then

            if kind ~= 'I' and kind ~= 'U' then
                print('Got message '.. kind ..' '..data)
            else
                -- nothing to do
            end

            process_message[kind](data)

            if kind == 'J' then
                if this_frame_messages[#this_frame_messages].replay_of_match_so_far then
                    --print('***BREAKING do_messages because received a replay')
                   -- we need to initialize P1 and P2 before we do any
				           --I or U messages
                   break  -- don't process any more messages this frame
                else
                    -- nothing to do
                end
            else
              -- nothing to do
            end

            if kind == 'U' then
                kind = 'in_buf'
            else
                -- nothing to do
            end

            if P1 and P1.mode and replay[P1.mode][kind] then
                replay[P1.mode][kind]=replay[P1.mode][kind]..data
            else
                -- nothing to do
            end

        else
            break
        end
    end
end

--- Request connection of the game
-- @function request_game
-- @param name of json
-- @return nil
function request_game(name)
    send_json({game_request={sender=config.name, receiver=name}})
end

--- Request spectator from server
-- @function request_spectate
-- @param roomNr name of json
-- @return nil
function request_spectate(roomNr)
    send_json({spectate_request={sender=config.name, roomNumber = roomNr}})
end

--- Update panels data
-- @function ask_for_panels
-- @param prev_panels actual panels
-- @return nil
function ask_for_panels(prev_panels)
    if TCP_sock then
        send_net('P'..tostring(P1.NCOLORS)..prev_panels)
    else
        make_local_panels(P1, prev_panels)
    end
end

--- Update global panels data
-- @function ask_for_gpanels
-- @param prev_panels actual panels state
-- @return nil
function ask_for_gpanels(prev_panels)
    if TCP_sock then
        send_net('Q'..tostring(P1.NCOLORS)..prev_panels)
    else
        make_local_gpanels(P1, prev_panels)
    end
end

--- Create panels using actual state panels
-- @function make_local_panels
-- @param stack data structure
-- @param prev_panel actual state of panels
-- @return nil
function make_local_panels(stack, prev_panels)
    local ret = make_panels(stack.NCOLORS, prev_panels, stack)

    stack.panel_buffer = stack.panel_buffer .. ret

	  local replay = replay[P1.mode]

    if replay and replay.pan_buf then
        replay.pan_buf = replay.pan_buf .. ret
    else
        --- nothing to do
    end
end

--- Create global panels using acutal state
-- @function make_local_gpanels
-- @param stack data structure
-- @param prev_panels actual state of panels
-- @return nil
function make_local_gpanels(stack, prev_panels)

    local ret = make_gpanels(stack.NCOLORS, prev_panels)

    stack.gpanel_buffer = stack.gpanel_buffer .. ret

    local replay = replay[P1.mode]

    -- If local and global panels has updated save replay in buffer
    if replay and replay.gpan_buf then
        replay.gpan_buf = replay.gpan_buf .. ret
    else
        -- nothing to do
    end
end

--- Send stack of controls for replay mode
-- @function STack.send_controls
-- @param self class method
-- @return Base64 encoded data
function Stack.send_controls(self)

  local k = keyboard[self.which] -- Represent keyboard
  local to_send

  to_send = base64encode[
    ((keys[k.raise_faster1] or keys[k.raise_faster2] or
      this_frame_keys[k.raise_faster1] or this_frame_keys[k.raise_faster2])
      and 32 or 0) +
    ((this_frame_keys[k.swap1] or this_frame_keys[k.swap2]) and 16 or 0) +
    ((keys[k.up] or this_frame_keys[k.up]) and 8 or 0) +
    ((keys[k.down] or this_frame_keys[k.down]) and 4 or 0) +
    ((keys[k.left] or this_frame_keys[k.left]) and 2 or 0) +
    ((keys[k.right] or this_frame_keys[k.right]) and 1 or 0)+1]

    -- load TCP_sock with invited query
    if TCP_sock then
        send_net('I'..to_send)
    else
        -- nothing to do
    end

    local replay = replay[self.mode]

    if replay and replay.in_buf then
        replay.in_buf = replay.in_buf .. to_send
    else
        -- nothing to do
    end

    return to_send
end
