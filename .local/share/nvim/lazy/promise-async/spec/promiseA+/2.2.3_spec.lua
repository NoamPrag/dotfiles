local helpers         = require('spec.helpers.init')
local testRejected    = helpers.testRejected
local setTimeout      = helpers.setTimeout
local deferredPromise = helpers.deferredPromise
local promise         = require('promise')
local dummy           = {dummy = 'dummy'}
local sentinel        = {sentinel = 'sentinel'}

describe('2.2.3: If `onRejected` is a function,', function()
    describe('2.2.3.1: it must be called after `promise` is rejected, ' ..
        'with `promise`’s rejection reason as its first argument.', function()
        testRejected(it, assert, sentinel, function(p)
            p:thenCall(nil, function(reason)
                assert.equal(sentinel, reason)
                done()
            end)
        end)
    end)

    describe('2.2.3.2: it must not be called before `promise` is rejected', function()
        it('rejected after a delay', function()
            local onRejected = spy.new(done)
            local p, _, reject = deferredPromise()
            p:thenCall(nil, onRejected)

            setTimeout(function()
                reject(dummy)
            end, 10)
            assert.True(wait())
            assert.spy(onRejected).was_called(1)
        end)

        it('never rejected', function()
            local onRejected = spy.new(done)
            local p = deferredPromise()
            p:thenCall(nil, onRejected)
            assert.False(wait(30))
            assert.spy(onRejected).was_not_called()
        end)
    end)

    describe('2.2.3.3: it must not be called more than once.', function()
        it('already-rejected', function()
            local onRejected = spy.new(done)
            promise.reject(dummy):thenCall(nil, onRejected)
            assert.spy(onRejected).was_not_called()
            assert.True(wait())
            assert.spy(onRejected).was_called(1)
        end)

        it('trying to reject a pending promise more than once, immediately', function()
            local onRejected = spy.new(done)
            local p, _, reject = deferredPromise()
            p:thenCall(nil, onRejected)
            reject(dummy)
            reject(dummy)
            assert.True(wait())
            assert.spy(onRejected).was_called(1)
        end)

        it('trying to reject a pending promise more than once, delayed', function()
            local onRejected = spy.new(done)
            local p, _, reject = deferredPromise()
            p:thenCall(nil, onRejected)
            setTimeout(function()
                reject(dummy)
                reject(dummy)
            end, 10)
            assert.True(wait())
            assert.spy(onRejected).was_called(1)
        end)

        it('trying to reject a pending promise more than once, immediately then delayed', function()
            local onRejected = spy.new(done)
            local p, _, reject = deferredPromise()
            p:thenCall(nil, onRejected)
            reject(dummy)
            setTimeout(function()
                reject(dummy)
            end, 10)
            assert.True(wait())
            assert.spy(onRejected).was_called(1)
        end)

        it('when multiple `thenCall` calls are made, spaced apart in time', function()
            local onRejected1 = spy.new(function() end)
            local onRejected2 = spy.new(function() end)
            local onRejected3 = spy.new(function() end)
            local p, _, reject = deferredPromise()
            p:thenCall(nil, onRejected1)
            setTimeout(function()
                p:thenCall(nil, onRejected2)
            end, 15)
            setTimeout(function()
                p:thenCall(nil, onRejected3)
            end, 25)
            setTimeout(function()
                reject(dummy)
                done()
            end, 35)
            assert.True(wait())
            assert.spy(onRejected1).was_called(1)
            assert.spy(onRejected2).was_called(1)
            assert.spy(onRejected3).was_called(1)
        end)

        it('when `thenCall` is interleaved with rejection', function()
            local onRejected1 = spy.new(function() end)
            local onRejected2 = spy.new(function() end)
            local p, _, reject = deferredPromise()
            p:thenCall(nil, onRejected1)
            reject(dummy)
            setTimeout(function()
                p:thenCall(nil, onRejected2)
                done()
            end, 10)
            assert.True(wait())
            assert.spy(onRejected1).was_called(1)
            assert.spy(onRejected2).was_called(1)
        end)
    end)
end)