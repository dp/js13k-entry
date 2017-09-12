window.V =
    m1: (point, angRad, length) ->
        newPoint = x:0, y:0
        newPoint.x = point.x + (Math.cos(angRad) * length)
        newPoint.y = point.y + (Math.sin(angRad) * length)
        newPoint

    m2: (fromPoint, toPoint) ->
        return 0 if fromPoint is toPoint
        x = toPoint.x - fromPoint.x
        y = toPoint.y - fromPoint.y
        distance= Math.sqrt(x*x+y*y)
        angle= Math.acos(x/distance)
        if y < 0
            angle = 0 - angle
        {angle, distance}

    m3: (fromPoint, toPoint) ->
        return 0 if fromPoint is toPoint
        x = toPoint.x - fromPoint.x
        y = toPoint.y - fromPoint.y
        Math.sqrt(x*x+y*y)

window.L =
    init: (lightEl) ->
        @lightEl = lightEl
        @on = false
        @lightValue = 0
        @viewRadius = 0
        @alpha = 1.0
        @reduction = 7
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

window.Msg =
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

window.Map =
    init: ->
        @w = 120
        @h = 80
        @tileSize = 25
        @seed = 559516
        @settings =
            initialDensity: 0.47
            reseedDensity: 0.51
            smoothCorners: true
            passes: [
                "combine-aggressive"
                "reseed-medium"
                "combine-aggressive"
                "reseed-small"
                "combine-aggressive"
                "remove-singles"]
            reseedMethod: 'top'
            emptyTolerance: 6
            wallRoughness: 0.2
        @canvas = document.createElement('canvas')
        @canvas.width = (@w + 1) * @tileSize
        @canvas.height = (@h + 1) * @tileSize
        @canvas.style.width = @canvas.width + 'px'
        @ctx = @canvas.getContext('2d')
        @floorCanvas = document.createElement('canvas')
        @floorCanvas.width = (@w + 1) * @tileSize
        @floorCanvas.height = (@h + 1) * @tileSize
        @floorCtx = @floorCanvas.getContext('2d')
        @generate()

    generate: ->
        tiles = new Array(@w)
        @wTiles = new Array(@w) # working area for tiles during cellular passed
        for x in [0..@w]
            tiles[x] = new Array(@h)
            @wTiles[x] = new Array(@h)
            for y in [0..@h]
                if @seededRandom() < @settings.initialDensity || x is 0 or y is 0 or x == @w or y == @h
                    tiles[x][y] = true
        @tiles = tiles

    tileAtPos: (pos) ->
        @tiles[Math.floor(pox.x / @tileSize)][Math.floor(pox.y / @tileSize)]

    generateCellular: ->
#        @cellularPass()
        for row, x in @tiles
            for tile, y in row
                if tile
                    @tiles[x][y] = {style:'W', sides:[]}

    cellularPass: (passType) ->
