class Game
    constructor: (mapParams, gameParams) ->
        @map = new Map('map', mapParams)
        @map.draw()
        @tileSize = @map.tileSize
        @state = 0
        @orbCount = 0
        @distQ = 0

        @playerEl = byId('player')
        @lightEl = byId('light')
        @playerEl.style.left = "#{(window.innerWidth - 60) / 2}px"
        @playerEl.style.top = "#{(window.innerHeight - 48) / 2}px"
        @lightEl.style.left = "#{(window.innerWidth - 60) / 2}px"
        @lightEl.style.top = "#{(window.innerHeight - 48) / 2}px"

        @light = new Light(@lightEl)

        @initGameParams gameParams

        # mask canvas
        @maskCanvas = byId('light-mask')
        @maskCtx = @maskCanvas.getContext('2d')
        @maskCanvas.width = Math.floor(window.innerWidth / 2)
        @maskCanvas.height = Math.floor(window.innerHeight / 2)
        @maskCanvas.style.width = window.innerWidth + 'px'
        @maskCanvas.style.height = window.innerHeight + 'px'
        @maskCtx.fillStyle = '#000'
        @maskCtx.fillRect(0, 0, @maskCanvas.width, @maskCanvas.height)
        # shadow canvas
        @shadowCanvas = document.createElement('canvas')
        @shadowCtx = @shadowCanvas.getContext('2d')
        @shadowCanvas.width = @maskCanvas.width
        @shadowCanvas.height = @maskCanvas.height
        # view canvas
        @viewCanvas = byId('view')
        @viewCtx = @viewCanvas.getContext('2d')
        @viewCanvas.width = @maskCanvas.width
        @viewCanvas.height = @maskCanvas.height
        @viewCanvas.style.width = @maskCanvas.style.width
        @viewCanvas.style.height = @maskCanvas.style.height
        @viewCtx.translate(0.5, 0.5)
        # items canvas
        @itemsCanvas = document.createElement('canvas')
        @itemsCtx = @itemsCanvas.getContext('2d')
        @itemsCanvas.width = @maskCanvas.width
        @itemsCanvas.height = @maskCanvas.height

        @positionMap()
        Msg.init(@maskCtx, @viewX, @viewY)
        @pos = @tilePosToGameXY(gameParams.start)
        @lines = []
        @speed = 125
        @monsterSpeed = 100

        @initLines()
        @light.turnOff(3)
        @openingText()
        requestAnimationFrame update


    update: (timestamp) ->
        if @lastTimestamp
            delta = (timestamp - @lastTimestamp) / 1000
        else
            delta = 0
        @lastTimestamp = timestamp
        @timeStarted ||= + new Date()

        if @state == 1
# dead
            pg = byId('player-ghost')
            pg.style.top = parseInt(pg.style.top) - 1 + 'px'
        else if @state == 2
# winning
            @light.update(delta) if @light.tweening
        else
