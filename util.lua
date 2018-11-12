local sort, pairs, select, unpack, error =
    table.sort, pairs, select, unpack, error
local type, setmetatable, getmetatable =
            type, setmetatable, getmetatable
local random = math.random

-- import logging system
log = require("log")

--- Return a key in current the frame
-- @param key 
-- @return 
function normal_key(key)
    return this_frame_keys[key]
end

-- Keys that have a fixed function in menus can be bound to other
-- meanings, but should continue working the same way in menus.
function repeating_key(key)
    local key_time = keys[key]
    return this_frame_keys[key] or
        (key_time and key_time > 25 and key_time % 3 ~= 0)
end


--- Sets up a button in the keyboard regarding its fixed and configurable behaviour
-- @param fixed table with the desired behaviour
-- @param configurable table which the desired behaviour
-- @param rept boolean tells if a button repeats(like pressing and holding)
-- @return a fuction with 1 param 
function menu_key_func(fixed, configurable, rept)
    assert(fixed, "Menu key func param fixed is nil")
    assert(configurable, "Menu key func param configurable is nil")

    local query = nil
    local menu_reserved_keys = {}

    if rept then
        query = repeating_key
        log.debug("Query = repeating_key")
    else
        query = normal_key
        log.debug("Query = normal_key")
    end
    
    for i=1, #fixed do
        menu_reserved_keys[#menu_reserved_keys + 1] = fixed[i]
    end
    
    return function(k)
        local res = false
        if multi then
            for i=1,#configurable do
                res = res or query(k[configurable[i]])
            end
        else
            for i=1, #fixed do
                res = res or query(fixed[i])
            end
            for i=1, #configurable do
                local keyname = k[configurable[i]]
                res = res or query(keyname) and
                not menu_reserved_keys[keyname]
            end
        end
        return res
    end
end

-- map for numeric tables 
function map(func, tab)
    log.debug("Map called") 
    local ret = {}
    for i=1, #tab do
        ret[i]=func(tab[i])
    end
    return ret
end


function map_inplace(func, tab) 
    for i=1, #tab do
        tab[i]=func(tab[i])
    end
    return tab
end

function map_dict_inplace(func, tab) 
    for key,val in pairs(tab) do
        tab[key]=func(val)
    end
    return tab
end

-- map for dicts 
function map_dict(func, tab)
    local ret = {}
    for key,val in pairs(tab) do
        ret[key]=func(val)
    end
    return ret
end

-- reduce for numeric tables 
function reduce(func, tab, ...)
    log.trace("Reduce table") 

    local idx, value = 2, nil
    if select("#", ...) ~= 0 then
        value = select(1, ...)
        idx = 1
    elseif #tab ~= 0 then
        value = tab[1]
    elseif #tab == 0 then
        log.error("Tried to reduce empty table with no initial value")  
    end

    for i=idx,#tab do
        value = func(value, tab[i])
    end

    return value
end

function content_equal(a,b) 
    log.trace("Content_equal called") 

    if type(a) ~= "table" or type(b) ~= "table" then
        log.debug("a or b is not a table") 

        return a == b
    end

    log.info("a and b are tables") 

    for i=1,2 do
        for k,v in pairs(a) do
            if b[k] ~= v then
                return false
            end
        end
        a,b=b,a
    end

    return true
end

-- iterate over frozen pairs in sorted order 
function spairs(tab)
    log.trace("Spairs called") 

    local keys,vals,idx = {},{},0
    for k in pairs(tab) do
        keys[#keys+1] = k
    end

    sort(keys)
    log.debug("Keys sorted") 

    for i=1,#keys do
        vals[i]=tab[keys[i]]
    end

    return function()
        idx = idx + 1
        log.debug("Returning keys[idx] and vals[idx] of the new idx") 

        return keys[idx], vals[idx]
    end
end

-- bounds b so a<=b<=c
function bound(a, b, c) 
    log.trace("Bound (a,b,c) called") 

    if b<a then 
        log.info("b < a")

        return a
    elseif b>c then
        log.info("b > c")  

        return c
    else
        log.info("a > b > c")

        return b 
    end
end

-- mods b so a<=b<=c
function wrap(a, b, c)
    log.trace("Wrap (a,b,c) called") 

    return (b-a)%(c-a+1)+a
end

--Note: this round() doesn't work with negative numbers 
function round(positive_decimal_number, number_of_decimal_places)
    log.trace("Round called") 

    if not number_of_decimal_places then
        number_of_decimal_places = 0
    end

    return math.floor(positive_decimal_number*10^number_of_decimal_places+0.5)/10^number_of_decimal_places
end

function car(tab)
    log.trace("Car called") 

    return tab[1]
end

function cdr(tab)
    log.trace("Cdr called") 

    return {select(2, unpack(tab))}
end

-- a useful right inverse of table.concat
function procat(str)
    log.trace("Procat called") 
    local ret = {}

    for i=1,#str do
        ret[i]=str:sub(i,i)
    end

    return ret
end

function uniformly(t)
    log.trace("Uniformly called") 

    return t[random(#t)]
end

-- does not perform deep comparisons of keys which are tables.
function deep_content_equal(a,b)
    log.trace("Deep_content_equal called") 

    if type(a) ~= "table" or type(b) ~= "table" then
        log.debug("a or b isn't a table") 
        return a == b
    end

    log.debug("a and b are tables") 

    for i=1,2 do
        for k,v in pairs(a) do
            if not deep_content_equal(v,b[k]) then
                return false
            end
        end
        a,b=b,a
    end

    return true
end

function shallowcpy(tab)
    log.trace("Shallowcpy called")
    local ret = {}
    
    for k,v in pairs(tab) do
        ret[k]=v
    end

    return ret
end

local deepcpy_mapping = {}
local real_deepcpy
function real_deepcpy(tab)
    log.trace("Real_deepcpy called") 

    if deepcpy_mapping[tab] ~= nil then
        log.debug("deepcpy_mapping[tab] isn't nil") 

        return deepcpy_mapping[tab]
    end

    log.debug("deepcpy_mapping[tab] is nil") 

    local ret = {}
    deepcpy_mapping[tab] = ret
    deepcpy_mapping[ret] = ret
    for k,v in pairs(tab) do
        if type(k) == "table" then
            k=real_deepcpy(k)
        end
        if type(v) == "table" then
            v=real_deepcpy(v)
        end
        ret[k]=v
    end

    return setmetatable(ret, getmetatable(tab))
end

function deepcpy(tab) 
    log.trace("Deepcpy called") 

    if type(tab) ~= "table" then
        log.debug("tab isn't a table") 

        return tab 
    end

    log.debug("tab is a table") 

    local ret = real_deepcpy(tab)
    deepcpy_mapping = {}
    return ret
end

-- Not actually for encoding/decoding byte streams as base64.
-- Rather, it's for encoding streams of 6-bit symbols in printable characters.
base64encode = procat("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890+/")
base64decode = {}
for i=1,64 do
    local val = i-1
    base64decode[base64encode[i]]={}
    local bit = 32
    for j=1,6 do
        base64decode[base64encode[i]][j]=(val>=bit)
        val=val%bit
        bit=bit/2
    end
end
