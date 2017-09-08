class Game
    constructor: (mapParams, gameParams) ->
        @map = new Map('map', mapParams)
        @map.canvas.style.width = @map.canvas.width + 'px'
        @map.draw()
        @tileSize = @map.tileSize
        @playerEl = byId('player')
        @lightEl = byId('light')
        @light = new Light(@lightEl)
        @initGameParams gameParams
        @shadowCanvas = document.createElement('canvas')
        @shadowCtx = @shadowCanvas.getContext('2d')
        @maskCanvas = byId('light-mask')
        @maskCtx = @maskCanvas.getContext('2d')
        @viewCanvas = byId('view')
        @viewCtx = @viewCanvas.getContext('2d')
        @shadowCanvas.width = (@map.w + 1) * @tileSize
        @shadowCanvas.height = (@map.h + 1) * @tileSize
        @maskCanvas.width = Math.floor(window.innerWidth / pixels)
        @maskCanvas.height = Math.floor(window.innerHeight / pixels)
        @maskCanvas.style.width = window.innerWidth + 'px'
        @maskCanvas.style.height = window.innerHeight + 'px'
        @viewCanvas.width = Math.floor(window.innerWidth / pixels)
        @viewCanvas.height = Math.floor(window.innerHeight / pixels)
        @viewCanvas.style.width = window.innerWidth + 'px'
        @viewCanvas.style.height = window.innerHeight + 'px'
        @viewCtx.translate(0.5, 0.5)
        @maskCtx.fillStyle = '#000'
        @maskCtx.fillRect(0,0,@maskCanvas.width, @maskCanvas.height)
        @gameWorld = byId('gameworld')
        @pos = @tilePosToGameXY(gameParams.start)
        @changed = true
#        @points = []
        @lines = []
        @speed = 125
        @playerEl.style.left = "#{(window.innerWidth - 60) / 2}px"
        @playerEl.style.top = "#{(window.innerHeight - 48) / 2}px"
        @lightEl.style.left = "#{(window.innerWidth - 60) / 2}px"
        @lightEl.style.top = "#{(window.innerHeight - 48) / 2}px"
#        @initPoints()
        @initLines()
        @light.turnOff()
        openingText()
        setTimeout( (->window.requestAnimationFrame update), 1000)


    update: (timestamp) ->
        if @lastTimestamp
            delta = (timestamp - @lastTimestamp) / 1000
        else
            delta = 0
        @lastTimestamp = timestamp

        @light.update(delta)

        @changed = true

        if right || left || up || down
            testRange = 24 / pixels
            newPos = {x:@pos.x, y:@pos.y}
            if right
                newPos.x = @pos.x + @speed * delta
                pixel = @map.pixelAt(Math.floor(newPos.x) + testRange, Math.floor(newPos.y))
                if pixel[3] < 10
                    @pos.x = newPos.x
                @playerEl.className = 'right'
            if left
                newPos.x = @pos.x - @speed * delta
                pixel = @map.pixelAt(Math.floor(newPos.x) - testRange, Math.floor(newPos.y))
                if pixel[3] < 10
                    @pos.x = newPos.x
                @playerEl.className = 'left'
            if down
                newPos.y = @pos.y + @speed * delta
                pixel = @map.pixelAt(Math.floor(newPos.x), Math.floor(newPos.y) + testRange)
                if pixel[3] < 10
                    @pos.y = newPos.y
                @playerEl.className = 'down'
            if up
                newPos.y = @pos.y - @speed * delta
                pixel = @map.pixelAt(Math.floor(newPos.x), Math.floor(newPos.y) - testRange)
                if pixel[3] < 10
                    @pos.y = newPos.y
                @playerEl.className = 'up'
            @lightEl.className = @playerEl.className

            @changed = true
        if window.toggleLight
            if @light.on
                @light.turnOff()
            else
                @light.turnOn()
            window.toggleLight = false
            @changed = true

        @playerTouchingOrb()
        @draw(delta)

    draw: (delta) ->
        return false unless @changed
        @shadowCtx.clearRect(0, 0, @shadowCanvas.width, @shadowCanvas.height)
        @drawOrbs()
        @drawMonsters()
#        @drawPointRays()
#        @drawPoints()
        @drawLineShadows() if @light.on
        @positionMap()
        @drawPlayerShadow()
        @drawExit(@shadowCtx)
        @drawLightMask()
