class Tween
    constructor: (time, elements) ->
        @time = time
        @elements = elements
        @running = true
        @timePassed = 0
        @update(0)

    update: (delta) ->
        return false unless @running
        @timePassed += delta
        if @timePassed > @time
            multiplier = 1
            @running = false
        else
            multiplier = @timePassed / @time
        for k,v of @elements
            v[2] = (v[1]-v[0]) * multiplier + v[0]
#        console.log 'delta', delta, 'timePassed', @timePassed, 'multiplier', multiplier

    value: (name) ->
        @elements[name][2]



window.Tween = Tween




