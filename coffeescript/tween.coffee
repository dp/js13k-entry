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

    value: (name) ->
        @elements[name][2]

    changeValue: (name, value) ->
        @elements[name][1] += value

        @running = true






window.Tween = Tween