#        @map.drawWalls(@shadowCtx)
#        @map.drawEdges(@shadowCtx)
#        @drawLines()
        @compositeCanvas()
        @changed = false

    compositeCanvas: ->
        game.viewCtx.drawImage(@map.floorCanvas, @viewX - @pos.x, @viewY - @pos.y)
        game.viewCtx.drawImage(@shadowCanvas, @viewX - @pos.x, @viewY - @pos.y)
        game.viewCtx.drawImage(@map.canvas, @viewX - @pos.x, @viewY - @pos.y)
        game.drawExit(game.viewCtx)

    drawPlayerShadow: ->
        radius = 24 / pixels
        @shadowCtx.save()
        @shadowCtx.translate(@pos.x, @pos.y + 24 / pixels)
        @shadowCtx.scale(1, 0.25)
        grd = @shadowCtx.createRadialGradient(0,0, 0, 0,0, radius)
        grd.addColorStop(0, 'rgba(0,0,0,0.6)')
        grd.addColorStop(1, 'rgba(0,0,0,0)')
        @shadowCtx.fillStyle=grd
        @shadowCtx.beginPath()
        @shadowCtx.arc(0,0, radius, 0, Math.PI * 2)
        @shadowCtx.fill()
        @shadowCtx.restore()

    playerTouchingOrb: ->
        for orb, i in @orbs
            if @itemInRange(orb, @tileSize) && !orb.used
                @light.addPower()
                orb.used = true

    drawOrbs: ->
        glowRadius = 15
        orbRadius = 4
        glowGradient = @shadowCtx.createRadialGradient(0, 0, orbRadius, 0, 0, glowRadius)
        glowGradient.addColorStop(0, 'rgba(143,194,242,0.4)')
        glowGradient.addColorStop(1, 'rgba(191,226,226,0)')

        orbGradient = @shadowCtx.createRadialGradient(1, -1, 1, 0, 0, orbRadius)
        orbGradient.addColorStop(0, '#bfe2e2')
        orbGradient.addColorStop(1, '#8fc2f2')

        #abcff3
        #8fc2f2
        shadowGradient = @shadowCtx.createRadialGradient(0,0, 0, 0,0, glowRadius)
        shadowGradient.addColorStop(0, 'rgba(191,226,226,0.4)')
        shadowGradient.addColorStop(0.2, 'rgba(143,194,242,0.4)')
        shadowGradient.addColorStop(1, 'rgba(143,194,242,0)')

        for orb in @orbs
            if @itemInRange(orb, 800) && !orb.used
                @shadowCtx.save()
                @shadowCtx.translate(orb.x, orb.y + 10)
                @shadowCtx.scale(1, 0.3)
                @shadowCtx.fillStyle = shadowGradient
                @shadowCtx.beginPath()
                @shadowCtx.arc(0, 0, glowRadius, 0, Math.PI * 2)
                @shadowCtx.fill()
                @shadowCtx.restore()

                @shadowCtx.save()
                @shadowCtx.translate(orb.x, orb.y)

                @shadowCtx.fillStyle = glowGradient
                @shadowCtx.beginPath()
                @shadowCtx.arc(0, 0, glowRadius, 0, Math.PI * 2)
                @shadowCtx.fill()

                @shadowCtx.fillStyle = orbGradient
                @shadowCtx.beginPath()
                @shadowCtx.arc(0, 0, orbRadius, 0, Math.PI * 2)
                @shadowCtx.fill()

                @shadowCtx.restore()

    drawMonsters: ->
        radius = 12
        for monster in @monsters
            if @itemInRange(monster, 800)
                angDist = Vectors.angleDistBetweenPoints @pos, monster
                @shadowCtx.save()
                @shadowCtx.translate(monster.x, monster.y)
                @shadowCtx.rotate(angDist.angle)
                @shadowCtx.fillStyle = '#000'
                @shadowCtx.beginPath()
                @shadowCtx.arc(0, 0, radius, 0, Math.PI * 2)
                @shadowCtx.fill()
                @shadowCtx.fillStyle = '#f20'
                @shadowCtx.beginPath()
                @shadowCtx.arc(-8, 3, 2, 0, Math.PI * 2)
                @shadowCtx.arc(-8, -3, 2, 0, Math.PI * 2)
                @shadowCtx.fill()

                @shadowCtx.restore()


    itemInRange: (pos, range) ->
        (Math.abs(pos.x - @pos.x) < range) && (Math.abs(pos.y - @pos.y) < range)

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
        lineCheckDist = 500
        shadowDrawRadius = 100
        @shadowCtx.lineWidth = 3
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

        @shadowCtx.fillStyle = 'rgba(0,0,0,0.7)'
        @shadowCtx.strokeStyle = 'rgba(0,0,0,0.7)'
        @shadowCtx.lineWidth = 0.5
        for l in drawLines
            p1 = l[0]
            p2 = l[1]

            # find lines within radius
            angDist1 = Vectors.angleDistBetweenPoints @pos, p1
            angDist2 = Vectors.angleDistBetweenPoints @pos, p2
            if angDist1.distance < shadowDrawRadius || angDist2.distance < shadowDrawRadius

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
        @shadowCtx.beginPath()
        @shadowCtx.moveTo(p1.x, p1.y)
        @shadowCtx.lineTo(end1.x, end1.y)
        @shadowCtx.stroke()


    drawLightMask: ->
        @maskCtx.fillStyle = "#000"
        radius = @light.viewRadius
        grd = @maskCtx.createRadialGradient(@viewX, @viewY, radius / 4, @viewX, @viewY, radius)
        grd.addColorStop(0, "rgba(255,255,255,#{@light.alpha})")
        grd.addColorStop(1, 'rgba(255,255,255,0)')

        @maskCtx.fillRect(0,0,@maskCanvas.width, @maskCanvas.height)
        @maskCtx.globalCompositeOperation = 'destination-out'
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

    drawExit: (ctx) ->
        if @itemInRange(@exit)
            radius = 2 * @tileSize / pixels
            unless @lightRays
                @lightRays = []
                for i in [0..5]
                    x = randInt( - radius, radius * 2 )
                    @lightRays.push {x: x, y: randInt(-7, 14), w: randInt(2, radius - x), h: randInt(100, 50)}
                console.log @lightRays
            ctx.save()
            ctx.translate(@exit.x, @exit.y)
            ctx.scale(1, 0.4)
            grd = ctx.createRadialGradient(0,0, 0, 0,0, radius)
            grd.addColorStop(0, 'rgba(255, 255, 255, 0.9)')
            grd.addColorStop(1, 'rgba(255, 255, 255, 0.2)')
            ctx.fillStyle=grd
            ctx.beginPath()
            ctx.arc(0,0, radius, 0, Math.PI * 2)
            ctx.fill()
            ctx.restore()

            ctx.save()
            ctx.translate(@exit.x, @exit.y)
            for ray in @lightRays
                grd = ctx.createLinearGradient(ray.x, ray.y, ray.x, ray.y - ray.h)
                grd.addColorStop(0, "rgba(255, 255, 255, #{0.3 + Math.random() / 5})")
                grd.addColorStop(1, 'rgba(255, 255, 255, 0)')
                ctx.fillStyle=grd
                ctx.beginPath()
                ctx.moveTo(ray.x, ray.y)
                ctx.lineTo(ray.x - 0.2 * ray.h, ray.y - ray.h)
                ctx.lineTo(ray.x - 0.2 * ray.h + ray.w, ray.y - ray.h)
                ctx.lineTo(ray.x + ray.w, ray.y)
                ctx.fill()
            ctx.restore()

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
        @viewX = window.innerWidth / 2 / pixels
        @viewY = window.innerHeight / 2 / pixels
        @gameWorld.style.left = @viewX - @pos.x + 'px'
        @gameWorld.style.top = @viewY - @pos.y + 'px'

    initGameParams: (params) ->
        @monsters = []
        @orbs = []
        @exit = @tilePosToGameXY(params.exit)
        for pos in params.monsters
            monster = @tilePosToGameXY(pos)
            monster.state = 0
            @monsters.push monster
        for pos in params.orbs
            @orbs.push @tilePosToGameXY(pos)

    tilePosToGameXY: (xy) ->
        x: (xy[0] + .5) * @tileSize, y: (xy[1] + .5) * @tileSize

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
        ['. . .', -.2, 1]
        ["It's dark,              ", 1, 5]
        ["             isn't it?", 0, 6]
#        ["Don't worry", 0, 10]
#        ["your night vision should return soon", 0, 12]
#        ["dev msg: space turns light on/off", 0, 20]
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
        window.toggleLight = true
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
        tileSize: 25
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
#        start: [76, 49],
        start: [40, 23],
        exit: [37, 21],
        monsters: [[32, 49], [80, 18], [102, 19], [62, 21], [76, 38], [57, 24], [113, 72], [116, 75], [117, 72],
            [115, 63], [73, 67], [49, 72], [5, 70], [13, 35], [49, 75], [97, 70], [86, 12], [63, 59], [91, 22]],
        orbs: [[50, 37], [60, 61], [35, 33], [24, 75], [10, 65], [10, 62], [18, 48], [105, 77], [114, 50], [116, 16],
            [102, 27], [49, 29], [73, 38], [80, 5], [79, 72], [101, 58], [5, 24], [91, 34]]
    }

    window.pixels = 2
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