# possible types are:
# "combine",
# "reseed-huge",
# "reseed-large",
# "reseed-med",
# "reseed-small",
# "remove-singles"
        for x in [1...@w]
            for y in [1...@h]
                @wTiles[x][y] = @tiles[x][y]
                if passType.match "combine"
                    if @nearbyTiles(x, y, 1) >= 5
                        @tiles[x][y] = true if passType == 'combine-aggressive'
                        @wTiles[x][y] = true
                    else
                        @tiles[x][y] = null if passType == 'combine-aggressive'
                        @wTiles[x][y] = null
                else if passType.match "reseed"
                    if passType == "reseed-huge"
                        range = 7
                    else if passType == "reseed-large"
                        range = 5
                    else if passType == "reseed-medium"
                        range = 4
                    else
                        range = 3
                    if @settings.reseedMethod == 'top'
                        if @nearbyTiles(x + range, y + range, range) <= @settings.emptyTolerance
                            @wTiles[x][y] = true if @seededRandom() < @settings.reseedDensity
                            @tiles[x][y] = @wTiles[x][y]
                    else
                        if @nearbyTiles(x, y, range) <= @settings.emptyTolerance
                            @wTiles[x][y] = true if @seededRandom() < @settings.reseedDensity
                else if passType == 'remove-singles'
                    count = @nearbyTiles(x, y, 1)
                    if count == 1 && @tiles[x][y]
                        @wTiles[x][y] = null
                    else if count == 8 && !@tiles[x][y]
                        @wTiles[x][y] = true

        for x in [1...@w]
            for y in [1...@h]
                @tiles[x][y] = @wTiles[x][y]
        true

    nearbyTiles: (x,y, dist) ->
        count = 0
        for xo in [x - dist .. x + dist]
            for yo in [y - dist .. y + dist]
                if xo < 0 || xo >= @w || yo < 0 || yo >= @h
                    count += 1
                else
                    count += 1 if @tiles[xo][yo] # && (xo != x && yo != y)
        count

    nearbyTile: (x, y, xOffset, yOffset) ->
        @tiles[x + xOffset][y + yOffset]


    findEdges: ->
        for row, x in @tiles
            for tile, y in row
                if tile
                    tile.sides.above = @tiles[x][y-1] if y > 0
                    tile.sides.below = @tiles[x][y+1] if y < @h
                    tile.sides.left = @tiles[x-1][y] if x > 0
                    tile.sides.right = @tiles[x+1][y] if x < @w
                    tile.corners = {
                        tl: {x:(x + 0) * @tileSize, y:(y + 0) * @tileSize}
                        tr: {x:(x + 1) * @tileSize, y:(y + 0) * @tileSize}
                        bl: {x:(x + 0) * @tileSize, y:(y + 1) * @tileSize}
                        br: {x:(x + 1) * @tileSize, y:(y + 1) * @tileSize}
                    }
                    tile.surrounded = @nearbyTiles(x, y, 1) == 9
        true

    moveCorners: ->
        variation = @settings.wallRoughness * @tileSize
        for x in [0...@w]
            for y in [0...@h]
                ox = oy = 0
                if @settings.smoothCorners
                    key = 0
                    key += 1 if @tiles[x][y]
                    key += 2 if @tiles[x+1][y]
                    key += 4 if @tiles[x][y+1]
                    key += 8 if @tiles[x+1][y+1]

                    if key == 1 || key == 4 || key == 11 || key == 14
                        ox = -1
                    else if key == 2 || key == 7 || key == 8 || key == 13
                        ox = 1
                    if key == 1 || key == 2 || key == 14 || key == 14
                        oy = -1
                    else if key == 4 || key == 7 || key == 8 || key == 11
                        oy = 1
                    ox = ox * @tileSize / 4
                    oy = oy * @tileSize / 4

                mx = ((x+1) * @tileSize) + ox + @randInt(-variation/2, variation)
                my = ((y+1) * @tileSize) + oy + @randInt(-variation/2, variation)

                @tiles[x][y]?.corners.br = {x: mx, y: my}
                @tiles[x+1][y]?.corners.bl = {x: mx, y: my}
                @tiles[x][y+1]?.corners.tr = {x: mx, y: my}
                @tiles[x+1][y+1]?.corners.tl = {x: mx, y: my}

    findSides: ->
        for row, x in @tiles
            for tile, y in row
                if tile
                    tile.lines = []
                    unless tile.sides.above
                        line = {
                            x1: tile.corners.tl.x,
                            y1: tile.corners.tl.y,
                            x2: tile.corners.tr.x,
                            y2: tile.corners.tr.y}
                        line.stuff = @findNormals(line.x1, line.y1, line.x2, line.y2)
                        tile.lines.push line
                    unless tile.sides.left
                        line = {
                            x1: tile.corners.tl.x,
                            y1: tile.corners.tl.y,
                            x2: tile.corners.bl.x,
                            y2: tile.corners.bl.y}
                        line.stuff = @findNormals(line.x2, line.y2, line.x1, line.y1)
                        tile.lines.push line
                    unless tile.sides.right
                        line = {
                            x1: tile.corners.tr.x,
                            y1: tile.corners.tr.y,
                            x2: tile.corners.br.x,
                            y2: tile.corners.br.y}
                        line.stuff = @findNormals(line.x1, line.y1, line.x2, line.y2)
                        tile.lines.push line
                    unless tile.sides.below
                        line = {
                            x1: tile.corners.bl.x,
                            y1: tile.corners.bl.y,
                            x2: tile.corners.br.x,
                            y2: tile.corners.br.y}
                        line.stuff = @findNormals(line.x2, line.y2, line.x1, line.y1)
                        tile.lines.push line

    findNormals: (x1, y1, x2, y2) ->
        mp = 1
        angDist = V.m2({x:x1, y:y1}, {x:x2, y:y2})
        mp:mp, ang: angDist.angle, normal:angDist.angle - Math.PI/2

    draw: ->
        for passType in @settings.passes
            @cellularPass(passType)

        @generateCellular()
        @findEdges()
        @moveCorners()
        @findSides()
        @drawFloor()
        @drawWalls(@ctx)
        @imageData = @ctx.getImageData(0, 0, @canvas.width, @canvas.height)

    pixelAt: (x, y) ->
        x = Math.floor(x)
        y = Math.floor(y)
        offset = ((@canvas.width * y) + x) * 4
        red = @imageData.data[offset]
        green = @imageData.data[offset + 1]
        blue = @imageData.data[offset + 2]
        alpha = @imageData.data[offset + 3]
        [red, green, blue, alpha]

    drawWalls: (ctx) ->
        ctx.fillStyle = '#585655'
        ctx.strokeStyle = '#585655'
        for row, x in @tiles
            for tile, y in row
                if tile
                    ctx.beginPath()
                    ctx.moveTo(tile.corners.tl.x, tile.corners.tl.y)
                    ctx.lineTo(tile.corners.tr.x, tile.corners.tr.y)
                    ctx.lineTo(tile.corners.br.x, tile.corners.br.y)
                    ctx.lineTo(tile.corners.bl.x, tile.corners.bl.y)
                    ctx.fill()
                    ctx.stroke()

    drawEdges: (ctx) ->
        ctx.strokeStyle = 'sandstone'
        ctx.beginPath()
        for row, x in @tiles
            for tile, y in row
                if tile
                    for line in tile.lines
                        ctx.moveTo(line.x1, line.y1)
                        ctx.lineTo(line.x2, line.y2)
        ctx.stroke()


    drawFloor: ->
        @floorCtx.fillStyle = '#888'
        @floorCtx.fillRect(0,0, @canvas.width, @canvas.height)
        hue1 = @randInt(0,360)
        hue2 = hue1 + 180
        v1 = 5
        v2 = 10
        v3 = 3
        v4 = 1
        v5 = 4
        for x in [0..@w]
            for y in [0..@h]
                colour = "hsla(#{@randHue(hue1, hue2)},#{@randInt(0,5)}%,#{@randInt(60,20)}%,0.5)"
                @drawRandomisedRect(x * @tileSize+@randInt(0,v1), y * @tileSize+@randInt(0,v1), @tileSize+@randInt(0,v2), @tileSize+@randInt(0,v2), colour, v3)
        for x in [0..@w]
            for y in [0..@h]
                colour = "hsla(#{@randHue(hue1, hue2)},#{@randInt(0,5)}%,#{@randInt(60,20)}%,0.8)"
                @drawRandomisedRect(x * @tileSize+@randInt(0,v1), y * @tileSize+@randInt(0,v1), @tileSize+@randInt(0,v2), @tileSize+@randInt(0,v2), colour, v3)
        for x in [0..@w]
            for y in [0..@h]
                unless @tiles[x][y] && @tiles[x][y].surrounded
                    count = @nearbyTiles(x, y, 2)
                    brightness = ((1 - (count / 20)) * 80) / 2 + 20
                    for i in [0..@randInt(0,count * 2)]
                        colour = "hsla(#{@randHue(hue1, hue2)},#{@randInt(0,v1)}%,#{@randInt(brightness,20)}%,0.8)"
                        @drawCircle(x * @tileSize+@randInt(0,@tileSize), y * @tileSize+@randInt(0,@tileSize), @randInt(v4, v5), colour)

    drawRandomisedRect: (x, y, w, h, colour, variation) ->
        @floorCtx.fillStyle = colour
        @floorCtx.beginPath()
        @floorCtx.moveTo(x + @randInt(0, variation), y + @randInt(0, variation))
        @floorCtx.lineTo(x + w + @randInt(0, variation), y + @randInt(0, variation))
        @floorCtx.lineTo(x + w + @randInt(0, variation), y + h + @randInt(0, variation))
        @floorCtx.lineTo(x + @randInt(0, variation), y + h + @randInt(0, variation))
        @floorCtx.fill()

    randHue: (hue1, hue2) ->
        if Math.random() > 0.5
            hue = hue1
        else
            hue = hue2
        hue + @randInt(-10,20)

    drawCircle: (x,y,r, colour) ->
        @floorCtx.fillStyle = colour
        @floorCtx.beginPath()
        @floorCtx.arc(x, y, r, 0, Math.PI * 2)
        @floorCtx.fill()

    lines: ->
        lines = []
        for row in @tiles
            for tile in row
                if tile
                    lines.push([{x:line.x1, y:line.y1}, {x:line.x2, y:line.y2}, line.stuff]) for line in tile.lines
        lines

    seededRandom: ->
        x = Math.sin(@seed++) * 10000
        x - Math.floor(x)

    randInt: (min, range) ->
        Math.floor(@seededRandom() * range) + min

