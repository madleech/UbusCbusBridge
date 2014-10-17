# servers
net = require 'net'
dgram = require 'dgram'

speaker = null # who was the last to talk

class tcp
	constructor: (@name, port = 5550) ->
		@connected = []
		@server = net.createServer @connection
		@server.on 'error', @error
		@server.listen port, '127.0.0.1'
		console.log "#{@name} listening on tcp://#{port}"
	
	connection: (sock) =>
		@connected.push sock
		console.log "#{@name} connection from: tcp://#{sock.remoteAddress}:#{sock.remotePort} (#{@connected.length} clients connected)"
		# handlers for receiving data and disconnects
		sock.on 'data', (data) =>
			speaker = sock
			console.log "#{@name} <- tcp: #{to_str data} (#{sock.remoteAddress}:#{sock.remotePort})"
			@onData data
		sock.on 'end', =>
			i = @connected.indexOf sock
			@connected.splice i, 1 if i isnt -1
	
	onData: (data) ->
	
	error: (err) =>
		console.log "#{@name} tcp error: #{err.stack}"
		@server.close()
	
	transmit: (data) ->
		for sock in @connected
			if speaker isnt sock
				console.log "#{@name} -> #{to_str data} (tcp://#{sock.remoteAddress}:#{sock.remotePort})"
				sock.write data
		speaker = null


class udp
	ignore: null
	
	constructor: (@name, @port = 5550) ->
		@server = dgram.createSocket 'udp4'
		@server.on 'message', @message
		@server.on 'error', @error
		@server.bind @port
		console.log "#{@name} listening on udp://#{@port}"
	
	message: (data, client) =>
		if "#{data}" isnt @ignore
			console.log "#{@name} <- #{to_str data} (udp://#{client.address}:#{client.port})"
			@onData data
		@ignore = null
	
	onData: (data) ->
	
	error: (err) =>
		console.log "#{@name} udp error: #{err.stack}"
		@server.close()
	
	transmit: (data) ->
		console.log "#{@name} -> #{to_str data} (udp://255.255.255.255:#{@port})"
		data = new Buffer data
		client = dgram.createSocket 'udp4'
		client.bind()
		client.on 'listening', =>
			client.setBroadcast true
			@ignore = "#{data}"
			client.send data, 0, data.length, @port, '255.255.255.255', (err, bytes) ->
			  client.close()


to_str = (buffer) ->
	"#{buffer}".trim()

module.exports = 
	tcp: tcp
	udp: udp