extends Node

onready var http_request = $HTTPRequest

var twilio_account_sid := ''
var twilio_auth_token := ''

signal tokens_generated (tokens)

const ENDPOINT = "https://api.twilio.com/2010-04-01/Accounts/%s/Tokens.json"

func generate_tokens() -> bool:
	if twilio_account_sid.length() == 0 or twilio_auth_token.length() == 0:
		return false
	
	var credentials = Marshalls.utf8_to_base64("%s:%s" % [twilio_account_sid, twilio_auth_token])
	var error = http_request.request(ENDPOINT % twilio_account_sid, ['Authorization: Basic %s' % credentials], true, HTTPClient.METHOD_POST, '')
	if error != OK:
		push_error("Unable to make request to Twilio endpoint")
		return false
	
	return true

func _parse_result(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray) -> Array:
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Error making HTTP request to Twilio: %s" % result)
		return []
	
	var data = body.get_string_from_utf8()
	var json_result := JSON.parse(data)
	if json_result.error != OK:
		push_error("Unable to parse response from Twilio: %s" % data)
		return []
	
	if typeof(json_result.result) != TYPE_DICTIONARY:
		push_error("Got unexpected data type from Twilio: %s" % json_result.result)
		return []
	
	return json_result.result.get("ice_servers", [])

func _on_HTTPRequest_request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray) -> void:
	emit_signal("tokens_generated", _parse_result(result, response_code, headers, body))
