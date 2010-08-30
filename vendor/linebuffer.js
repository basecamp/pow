var events = require('events')
var sys = require('sys')

function indexOf(buffer, char) {
	for(var i = 0; i < buffer.length; i++) {
		if(buffer[i] == char) {
			return i
		}
	}

	return -1
}

function LineBuffer() {
	events.EventEmitter.call(this)
	this.buffers = []
	this.lines = []
	this.writeable = true
	this.paused = false
	this.readable = true
	this.encoding = false
}

sys.inherits(LineBuffer, events.EventEmitter)
LineBuffer.prototype.write = function write(buffer) {
	if(typeof buffer === 'string') {
		buffer = new Buffer(buffer, 'utf8')
	}
	var end = -1
	var t
	if((t = indexOf(buffer, 10)) >= 0) { // \r
		end = t
		if(buffer[end + 1] == 13) { // \n
			end += 1
		}
	} else if((t = indexOf(buffer, 13)) >= 0) { // \n alone
		end = t
	}

	if(end >= 0) {
		this.buffers.push(buffer.slice(0, (end == buffer.length ?  end : end + 1)))

		this.dequeue()
		// Dequeue this until no more line end characters remain,
		// queue the rest
		if(end < buffer.length) {
			buffer = buffer.slice(end + 1, buffer.length)
			return this.write(buffer)
		}

		return !this.paused
	} else {
		this.buffers.push(buffer)
		return true
	}
}

LineBuffer.prototype.dequeue = function() {
	// Dequeue anything in this.buffers
	var len = 0
	for(var i = 0; i < this.buffers.length; i++) {
		len += this.buffers[i].length
	}
	if(len > 0 && this.buffers.length > 1) {
		var b = new Buffer(len)
		var offset = 0
		for(var i = 0; i < this.buffers.length; i++) {
			this.buffers[i].copy(b, offset)
			offset += this.buffers[i].length
		}
		queue(this, b)
	} else {
		queue(this, this.buffers[0])
	}
	this.buffers = []
}

function queue(lb, buffer) {
	lb.lines.push(buffer)
	if(!lb.paused) lb.resume()
}

LineBuffer.prototype.pause = function() {
	this.paused = true
}

LineBuffer.prototype.resume = function() {
	this.paused = false
	while(this.lines.length > 0) {
		if(this.paused) break
		if(this.encoding) {
			this.emit('data', this.lines.shift().toString(this.encoding))
		} else {
			this.emit('data', this.lines.shift())
		}
	}
	if(!this.paused && this.writable) this.emit('drain')
}

LineBuffer.prototype.destroy = function() {
	this.readable = false
}

LineBuffer.prototype.setEncoding = function(encoding) {
	this.encoding = encoding
}

LineBuffer.prototype.end = function(buffer, encoding) {
	if(buffer) {
		if(typeof buffer === 'string') buffer = new Buffer(buffer, encoding)
		this.write(buffer)
	}

	this.dequeue()
	this.writable = false
}

exports.LineBuffer = LineBuffer
