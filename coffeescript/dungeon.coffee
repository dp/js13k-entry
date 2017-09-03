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

    randomSeed: ->
        byId('seed').value = Math.floor(Math.random() * 1000000)

    zoom: ->
        # @map.canvas.style.transform = "scale(#{byId('zoom').value})"
        @map.canvas.style.width = @map.canvas.width * parseFloat(byId('zoom').value)+'px'
