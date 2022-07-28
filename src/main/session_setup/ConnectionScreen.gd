extends "res://src/ui/Screen.gd"

var Steam = Engine.get_singleton("Steam")

onready var tab_container := $TabContainer
onready var login_email_field := $TabContainer/Login/GridContainer/Email
onready var login_password_field := $TabContainer/Login/GridContainer/Password
onready var login_save_checkbox := $TabContainer/Login/GridContainer/SaveCheckBox
onready var create_account_tab := $"TabContainer/Create Account"
onready var create_account_username_field = $"TabContainer/Create Account/GridContainer/Username"
onready var create_account_save_checkbox := $"TabContainer/Create Account/GridContainer/SaveCheckBox"
onready var forgot_password_tab = $"TabContainer/Forgot password?"
onready var steam_tab = $TabContainer/Steam
onready var steam_username_field := $TabContainer/Steam/GridContainer/Username
onready var steam_login_button := $TabContainer/Steam/SteamLoginButton

const CREDENTIALS_FILENAME = 'user://credentials.json.enc'
const CREDENTIALS_FILENAME_OLD = 'user://credentials.json'

const FORGOT_PASSWORD_URL = 'https://www.snopekgames.com/player/forgot-password'

var email: String = ''
var password: String = ''

var _reconnect: bool = false
var _next_screen

enum LoginType {
	EMAIL,
	STEAM
}
var _login_type = LoginType.EMAIL

var _steam_auth_session_ticket: String = ''
var _steam_create := false

func _ready() -> void:
	tab_container.set_tab_title(0, "SESSION_SETUP_TAB_STEAM")
	tab_container.set_tab_title(1, "SESSION_SETUP_TAB_LOGIN")
	tab_container.set_tab_title(2, "SESSION_SETUP_TAB_CREATE_ACCOUNT")
	tab_container.set_tab_title(3, "SESSION_SETUP_TAB_FORGOT_PASSWORD")

	if SteamManager.use_steam:
		Steam.connect("get_auth_session_ticket_response", self, "_on_steam_auth_session_ticket_response")

		create_account_tab.queue_free()
		tab_container.set_tab_title(0, "SESSION_SETUP_TAB_CREATE_ACCOUNT")
		steam_username_field.text = Steam.getPersonaName()
	else:
		tab_container.current_tab = 1
		steam_tab.queue_free()

	if Globals.arguments.has('email') and Globals.arguments.has('password'):
		# Take email and password via command-line for debugging.
		_set_credentials(Globals.arguments['email'], Globals.arguments['password'])
		login_save_checkbox.pressed = false
		login_save_checkbox.visible = false
		create_account_save_checkbox.pressed = false
		create_account_save_checkbox.visible = false
	else:
		var file = File.new()
		if file.file_exists(CREDENTIALS_FILENAME):
			if file.open_encrypted_with_pass(CREDENTIALS_FILENAME, File.READ, Build.encryption_password) == OK:
				_load_credentials(file)
		elif file.file_exists(CREDENTIALS_FILENAME_OLD):
			if file.open(CREDENTIALS_FILENAME_OLD, File.READ) == OK:
				_load_credentials(file)
				# Remove this file and replace with the new one.
				var dir = Directory.new()
				dir.remove(CREDENTIALS_FILENAME_OLD)
				_save_credentials()

func _set_credentials(_email: String, _password: String) -> void:
	email = _email
	password = _password

	login_email_field.text = email
	login_password_field.text = password

func _load_credentials(file: File) -> void:
	var result := JSON.parse(file.get_as_text())
	if result.result is Dictionary:
		_set_credentials(result.result['email'], result.result['password'])
	file.close()

func _save_credentials() -> void:
	var file = File.new()
	file.open_encrypted_with_pass(CREDENTIALS_FILENAME, File.WRITE, Build.encryption_password)
	var credentials = {
		email = email,
		password = password,
	}
	file.store_line(JSON.print(credentials))
	file.close()

func _show_screen(info: Dictionary = {}) -> void:
	_reconnect = info.get('reconnect', false)
	_next_screen = info.get('next_screen', 'MatchScreen')

	tab_container.current_tab = 0

	# If we're in the Steam version, try to login via Steam first.
	if SteamManager.use_steam:
		do_steam_login()
		return

	# If we have a stored email and password, attempt to login straight away.
	if email != '' and password != '':
		do_login()
		return

func do_login(save_credentials: bool = false) -> void:
	_login_type = LoginType.EMAIL
	visible = false

	if _reconnect:
		ui_layer.show_message("MESSAGE_SESSION_EXPIRED")
		_reconnect = false
	else:
		ui_layer.show_message("MESSAGE_SESSION_LOGGING_IN")

	var nakama_session = yield(Online.nakama_client.authenticate_email_async(email, password, null, false), "completed")

	if nakama_session.is_exception():
		visible = true
		login_email_field.grab_focus()
		ui_layer.show_message("MESSAGE_LOGIN_FAILED")

		# Clear stored email and password, but leave the fields alone so the
		# user can attempt to correct them.
		email = ''
		password = ''

		# We always set Online.nakama_session in case something is yielding
		# on the "session_changed" signal.
		Online.nakama_session = null
	else:
		if save_credentials:
			_save_credentials()

		Online.nakama_session = nakama_session
		if SteamManager.use_steam:
			# This will lead to linking the Steam account.
			_get_steam_auth_session_ticket()

		ui_layer.hide_message()

		if _next_screen:
			ui_layer.show_screen(_next_screen)