window.Game =
    init: ->
        Map.init()
        Map.draw()

        @tileSize = Map.tileSize
        @state = 0
        @orbCount = 0
        @distQ = 0

        @playerEl = byId('p')
        @lightEl = byId('l')
        @playerEl.style.left = "#{(window.innerWidth - 60) / 2}px"
        @playerEl.style.top = "#{(window.innerHeight - 48) / 2}px"
        @lightEl.style.left = "#{(window.innerWidth - 60) / 2}px"
        @lightEl.style.top = "#{(window.innerHeight - 48) / 2}px"

        L.init(@lightEl)

        @initGameParams {
            monsters: [[32, 49], [80, 18], [102, 19], [62, 21], [76, 38], [57, 24], [113, 72], [116, 75], [117, 72],
                [115, 63], [73, 67], [49, 72], [5, 70], [13, 35], [49, 75], [97, 70], [86, 12], [63, 59], [91, 22]],
            orbs: [[60,61],[35,33],[10,62],[18,48],[105,77],[114,50],[116,16],[49,29],[73,38],[80,5],[79,72],[101,58],
                [72,45],[80,49],[51,46]],
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
                {x: 4, y: 51, r: "3", msg: "I feel like we're|going in circles!"}, # 11
                {x: 35, y: 32, r: "7", msg: "Well, that was a waste|of time"}] # 12
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
        Msg.init(@maskCtx, @viewX, @viewY)
        @pos = @tilePosToGameXY([76, 49])
        @exit = @tilePosToGameXY([37, 21])
        @lines = []
        @speed = 125
        @monsterSpeed = 100

        @initLines()
        L.turnOff(3)
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
            pg = byId('pg')
            pg.style.top = parseInt(pg.style.top) - 1 + 'px'
        else if @state == 2
