class Game
    constructor: () ->
        @canvas = document.getElementById('light-mask')
        @ctx = @canvas.getContext('2d')
        @pos = x:10, y:10
        @changed = true
        @points = []
        @lines = []
#        @initPoints()
        @initLines()

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
#        @drawPointRays()
#        @drawPoints()
        @drawLineShadows()
        @drawLines()
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

    drawLines: ->
        @ctx.strokeStyle = '#800'
        @ctx.beginPath()
        for l in @lines
            @ctx.moveTo(l[0].x, l[0].y)
            @ctx.lineTo(l[1].x, l[1].y)
        @ctx.stroke()

    drawLineShadows: ->
        @ctx.fillStyle = 'rgba(0,0,0,0.3)'
        for l in @lines
            p1 = l[0]
            p2 = l[1]
            angDist1 = Vectors.angleDistBetweenPoints @pos, p1
            angDist2 = Vectors.angleDistBetweenPoints @pos, p2
            if angDist1.distance < 300 || angDist2.distance < 300
                @ctx.beginPath()
                end1 = Vectors.addVectorToPoint(p1, angDist1.angle, 900)
                end2 = Vectors.addVectorToPoint(p2, angDist2.angle, 900)
                @ctx.moveTo(p1.x, p1.y)
                @ctx.lineTo(end1.x, end1.y)
                @ctx.lineTo(end2.x, end2.y)
                @ctx.lineTo(p2.x, p2.y)
                @ctx.lineTo(p1.x, p1.y)
                @ctx.fill()

    updateMousePos: (e) ->
        game.pos.x = e.pageX
        game.pos.y = e.pageY
        game.changed = true

    initPoints: ->
        for i in [0..999]
            @points[i] = {x:randInt(50, 1580), y:randInt(50, 850)}

    initLines: ->
        for i in [0..99]
            p1 = {x:randInt(50, 1580), y:randInt(50, 850)}
            p2 = Vectors.addVectorToPoint(p1, Math.random() * Math.PI * 2, randInt(20, 100))
            @lines[i] = [p1, p2]


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

