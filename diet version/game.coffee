window.Game =
    init: ->
        Map.init()
        Map.draw()

        @tileSize = Map.tileSize
        @state = 0

        @playerEl = byId('p')
        @lightEl = byId('l')
        @playerEl.style.left = "#{(window.innerWidth - 60) / 2}px"
        @playerEl.style.top = "#{(window.innerHeight - 48) / 2}px"
        @lightEl.style.left = "#{(window.innerWidth - 60) / 2}px"
        @lightEl.style.top = "#{(window.innerHeight - 48) / 2}px"

        Light.init(@lightEl)

        @initGameParams {
            monsters: [[32, 49], [80, 18], [102, 19], [62, 21], [76, 38], [57, 24], [113, 72], [116, 75], [117, 72],
                [115, 63], [73, 67], [49, 72], [5, 70], [13, 35], [49, 75], [97, 70], [86, 12], [63, 59], [91, 22]],
            orbs: [[60,61],[35,33],[10,62],[18,48],[105,77],[114,50],[116,16],[49,29],[73,38],[80,5],[79,72],[101,58],
                [72,45],[80,49],[51,46]],
            triggers: [{x: 70,y: 43,r: 3,msg: "Let's get out of here"},
                {x: 85,y: 59,r: 7,msg: "I think we're headed in the right direction"},
                {x: 117,y: 69,r: 5,msg: "I've got a bad feeling about this ..."},
                {x: 52,y: 21,r: 7,msg: "I'm sure the air is fresher here"},
                {x: 57,y: 60,r: 5,msg: "Do we need that light?"}]
        }

        # mask canvas
        @maskCanvas = byId('lm')
        @maskCtx = @maskCanvas.getContext('2d')
        @maskCanvas.width = Math.floor(window.innerWidth / 2)
        @maskCanvas.height = Math.floor(window.innerHeight / 2)
        @maskCanvas.style.width = window.innerWidth + 'px'
        @maskCanvas.style.height = window.innerHeight + 'px'
        @maskCtx.fillStyle = '#000'
        @maskCtx.fillRect(0,0,@maskCanvas.width, @maskCanvas.height)
        # shadow canvas
        @shadowCanvas = document.createElement('canvas')
        @shadowCtx = @shadowCanvas.getContext('2d')
        @shadowCanvas.width = @maskCanvas.width
        @shadowCanvas.height = @maskCanvas.height
        # view canvas
        @viewCanvas = byId('v')
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
        @pos = @tilePosToGameXY([76, 49])
        @exit = @tilePosToGameXY([37, 21])
        @lines = []
        @speed = 125
        @monsterSpeed = 110

        @initLines()
        Light.turnOff(3)
        @openingText()
        requestAnimationFrame update


    update: (timestamp) ->
        if @lastTimestamp
            delta = (timestamp - @lastTimestamp) / 1000
        else
            delta = 0
        @lastTimestamp = timestamp

        if @state == 1
            # dead
            pg = byId('pg')
            pg.style.top = parseInt(pg.style.top) - 1 + 'px'
        else if @state == 2
            # winning
                Light.update(delta) if Light.tweening
        else
            # playing
            Light.update(delta)

            if right || left || up || down
                dist = @speed * delta
                testRange = 12 + dist

                if right
                    @pos.x += dist unless @wallAt(x:@pos.x + testRange, y:@pos.y)
                    className = 'r'
                if left
                    @pos.x -= dist unless @wallAt(x:@pos.x - testRange, y:@pos.y)
                    className = 'l'
                if down
                    @pos.y += dist unless @wallAt(x:@pos.x, y:@pos.y + testRange)
                    className = 'd'
                if up
                    @pos.y -= dist unless @wallAt(x:@pos.x, y:@pos.y - testRange)
                    className = 'u'
                @lightEl.className = @playerEl.className = className

                if @itemInRange(x:@exit.x, y:@exit.y - 70, 80)
                    @win()

            if window.toggleLight
                if Light.on
                    Light.turnOff()
                else
                    Light.turnOn()
                window.toggleLight = false

            @playerTouchingOrb()
            @playerTouchingTrigger()
            @moveMonsters(delta)
        @draw(delta)

    moveMonsters: (delta) ->
        for monster, i in @monsters
            if @itemOnScreen(monster) || monster.state == 1
                dx = (@pos.x - monster.x) / 20
                dy = (@pos.y - monster.y) / 20
                visible = true
                for i in [0..20]
                    if @wallAt(x:monster.x + dx * i, y:monster.y + dy * i)
                        visible = false

                if visible && monster.state == 0
                    monster.state = 1

                # monster idle. see if they can see player
                else if monster.state == 1
                    # monster has seen player. now to follow them
                    angDist = Vectors.angleDistBetweenPoints(monster, @pos)
                    dist = angDist.distance
                    angle = angDist.angle
                    if visible && Light.on && dist > 40 && (dist < Light.viewRadius)
                        speed = @monsterSpeed * (dist / Light.lightValue) / 3
                        angle += 0.5
                    else
                        speed = @monsterSpeed
                    stuck = true
                    attempts = 0
                    while stuck && attempts < 20
                        newPos = Vectors.addVectorToPoint(monster, angle, speed * delta)
                        # test two points in front of the monster
                        tp1 = Vectors.addVectorToPoint(newPos, angle + 1.0, 18.0)
                        tp2 = Vectors.addVectorToPoint(newPos, angle - 1.0, 18.0)
                        attempts += 1
                        if @wallAt(tp1)
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
        byId('vp').className='ded'
        pg = byId('pg')
        pg.style.top = @playerEl.style.top
        pg.style.left = @playerEl.style.left
        @state = 1
        @say('You had one job ... ', 4, 10)

    win: ->
        byId('vp').className='win'
        @state = 2
        @playerEl.className = 'd'
        @lightEl.className = 'd'
        Light.addPower()
        @say("Thanks, you're a hero!<br>I think I’ll be ok from here :)", 100, 200)

    draw: () ->
        @shadowCtx.clearRect(0, 0, @shadowCanvas.width, @shadowCanvas.height)
        @shadowCtx.save()
        @shadowCtx.translate(@viewX - @pos.x, @viewY - @pos.y)

        @itemsCtx.clearRect(0, 0, @itemsCanvas.width, @itemsCanvas.height)
        @itemsCtx.save()
        @itemsCtx.translate(@viewX - @pos.x, @viewY - @pos.y)

        @maskCtx.fillStyle = '#000'
        @maskCtx.fillRect(0,0,@maskCanvas.width, @maskCanvas.height)

        @drawOrbs()
        @drawMonsters()
        @drawLineShadows()
        @drawPlayerShadow()
        @drawExit(@itemsCtx)
        @itemsCtx.restore()
        @shadowCtx.restore()
        @compositeCanvas()

    wallAt: (pos) ->
        Map.pixelAt(pos.x, pos.y)[3] > 10

    compositeCanvas: ->
        @viewCtx.fillStyle = 'red'
        @viewCtx.fillRect(0,0, @viewCanvas.width, @viewCanvas.height)
        # draw floor
        @viewCtx.drawImage(Map.floorCanvas, @viewX - @pos.x, @viewY - @pos.y)
