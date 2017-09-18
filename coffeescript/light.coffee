class Light
    constructor: (lightEl) ->
        @lightEl = lightEl
        @on = false
        @lightValue = 0
        @viewRadius = 0
        @alpha = 1.0
        @reduction = 8
        @tweening = false
        @tweenTimePassed = 0
        @tweenTime = 0
        @tweenTargetRadius = 0
        @tweenTargetAlpha = 0
        @tweenStartRadius = 0
        @tweenStartAlpha = 0
        @tweenRadius = 0
        @maxDarkRadius = 40

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
                @viewRadius = @lightValue
        else # off
            @viewRadius = @maxDarkRadius

        @viewRadius =  Math.pow(@viewRadius, 0.333) * 40

    turnOff: (time = 2.0) ->
        @on = false
        @viewRadius = 0
        @alpha = 0.0
        @tweenTo time, @maxDarkRadius, 0.4
        @lightEl.style.display = 'none'
        true

    turnOn: (time = 1.0) ->
        return false if @lightValue < 1
        @on = true
        @tweenTo time, @lightValue , 1.0
        @lightEl.style.display = 'block'
        true

    tweenTo: (time, radius, alpha) ->
        @tweenTimePassed = 0
        @tweenTime = time
        @tweening = true
        @tweenStartRadius = Math.pow(@viewRadius / 40, 1/0.333)
        @tweenTargetRadius = radius
        @tweenStartAlpha = @alpha
        @tweenTargetAlpha = alpha

    addPower: ->
        @lightValue += 90
        @turnOn(1.0)

Msg =
    init: (@ctx, @originX, @originY) ->
        @messages = []
        @list = []
        @maxTime = 10

    update: (delta) ->
        for msg in @messages
            if msg.hold > 0
                msg.hold -= delta
            else if msg.fade > 0
                msg.fade -= delta

    draw: ->
        for msg in @messages
            if msg.fade > 0
                if msg.hold <= 0
                    @ctx.globalAlpha = (msg.fade / msg.fadeTime)
                @ctx.fillStyle = msg.colour
                @ctx.font = msg.font
                @ctx.fillText(msg.txt, msg.x, msg.y)
                @ctx.globalAlpha = 1.0

    say: (text, args = {}) ->
        lines = text.split('|')
        args.colour ||='white'
        args.x ||= @originX - 235
        args.y ||= 0
        args.size ||= 18
        args.hold ||= 2
        args.fade ||= 10
        for line, i in lines
            msg =
                txt:line,
                colour:args.colour,
                size: args.size,
                font: "#{args.size}px sans-serif",
                x: @originX + args.x,
                y: @originY + args.y,
                hold: args.hold,
                fade: args.fade,
                fadeTime: args.fade
            @messages.push msg
            unless args.y
                gap = (msg.size + 5)
                gap += 20 if i == 0
                m.y -= gap for m in @list
                @list.push msg


window.Light = Light
window.Msg = Msg
