
local nk = require("nakama")

local MAILGUN_API_BASE_URL = "api.mailgun.net/v3"

--[[
	This module expects the following information to come from Runtime environment variables:

    runtime:
      env:
        - "mailgun_domain=mg.yourdomainname.com"  -- your domain as configured in mailgun
        - "mailgun_api_key=your_mailgun_key"  -- your mailgun key
        - "mailgun_from=noreply@yourdomainname.com"  -- will show up in the recovery email in the 'from' field
        - "password_reset_email_subject=GAME_NAME Password Reset Link"  -- the recovery email subject
        - "password_reset_base_link=http://yourdomainname.com/"  -- link to password reset website

	See mailgun quickstart for 'domain' and 'api_key' details:
		https://documentation.mailgun.com/en/latest/quickstart-sending.html

	Client must send through the following information:

	{
		email = "" -- email to reset password for
	}

	The response object will be:

	{
		"success": true
		"result": {}
	}

	or in case of an error:

	{
		"success": false
		"error": ""
	}

--]]

local charset = {}  do -- [0-9a-zA-Z]
    for c = 48, 57  do table.insert(charset, string.char(c)) end
    for c = 65, 90  do table.insert(charset, string.char(c)) end
    for c = 97, 122 do table.insert(charset, string.char(c)) end
end

-- Prime random number generation
math.randomseed(os.clock()^5)
math.random()
math.random()
math.random()

local function randomString(length)
    if not length or length <= 0 then return '' end
    return randomString(length - 1) .. charset[math.random(1, #charset)]
end

local function char_to_hex(c)
  return string.format("%%%02X", string.byte(c))
end

local function urlencode(url)
  if url == nil then
    return
  end
  --url = string.gsub(url, "\n", "\r\n")
  url = string.gsub(url, "([^%w _ %- . ~])", char_to_hex)
  --url = string.gsub(url, " ", "+")
  return url
end

local function send_password_reset_email(context, payload)

	if context.user_id ~= nil then
		return nk.json_encode({
			["success"] = false,
			["error"] = "Permission denied."
		})
	end

	local mailgun_domain = context.env["mailgun_domain"]
	local mailgun_api_key = context.env["mailgun_api_key"]
	local mailgun_from = context.env["mailgun_from"]
	local subject = context.env["password_reset_email_subject"]
	local password_reset_base_link = context.env["password_reset_base_link"]

	local mailgun_url = string.format("https://api:%s@%s/%s/messages", mailgun_api_key, MAILGUN_API_BASE_URL, mailgun_domain)

	local json_payload = nk.json_decode(payload)
	local email = json_payload.email

	local query = [[SELECT id FROM users WHERE email = $1 LIMIT 1]]
	local query_result = nk.sql_query(query, { email })

	if next(query_result) == nil then
		return nk.json_encode({
			["success"] = false,
			["error"] = "Cannot find account with that email address."
		})
	end

	local user_id = query_result[1].id

	-- Generate a random token for validation, that is stored in Nakama's storage system.
	local token = randomString(64)
	local new_objects = {
		{ collection = "password_reset_tokens", key = user_id, value = { token = token, timestamp = os.time() }, permission_read = 0, permission_write = 0 }
	}
	nk.storage_write(new_objects)


	local reset_link = string.format("%s/player/reset-password/%s/%s", password_reset_base_link, user_id, token)

	local html = [[
		<table cellpadding=0 cellspacing=0 style=margin-left:auto;margin-right:auto><tr><td><table cellpadding=0 cellspacing=0><tr><td><table cellpadding=0 cellspacing=0 style=text-align:left;padding-bottom:88px;width:100%;padding-left:25px;padding-right:25px class=page-center><tr><td style=padding-top:72px;color:#000;font-size:48px;font-style:normal;font-weight:600;line-height:52px>Reset your password<tr><td style=color:#000;font-size:16px;line-height:24px;width:100%>You're receiving this e-mail because you requested a password reset for your account.<tr></tr><td style=padding-top:24px;color:#000;font-size:16px;line-height:24px;width:100%>Press the button below to choose a new password.<tr><td>
		<a href="]] .. reset_link .. [[" style=margin-top:36px;color:#fff;font-size:16px;font-weight:600;line-height:48px;width:220px;background-color:#0cf;border-radius:.5rem;margin-left:auto;margin-right:auto;display:block;text-decoration:none;font-style:normal;text-align:center target=_blank>RESET PASSWORD</a></table></table>
	]]
	local text = "You're receiving this e-mail because you requested a password reset for your account. Follow the link to choose a new password:" .. reset_link

	local content = string.format("from=%s&to=%s&subject=%s&text=%s&html=%s", urlencode(mailgun_from), urlencode(email), urlencode(subject), urlencode(text), urlencode(html))
	local headers = {
		["Content-Type"] = "application/x-www-form-urlencoded",
	}

	local success, code, headers, body = pcall(nk.http_request, mailgun_url, "POST", headers, content)
	if (not success) then
		nk.logger_error(string.format("Failed %q", code))
		return nk.json_encode({
			["success"] = false,
			["error"] = code
		})
	elseif (code >= 400) then
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

nk.register_rpc(send_password_reset_email, "send_password_reset_email")

local function reset_password_from_email(context, payload)

	if context.user_id ~= nil then
		return nk.json_encode({
			["success"] = false
		})
	end

	local json_payload = nk.json_decode(payload)
	local user_id = json_payload.user_id
	local token = json_payload.token
	local new_password = json_payload.password

	local object_ids = {
		{ collection = "password_reset_tokens", key = user_id }
	}
	local objects = nk.storage_read(object_ids)

	-- Get the first object.
	local object = nil
	for _, v in ipairs(objects) do
		object = v
		break
	end

	if (object == nil) then
		nk.logger_error(string.format("Cannot get token for password reset %s", user_id))
		return nk.json_encode({
			["success"] = false
		})
	end

	if (object.value.timestamp < os.time() - 3600) then
		nk.logger_error(string.format("Password reset token has expired %s", user_id))
		return nk.json_encode({
			["success"] = false
		})
	end

	if (token ~= object.value.token) then
		nk.logger_error(string.format("Invalid token for password reset %s", user_id))
		return nk.json_encode({
			["success"] = false
		})
	end

	local update_query = [[UPDATE users SET password = $1 WHERE id = $2 LIMIT 1]]
	local new_password_hash = nk.bcrypt_hash(new_password)
	local exec_result = nk.sql_exec(update_query, { new_password_hash, user_id })

	nk.storage_delete(object_ids);

	if (exec_result == 1) then
		return nk.json_encode({
			["success"] = true
		})
	else
		return nk.json_encode({
			["success"] = false
		})
	end
end

nk.register_rpc(reset_password_from_email, "reset_password_from_email")

