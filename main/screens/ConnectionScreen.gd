extends "res://main/Screen.gd"

onready var tab_container := $TabContainer
onready var login_email_field := $TabContainer/Login/GridContainer/Email
onready var login_password_field := $TabContainer/Login/GridContainer/Password

const CREDENTIALS_FILENAME = 'user://credentials.json'

var email: String = ''
var password: String = ''

var _reconnect: bool = false
var _next_screen

var _steam_auth_session_ticket: String = ''

func _ready() -> void:
	if GameState.use_steam:
		Steam.connect("get_auth_session_ticket_response", self, "_on_steam_auth_session_ticket_response")
		return
		
	var file = File.new()
	if file.file_exists(CREDENTIALS_FILENAME):
		file.open(CREDENTIALS_FILENAME, File.READ)
		var result := JSON.parse(file.get_as_text())
		if result.result is Dictionary:
			email = result.result['email']
			password = result.result['password']
			login_email_field.text = email
			login_password_field.text = password
		file.close()


func _save_credentials() -> void:
	var file = File.new()
	file.open(CREDENTIALS_FILENAME, File.WRITE)
	var credentials = {
		email = email,
		password = password,
	}
	file.store_line(JSON.print(credentials))
	file.close()

func _show_screen(info: Dictionary = {}) -> void:
	_reconnect = info.get('reconnect', false)
	_next_screen = info.get('next_screen', 'MatchScreen')
	
	if GameState.use_steam:
		visible = false
		do_steam_login()
		return
	
	tab_container.current_tab = 0
	
	# If we have a stored email and password, attempt to login straight away.
	if email != '' and password != '':
		do_login()

func do_login(save_credentials: bool = false) -> void:
	visible = false
	
	if _reconnect:
		ui_layer.show_message("Session expired! Reconnecting...")
	else:
		ui_layer.show_message("Logging in...")
	
	var nakama_session = yield(Online.nakama_client.authenticate_email_async(email, password, null, false), "completed")
	
	if nakama_session.is_exception():
		visible = true
		ui_layer.show_message("Login failed!")
		
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
		ui_layer.hide_message()
		
		if _next_screen:
			ui_layer.show_screen(_next_screen)

func do_steam_login() -> void:
	if _reconnect:
		ui_layer.show_message("Session expired! Reconnecting via Steam...")
	else:
		ui_layer.show_message("Logging in via Steam...")
	
	var result = Steam.getAuthSessionTicket()
	
	# Convert binary ticket to hexidecimal.
	# See: https://partner.steamgames.com/doc/webapi/ISteamUserAuth#AuthenticateUserTicket
	# Nakama uses that method to authenticate on its end.
	_steam_auth_session_ticket = ''
	for i in range(result['size']):
		_steam_auth_session_ticket += "%02x" % result['buffer'][i]

func _on_steam_auth_session_ticket_response(_auth_ticket_id, _result) -> void:
	if _result == Steam.RESULT_OK:
		pass
	else:
		ui_layer.show_message("Unable to login via Steam. Please try again later.")
	
	# TODO: handle if the username is taken!
	var nakama_session = yield(Online.nakama_client.authenticate_steam_async(_steam_auth_session_ticket, Steam.getPersonaName(), true), "completed")
	if nakama_session.is_exception():
		#ui_layer.show_message("Server backend is unable to verify your Steam token")
		ui_layer.show_message(nakama_session.get_exception().message)
	else:
		Online.nakama_session = nakama_session
		ui_layer.hide_message()
		
		if _next_screen:
			ui_layer.show_screen(_next_screen)

func _on_LoginButton_pressed() -> void:
	email = login_email_field.text.strip_edges()
	password = login_password_field.text.strip_edges()
	do_login($TabContainer/Login/GridContainer/SaveCheckBox.pressed)

func _on_CreateAccountButton_pressed() -> void:
	email = $"TabContainer/Create Account/GridContainer/Email".text.strip_edges()
	password = $"TabContainer/Create Account/GridContainer/Password".text.strip_edges()
	
	var username = $"TabContainer/Create Account/GridContainer/Username".text.strip_edges()
	var save_credentials = $"TabContainer/Create Account/GridContainer/SaveCheckBox".pressed
	
	if email == '':
		ui_layer.show_message("Must provide email")
		return
	if password == '':
		ui_layer.show_message("Must provide password")
		return
	if username == '':
		ui_layer.show_message("Must provide username")
		return
	
	visible = false
	ui_layer.show_message("Creating account...")

	var nakama_session = yield(Online.nakama_client.authenticate_email_async(email, password, username, true), "completed")
	
	if nakama_session.is_exception():
		visible = true
		
		var msg = nakama_session.get_exception().message
		# Nakama treats registration as logging in, so this is what we get if the
		# the email is already is use but the password is wrong.
		if msg == 'Invalid credentials.':
			msg = 'E-mail already in use.'
		elif msg == '':
			msg = "Unable to create account"
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
