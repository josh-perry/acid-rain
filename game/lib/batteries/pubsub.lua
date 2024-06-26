--[[
	dead-simple publish-subscribe message bus
]]

local path = (...):gsub("pubsub", "")
local class = require(path .. "class")
local set = require(path .. "set")

local pubsub = class({
	name = "pubsub",
})

--create a new pubsub bus
function pubsub:new()
	self.subscriptions = {}
	self.queuedSubscriptions = {}
end

--(internal; notify a callback set of an event)
function pubsub:_notify(callbacks, ...)
	if callbacks then
		for _, f in callbacks:ipairs() do
			f(...)
		end
	end
end

--publish an event, with optional arguments
--notifies both the direct subscribers, and those subscribed to "everything"
function pubsub:publish(event, ...)
	self:_notify(self.subscriptions[event], ...)
	self:_notify(self.subscriptions.everything, event, ...)
end

function pubsub:queue(event, ...)
	table.insert(self.queuedSubscriptions, {
		event = event,
		args = {...}
	})
end

function pubsub:flush_queue()
	if self.locked then
		return
	end

	self.locked = true

	for _, v in ipairs(self.queuedSubscriptions) do
		self:publish(v.event, unpack(v.args))
	end

	self.queuedSubscriptions = {}
	pubsub.locked = false
end

--subscribe to an event
--can be a specifically named event, or "everything" to get notified for any event
--for "everything", the callback will receive the event name as the first argument
function pubsub:subscribe(event, callback)
	local callbacks = self.subscriptions[event]
	if not callbacks then
		callbacks = set()
		self.subscriptions[event] = callbacks
	end
	callbacks:add(callback)
end

--unsubscribe from an event
function pubsub:unsubscribe(event, callback)
	local callbacks = self.subscriptions[event]
	if callbacks then
		callbacks:remove(callback)
		if callbacks:size() == 0 then
			self.subscriptions[event] = nil
		end
	end
end

--check if there is a subscriber for a given event
function pubsub:has_subcriber(event)
	return self.subscriptions[event] ~= nil
end

return pubsub
