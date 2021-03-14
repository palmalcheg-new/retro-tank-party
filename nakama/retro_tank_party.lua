
local nk = require("nakama")

--[[
	This function expects the following information to come from Runtime environment variables:

    runtime:
      env:
        - "twilio_account_sid=your_account_sid"
        - "twilio_auth_token=your_auth_token"
--]]

local function get_ice_servers(context, payload)

	local twilio_account_sid = context.env["twilio_account_sid"]
	local twilio_auth_token = context.env["twilio_auth_token"]

	local url = string.format("https://api.twilio.com/2010-04-01/Accounts/%s/Tokens.json", twilio_account_sid)
	local credentials = nk.base64_encode(string.format("%s:%s", twilio_account_sid, twilio_auth_token))
	local headers = {
		["Authorization"] = string.format("Basic %s", credentials),
	}

	local success, code, headers, body = pcall(nk.http_request, url, "POST", headers, '')
	if (not success) then
		nk.logger_error(string.format("Failed %q", code))
		return nk.json_encode({
			["success"] = false,
			["error"] = code
		})
	elseif (code ~= 201) then
		nk.logger_error(string.format("Failed %q %q", code, body))
		return nk.json_encode({
			["success"] = false,
			["error"] = code,
			["response"] = body
		})
	else
		nk.logger_info(string.format("Success %q %q", code, body))
		return nk.json_encode({
			["success"] = true,
			["response"] = nk.json_decode(body)
		})
	end
end


nk.register_rpc(get_ice_servers, "get_ice_servers")

