class Light
    constructor: (lightEl) ->
        @lightEl = lightEl
        @on = false
        @lightValue = 100
        @viewRadius = 0
        @alpha = 1.0
        @reduction = 4
        @tweening = false
        @tweenTimePassed = 0
        @tweenTime = 0
        @tweenTargetRadius = 0
        @tweenTargetAlpha = 0
        @tweenStartRadius = 0
        @tweenStartAlpha = 0

    update: (delta) ->
        if @tweening
            @tweenTimePassed += delta
            if @tweenTimePassed > @tweenTime
                multiplier = 1
                @tweening = false
            else
                multiplier = @tweenTimePassed / @tweenTime
            @viewRadius = (@tweenTargetRadius - @tweenStartRadius) * multiplier + @tweenStartRadius
            @alpha = (@tweenTargetAlpha - @tweenStartAlpha) * multiplier + @tweenStartAlpha
        else if @on
            @lightValue -= @reduction * delta
            if @lightValue < 1
                @lightValue = 0
                @turnOff()
            else
                @viewRadius = @lightValue + 20

        @viewRadius = 200 if @viewRadius > 200

    turnOff: (time = 3.0) ->
        @on = false
        @viewRadius = 0
        @alpha = 0.0
        @tweenTo time, 100, 0.4
        @lightEl.style.display = 'none'
        true

    turnOn: (time = 1.0) ->
        return false if @lightValue < 1
        @on = true
        @tweenTo time, @lightValue + 20, 1.0
        @lightEl.style.display = 'block'
        true

    tweenTo: (time, radius, alpha) ->
        @tweenTimePassed = 0
        @tweenTime = time
        @tweening = true
        @tweenStartRadius = @viewRadius
        @tweenTargetRadius = radius
        @tweenStartAlpha = @alpha
        @tweenTargetAlpha = alpha

    addPower: ->
        @lightValue += 100
        @turnOn(1.0)

window.Light = Light