# winning
            L.update(delta) if L.tweening
        else
# playing
            L.update(delta)

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

            if window.toggleL
                if L.on
                    L.turnOff()
                else
                    L.turnOn()
                window.toggleLight = false

            @playerTouchingOrb()
            @playerTouchingTrigger()
            @moveMonsters(delta)
            Msg.update(delta)
        @draw(delta)

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
                    angDist = V.m2(monster, @pos)
                    dist = angDist.distance
                    angle = angDist.angle
                    if visible && L.on && dist < (L.viewRadius + 20)
                        # speed will be -ve if inside circle
                        # meaning they go backwards
                        speed = (dist - L.viewRadius)
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
                        newPos = V.m1(monster, angle, speed * delta)
                        # test two points in front of the monster
                        tp1 = V.m1(newPos, angle + 1.0, 18.0)
                        tp2 = V.m1(newPos, angle - 1.0, 18.0)
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
                                if V.m3(@pos, monster) < 22
                                    @die()

    die: ->
        byId('vp').className='ded'
        pg = byId('pg')
        pg.style.top = @playerEl.style.top
        pg.style.left = @playerEl.style.left
        @state = 1
        Msg.say('You had one job ... ', x: -130, y: @viewY - 40, colour:'#b00', size:30)
        L.alpha = 0.4 if L.alpha < 0.4
        L.viewRadius = 20 if L.viewRadius < 20
        @printStats()

    win: ->
        byId('vp').className='win'
        @state = 2
        @playerEl.className = 'd'
        @lightEl.className = 'd'
        L.addPower()
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
        @maskCtx.fillRect(0,0,@maskCanvas.width, @maskCanvas.height)

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
        if L.on
            @viewCtx.globalAlpha = 0.7
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
                L.addPower()
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
                angDist = V.m2 @pos, monster

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
                p2 = l[1] # point 2
                angDist1 = V.m2 @pos, p1
                angDist2 = V.m2 @pos, p2
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
        end1 = V.m1(p1, ang1, 900)
        end2 = V.m1(p2, ang2, 900)
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
        radius = L.viewRadius
        grd = @maskCtx.createRadialGradient(@viewX, @viewY, radius / 4, @viewX, @viewY, radius)
        grd.addColorStop(0, "rgba(255,255,255,#{L.alpha})")
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
    Game.update(timestamp)
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



window.initGame = ->
    Game.init()