#
#        # remove items in shadows from items canvas
#        if true
        @itemsCtx.globalCompositeOperation = 'destination-out'
        @itemsCtx.drawImage(@shadowCanvas,0, 0)
        @itemsCtx.globalCompositeOperation = 'source-over'
#
#        # remove items in shadows from light mask canvas
        @maskCtx.drawImage(@shadowCanvas,0, 0)
#
#        # draw items
        @viewCtx.drawImage(@itemsCanvas, 0, 0)
#
#        # draw shadows
        if Light.on
            @viewCtx.globalAlpha = 0.6
            @viewCtx.drawImage(@shadowCanvas,0, 0)
            @viewCtx.globalAlpha = 1
#
#        # draw dungeon walls
        @viewCtx.drawImage(Map.canvas, @viewX - @pos.x, @viewY - @pos.y)
        @drawLightMask()

    drawPlayerShadow: ->
        radius = 24 / 2
        @shadowCtx.save()
        @shadowCtx.translate(@pos.x, @pos.y + 24 / 2)
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
                Light.addPower()
                orb.used = true

    playerTouchingTrigger: ->
        for t in @triggers
            if @itemInRange(t, t.r) && !t.used
                console.log 't', t.msg
                eval(t.action) if t.action
                @say(t.msg, 0, 0) if t.msg
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
        @maskCtx.fillStyle=grd

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
        radius = Light.viewRadius
        grd = @maskCtx.createRadialGradient(@viewX, @viewY, radius / 4, @viewX, @viewY, radius)
        grd.addColorStop(0, "rgba(255,255,255,#{Light.alpha})")
        grd.addColorStop(1, 'rgba(255,255,255,0)')

        @maskCtx.globalCompositeOperation = 'destination-out'
        @maskCtx.fillStyle=grd
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
                    x = randInt( - radius, radius * 2 )
                    @lightRays.push {x: x, y: randInt(-7, 14), w: randInt(2, radius - x), h: randInt(100, 50)}
                console.log @lightRays

            # draw light circle on ground
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

            # draw light rays
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

            # cur hole in light mask
            @maskCtx.fillStyle = "#000"
            maskRadius = radius * 1.5
            grd = @maskCtx.createRadialGradient(0, 0, 0, 0, 0, maskRadius)
            grd.addColorStop(0, "rgba(255,255,255,0.8)")
            grd.addColorStop(1, 'rgba(255,255,255,0)')
            @maskCtx.globalCompositeOperation = 'destination-out'
            @maskCtx.fillStyle=grd
            @maskCtx.save()
            @maskCtx.translate(@exit.x - @pos.x + @viewX, @exit.y - @pos.y + @viewY)
            @maskCtx.scale(1, 0.4)
            @maskCtx.beginPath()
            @maskCtx.arc(0, 0, maskRadius, 0, Math.PI * 2)
            @maskCtx.fill()
            @maskCtx.restore()
            @maskCtx.globalCompositeOperation = 'source-over'


    initLines: ->
        @lines = Map.lines()

    positionMap: ->
        @viewX = window.innerWidth / 4
        @viewY = window.innerHeight / 4

    initGameParams: (params) ->
        @monsters = []
        @orbs = []
        @triggers = []
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

    testTrigger: (trigger) ->
        @testCount ||= 1
        console.log 'trigger', @testCount
        trigger.used = true

    say: (msg, holdTime, delay) ->
        msg = msg.replace(/\s/g,'&nbsp;').replace("'", '&rsquo;')
        holdTime = 2000 + holdTime * 1000
        el = document.createElement('span')
        el.innerHTML = msg
    #    el.appendChild(document.createTextNode(msg))
        el.className = 't fi'
        o = document.getElementById('o')
        o.appendChild(el)
        setTimeout( (->el.className = 't'), 100)
        setTimeout( (->el.className = 't fo'), holdTime)
        setTimeout( (->o.removeChild(el)), holdTime + 4000 + delay)

    saySoon: (msg, holdTime, delay) ->
        setTimeout( (=> @say(msg, holdTime, 0)), delay * 1000)

    openingText: ->
        messages =[
            ['. . .', 0, 0]
            ["How did I end up here?", 0, 3]]
        for msg in messages
            @saySoon msg[0], msg[1], msg[2]

# ----------------------------------------------------------------------------------------------------------------------

window.randSeed = 1234
window.randomX = ->
    x = Math.sin(randSeed++) * 10000
    x - Math.floor(x)

window.randInt = (min, range) ->
    Math.floor(randomX() * range) + min

window.update = (timestamp) ->
    Game.update(timestamp)
    if window.paused
        console.log 'Game is paused'
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
    if(e.keyCode == 37 || e.keyCode == 65 ||e.keyCode == 81)
        window.left = true
    if(e.keyCode == 66)
        window.paused = true
        console.log 'Paused'


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
    Game.init()