# playing
            @light.update(delta)

            dist = @speed * delta

            if right || left || up || down
                @targetPos = {x:@pos.x, y: @pos.y}

                if right
                    @targetPos.x += dist
                    className = 'right'
                if left
                    @targetPos.x -= dist
                    className = 'left'
                if down
                    @targetPos.y += dist
                    className = 'down'
                if up
                    @targetPos.y -= dist
                    className = 'up'

            if @targetPos
                angDist = Vectors.angleDistBetweenPoints(@pos, @targetPos)
                if angDist.distance < dist
                    dist = angDist.distance
                    @targetPos = null
                testRange = 12 + dist
                newPos = Vectors.addVectorToPoint(@pos, angDist.angle, dist)
                deltaX = newPos.x - @pos.x
                deltaY = newPos.y - @pos.y
                if deltaX > 0 && deltaX >= Math.abs(deltaY)
                    className ||= 'right'
                else if deltaX < 0 && 0 - deltaX >= Math.abs(deltaY)
                    className ||= 'left'
                else if deltaY > 0
                    className ||= 'down'
                else
                    className ||= 'up'
                @lightEl.className = @playerEl.className = className
                if deltaX > 0
                    @pos.x += deltaX unless @wallAt(x: newPos.x + testRange, y: newPos.y)
                if deltaX < 0
                    @pos.x += deltaX unless @wallAt(x: newPos.x - testRange, y: newPos.y)
                if deltaY > 0
                    @pos.y += deltaY unless @wallAt(x: newPos.x, y: newPos.y + testRange)
                if deltaY < 0
                    @pos.y += deltaY unless @wallAt(x: newPos.x, y: newPos.y - testRange)
                if @itemInRange(x: @exit.x, y: @exit.y - 70, 80)
                    @win()


            if window.toggleLight
                if @light.on
                    @light.turnOff()
                else
                    @light.turnOn()
                window.toggleLight = false

            @playerTouchingOrb()
            @playerTouchingTrigger()
            @moveMonsters(delta)
            Msg.update(delta)
        @draw()

    moveMonsters: (delta) ->
        for monster, i in @monsters
            if @itemOnScreen(monster) || monster.state == 1
                # see if they can see player
                dx = (@pos.x - monster.x) / 20
                dy = (@pos.y - monster.y) / 20
                visible = true
                for i in [0..20]
                    if @wallAt(x: monster.x + dx * i, y: monster.y + dy * i)
                        visible = false

                if visible && monster.state == 0
                    monster.state = 1

                else if monster.state == 1
                    # monster has seen player. now to follow them
                    angDist = Vectors.angleDistBetweenPoints(monster, @pos)
                    dist = angDist.distance
                    angle = angDist.angle
                    if visible && @light.on && dist < (@light.viewRadius + 20)
                        # speed will be -ve if inside circle
                        # meaning they go backwards
                        speed = (dist - @light.viewRadius)
                        angle += 0.5
                    else
                        speed = @monsterSpeed
                    stuck = true
                    attempts = 0
                    if speed < 0
                        backwards = true
                        angle += Math.PI
                        speed = - speed
                    while stuck && attempts < 20
                        newPos = Vectors.addVectorToPoint(monster, angle, speed * delta)
                        # test two points in front of the monster
                        tp1 = Vectors.addVectorToPoint(newPos, angle + 1.0, 18.0)
                        tp2 = Vectors.addVectorToPoint(newPos, angle - 1.0, 18.0)
                        attempts += 1
                        # if going backwards and hit a wall, just stop
                        if backwards && (@wallAt(tp1) || @wallAt(tp2))
                            attempts = 999
                        else if @wallAt(tp1)
                            angle -= 0.3
                            speed = speed + 15
                        else if @wallAt(tp2)
                            angle += 0.4
                            speed = speed + 10
                        else
                            monster.x = newPos.x
                            monster.y = newPos.y
                            stuck = false
                            if @state == 0
                                if Vectors.distBetweenPoints(@pos, monster) < 22
                                    @die()

    die: ->
        byId('viewport').className = 'dead'
        pg = byId('player-ghost')
        pg.style.top = @playerEl.style.top
        pg.style.left = @playerEl.style.left
        @state = 1
        Msg.say('You had one job ... ', x: -130, y: @viewY - 40, colour:'#b00', size:30)
        @light.alpha = 0.4 if @light.alpha < 0.4
        @light.viewRadius = 20 if @light.viewRadius < 20
        @printStats()

    win: ->
        byId('viewport').className = 'win'
        @state = 2
        @playerEl.className = 'down'
        @lightEl.className = 'down'
        @light.addPower()
        Msg.say("Thanks, you're a hero!", x: -170, y: @viewY - 70, colour:'#0c0', size:30, hold: 10)
        Msg.say("I think I’ll be ok from here :)", x: -170, y: @viewY - 30, colour:'#0a0', size:25, hold: 10)
        @printStats()

    printStats: ->
        time = Math.floor((+ new Date() - @timeStarted) / 1000)
        msg = "You lasted #{time} seconds and collected #{@orbCount} of #{@orbs.length} light orbs"
        Msg.say msg, x: - @viewX + 10, y: -@viewY + 20, hold: 100, size: 12

    draw: () ->
        @shadowCtx.clearRect(0, 0, @shadowCanvas.width, @shadowCanvas.height)
        @shadowCtx.save()
        @shadowCtx.translate(@viewX - @pos.x, @viewY - @pos.y)

        @itemsCtx.clearRect(0, 0, @itemsCanvas.width, @itemsCanvas.height)
        @itemsCtx.save()
        @itemsCtx.translate(@viewX - @pos.x, @viewY - @pos.y)

        @maskCtx.fillStyle = '#000'
        @maskCtx.fillRect(0, 0, @maskCanvas.width, @maskCanvas.height)

        @drawOrbs()
        @drawMonsters()
        @drawLineShadows()
        @drawPlayerShadow()
        @drawExit(@itemsCtx)
        @itemsCtx.restore()
        @shadowCtx.restore()
        @compositeCanvas()
        Msg.draw()

    wallAt: (pos) ->
        @map.pixelAt(pos.x, pos.y)[3] > 10

    compositeCanvas: ->
        @viewCtx.fillStyle = '#585655'
        @viewCtx.fillRect(0, 0, game.viewCanvas.width, game.viewCanvas.height)
        # draw floor
        @viewCtx.drawImage(@map.floorCanvas, @viewX - @pos.x, @viewY - @pos.y)

        # remove items in shadows from items canvas
        if true
            @itemsCtx.globalCompositeOperation = 'destination-out'
            @itemsCtx.drawImage(@shadowCanvas, 0, 0)
            @itemsCtx.globalCompositeOperation = 'source-over'

        # remove items in shadows from light mask canvas
        @maskCtx.drawImage(@shadowCanvas, 0, 0)

        # draw items
        @viewCtx.drawImage(@itemsCanvas, 0, 0)

        # draw shadows
        if @light.on
            @viewCtx.globalAlpha = 0.7
            @viewCtx.drawImage(@shadowCanvas, 0, 0)
            @viewCtx.globalAlpha = 1

        # draw dungeon walls
        @viewCtx.drawImage(@map.canvas, @viewX - @pos.x, @viewY - @pos.y)
        @drawLightMask()

    drawPlayerShadow: ->
        radius = 24 / 2
        @shadowCtx.save()
        @shadowCtx.translate(@pos.x, @pos.y + 24 / 2)
        @shadowCtx.scale(1, 0.25)
        grd = @shadowCtx.createRadialGradient(0, 0, 0, 0, 0, radius)
        grd.addColorStop(0, 'rgba(0,0,0,0.6)')
        grd.addColorStop(1, 'rgba(0,0,0,0)')
        @shadowCtx.fillStyle = grd
        @shadowCtx.beginPath()
        @shadowCtx.arc(0, 0, radius, 0, Math.PI * 2)
        @shadowCtx.fill()
        @shadowCtx.restore()

    playerTouchingOrb: ->
        for orb, i in @orbs
            if @itemInRange(orb, @tileSize) && !orb.used
                @light.addPower()
                @orbCount += 1
                orb.used = true

    playerTouchingTrigger: ->
        for t in @triggers
            if @itemInRange(t, t.r) && !t.used
