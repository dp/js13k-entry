class Map

    constructor: () ->
        @w = 27
        @h = 15
        @tileSize = 60
        @canvas = document.getElementById('floor')
        @ctx = @canvas.getContext('2d')
        @generate()

    generate: ->
        tiles = new Array(@w)
        for x in [0..@w]
            tiles[x] = new Array(@h)
            for y in [0..@h]
                if Math.random() < 0.25 || x is 0 or y is 0 or x == @w or y == @h
                    tiles[x][y] = {style:'W', sides:{}}
        @tiles = tiles

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
        true

    moveCorners: ->
        variation = 20
        for x in [0...@w]
            for y in [0...@h]
                mx = ((x+1) * @tileSize) + randInt(-variation/2, variation)
                my = ((y+1) * @tileSize) + randInt(-variation/2, variation)
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
                        tile.lines.push {
                            x1: tile.corners.tl.x,
                            y1: tile.corners.tl.y,
                            x2: tile.corners.tr.x,
                            y2: tile.corners.tr.y}
                    unless tile.sides.left
                        tile.lines.push {
                            x1: tile.corners.tl.x,
                            y1: tile.corners.tl.y,
                            x2: tile.corners.bl.x,
                            y2: tile.corners.bl.y}
                    unless tile.sides.right
                        tile.lines.push {
                            x1: tile.corners.tr.x,
                            y1: tile.corners.tr.y,
                            x2: tile.corners.br.x,
                            y2: tile.corners.br.y}
                    unless tile.sides.below
                        tile.lines.push {
                            x1: tile.corners.bl.x,
                            y1: tile.corners.bl.y,
                            x2: tile.corners.br.x,
                            y2: tile.corners.br.y}

    print: ->
        # prints sideways
        for row in @tiles
            console.log row.join()

    draw: ->
        @findEdges()
        @moveCorners()
        @findSides()
        @ctx.fillStyle = '#888'
        @ctx.fillRect(0,0, @canvas.width, @canvas.height)
        @drawFloor()
        @drawWalls(@ctx)
        @drawEdges(@ctx)

    drawWalls: (ctx) ->
        # colours here https://www.computerhope.com/htmcolor.htm
        ctx.fillStyle = '#111'
        ctx.strokeStyle = '#111'
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
        hue1 = randInt(0,360)
        hue2 = hue1 + 180
        for i in [0..100]
            if Math.random() > 0.5
                hue = hue1
            else
                hue = hue2
            colour = "hsla(#{hue + randInt(-20,40)},#{randInt(0,10)}%,#{randInt(30,50)}%,0.5)"
            @drawRandomisedRect(randInt(-100, 1600), randInt(-100, 900), randInt(100, 300), randInt(100, 300), colour, 50)
        for i in [0..100]
            if Math.random() > 0.5
                hue = hue1
            else
                hue = hue2
            colour = "hsla(#{hue + randInt(-10,20)},#{randInt(0,10)}%,#{randInt(30,70)}%,0.4)"
            @drawRandomisedRect(randInt(-100, 1600), randInt(-100, 900), randInt(50, 100), randInt(50, 100), colour, 10)
        for i in [0..1000]
            if Math.random() > 0.5
                hue = hue1
            else
                hue = hue2
            colour = "hsla(#{hue + randInt(-10,20)},#{randInt(0,5)}%,#{randInt(60,40)}%,0.3)"
            @drawRandomisedRect(randInt(-10, 1660), randInt(-10, 950), randInt(10, 60), randInt(10, 60), colour, 10)
        for i in [0..10000]
            if Math.random() > 0.5
                hue = hue1
            else
                hue = hue2
            colour = "hsla(#{hue + randInt(-10,20)},#{randInt(0,0)}%,#{randInt(60,40)}%,0.5)"
            @drawRandomisedRect(randInt(-10, 1660), randInt(-10, 950), randInt(10, 30), randInt(10, 30), colour, 5)

    drawRandomisedRect: (x, y, w, h, colour, variation) ->
        @ctx.fillStyle = colour
        @ctx.beginPath()
        @ctx.moveTo(x + randInt(0, variation), y + randInt(0, variation))
        @ctx.lineTo(x + w + randInt(0, variation), y + randInt(0, variation))
        @ctx.lineTo(x + w + randInt(0, variation), y + h + randInt(0, variation))
        @ctx.lineTo(x + randInt(0, variation), y + h + randInt(0, variation))
        @ctx.fill()

    lines: ->
        lines = []
        for row in @tiles
            for tile in row
                if tile
                    lines.push([{x:line.x1, y:line.y1}, {x:line.x2, y:line.y2}]) for line in tile.lines
        lines

window.Map = Map