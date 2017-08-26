class Game
    constructor: () ->
        @shadowCanvas = document.getElementById('shadows')
        @shadowCtx = @shadowCanvas.getContext('2d')
        @maskCanvas = document.getElementById('light-mask')
        @maskCtx = @maskCanvas.getContext('2d')
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
        @shadowCtx.clearRect(0, 0, @shadowCanvas.width, @shadowCanvas.height)
        @drawLightMask()
        @drawOrb()
#        @drawPointRays()
#        @drawPoints()
#        @drawLineShadows()
        @drawLines()
        @changed = false

    drawOrb: ->
        @shadowCtx.fillStyle = '#0ff'
        @shadowCtx.beginPath()
        @shadowCtx.arc(@pos.x, @pos.y, 10, 0, Math.PI * 2)
        @shadowCtx.fill()

    drawPoints: ->
        @shadowCtx.fillStyle = '#008'
        for p in @points
            @shadowCtx.beginPath()
            @shadowCtx.arc(p.x, p.y, 1, 0, Math.PI * 2)
            @shadowCtx.fill()

    drawPointRays: ->
        @shadowCtx.strokeStyle = '#080'
        @shadowCtx.beginPath()
        for p in @points
            angDist = Vectors.angleDistBetweenPoints @pos, p
            if angDist.distance < 100
                endPoint = Vectors.addVectorToPoint(p, angDist.angle, 200)
                @shadowCtx.moveTo(p.x, p.y)
                @shadowCtx.lineTo(endPoint.x, endPoint.y)
        @shadowCtx.stroke()

    drawLines: ->
        @shadowCtx.strokeStyle = '#800'
        @shadowCtx.beginPath()
        for l in @lines
            @shadowCtx.moveTo(l[0].x, l[0].y)
            @shadowCtx.lineTo(l[1].x, l[1].y)
        @shadowCtx.stroke()

    drawLineShadows: ->
        @shadowCtx.fillStyle = 'rgba(0,0,0,0.6)'
        for l in @lines
            p1 = l[0]
            p2 = l[1]
            angDist1 = Vectors.angleDistBetweenPoints @pos, p1
            angDist2 = Vectors.angleDistBetweenPoints @pos, p2
            if angDist1.distance < 300 || angDist2.distance < 300
                @shadowCtx.beginPath()
                end1 = Vectors.addVectorToPoint(p1, angDist1.angle, 900)
                end2 = Vectors.addVectorToPoint(p2, angDist2.angle, 900)
                @shadowCtx.moveTo(p1.x, p1.y)
                @shadowCtx.lineTo(end1.x, end1.y)
                @shadowCtx.lineTo(end2.x, end2.y)
                @shadowCtx.lineTo(p2.x, p2.y)
                @shadowCtx.lineTo(p1.x, p1.y)
                @shadowCtx.fill()

    drawLightMask: ->
#        return
        radius = 500
        @maskCtx.fillStyle = '#000'
        @maskCtx.fillRect(0,0,1680,950)
        @maskCtx.globalCompositeOperation = 'destination-out'

        grd = @maskCtx.createRadialGradient(@pos.x, @pos.y, radius / 4, @pos.x, @pos.y, radius)
        grd.addColorStop(0, 'white')
#        grd.addColorStop(0.7, 'rgba(255,255,255,0.5)')
        grd.addColorStop(1, 'rgba(255,255,255,0)')
        @maskCtx.fillStyle=grd
        @maskCtx.beginPath()
        @maskCtx.arc(@pos.x, @pos.y, radius, 0, Math.PI * 2)
        @maskCtx.fill()
        @maskCtx.globalCompositeOperation = 'source-over'

        # draw red ring
#        @maskCtx.strokeStyle = 'red'
#        @maskCtx.lineWidth = 5
#        @maskCtx.beginPath()
#        @maskCtx.arc(@pos.x, @pos.y, radius, 0, Math.PI * 2)
#        @maskCtx.stroke()
#        @maskCtx.lineWidth = 1


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