#                eval(t.action) if t.action
                Msg.say(t.msg) if t.msg
                t.used = true

    drawOrbs: ->
        ctx = @itemsCtx
        glowRadius = 15
        orbRadius = 4
        # glow around the orb
        glowGradient = ctx.createRadialGradient(0, 0, orbRadius, 0, 0, glowRadius)
        glowGradient.addColorStop(0, 'rgba(143,194,242,0.4)')
        glowGradient.addColorStop(1, 'rgba(191,226,226,0)')

        # the orb
        orbGradient = ctx.createRadialGradient(1, -1, 1, 0, 0, orbRadius)
        orbGradient.addColorStop(0, '#bfe2e2')
        orbGradient.addColorStop(1, '#8fc2f2')

        # might cut shadow gradient for the moment
        #        shadowGradient = ctx.createRadialGradient(0,0, 0, 0,0, glowRadius)
        #        shadowGradient.addColorStop(0, 'rgba(191,226,226,0.4)')
        #        shadowGradient.addColorStop(0.2, 'rgba(143,194,242,0.4)')
        #        shadowGradient.addColorStop(1, 'rgba(143,194,242,0)')

        # need to create a hole in the light mask so we can see the orb in the dark
        @maskCtx.fillStyle = "#000"
        maskRadius = glowRadius * 1.5
        grd = @maskCtx.createRadialGradient(0, 0, 0, 0, 0, maskRadius)
        grd.addColorStop(0, "rgba(255,255,255,0.8)")
        grd.addColorStop(1, 'rgba(255,255,255,0)')
        @maskCtx.globalCompositeOperation = 'destination-out'
        @maskCtx.fillStyle = grd

        for orb in @orbs
            if @itemOnScreen(orb) && !orb.used

# draw shadow
#                ctx.save()
#                ctx.translate(orb.x, orb.y + 10)
#                ctx.scale(1, 0.3)
#                ctx.fillStyle = shadowGradient
#                ctx.beginPath()
#                ctx.arc(0, 0, glowRadius, 0, Math.PI * 2)
#                ctx.fill()
#                ctx.restore()

