Vectors =
  originPoint: ->
    {x:0, y:0}

  degToRad: (deg) ->
    0.017453292519943295 * deg

  radToDeg: (rad) ->
    57.29577951308232 * rad

  rotatePoint: (point, angle) ->
    x= point[0]
    y= point[1]
    # convert point to polar
    length= Math.sqrt(x*x+y*y)
    angleR= Math.acos(x/length)
    if (y<0)
      angleR = 0 - angleR
    # add angle
    angleR += angle
    # convert back to cartesian
    x1= Math.cos(angleR)* length
    y1= Math.sin(angleR)* length
    return [x1,y1]

  rotatePath: (path, angle) ->
    path.map (p) => @rotatePoint(p, angle)

  addVectorToPoint: (point, angRad, length) ->
#    angRad = @degToRad(direction)
#    angRad = direction
    newPoint = x:0, y:0
    newPoint.x = point.x + (Math.cos(angRad) * length)
    newPoint.y = point.y + (Math.sin(angRad) * length)
    newPoint

  addVectors: (angle1, length1, angle2, length2) ->
    x1 = Math.cos(angle1) * length1
    y1 = Math.sin(angle1) * length1
    x2 = Math.cos(angle2) * length2
    y2 = Math.sin(angle2) * length2

    xR = x1 + x2
    yR = y1 + y2
    lengthR = Math.sqrt(xR*xR+yR*yR)
    return [0,0] if lengthR is 0

    angleR = Math.acos(xR/lengthR)
    angleR = 0 - angleR if yR < 0

    return [angleR, lengthR]


  angleDistBetweenPoints: (fromPoint, toPoint) ->
    return 0 if fromPoint is toPoint
    x = toPoint.x - fromPoint.x
    y = toPoint.y - fromPoint.y
    distance= Math.sqrt(x*x+y*y)
    angle= Math.acos(x/distance)
    if y < 0
      angle = 0 - angle
    {angle, distance}

  distBetweenPoints: (fromPoint, toPoint) ->
    return 0 if fromPoint is toPoint
    x = toPoint.x - fromPoint.x
    y = toPoint.y - fromPoint.y
    Math.sqrt(x*x+y*y)

  shapesWithinReach: (shapeA, shapeB) ->
    Vectors.distBetweenPoints(shapeA.position, shapeB.position) < shapeA.reach + shapeB.reach

  shapeBounds: (paths) ->
    return {minX:0, minY:0, maxX:0, maxY:0} if paths.length is 0 or paths[0].length is 0 or paths[0][0].length is 0
    minX = maxX = paths[0][0][1]
    minY = maxY = paths[0][0][1]
    for path in paths
      for point in path
        minX = point[0] if point[0] < minX
        maxX = point[0] if point[0] > maxX
        minY = point[1] if point[1] < minY
        maxY = point[1] if point[1] > maxY
    {minX, maxX, minY, maxY}

  shapeCentre: (paths) ->
    bounds = @shapeBounds(paths)
    {x: (bounds.minX + bounds.maxX)/2, y:(bounds.minY + bounds.maxY)/2}

  distFromOrigin: (x, y) ->
    Math.sqrt(x * x + y * y)

  movePathOrigin: (paths, originX, originY) ->
    for path in paths
      for point in path
        unless point.length is 0
          point[0] -= originX
          point[1] -= originY

  centrePath: (paths) ->
    centre = Vectors.shapeCentre(paths)
    Vectors.movePathOrigin(paths, centre.x, centre.y)

  centrePathH: (paths) ->
    centre = Vectors.shapeCentre(paths)
    Vectors.movePathOrigin(paths, centre.x, 0)

  centrePathV: (paths) ->
    centre = Vectors.shapeCentre(paths)
    Vectors.movePathOrigin(paths, 0, centre.y)


window.Vectors = Vectors