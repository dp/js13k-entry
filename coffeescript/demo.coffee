class Game
    constructor: (mapParams, gameParams) ->
        @map = new Map('map', mapParams)
        @map.canvas.style.width = @map.canvas.width + 'px'
        @map.draw()

        @shadowCanvas = document.getElementById('shadows')
        @shadowCtx = @shadowCanvas.getContext('2d')
        @maskCanvas = document.getElementById('light-mask')
        @maskCtx = @maskCanvas.getContext('2d')

        @shadowCanvas.width = (@map.w + 1) * @map.tileSize
        @shadowCanvas.height = (@map.h + 1) * @map.tileSize
        @maskCanvas.width = window.innerWidth
        @maskCanvas.height = window.innerHeight
        @maskCtx.fillStyle = '#000'
        @maskCtx.fillRect(0,0,@maskCanvas.width, @maskCanvas.height)
        @gameWorld = byId('gameworld')
        #        @map.generate()
        @pos = x: gameParams.startPos[0] * mapParams.tileSize, y: gameParams.startPos[1] * mapParams.tileSize
        @changed = true
#        @points = []
        @lines = []
        @speed = 200
        @lightRadius = 500
        @nightVisionRadius = 0
        @maxNightVisionRadius = 200
        @nightVisionChangeRate = 10
        @lightOn = false
#        @initPoints()
        @initLines()
        openingText()
        setTimeout( (->window.requestAnimationFrame update), 10000)



    update: (timestamp) ->
        if @lastTimestamp
            delta = (timestamp - @lastTimestamp) / 1000
        else
            delta = 0
        @lastTimestamp = timestamp
        unless @lightOn
            if @nightVisionRadius < @maxNightVisionRadius
                @changed = true
                @nightVisionRadius += @nightVisionChangeRate * delta
                @nightVisionRadius = @maxNightVisionRadius if @nightVisionRadius > @maxNightVisionRadius
        if right || left || up || down
            testRange = 9
            newPos = {x:@pos.x, y:@pos.y}
            if right
                newPos.x = @pos.x + @speed * delta
                pixel = @map.pixelAt(Math.floor(newPos.x) + testRange, Math.floor(newPos.y))
                if pixel[3] < 10
                    @pos.x = newPos.x
            if left
                newPos.x = @pos.x - @speed * delta
                pixel = @map.pixelAt(Math.floor(newPos.x) - testRange, Math.floor(newPos.y))
                if pixel[3] < 10
                    @pos.x = newPos.x
            if down
                newPos.y = @pos.y + @speed * delta
                pixel = @map.pixelAt(Math.floor(newPos.x), Math.floor(newPos.y) + testRange)
                if pixel[3] < 10
                    @pos.y = newPos.y
            if up
                newPos.y = @pos.y - @speed * delta
                pixel = @map.pixelAt(Math.floor(newPos.x), Math.floor(newPos.y) - testRange)
                if pixel[3] < 10
                    @pos.y = newPos.y
#            pixel = @map.pixelAt(Math.floor(newPos.x), Math.floor(newPos.y))
#            console.log(pixel)
#            if pixel[3] < 10
#                @pos.x = newPos.x
#                @pos.y = newPos.y
            @changed = true

        @draw(delta)

    draw: (delta) ->
        return false unless @changed
        @shadowCtx.clearRect(0, 0, @shadowCanvas.width, @shadowCanvas.height)
        @drawOrb()
#        @drawPointRays()
#        @drawPoints()
        @drawLineShadows()
        @positionMap()
        @drawLightMask()
