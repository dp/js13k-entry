window.Dungeon =
    generate: ->
        params =
            seed: byId('seed').value
            width: byId('width').value
            height: byId('height').value
            tileSize: byId('tile-size').value
            initialDensity: byId('initial-density').value
            reseedDensity: byId('reseed-density').value
            smoothCorners: byId('smooth').checked
            reseedMethod: byId('reseed-method').value
            emptyTolerance: byId('empty-tolerance').value
            wallRoughness: byId('wall-roughness').value
            passes: []

        for i in [1..6]
            value = byId('pass-'+i).value
            params.passes.push value unless value == ''
        console.log params.passes
        byId('params').innerHTML = JSON.stringify(params)

        window.randSeed = seed
        @map = new Map('map', params)
        @zoom()
        @map.draw()

        @canvas = document.getElementById('items')
        @canvas.onclick = @canvasClicked
        @canvas.width = @map.canvas.width
        @canvas.height = @map.canvas.height
        @ctx = @canvas.getContext('2d')
        @items = {
            start: [50,50]
            exit: [60,20]
            monsters: []
            orbs: []}


    canvasClicked: (e) ->
        tileSize = Dungeon.map.tileSize
        Dungeon.addItem Math.floor(e.layerX / tileSize), Math.floor(e.layerY / tileSize)
        Dungeon.drawItems()

    randomSeed: ->
        byId('seed').value = Math.floor(Math.random() * 1000000)

    zoom: ->
        # @map.canvas.style.transform = "scale(#{byId('zoom').value})"
        @map.canvas.style.width = @map.canvas.width * parseFloat(byId('zoom').value)+'px'

    drawItems: ->
        @ctx.clearRect(0, 0, @canvas.width, @canvas.height)
        tileSize = @map.tileSize
        @ctx.fillStyle = 'cyan'
        for item in @items.orbs
            @ctx.fillRect(item[0] * tileSize, item[1] * tileSize, tileSize, tileSize)
        @ctx.fillStyle = 'red'
        for item in @items.monsters
            @ctx.fillRect(item[0] * tileSize, item[1] * tileSize, tileSize, tileSize)
        @ctx.fillStyle = 'limegreen'
        item = @items.start
        @ctx.fillRect(item[0] * tileSize, item[1] * tileSize, tileSize, tileSize)
        @ctx.fillStyle = 'green'
        item = @items.exit
        @ctx.fillRect(item[0] * tileSize, item[1] * tileSize, tileSize, tileSize)

    addItem: (x, y) ->
        itemType = byId('item-type').value
        if itemType == 'start' || itemType == 'exit'
            @items[itemType] = [x,y]
        else
            match = null
            for item, i in @items[itemType]
                if item[0] == x && item[1] == y
                    match = i
                    console.log x, y, item, i
            if match
                console.log 'before', @items[itemType], match
                @items[itemType].splice(match, 1)
                console.log 'after', @items[itemType]
            else
                @items[itemType].push [x,y]
        byId('locations').innerHTML = JSON.stringify(@items)

window.pixels = 1
