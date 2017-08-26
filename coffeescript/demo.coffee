class Game
    constructor: () ->
        @canvas = document.getElementById('light-mask')
        @ctx = @canvas.getContext('2d')
        @pos = x:10, y:10
        @changed = true
        @points = []
        @initPoints()

    update: (timestamp) ->
        if @lastTimestamp
            delta = (timestamp - @lastTimestamp) / 1000
        else
            delta = 0
        @lastTimestamp = timestamp
        @draw(delta)

    draw: (delta) ->
        return false unless @changed
        @ctx.clearRect(0, 0, @canvas.width, @canvas.height)
        @drawOrb()
        @drawPointRays()
        @drawPoints()
        @changed = false

    drawOrb: ->
        @ctx.fillStyle = '#0ff'
        @ctx.beginPath()
        @ctx.arc(@pos.x, @pos.y, 10, 0, Math.PI * 2)
        @ctx.fill()

    drawPoints: ->
        @ctx.fillStyle = '#008'
        for p in @points
            @ctx.beginPath()
            @ctx.arc(p.x, p.y, 1, 0, Math.PI * 2)
            @ctx.fill()

    drawPointRays: ->
        @ctx.strokeStyle = '#080'
        @ctx.beginPath()
        for p in @points
            angDist = Vectors.angleDistBetweenPoints @pos, p
            if angDist.distance < 100
                endPoint = Vectors.addVectorToPoint(p, angDist.angle, 200)
                @ctx.moveTo(p.x, p.y)
                @ctx.lineTo(endPoint.x, endPoint.y)
        @ctx.stroke()

    updateMousePos: (e) ->
        game.pos.x = e.pageX
        game.pos.y = e.pageY
        game.changed = true

    initPoints: ->
        for i in [0..999]
            @points[i] = {x:randInt(50, 1580), y:randInt(50, 850)}


window.randInt = (min, range) ->
    Math.floor(Math.random() * range) + min

window.update = (timestamp) ->
    game.update(timestamp)
    window.requestAnimationFrame update
    true

window.initGame = ->
    window.game = new Game()
    window.requestAnimationFrame update
    document.onmousemove = game.updateMousePos

#    canvas = document.getElementById('light-mask')
#    ctx = canvas.getContext('2d')
#    ctx.fillStyle = '#000'
#    ctx.fillRect(0,0,1200,800)
#    ctx.globalCompositeOperation = 'destination-out'
#
#    grd = ctx.createRadialGradient(400,400, 100, 400, 400, 300)
#    grd.addColorStop(0, 'white')
#    grd.addColorStop(1, 'rgba(0,0,0,0)')
#    ctx.fillStyle=grd
#    ctx.beginPath()
#    ctx.arc(400, 400, 300, 0, Math.PI * 2)
#    ctx.fill()



window.Game = Game