#        @map.drawWalls(@shadowCtx)
#        @map.drawEdges(@shadowCtx)
#        @drawLines()
        @changed = false

    drawOrb: ->
        radius = 20
        if @lightOn
            grd = @maskCtx.createRadialGradient(@pos.x, @pos.y, 10, @pos.x, @pos.y, radius)
            grd.addColorStop(0, 'rgba(60,255,255,0.4)')
            grd.addColorStop(0.5, 'rgba(60,255,255,0.2)')
            grd.addColorStop(1, 'rgba(60,255,255,0)')
            @shadowCtx.fillStyle=grd
            @shadowCtx.beginPath()
            @shadowCtx.arc(@pos.x, @pos.y, radius, 0, Math.PI * 2)
            @shadowCtx.fill()

            grd = @maskCtx.createRadialGradient(@pos.x+3, @pos.y-3, 2, @pos.x, @pos.y, 7)
            grd.addColorStop(0, '#fff')
            grd.addColorStop(1, '#0ff')
            @shadowCtx.fillStyle=grd
            @shadowCtx.beginPath()
            @shadowCtx.arc(@pos.x, @pos.y, 7, 0, Math.PI * 2)
            @shadowCtx.fill()

            @shadowCtx.strokeStyle = '#fff'
            @shadowCtx.beginPath()
            @shadowCtx.arc(@pos.x, @pos.y, 8, 0, Math.PI * 2)
            @shadowCtx.stroke()
        else
            @shadowCtx.strokeStyle = '#066'
            @shadowCtx.fillStyle = '#288'
            @shadowCtx.beginPath()
            @shadowCtx.arc(@pos.x, @pos.y, 8, 0, Math.PI * 2)
            @shadowCtx.stroke()
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
        lineCheckDist = @lightRadius + 20
        @shadowCtx.lineWidth = 6
        drawLines = []
        for l in @lines
            # find lines in a close box
            if (Math.abs(l[0].x - @pos.x) < lineCheckDist) && (Math.abs(l[0].y - @pos.y) < lineCheckDist)
                drawLines.push l

#        for l in drawLines
#            @shadowCtx.strokeStyle = '#B8B6B5'
            @shadowCtx.strokeStyle = '#888685'
            @shadowCtx.beginPath()
            @shadowCtx.moveTo(l[0].x, l[0].y)
            @shadowCtx.lineTo(l[1].x, l[1].y)
            @shadowCtx.stroke()
        for l in drawLines
            p1 = l[0]
            p2 = l[1]

            # find lines within radius
            angDist1 = Vectors.angleDistBetweenPoints @pos, p1
            angDist2 = Vectors.angleDistBetweenPoints @pos, p2
            if angDist1.distance < @lightRadius || angDist2.distance < @lightRadius

                # draw them in green
#                @shadowCtx.strokeStyle = '#0f0'
#                @shadowCtx.beginPath()
#                @shadowCtx.moveTo(l[0].x, l[0].y)
#                @shadowCtx.lineTo(l[1].x, l[1].y)
#                @shadowCtx.stroke()

                if l[2]
#                    @shadowCtx.strokeStyle = 'rgb(20,20,220)'
#                    @shadowCtx.beginPath()
#                    @shadowCtx.moveTo(l[2].mp.x, l[2].mp.y)
#                    p2 = Vectors.addVectorToPoint(l[2].mp, l[2].normal, 50)
#                    @shadowCtx.lineTo(p2.x, p2.y)
#                    @shadowCtx.stroke()

                    # see if face pints away from player
                    angle = angDist1.angle

                    delta = angle - l[2].ang
                    delta += Math.PI * 2 if delta < Math.PI
                    delta -= Math.PI * 2 if delta > Math.PI

                    if delta < 0
                        @shadowCtx.fillStyle = 'rgba(20,20,20,0.6)'
                        @drawShadow(p1, p2, angDist1.angle, angDist2.angle)



        #                    @shadowCtx.fillStyle = 'rgba(0,0,0,0.2)'
#                    altPos = Vectors.addVectorToPoint(@pos, angDist1.angle + Math.PI/2, 10)
#                    angDist1 = Vectors.angleDistBetweenPoints altPos, p1
#                    angDist2 = Vectors.angleDistBetweenPoints altPos, p2
#                    @drawShadow(p1, p2, angDist1.angle, angDist2.angle)
#
#                    altPos = Vectors.addVectorToPoint(@pos, angDist2.angle - Math.PI/2, 10)
#                    angDist1 = Vectors.angleDistBetweenPoints altPos, p1
#                    angDist2 = Vectors.angleDistBetweenPoints altPos, p2
#                    @drawShadow(p1, p2, angDist1.angle, angDist2.angle)


        # draw green circle
