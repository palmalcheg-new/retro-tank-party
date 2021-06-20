
local nk = require("nakama")

local function disable_hook(context, payload)
	return nil
end

-- Comment out the authentication methods you want to leave enabled.

nk.register_req_before(disable_hook, "AuthenticateDevice")
--nk.register_req_before(disable_hook, "AuthenticateEmail")
nk.register_req_before(disable_hook, "AuthenticateFacebook")
nk.register_req_before(disable_hook, "AuthenticateFacebookInstantGame")
nk.register_req_before(disable_hook, "AuthenticateGoogle")
nk.register_req_before(disable_hook, "AuthenticateGameCenter")
--nk.register_req_before(disable_hook, "AuthenticateSteam")
nk.register_req_before(disable_hook, "AuthenticateCustom")