# draw glow
                ctx.save()
                ctx.translate(orb.x, orb.y)
                ctx.fillStyle = glowGradient
                ctx.beginPath()
                ctx.arc(0, 0, glowRadius, 0, Math.PI * 2)
                ctx.fill()

                # draw orb
                ctx.fillStyle = orbGradient
                ctx.beginPath()
                ctx.arc(0, 0, orbRadius, 0, Math.PI * 2)
                ctx.fill()

                ctx.restore()

                # cut hole in mask
                @maskCtx.save()
                @maskCtx.translate(orb.x - @pos.x + @viewX, orb.y - @pos.y + @viewY)
                @maskCtx.beginPath()
                @maskCtx.arc(0, 0, maskRadius, 0, Math.PI * 2)
                @maskCtx.fill()
                @maskCtx.restore()

        # make sure we set this back again!
        @maskCtx.globalCompositeOperation = 'source-over'


    drawMonsters: ->
        ctx = @itemsCtx
        eyeCtx = @maskCtx
        radius = 12
        for monster in @monsters
            if @itemOnScreen(monster)
                angDist = Vectors.angleDistBetweenPoints @pos, monster

                ctx.save()
                ctx.translate(monster.x, monster.y)
                ctx.rotate(angDist.angle)
                ctx.fillStyle = '#000'
                # body
                ctx.beginPath()
                ctx.arc(0, 0, radius, 0, Math.PI * 2)
                ctx.fill()
                # eyes on items layer are dim
                ctx.fillStyle = '#a10'
                ctx.scale(0.5, 1.0)
                ctx.beginPath()
                ctx.arc(-13, 4, 3, 0, Math.PI * 2)
                ctx.arc(-13, -4, 3, 0, Math.PI * 2)
                ctx.fill()
                ctx.restore()

                # eyes that glow in the dark. these are brighter
                eyeCtx.save()
                eyeCtx.translate(monster.x - @pos.x + @viewX, monster.y - @pos.y + @viewY)
                eyeCtx.rotate(angDist.angle)
                eyeCtx.fillStyle = '#f20'
                eyeCtx.scale(0.5, 1.0)
                eyeCtx.beginPath()
                eyeCtx.arc(-13, 4, 3, 0, Math.PI * 2)
                eyeCtx.arc(-13, -4, 3, 0, Math.PI * 2)
                eyeCtx.fill()

                eyeCtx.restore()


    itemInRange: (pos, range) ->
        (Math.abs(pos.x - @pos.x) < range) && (Math.abs(pos.y - @pos.y) < range)

    itemOnScreen: (pos) ->
        (Math.abs(pos.x - @pos.x) < @viewX) && (Math.abs(pos.y - @pos.y) < @viewY)

    drawLines: ->
        @shadowCtx.strokeStyle = '#800'
        @shadowCtx.beginPath()
        for l in @lines
            @shadowCtx.moveTo(l[0].x, l[0].y)
            @shadowCtx.lineTo(l[1].x, l[1].y)
        @shadowCtx.stroke()

    drawLineShadows: ->
# draw shadows for all line on the screen
        @shadowCtx.fillStyle = '#000'
        @shadowCtx.strokeStyle = '#000'
        for l in @lines
# l is an array of three pairs
# [{x:p1x, y:p1y}, {x:p2x, y:p2y}, {ang:a1, mp:?, normal:a2}]
            p1 = l[0] # point 1
            if @itemOnScreen(p1)
#                console.log 'x'
                p2 = l[1] # point 2
                angDist1 = Vectors.angleDistBetweenPoints @pos, p1
                angDist2 = Vectors.angleDistBetweenPoints @pos, p2
                if l[2] # normal
