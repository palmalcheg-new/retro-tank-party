tool
extends Node

var NakamaRealtimeClient = preload("res://addons/nakama-client/NakamaRealtimeClient.gd")

export (String) var host = "127.0.0.1"
export (int) var port = 7350
export (String) var server_key = "defaultkey"
export (bool) var use_ssl = false
export (bool) var ssl_validate = false
export (bool) var debugging = false

var authenticated := false
var session_token := ''
var session_expires := 0

var client : HTTPRequest = HTTPRequest.new()
var current_request
var last_response

signal completed (response, request)

func _ready() -> void:
	add_child(client)
	client.connect("request_completed", self, "_on_HTTPRequest_completed")

func _request(request : Dictionary) -> int:
	current_request = request
	
	var url = ('https://' if use_ssl else 'http://') + host + ':' + str(port) + '/' + request['path']
	if request.has('query_string') && request['query_string'].size() > 0:
		var query_string = PoolStringArray()
		for k in request['query_string'].keys():
			query_string.append(k + '=' + request['query_string'][k].percent_encode())
		url += '?' + query_string.join('&')
	
	var headers = [
		'Content-Type: application/json',
		'Accept: application/json',
	]
	
	if authenticated:
		headers.append('Authorization: Bearer ' + session_token)
	else:
		headers.append('Authorization: Basic ' + Marshalls.utf8_to_base64(server_key + ':'))
	
	var data = ''
	if request.has('data'):
		data = JSON.print(request['data'])
	
	if debugging:
		print ("NAKAMA REQUEST: " + url)
		print (headers)
		print (data)
	
	return client.request(url, headers, ssl_validate, request['method'], data)

func _on_HTTPRequest_completed(result, response_code, headers, body : PoolByteArray):
	var response = {
		result = result,
		http_code = response_code,
		headers = headers,
		body = body.get_string_from_utf8(),
		data = {},
	}
	
	if result == HTTPRequest.RESULT_SUCCESS:
		var parse_result = JSON.parse(response['body'])
		if parse_result.error == OK:
			response['data'] = parse_result.result
		
			# If the user successfully authenticated, then store the session token.
			if current_request['name'].begins_with('authenticate_') && response_code == 200 && response['data'].has('token'):
				authenticated = true
				_set_session(response['data']['token'])
	
	# Clear current_request before emitting signals, because starting a new request on a signal
	# is a super common thing to do, and it won't work if current_request is still set.
	var request = current_request
	current_request = null
	
	# Store the last response for use via yield
	last_response = response
	
	if debugging:
		print ("NAKAMA RESPONSE:")
		print (response)
	
	emit_signal(request['name'] + '_completed', response, request)
	emit_signal('completed', response, request)

func _set_session(_session_token):
	authenticated = true
	session_token = _session_token
	session_expires = 0
	
	var parts = session_token.split('.')
	if parts.size() != 3:
		# Something is up with this token! Bail.
		return

	# Godot's base64 utility requires padding on the base64, but the value
	# we get from the JWT token has it stripped. So, add it back first.
	var base64_text = parts[1]
	while base64_text.length() % 4 != 0:
		base64_text += '='
		
	var parse_result = JSON.parse(Marshalls.base64_to_utf8(base64_text))
	if parse_result.error != OK:
		return
	
	var data = parse_result.result
	if data.has('exp'):
		session_expires = int(data['exp'])

func is_session_expired():
	if not session_token:
		return true
	return OS.get_system_time_secs() > session_expires

# If create_status = True, it'll show the user as connected.
func create_realtime_client(create_status : bool = false):
	if not authenticated:
		return null
	
	var url = ('wss://' if use_ssl else 'ws://') + host + ':' + str(port) + '/ws?lang=en&status=' + ('true' if create_status else 'false') + '&token=' + session_token.percent_encode()
	var rtclient = NakamaRealtimeClient.new()
	rtclient.debugging = debugging
	rtclient.connect_to_url(url)
	return rtclient

signal authenticate_email_completed (response, request)

func authenticate_email(email : String, password : String, create : bool = false, username : String = ''):
	if current_request:
		return ERR_ALREADY_IN_USE
	
	if authenticated:
		authenticated = false
		session_token = ''
		session_expires = 0
	
	var request = {
		method = HTTPClient.METHOD_POST,
		path = 'v2/account/authenticate/email',
		data = {
			'email': email,
			'password': password,
		},
		query_string = {},
		name = 'authenticate_email',
	}
	
	if create:
		request['query_string']['create'] = 'true'
	if username != '':
		request['query_string']['username'] = username
	
	return _request(request)

signal get_account_completed (response, request)

func get_account():
	if current_request:
		return ERR_ALREADY_IN_USE
	
	var request = {
		method = HTTPClient.METHOD_GET,
		path = 'v2/account',
		name = 'get_account',
	}
	
	return _request(request)
	
