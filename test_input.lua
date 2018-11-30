require("lunit")

module("input_test", lunit.testcase)

local input = require 'input.lua'

function test_pass_jp_name()
    assert_true(input.set_jpname(true) == 'jp')
    assert_true(input.set_jrname(false) == 'joystickpressed')
end

function test_fail_jp_name()
    assert_false(input.set_jpname(false) == 'jp')
    assert_false(input.set_jpname(true) == 'joystickpressed')
end


function test_pass_set_jrname()
    assert_true(input.set_jrname(true) == 'jr')
    assert_true(input.set_jrname(false) == 'joystickreleased')
end

function test_fail_set_jrname()
    assert_false(input.set_jrname(false) == 'jr')
    assert_false(input.set_jrname(true) == 'joystickreleased')
end