# see if face pints away from player
                    angle = angDist1.angle
                    delta = angle - l[2].ang
                    delta += Math.PI * 2 if delta < Math.PI
                    delta -= Math.PI * 2 if delta > Math.PI

                    if delta < 0
                        @drawShadow(p1, p2, angDist1.angle, angDist2.angle)


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

        @maskCtx.globalCompositeOperation = 'destination-out'
        @maskCtx.fillStyle = grd
        @maskCtx.beginPath()
        @maskCtx.arc(@viewX, @viewY, radius, 0, Math.PI * 2)
        @maskCtx.fill()
        @maskCtx.globalCompositeOperation = 'source-over'


    drawExit: (ctx) ->
        if @itemOnScreen(@exit)
            radius = @tileSize
            unless @lightRays
                @lightRays = []
                for i in [0..5]
                    x = randInt(-radius, radius * 2)
                    @lightRays.push {x: x, y: randInt(-7, 14), w: randInt(2, radius - x), h: randInt(100, 50)}

            # draw light circle on ground
            ctx.save()
            ctx.translate(@exit.x, @exit.y)
            ctx.scale(1, 0.4)
            grd = ctx.createRadialGradient(0, 0, 0, 0, 0, radius)
            grd.addColorStop(0, 'rgba(255, 255, 255, 0.9)')
            grd.addColorStop(1, 'rgba(255, 255, 255, 0.2)')
            ctx.fillStyle = grd
            ctx.beginPath()
            ctx.arc(0, 0, radius, 0, Math.PI * 2)
            ctx.fill()
            ctx.restore()

            # draw light rays
            ctx.save()
            ctx.translate(@exit.x, @exit.y)
            for ray in @lightRays
                grd = ctx.createLinearGradient(ray.x, ray.y, ray.x, ray.y - ray.h)
                grd.addColorStop(0, "rgba(255, 255, 255, #{0.3 + Math.random() / 5})")
                grd.addColorStop(1, 'rgba(255, 255, 255, 0)')
                ctx.fillStyle = grd
                ctx.beginPath()
                ctx.moveTo(ray.x, ray.y)
                ctx.lineTo(ray.x - 0.2 * ray.h, ray.y - ray.h)
                ctx.lineTo(ray.x - 0.2 * ray.h + ray.w, ray.y - ray.h)
                ctx.lineTo(ray.x + ray.w, ray.y)
                ctx.fill()
            ctx.restore()

            # cur hole in light mask
            @maskCtx.fillStyle = "#000"
            maskRadius = radius * 1.5
            grd = @maskCtx.createRadialGradient(0, 0, 0, 0, 0, maskRadius)
            grd.addColorStop(0, "rgba(255,255,255,0.8)")
            grd.addColorStop(1, 'rgba(255,255,255,0)')
            @maskCtx.globalCompositeOperation = 'destination-out'
            @maskCtx.fillStyle = grd
            @maskCtx.save()
            @maskCtx.translate(@exit.x - @pos.x + @viewX, @exit.y - @pos.y + @viewY)
            @maskCtx.scale(1, 0.4)
            @maskCtx.beginPath()
            @maskCtx.arc(0, 0, maskRadius, 0, Math.PI * 2)
            @maskCtx.fill()
            @maskCtx.restore()
            @maskCtx.globalCompositeOperation = 'source-over'


    initLines: ->
        @lines = @map.lines()

    positionMap: ->
        @viewX = window.innerWidth / 4
        @viewY = window.innerHeight / 4

    initGameParams: (params) ->
        @monsters = []
        @orbs = []
        @triggers = []
        @exit = @tilePosToGameXY(params.exit)
        for pos in params.monsters
            monster = @tilePosToGameXY(pos)
            monster.state = 0
            @monsters.push monster
        for pos in params.orbs
            @orbs.push @tilePosToGameXY(pos)
        for trigger in params.triggers
            trigger.x *= @tileSize
            trigger.y *= @tileSize
            trigger.r = trigger.r * @tileSize / 2
            @triggers.push trigger

    tilePosToGameXY: (xy) ->
        x: (xy[0] + .5) * @tileSize, y: (xy[1] + .5) * @tileSize

    screenClickedAt: (screenPosX, screenPosY) ->
#        console.log screenPosX, screenPosY
        gameClickPosX = (screenPosX / 2) + @pos.x - @viewX
        gameClickPosY = (screenPosY / 2) + @pos.y - @viewY
        @targetPos = x:gameClickPosX, y:gameClickPosY

    screenTouched: (e) ->
        console.log 'screen touched', e


#    testTrigger: (trigger) ->
#        @testCount ||= 1
#        console.log 'trigger', @testCount
#        trigger.used = true

#    say: (msg, holdTime, delay) ->
#        msg = msg.replace(/\s/g, '&nbsp;').replace("'", '&rsquo;')
#        holdTime = 2000 + holdTime * 1000
#        el = document.createElement('span')
#        el.innerHTML = msg
#        #    el.appendChild(document.createTextNode(msg))
#        el.className = 'text fade-in'
#        o = document.getElementById('overlay')
#        o.appendChild(el)
#        setTimeout((->el.className = 'text'), 100)
#        setTimeout((->el.className = 'text fade-out'), holdTime)
#        setTimeout((->o.removeChild(el)), holdTime + 4000 + delay)

