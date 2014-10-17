server = require './server'

# create servers
servers =
	cbus: new server.tcp 'CBUS', 5551
	ubus_local: new server.tcp 'UBUS'
	ubus_global: new server.udp 'UBUS'

# create a bridge
bridge = (server) ->
	(data) ->
		servers.cbus.transmit to_cbus data if server isnt servers.cbus
		servers.ubus_local.transmit to_ubus data if server isnt servers.ubus_local
		servers.ubus_global.transmit to_ubus data if server isnt servers.ubus_global

# set up bridges
for name, server of servers
	servers[name].onData = bridge server

# trivial conversions
to_ubus = (data) ->
	"#{data}".replace /^:SBFE0N9([01])00([0-9A-F]{6});[\s]*$/, 'U4$1$2'

to_cbus = (data) ->
	"#{data}".replace /^U4([01])([0-9A-F]{6})[\s]*$/, ':SBFE0N9$100$2;'