#        @shadowCtx.strokeStyle = '#0f0'
#        @shadowCtx.beginPath()
#        @shadowCtx.arc(@pos.x, @pos.y, @lightRadius, 0, Math.PI * 2)
#        @shadowCtx.stroke()
        @shadowCtx.lineWidth = 1


    drawShadow: (p1, p2, ang1, ang2) ->
        @shadowCtx.beginPath()
        end1 = Vectors.addVectorToPoint(p1, ang1, 900)
        end2 = Vectors.addVectorToPoint(p2, ang2, 900)
        @shadowCtx.moveTo(p1.x, p1.y)
        @shadowCtx.lineTo(end1.x, end1.y)
        @shadowCtx.lineTo(end2.x, end2.y)
        @shadowCtx.lineTo(p2.x, p2.y)
        @shadowCtx.lineTo(p1.x, p1.y)
        @shadowCtx.fill()
#        @shadowCtx.stroke()


    drawLightMask: ->
#        return
        @maskCtx.fillStyle = '#000'
        @maskCtx.fillRect(0,0,@maskCanvas.width, @maskCanvas.height)
        @maskCtx.globalCompositeOperation = 'destination-out'

        if @lightOn
            radius = @lightRadius
            grd = @maskCtx.createRadialGradient(@viewX, @viewY, radius / 4, @viewX, @viewY, radius)
            grd.addColorStop(0, 'white')
            grd.addColorStop(1, 'rgba(255,255,255,0)')
        else
            radius = @nightVisionRadius
            grd = @maskCtx.createRadialGradient(@viewX, @viewY, radius / 4, @viewX, @viewY, radius)
            grd.addColorStop(0, 'rgba(255,255,255, 0.4)')
            grd.addColorStop(1, 'rgba(255,255,255,0)')
        @maskCtx.fillStyle=grd
        @maskCtx.beginPath()
        @maskCtx.arc(@viewX, @viewY, radius, 0, Math.PI * 2)
        @maskCtx.fill()
        @maskCtx.globalCompositeOperation = 'source-over'

        # draw red ring
        if false
            @maskCtx.strokeStyle = 'red'
            @maskCtx.lineWidth = 5
            @maskCtx.beginPath()
            @maskCtx.arc(@viewX, @viewY, radius, 0, Math.PI * 2)
            @maskCtx.stroke()
            @maskCtx.lineWidth = 1


    updateMousePos: (e) ->
        game.pos.x = e.pageX
        game.pos.y = e.pageY - 10
        game.changed = true

    initPoints: ->
        for i in [0..999]
            @points[i] = {x:randInt(50, 1580), y:randInt(50, 850)}

    initLines: ->
        @lines = @map.lines()

    positionMap: ->
        # move the position of the map so the player stays in the screen centre
        @viewX = window.innerWidth / 2
        @viewY = window.innerHeight / 2
        @gameWorld.style.left = @viewX - @pos.x + 'px'
        @gameWorld.style.top = @viewY - @pos.y + 'px'

window.say = (msg, holdTime, delay) ->
    msg = msg.replace(/\s/g,'&nbsp;').replace("'", '&rsquo;')
    holdTime = 2000 + holdTime * 1000
    el = document.createElement('span')
    el.innerHTML = msg
#    el.appendChild(document.createTextNode(msg))
    el.className = 'text fade-in'
    o = document.getElementById('overlay')
    o.appendChild(el)
    setTimeout( (->el.className = 'text'), 100)
    setTimeout( (->el.className = 'text fade-out'), holdTime)
    setTimeout( (->o.removeChild(el)), holdTime + 10000)

window.saySoon = (msg, holdTime, delay) ->
    setTimeout( (-> say(msg, holdTime)), delay * 1000)

