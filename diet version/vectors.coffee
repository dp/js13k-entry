window.Vectors =
  addVectorToPoint: (point, angRad, length) ->
    newPoint = x:0, y:0
    newPoint.x = point.x + (Math.cos(angRad) * length)
    newPoint.y = point.y + (Math.sin(angRad) * length)
    newPoint

  angleDistBetweenPoints: (fromPoint, toPoint) ->
    return 0 if fromPoint is toPoint
    x = toPoint.x - fromPoint.x
    y = toPoint.y - fromPoint.y
    distance= Math.sqrt(x*x+y*y)
    angle= Math.acos(x/distance)
    if y < 0
      angle = 0 - angle
    {angle, distance}