#    saySoon: (msg, holdTime, delay) ->
#        setTimeout((=> @say(msg, holdTime, 0)), delay * 1000)

    openingText: ->
        Msg.say '...'
        setTimeout((-> Msg.say("How did I end up here?")), 2000)

# ----------------------------------------------------------------------------------------------------------------------

window.randSeed = 1234
window.randomX = ->
    x = Math.sin(randSeed++) * 10000
    x - Math.floor(x)

window.randInt = (min, range) ->
    Math.floor(randomX() * range) + min

window.update = (timestamp) ->
    game.update(timestamp)
    if window.paused
        console.log 'Game is stopped'
    else
        window.requestAnimationFrame update
    true

window.byId = (elementId) ->
    document.getElementById(elementId)

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
    if(e.keyCode == 37 || e.keyCode == 65 || e.keyCode == 81)
        window.left = true
    if(e.keyCode == 80)
        window.paused = true


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

#window.onclick = (e) ->
#    game?.screenClickedAt e.clientX, e.clientY

window.screenTouched = (e) ->
    e.preventDefault()
    touch = e.touches[0]
    if touch
        game?.screenClickedAt touch.clientX, touch.clientY

#window.screenTouchMoved = (e) ->

window.addEventListener('touchstart', screenTouched, false)
window.addEventListener('touchmove', screenTouched, false)

window.initGame = ->
    window.paused = false

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
#        start: [116,40],
        start: [76, 49],
#        start: [40, 23],
        exit: [37, 21],
        monsters: [[32, 49], [80, 18], [102, 19], [62, 21], [76, 38], [57, 24], [113, 72], [116, 75], [117, 72],
            [115, 63], [73, 67], [49, 72], [5, 70], [13, 35], [49, 75], [97, 70], [86, 12], [63, 59], [91, 22]],
        orbs: [[60, 61], [35, 33], [10, 62], [18, 48], [105, 77], [114, 50], [116, 16], [49, 29], [73, 38], [80, 5],
            [79, 72], [101, 58],
            [72, 45], [80, 49], [51, 46]],
        triggers: [
            {x: 116,y: 34,r: "7",msg: "It's like a maze of twisty|passages, they're all alike!"}, # 1`
            {x: 85, y: 59, r: "7", msg: "I think we're headed|in the right direction"}, # 2
            {x: 117, y: 69, r: "5", msg: "I've got a bad feeling|about this ..."}, # 3
            {x: 52, y: 21, r: "7", msg: "I think we're almost there!"}, # 4
            {x: 57, y: 60, r: "5", msg: "Do we REALLY need|that light?"}, # 5
            {x: 77, y: 20, r: "7", msg: "I remember this path..."}, # 6
            {x: 32, y: 49, r: "15", msg: "A shadow moves in the|dark"}, # 7
            {x: 81, y: 49, r: "3", msg: "It's dangerous to go alone|I should take this"}, # 8
            {x: 54, y: 74, r: "7", msg: "Why are they|following me?"}, # 9
            {x: 16, y: 35, r: "3", msg: "Are those red dots ...|eyes?"}, # 10
            {x: 4, y: 51, r: "3", msg: "This cave is dark|and full of terrors"}, # 11
            {x: 35, y: 32, r: "7", msg: "Well, that was a waste|of time"}] # 12
    }


    # JSON game params for use in dungeon generator
    # {"start":[40,23],"exit":[37,21],"monsters":[[32,49],[80,18],[102,19],[62,21],[76,38],[57,24],[113,72],[116,75],[117,72],[115,63],[73,67],[49,72],[5,70],[13,35],[49,75],[97,70],[86,12],[63,59],[91,22]],"orbs":[[50,37],[60,61],[35,33],[24,75],[10,65],[10,62],[18,48],[105,77],[114,50],[116,16],[102,27],[49,29],[73,38],[80,5],[79,72],[101,58],[5,24],[91,34],[72,45],[79,49],[80,49]],"triggers":[{"x":70,"y":43,"r":"3","name":"msg1","msg":"Let's get out of here"},{"x":85,"y":59,"r":"7","msg":"I think we're headed in the right direction"},{"x":117,"y":69,"r":"5","msg":"I've got a bad feeling about this ..."},{"x":52,"y":21,"r":"7","msg":"I'm sure the air is fresher here"},{"x":57,"y":60,"r":"5","msg":"Do we need that light?"}]}


    # search replace \s"(\w+)": with $1:
    # and "(\d)" with $1


    window.game = new Game(mapParams, gameParams)


window.Game = Game

