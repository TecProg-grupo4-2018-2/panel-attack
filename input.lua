-----------------
--- Input Module
--- Handle input hardware
--- @module input

local jpexists, jpname, jrname

log = require("log")

-- set jpexists if key is 'jp'
for k,v in pairs(love.handlers) do
    if k=="jp" then
        jpexists = true
    end
end

-- set variables names
if jpexists then
    jpname = "jp"
    jrname = "jr"
else
    jpname = "joystickpressed"
    jrname = "joystickreleased"
end

local __old_jp_handler = love.handlers[jpname]
local __old_jr_handler = love.handlers[jrname]


love.handlers[jpname] = function(a, b)
    __old_jp_handler(a,b)
    love.keypressed("j"..a:getID()..b)
end

love.handlers[jrname] = function(a,b)
    __old_jr_handler(a,b)
    love.keyreleased("j"..a:getID()..b)
end

local prev_ax = {}

--- Press a button o relased then
-- @function axis_to_buttonA
-- @param idx index of a joystick axis
-- @param value value of the axis
-- @return nil
local axis_to_button = function(idx, value)

    local prev = prev_ax[idx] or 0

    assert(value > .0)
    assert(value < 1.0)

    if value > .5 then
        if prev < .5 then
            log.debug("value > 5 and prev < .5")
            love.keypressed("ja"..idx.."+")
        end
    elseif value < -.5 then
        if prev > -.5 then
            log.debug("value < 5 and prev < .5")
            love.keypressed("ja"..idx.."-")
        end
    else
        
        log.debug("key released")

        if prev > .5 then
            love.keyreleased("ja"..idx.."+")
        elseif prev < -.5 then
            love.keyreleased("ja"..idx.."-")
        end
    end

    prev_ax[idx] = value

end

local prev_hat = {{},{}}

--- get a direction of a button
-- @function hat_to_button
-- @param idx index of the control
-- @param value value of this control
-- @return nil
local hat_to_button = function(idx, value)

    if string.len(value) == 1 then
        if value == "l" or value == "r" then
            value = value .. "c"
        else
            value = "c" .. value
        end
    end
   
    value = procat(value)

    for i=1,2 do
        local prev = prev_hat[i][idx] or "c"

        if value[i] ~= prev and value[i] ~= "c" then
            love.keypressed("jh"..idx..value[i])
        end

        if prev ~= value[i] and prev ~= "c" then
            love.keyreleased("jh"..idx..prev)
        end
        prev_hat[i][idx] = value[i]
    end

end

--- Get the direction of a joystick
-- @function love.joystick.getHats
-- @paramm joystick
-- @return A table of directions
function love.joystick.getHats(joystick)

    local n = joystick:getHatCount()
    local ret = {}

    for index_joystick=1,n do

        log.debug("Get the joystick number "..i.."/"..n)
        directions[index_joystick] = joystick:getHat(index_joystick)
    end
    
    return unpack(directions)

end

--- Get all axes of a joystick and press thess
-- @function joystick_ax
-- @param nil
-- @return nil
function joystick_ax()
    local joysticks = love.joystick.getJoysticks()

    for k,v in ipairs(joysticks) do
        local axes = {v:getAxes()}

        for idx,value in ipairs(axes) do
            axis_to_button(k..idx, value)
        end

        local hats = {love.joystick.getHats(v)}

        for idx,value in ipairs(hats) do
            hat_to_button(k..idx, value)
        end
    end
end

--- 
-- @function love.keypressed
-- @param key character of key pressed
-- @param isrepeat view if the pressed action is repeated
-- @return nil
function love.keypressed(key, isrepeat)

    if key == "return" and not isrepeat and love.keyboard.isDown("lalt") then
        love.window.setFullscreen(not love.window.getFullscreen(), "desktop")
        return
    else
        if not isrepeat then 
            keys[key] = 0
        end

        this_frame_keys[key] = true
        
    end

end

--- Text inserted by the user
-- @function love.textinput
-- @param text input text
-- @return nil
function love.textinput(text)

    log.debug("Text inserted: "..text)
    this_frame_unicodes[#this_frame_unicodes+1] = text
end

--- Release a buttom 
-- @function love.keyreleased
-- @param key key for release
-- @param unicode codification for the text (not used)
-- @return nil
function love.keyreleased(key, unicode)
    log.debug("Release the key: "..key)
    keys[key] = nil
end

--- Map the number of times with a pressed key
-- @function key_counts
-- @param nil
-- @return nil
function key_counts()

    for key,value in pairs(keys) do
        keys[key] = value + 1
    end

end

--- Handle a virtual stack for controls
-- @function Stack.controls
-- @param self ??
-- @return nil
function Stack.controls(self)

    local new_dir = nil
    local sdata = self.input_state
    local raise, swap, up, down, left, right = unpack(base64decode[sdata])
    
    if (raise) and (not self.prevent_manual_raise) then
        self.manual_raise = true
        self.manual_raise_yet = false
    end

    self.swap_1 = swap
    self.swap_2 = swap

    if up then
        log.debug("up key")
        new_dir = "up"
    elseif down then
        log.debug("down key")
        new_dir = "down"
    elseif left then
        log.debug("left key")
        new_dir = "left"
    elseif right then
        log.debug("right key")
        new_dir = "right"
    end

    if new_dir == self.cur_dir then
        if self.cur_timer ~= self.cur_wait_time then
            self.cur_timer = self.cur_timer + 1
        end
    else
        self.cur_dir = new_dir
        self.cur_timer = 0
    end

end