window.openingText = ->
    messages =[
        ['.      ', .8, 1]
        ['   .   ', .3, 1.5]
        ['      .', -.2, 2]
        ["It's dark,              ", 1, 5]
        ["             isn't it?", 0, 6]
        ["Don't worry", 0, 10]
        ["your night vision should return soon", 0, 12]
        ]
    for msg in messages
        saySoon msg[0], msg[1], msg[2]

# ----------------------------------------------------------------------------------------------------------------------

window.randSeed = Math.floor(Math.random() * 10000)
#window.randSeed = 8288
# also 4693 5730

# for tall
# @w = 27 * 4
# @h = 15 * 8
# @tileSize = 7
# 8165
# 8288


window.randomX = ->
    x = Math.sin(randSeed++) * 10000
    x - Math.floor(x)

window.randInt = (min, range) ->
    Math.floor(randomX() * range) + min

window.update = (timestamp) ->
    game.update(timestamp)
    window.requestAnimationFrame update
    true

window.byId = (elementId) ->
    document.getElementById(elementId)

window.debug = (msg) ->
    document.getElementById('debug').innerHTML = msg

# Keys states (false: key is released / true: key is pressed)
window.up = window.right = window.down = window.left = false

# Keydown listener
window.onkeydown = (e) ->
    # Up (up / W / Z)
    if e.keyCode == 32
        pixel = game.map.ctx.getImageData(game.pos.x, game.pos.y, 1, 1)
        console.log pixel.data
    if(e.keyCode == 38 || e.keyCode == 90 || e.keyCode == 87)
        window.up = true
    # Right (right / D)
    if(e.keyCode == 39 || e.keyCode == 68)
        window.right = true
    # Down (down / S)
    if(e.keyCode == 40 || e.keyCode == 83)
        window.down = true
    # Left (left / A / Q)
    if(e.keyCode == 37 || e.keyCode == 65 ||e.keyCode == 81)
        window.left = true
#    console.log "up:#{up} down:#{down} left:#{left} right:#{right}"


# Keyup listener
window.onkeyup = (e) ->
    # Up
    if(e.keyCode == 38 || e.keyCode == 90 || e.keyCode == 87)
        window.up = false
    # Right
    if(e.keyCode == 39 || e.keyCode == 68)
        window.right = false
    # Down
    if(e.keyCode == 40 || e.keyCode == 83)
        window.down = false
    # Left
    if(e.keyCode == 37 || e.keyCode == 65 || e.keyCode == 81)
        window.left = false
#    console.log "up:#{up} down:#{down} left:#{left} right:#{right}"


    
window.initGame = ->
#    debug "Map #"+randSeed
#    window.game = new Game()
#    document.onmousemove = game.updateMousePos


    mapParams = {
        seed: 559516
        width: 120
        height: 80
        tileSize: 50
        initialDensity: 47
        reseedDensity: 51
        smoothCorners: true
        reseedMethod: 'top'
        emptyTolerance: 6
        wallRoughness: 25
        passes: [
            "combine-aggressive"
            "reseed-medium"
            "combine-aggressive"
            "reseed-small"
            "combine-aggressive"
            "remove-singles"]
        }
    gameParams = {
        startPos: [76,49]
    }

    window.game = new Game(mapParams, gameParams)


#    @map = new Map('map', params)
#    @map.canvas.style.width = @map.canvas.width + 'px'
#    @map.draw()

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


#sourceCanvas = game.map.canvas
#mc = game.maskCtx
#mc.drawImage(sourceCanvas, -1000, -1000)


#s = document.createElement('span')
#<span>
#    s.appendChild(document.createTextNode("... It's so dark ..."))
##text "... It's so dark ..."
#s.className = 'text'
#"text"
#o=document.getElementById('overlay')
#<div id="overlay">
#    o.appendChild(s)
#<span class="text">
#    s.classList
#DOMTokenList [ "text" ]
#s.className = "text fade-out"
#"text fade-out"



window.Game = Game

