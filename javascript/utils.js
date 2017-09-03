window.randomXY = function(){
    var x = Math.sin(randSeed++) * 10000
    return x - Math.floor(x)
}

window.randIntX = function(min, range) {
    return Math.floor(randomX() * range) + min
}


window.debug = function(msg) {
    document.getElementById('debug').innerHTML = msg
}

window.byId = function(elementId) {
    return document.getElementById(elementId)
}