func do_steam_login(create: bool = false) -> void:
	_login_type = LoginType.STEAM
	_steam_create = create
	visible = false

	if _reconnect:
		ui_layer.show_message("MESSAGE_SESSION_EXPIRED_STEAM")
		_reconnect = false
	else:
		ui_layer.show_message("MESSAGE_SESSION_LOGGING_IN_STEAM")

	_get_steam_auth_session_ticket()

func _get_steam_auth_session_ticket() -> void:
	var result = Steam.getAuthSessionTicket()

	# Convert binary ticket to hexidecimal.
	# See: https://partner.steamgames.com/doc/webapi/ISteamUserAuth#AuthenticateUserTicket
	# Nakama uses that method to authenticate on its end.
	_steam_auth_session_ticket = ''
	for i in range(result['size']):
		_steam_auth_session_ticket += "%02x" % result['buffer'][i]

func _on_steam_auth_session_ticket_response(_auth_ticket_id, _result) -> void:
	if _login_type == LoginType.STEAM:
		if _result != Steam.RESULT_OK:
			ui_layer.show_message("MESSAGE_LOGIN_FAILED_STEAM")
			visible = true
			steam_login_button.focus.grab_without_sound()
			return

		_finish_authenticate_steam()
	elif _login_type == LoginType.EMAIL:
		if _result != Steam.RESULT_OK:
			# We just silently don't link to Steam.
			return
		_finish_link_steam()

func _finish_authenticate_steam() -> void:
	var nakama_session = yield(Online.nakama_client.authenticate_steam_async(_steam_auth_session_ticket, steam_username_field.text.strip_edges(), _steam_create), "completed")
	if nakama_session.is_exception():
		print (nakama_session.get_exception().message)
		var exception: NakamaException = nakama_session.get_exception()
		if exception.grpc_status_code == 5:
			ui_layer.show_message("MESSAGE_NO_USER_ACCOUNT")
		elif exception.grpc_status_code == 6:
			ui_layer.show_message("MESSAGE_USERNAME_TAKEN")
		else:
			ui_layer.show_message("MESSAGE_LOGIN_FAILED_STEAM")
		visible = true
		steam_login_button.focus.grab_without_sound()
	else:
		Online.nakama_session = nakama_session
		ui_layer.hide_message()

		if _next_screen:
			ui_layer.show_screen(_next_screen)

func _finish_link_steam() -> void:
	# We don't check if this succeeded or not. Even if it fails, we're still
	# logged in, so we keep going, and we'll try again the next time the user
	# logs in.
	Online.nakama_client.link_steam_async(Online.nakama_session, _steam_auth_session_ticket)

func _on_SteamLoginButton_pressed() -> void:
	do_steam_login(true)

func _on_LoginButton_pressed() -> void:
	email = login_email_field.text.strip_edges()
	password = login_password_field.text.strip_edges()
	do_login(login_save_checkbox.pressed)

func _on_CreateAccountButton_pressed() -> void:
	email = $"TabContainer/Create Account/GridContainer/Email".text.strip_edges()
	password = $"TabContainer/Create Account/GridContainer/Password".text.strip_edges()

	var username = $"TabContainer/Create Account/GridContainer/Username".text.strip_edges()
	var save_credentials = create_account_save_checkbox.pressed

	if email == '':
		ui_layer.show_message("MESSAGE_EMAIL_REQUIRED")
		return
	if password == '':
		ui_layer.show_message("MESSAGE_PASSWORD_REQUIRED")
		return
	if username == '':
		ui_layer.show_message("MESSAGE_USERNAME_REQUIRED")
		return

	visible = false
	ui_layer.show_message("MESSAGE_CREATING_ACCOUNT")

	var nakama_session = yield(Online.nakama_client.authenticate_email_async(email, password, username, true), "completed")

	if nakama_session.is_exception():
		visible = true
		create_account_username_field.grab_focus()

		var msg = nakama_session.get_exception().message
		# Nakama treats registration as logging in, so this is what we get if the
		# the email is already is use but the password is wrong.
		if msg == 'Invalid credentials.':
			msg = 'MESSAGE_EMAIL_TAKEN'
		elif msg == '':
			msg = 'MESSAGE_CREATE_ACCOUNT_FAILED'
		ui_layer.show_message(msg)

		# We always set Online.nakama_session in case something is yielding
		# on the "session_changed" signal.
		Online.nakama_session = null
	else:
		if save_credentials:
			_save_credentials()
		Online.nakama_session = nakama_session
		ui_layer.hide_message()
		ui_layer.show_screen("MatchScreen")

func _on_ResetPasswordButton_pressed() -> void:
	var email = $"TabContainer/Forgot password?/GridContainer/Email".text.strip_edges()

	if email == '':
		ui_layer.show_message("MESSAGE_EMAIL_REQUIRED")
		return

	var http_request := HTTPRequest.new()
	add_child(http_request)

	ui_layer.show_message("MESSAGE_PASSWORD_RESET_SENDING")

	var data :=  {
		form_id = "custom_forgot_password_form",
		email = email,
		op = "submit",
	}

	var http_client := HTTPClient.new()
	var query_string: String = http_client.query_string_from_dict(data)

	var headers := ["Content-Type: application/x-www-form-urlencoded"]
	if http_request.request(FORGOT_PASSWORD_URL, headers, true, HTTPClient.METHOD_POST, query_string) != OK:
		http_request.queue_free()
		ui_layer.show_message("MESSAGE_PASSWORD_RESET_FAILED")
		return

	var response = yield(http_request, "request_completed")
	var result = response[0]
	var response_code = response[1]

	if result != HTTPRequest.RESULT_SUCCESS or response_code >= 400:
		http_request.queue_free()
		ui_layer.show_message("MESSAGE_PASSWORD_RESET_FAILED")
		return

	ui_layer.show_message("MESSAGE_PASSWORD_RESET_SENT")

