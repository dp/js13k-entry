class Map

    constructor: (canvasId, args) ->
        @w = parseInt(args.width)
        @h = parseInt(args.height)
        @tileSize = parseInt(args.tileSize)
        @seed = parseInt(args.seed)
        @settings =
            initialDensity: parseInt(args.initialDensity) / 100
            reseedDensity: parseInt(args.reseedDensity) / 100
            smoothCorners: args.smoothCorners
            passes: args.passes
            reseedMethod: args.reseedMethod
            emptyTolerance: parseInt(args.emptyTolerance)
            wallRoughness: parseInt(args.wallRoughness) / 100
        @canvas = document.getElementById(canvasId)
        @canvas.width = (@w + 1) * @tileSize
        @canvas.height = (@h + 1) * @tileSize
        @ctx = @canvas.getContext('2d')
        @floorCanvas = document.getElementById('floor')
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
                if passType.match "combine" #|| passType.match "reseed"
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
        mp = 1 #Vectors.centreLine(x1, y1, x2, y2)
        angDist = Vectors.angleDistBetweenPoints({x:x1, y:y1}, {x:x2, y:y2})
#        angDist.angle += Math.PI * 2 if angDist.angle < 0
        mp:mp, ang: angDist.angle, normal:angDist.angle - Math.PI/2

    print: ->
        # prints sideways
        for row in @tiles
            console.log row.join()

    draw: ->
        for passType in @settings.passes
            @cellularPass(passType)

        @generateCellular()
        @findEdges()
        @moveCorners()
        @findSides()
#        @ctx.fillStyle = '#eee'
#        @ctx.fillRect(0,0, @canvas.width, @canvas.height)
        @drawFloor()
        @drawWalls(@ctx)
#        @drawEdges(@ctx)
        @imageData = @ctx.getImageData(0, 0, @canvas.width, @canvas.height)

    pixelAt: (x, y) ->
        offset = ((@canvas.width * y) + x) * 4
        red = @imageData.data[offset]
        green = @imageData.data[offset + 1]
        blue = @imageData.data[offset + 2]
        alpha = @imageData.data[offset + 3]
        [red, green, blue, alpha]
#        [0,0,0,0]

    drawWalls: (ctx) ->
        # colours here https://www.computerhope.com/htmcolor.htm
        ctx.fillStyle = '#686665'
        ctx.strokeStyle = '#686665'
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
#                    @ctx.fillRect(x * @tileSize, y * @tileSize, @tileSize, @tileSize)

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
        for x in [0..@w]
            for y in [0..@h]
                colour = "hsla(#{@randHue(hue1, hue2)},#{@randInt(0,5)}%,#{@randInt(60,20)}%,0.5)"
                @drawRandomisedRect(x * @tileSize+@randInt(0,10), y * @tileSize+@randInt(0,10), @tileSize+@randInt(0,20), @tileSize+@randInt(0,20), colour, 5)
        for x in [0..@w]
            for y in [0..@h]
                if Math.random() > 0.5
                    hue = hue1
                else
                    hue = hue2
                colour = "hsla(#{@randHue(hue1, hue2)},#{@randInt(0,5)}%,#{@randInt(60,20)}%,0.8)"
                @drawRandomisedRect(x * @tileSize+@randInt(0,10), y * @tileSize+@randInt(0,10), @tileSize+@randInt(0,20), @tileSize+@randInt(0,20), colour, 5)
        for x in [0..@w]
            for y in [0..@h]
                unless @tiles[x][y] && @tiles[x][y].surrounded
                    count = @nearbyTiles(x, y, 2)
                    brightness = ((1 - (count / 20)) * 80) / 2 + 20
                    for i in [0..@randInt(0,count * 2)]
                        colour = "hsla(#{@randHue(hue1, hue2)},#{@randInt(0,10)}%,#{@randInt(brightness,20)}%,0.8)"
                        @drawCircle(x * @tileSize+@randInt(0,@tileSize), y * @tileSize+@randInt(0,@tileSize), @randInt(3,7), colour)

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

window.Map = Map