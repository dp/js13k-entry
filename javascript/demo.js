// Generated by CoffeeScript 1.12.5
(function() {
  var Game;

  Game = (function() {
    function Game(mapParams, gameParams) {
      this.map = new Map('map', mapParams);
      this.map.draw();
      this.tileSize = this.map.tileSize;
      this.state = 0;
      this.playerEl = byId('player');
      this.lightEl = byId('light');
      this.playerEl.style.left = ((window.innerWidth - 60) / 2) + "px";
      this.playerEl.style.top = ((window.innerHeight - 48) / 2) + "px";
      this.lightEl.style.left = ((window.innerWidth - 60) / 2) + "px";
      this.lightEl.style.top = ((window.innerHeight - 48) / 2) + "px";
      this.light = new Light(this.lightEl);
      this.initGameParams(gameParams);
      this.maskCanvas = byId('light-mask');
      this.maskCtx = this.maskCanvas.getContext('2d');
      this.maskCanvas.width = Math.floor(window.innerWidth / 2);
      this.maskCanvas.height = Math.floor(window.innerHeight / 2);
      this.maskCanvas.style.width = window.innerWidth + 'px';
      this.maskCanvas.style.height = window.innerHeight + 'px';
      this.maskCtx.fillStyle = '#000';
      this.maskCtx.fillRect(0, 0, this.maskCanvas.width, this.maskCanvas.height);
      this.shadowCanvas = document.createElement('canvas');
      this.shadowCtx = this.shadowCanvas.getContext('2d');
      this.shadowCanvas.width = this.maskCanvas.width;
      this.shadowCanvas.height = this.maskCanvas.height;
      this.viewCanvas = byId('view');
      this.viewCtx = this.viewCanvas.getContext('2d');
      this.viewCanvas.width = this.maskCanvas.width;
      this.viewCanvas.height = this.maskCanvas.height;
      this.viewCanvas.style.width = this.maskCanvas.style.width;
      this.viewCanvas.style.height = this.maskCanvas.style.height;
      this.viewCtx.translate(0.5, 0.5);
      this.itemsCanvas = document.createElement('canvas');
      this.itemsCtx = this.itemsCanvas.getContext('2d');
      this.itemsCanvas.width = this.maskCanvas.width;
      this.itemsCanvas.height = this.maskCanvas.height;
      this.positionMap();
      this.pos = this.tilePosToGameXY(gameParams.start);
      this.lines = [];
      this.speed = 125;
      this.monsterSpeed = 140;
      this.initLines();
      this.light.turnOff(3);
      this.openingText();
      requestAnimationFrame(update);
    }

    Game.prototype.update = function(timestamp) {
      var className, delta, dist, pg, testRange;
      if (this.lastTimestamp) {
        delta = (timestamp - this.lastTimestamp) / 1000;
      } else {
        delta = 0;
      }
      this.lastTimestamp = timestamp;
      if (this.state === 1) {
        pg = byId('player-ghost');
        pg.style.top = parseInt(pg.style.top) - 1 + 'px';
      } else if (this.state === 2) {
        if (this.light.tweening) {
          this.light.update(delta);
        }
      } else {
        this.light.update(delta);
        if (right || left || up || down) {
          dist = this.speed * delta;
          testRange = 12 + dist;
          if (right) {
            if (!this.wallAt({
              x: this.pos.x + testRange,
              y: this.pos.y
            })) {
              this.pos.x += dist;
            }
            className = 'right';
          }
          if (left) {
            if (!this.wallAt({
              x: this.pos.x - testRange,
              y: this.pos.y
            })) {
              this.pos.x -= dist;
            }
            className = 'left';
          }
          if (down) {
            if (!this.wallAt({
              x: this.pos.x,
              y: this.pos.y + testRange
            })) {
              this.pos.y += dist;
            }
            className = 'down';
          }
          if (up) {
            if (!this.wallAt({
              x: this.pos.x,
              y: this.pos.y - testRange
            })) {
              this.pos.y -= dist;
            }
            className = 'up';
          }
          this.lightEl.className = this.playerEl.className = className;
          if (this.itemInRange({
            x: this.exit.x,
            y: this.exit.y - 70
          }, 80)) {
            this.win();
          }
        }
        if (window.toggleLight) {
          if (this.light.on) {
            this.light.turnOff();
          } else {
            this.light.turnOn();
          }
          window.toggleLight = false;
        }
        this.playerTouchingOrb();
        this.playerTouchingTrigger();
        this.moveMonsters(delta);
      }
      return this.draw(delta);
    };

    Game.prototype.moveMonsters = function(delta) {
      var angDist, angle, attempts, dist, dx, dy, i, j, k, len, monster, newPos, ref, results, speed, stuck, tp1, tp2, visible;
      ref = this.monsters;
      results = [];
      for (i = j = 0, len = ref.length; j < len; i = ++j) {
        monster = ref[i];
        if (this.itemOnScreen(monster) || monster.state === 1) {
          dx = (this.pos.x - monster.x) / 20;
          dy = (this.pos.y - monster.y) / 20;
          visible = true;
          for (i = k = 0; k <= 20; i = ++k) {
            if (this.wallAt({
              x: monster.x + dx * i,
              y: monster.y + dy * i
            })) {
              visible = false;
            }
          }
          if (visible && monster.state === 0) {
            results.push(monster.state = 1);
          } else if (monster.state === 1) {
            angDist = Vectors.angleDistBetweenPoints(monster, this.pos);
            dist = angDist.distance;
            angle = angDist.angle;
            if (visible && this.light.on && dist > 40 && (dist < this.light.viewRadius)) {
              speed = this.monsterSpeed * (dist / this.light.lightValue) / 3;
              angle += 0.5;
            } else {
              speed = this.monsterSpeed;
            }
            stuck = true;
            attempts = 0;
            results.push((function() {
              var results1;
              results1 = [];
              while (stuck && attempts < 20) {
                newPos = Vectors.addVectorToPoint(monster, angle, speed * delta);
                tp1 = Vectors.addVectorToPoint(newPos, angle + 1.0, 18.0);
                tp2 = Vectors.addVectorToPoint(newPos, angle - 1.0, 18.0);
                attempts += 1;
                if (this.wallAt(tp1)) {
                  angle -= 0.3;
                  results1.push(speed = speed + 15);
                } else if (this.wallAt(tp2)) {
                  angle += 0.4;
                  results1.push(speed = speed + 10);
                } else {
                  monster.x = newPos.x;
                  monster.y = newPos.y;
                  stuck = false;
                  if (this.state === 0) {
                    if (Vectors.distBetweenPoints(this.pos, monster) < 22) {
                      results1.push(this.die());
                    } else {
                      results1.push(void 0);
                    }
                  } else {
                    results1.push(void 0);
                  }
                }
              }
              return results1;
            }).call(this));
          } else {
            results.push(void 0);
          }
        } else {
          results.push(void 0);
        }
      }
      return results;
    };

    Game.prototype.die = function() {
      var pg;
      byId('viewport').className = 'dead';
      pg = byId('player-ghost');
      pg.style.top = this.playerEl.style.top;
      pg.style.left = this.playerEl.style.left;
      this.state = 1;
      return this.say('You had one job ... ', 4, 10);
    };

    Game.prototype.win = function() {
      byId('viewport').className = 'win';
      this.state = 2;
      this.playerEl.className = 'down';
      this.light.addPower();
      return this.say("Thanks, you're a hero!<br>Finally, peace will return to my village", 100, 200);
    };

    Game.prototype.draw = function() {
      this.shadowCtx.clearRect(0, 0, this.shadowCanvas.width, this.shadowCanvas.height);
      this.shadowCtx.save();
      this.shadowCtx.translate(this.viewX - this.pos.x, this.viewY - this.pos.y);
      this.itemsCtx.clearRect(0, 0, this.itemsCanvas.width, this.itemsCanvas.height);
      this.itemsCtx.save();
      this.itemsCtx.translate(this.viewX - this.pos.x, this.viewY - this.pos.y);
      this.maskCtx.fillStyle = '#000';
      this.maskCtx.fillRect(0, 0, this.maskCanvas.width, this.maskCanvas.height);
      this.drawOrbs();
      this.drawMonsters();
      this.drawLineShadows();
      this.drawPlayerShadow();
      this.drawExit(this.itemsCtx);
      this.itemsCtx.restore();
      this.shadowCtx.restore();
      return this.compositeCanvas();
    };

    Game.prototype.wallAt = function(pos) {
      return this.map.pixelAt(pos.x, pos.y)[3] > 10;
    };

    Game.prototype.compositeCanvas = function() {
      this.viewCtx.fillStyle = '#585655';
      this.viewCtx.fillRect(0, 0, game.viewCanvas.width, game.viewCanvas.height);
      this.viewCtx.drawImage(this.map.floorCanvas, this.viewX - this.pos.x, this.viewY - this.pos.y);
      if (true) {
        this.itemsCtx.globalCompositeOperation = 'destination-out';
        this.itemsCtx.drawImage(this.shadowCanvas, 0, 0);
        this.itemsCtx.globalCompositeOperation = 'source-over';
      }
      this.maskCtx.drawImage(this.shadowCanvas, 0, 0);
      this.viewCtx.drawImage(this.itemsCanvas, 0, 0);
      if (this.light.on) {
        this.viewCtx.globalAlpha = 0.6;
        this.viewCtx.drawImage(this.shadowCanvas, 0, 0);
        this.viewCtx.globalAlpha = 1;
      }
      this.viewCtx.drawImage(this.map.canvas, this.viewX - this.pos.x, this.viewY - this.pos.y);
      return this.drawLightMask();
    };

    Game.prototype.drawPlayerShadow = function() {
      var grd, radius;
      radius = 24 / 2;
      this.shadowCtx.save();
      this.shadowCtx.translate(this.pos.x, this.pos.y + 24 / 2);
      this.shadowCtx.scale(1, 0.25);
      grd = this.shadowCtx.createRadialGradient(0, 0, 0, 0, 0, radius);
      grd.addColorStop(0, 'rgba(0,0,0,0.6)');
      grd.addColorStop(1, 'rgba(0,0,0,0)');
      this.shadowCtx.fillStyle = grd;
      this.shadowCtx.beginPath();
      this.shadowCtx.arc(0, 0, radius, 0, Math.PI * 2);
      this.shadowCtx.fill();
      return this.shadowCtx.restore();
    };

    Game.prototype.playerTouchingOrb = function() {
      var i, j, len, orb, ref, results;
      ref = this.orbs;
      results = [];
      for (i = j = 0, len = ref.length; j < len; i = ++j) {
        orb = ref[i];
        if (this.itemInRange(orb, this.tileSize) && !orb.used) {
          this.light.addPower();
          results.push(orb.used = true);
        } else {
          results.push(void 0);
        }
      }
      return results;
    };

    Game.prototype.playerTouchingTrigger = function() {
      var j, len, ref, results, t;
      ref = this.triggers;
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        t = ref[j];
        if (this.itemInRange(t, t.r) && !t.used) {
          console.log('t', t.msg);
          if (t.action) {
            eval(t.action);
          }
          if (t.msg) {
            this.say(t.msg, 0, 0);
          }
          results.push(t.used = true);
        } else {
          results.push(void 0);
        }
      }
      return results;
    };

    Game.prototype.drawOrbs = function() {
      var ctx, glowGradient, glowRadius, grd, j, len, maskRadius, orb, orbGradient, orbRadius, ref;
      ctx = this.itemsCtx;
      glowRadius = 15;
      orbRadius = 4;
      glowGradient = ctx.createRadialGradient(0, 0, orbRadius, 0, 0, glowRadius);
      glowGradient.addColorStop(0, 'rgba(143,194,242,0.4)');
      glowGradient.addColorStop(1, 'rgba(191,226,226,0)');
      orbGradient = ctx.createRadialGradient(1, -1, 1, 0, 0, orbRadius);
      orbGradient.addColorStop(0, '#bfe2e2');
      orbGradient.addColorStop(1, '#8fc2f2');
      this.maskCtx.fillStyle = "#000";
      maskRadius = glowRadius * 1.5;
      grd = this.maskCtx.createRadialGradient(0, 0, 0, 0, 0, maskRadius);
      grd.addColorStop(0, "rgba(255,255,255,0.8)");
      grd.addColorStop(1, 'rgba(255,255,255,0)');
      this.maskCtx.globalCompositeOperation = 'destination-out';
      this.maskCtx.fillStyle = grd;
      ref = this.orbs;
      for (j = 0, len = ref.length; j < len; j++) {
        orb = ref[j];
        if (this.itemOnScreen(orb) && !orb.used) {
          ctx.save();
          ctx.translate(orb.x, orb.y);
          ctx.fillStyle = glowGradient;
          ctx.beginPath();
          ctx.arc(0, 0, glowRadius, 0, Math.PI * 2);
          ctx.fill();
          ctx.fillStyle = orbGradient;
          ctx.beginPath();
          ctx.arc(0, 0, orbRadius, 0, Math.PI * 2);
          ctx.fill();
          ctx.restore();
          this.maskCtx.save();
          this.maskCtx.translate(orb.x - this.pos.x + this.viewX, orb.y - this.pos.y + this.viewY);
          this.maskCtx.beginPath();
          this.maskCtx.arc(0, 0, maskRadius, 0, Math.PI * 2);
          this.maskCtx.fill();
          this.maskCtx.restore();
        }
      }
      return this.maskCtx.globalCompositeOperation = 'source-over';
    };

    Game.prototype.drawMonsters = function() {
      var angDist, ctx, eyeCtx, j, len, monster, radius, ref, results;
      ctx = this.itemsCtx;
      eyeCtx = this.maskCtx;
      radius = 12;
      ref = this.monsters;
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        monster = ref[j];
        if (this.itemOnScreen(monster)) {
          angDist = Vectors.angleDistBetweenPoints(this.pos, monster);
          ctx.save();
          ctx.translate(monster.x, monster.y);
          ctx.rotate(angDist.angle);
          ctx.fillStyle = '#000';
          ctx.beginPath();
          ctx.arc(0, 0, radius, 0, Math.PI * 2);
          ctx.fill();
          ctx.fillStyle = '#a10';
          ctx.scale(0.5, 1.0);
          ctx.beginPath();
          ctx.arc(-13, 4, 3, 0, Math.PI * 2);
          ctx.arc(-13, -4, 3, 0, Math.PI * 2);
          ctx.fill();
          ctx.restore();
          eyeCtx.save();
          eyeCtx.translate(monster.x - this.pos.x + this.viewX, monster.y - this.pos.y + this.viewY);
          eyeCtx.rotate(angDist.angle);
          eyeCtx.fillStyle = '#f20';
          eyeCtx.scale(0.5, 1.0);
          eyeCtx.beginPath();
          eyeCtx.arc(-13, 4, 3, 0, Math.PI * 2);
          eyeCtx.arc(-13, -4, 3, 0, Math.PI * 2);
          eyeCtx.fill();
          results.push(eyeCtx.restore());
        } else {
          results.push(void 0);
        }
      }
      return results;
    };

    Game.prototype.itemInRange = function(pos, range) {
      return (Math.abs(pos.x - this.pos.x) < range) && (Math.abs(pos.y - this.pos.y) < range);
    };

    Game.prototype.itemOnScreen = function(pos) {
      return (Math.abs(pos.x - this.pos.x) < this.viewX) && (Math.abs(pos.y - this.pos.y) < this.viewY);
    };

    Game.prototype.drawLines = function() {
      var j, l, len, ref;
      this.shadowCtx.strokeStyle = '#800';
      this.shadowCtx.beginPath();
      ref = this.lines;
      for (j = 0, len = ref.length; j < len; j++) {
        l = ref[j];
        this.shadowCtx.moveTo(l[0].x, l[0].y);
        this.shadowCtx.lineTo(l[1].x, l[1].y);
      }
      return this.shadowCtx.stroke();
    };

    Game.prototype.drawLineShadows = function() {
      var angDist1, angDist2, angle, delta, j, l, len, p1, p2, ref, results;
      this.shadowCtx.fillStyle = '#000';
      this.shadowCtx.strokeStyle = '#000';
      ref = this.lines;
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        l = ref[j];
        p1 = l[0];
        if (this.itemOnScreen(p1)) {
          p2 = l[1];
          angDist1 = Vectors.angleDistBetweenPoints(this.pos, p1);
          angDist2 = Vectors.angleDistBetweenPoints(this.pos, p2);
          if (l[2]) {
            angle = angDist1.angle;
            delta = angle - l[2].ang;
            if (delta < Math.PI) {
              delta += Math.PI * 2;
            }
            if (delta > Math.PI) {
              delta -= Math.PI * 2;
            }
            if (delta < 0) {
              results.push(this.drawShadow(p1, p2, angDist1.angle, angDist2.angle));
            } else {
              results.push(void 0);
            }
          } else {
            results.push(void 0);
          }
        } else {
          results.push(void 0);
        }
      }
      return results;
    };

    Game.prototype.drawShadow = function(p1, p2, ang1, ang2) {
      var end1, end2;
      this.shadowCtx.beginPath();
      end1 = Vectors.addVectorToPoint(p1, ang1, 900);
      end2 = Vectors.addVectorToPoint(p2, ang2, 900);
      this.shadowCtx.moveTo(p1.x, p1.y);
      this.shadowCtx.lineTo(end1.x, end1.y);
      this.shadowCtx.lineTo(end2.x, end2.y);
      this.shadowCtx.lineTo(p2.x, p2.y);
      this.shadowCtx.lineTo(p1.x, p1.y);
      this.shadowCtx.fill();
      this.shadowCtx.beginPath();
      this.shadowCtx.moveTo(p1.x, p1.y);
      this.shadowCtx.lineTo(end1.x, end1.y);
      return this.shadowCtx.stroke();
    };

    Game.prototype.drawLightMask = function() {
      var grd, radius;
      this.maskCtx.fillStyle = "#000";
      radius = this.light.viewRadius;
      grd = this.maskCtx.createRadialGradient(this.viewX, this.viewY, radius / 4, this.viewX, this.viewY, radius);
      grd.addColorStop(0, "rgba(255,255,255," + this.light.alpha + ")");
      grd.addColorStop(1, 'rgba(255,255,255,0)');
      this.maskCtx.globalCompositeOperation = 'destination-out';
      this.maskCtx.fillStyle = grd;
      this.maskCtx.beginPath();
      this.maskCtx.arc(this.viewX, this.viewY, radius, 0, Math.PI * 2);
      this.maskCtx.fill();
      return this.maskCtx.globalCompositeOperation = 'source-over';
    };

    Game.prototype.drawExit = function(ctx) {
      var grd, i, j, k, len, maskRadius, radius, ray, ref, x;
      if (this.itemOnScreen(this.exit)) {
        radius = this.tileSize;
        if (!this.lightRays) {
          this.lightRays = [];
          for (i = j = 0; j <= 5; i = ++j) {
            x = randInt(-radius, radius * 2);
            this.lightRays.push({
              x: x,
              y: randInt(-7, 14),
              w: randInt(2, radius - x),
              h: randInt(100, 50)
            });
          }
          console.log(this.lightRays);
        }
        ctx.save();
        ctx.translate(this.exit.x, this.exit.y);
        ctx.scale(1, 0.4);
        grd = ctx.createRadialGradient(0, 0, 0, 0, 0, radius);
        grd.addColorStop(0, 'rgba(255, 255, 255, 0.9)');
        grd.addColorStop(1, 'rgba(255, 255, 255, 0.2)');
        ctx.fillStyle = grd;
        ctx.beginPath();
        ctx.arc(0, 0, radius, 0, Math.PI * 2);
        ctx.fill();
        ctx.restore();
        ctx.save();
        ctx.translate(this.exit.x, this.exit.y);
        ref = this.lightRays;
        for (k = 0, len = ref.length; k < len; k++) {
          ray = ref[k];
          grd = ctx.createLinearGradient(ray.x, ray.y, ray.x, ray.y - ray.h);
          grd.addColorStop(0, "rgba(255, 255, 255, " + (0.3 + Math.random() / 5) + ")");
          grd.addColorStop(1, 'rgba(255, 255, 255, 0)');
          ctx.fillStyle = grd;
          ctx.beginPath();
          ctx.moveTo(ray.x, ray.y);
          ctx.lineTo(ray.x - 0.2 * ray.h, ray.y - ray.h);
          ctx.lineTo(ray.x - 0.2 * ray.h + ray.w, ray.y - ray.h);
          ctx.lineTo(ray.x + ray.w, ray.y);
          ctx.fill();
        }
        ctx.restore();
        this.maskCtx.fillStyle = "#000";
        maskRadius = radius * 1.5;
        grd = this.maskCtx.createRadialGradient(0, 0, 0, 0, 0, maskRadius);
        grd.addColorStop(0, "rgba(255,255,255,0.8)");
        grd.addColorStop(1, 'rgba(255,255,255,0)');
        this.maskCtx.globalCompositeOperation = 'destination-out';
        this.maskCtx.fillStyle = grd;
        this.maskCtx.save();
        this.maskCtx.translate(this.exit.x - this.pos.x + this.viewX, this.exit.y - this.pos.y + this.viewY);
        this.maskCtx.scale(1, 0.4);
        this.maskCtx.beginPath();
        this.maskCtx.arc(0, 0, maskRadius, 0, Math.PI * 2);
        this.maskCtx.fill();
        this.maskCtx.restore();
        return this.maskCtx.globalCompositeOperation = 'source-over';
      }
    };

    Game.prototype.initLines = function() {
      return this.lines = this.map.lines();
    };

    Game.prototype.positionMap = function() {
      this.viewX = window.innerWidth / 4;
      return this.viewY = window.innerHeight / 4;
    };

    Game.prototype.initGameParams = function(params) {
      var j, k, len, len1, len2, m, monster, pos, ref, ref1, ref2, results, trigger;
      this.monsters = [];
      this.orbs = [];
      this.triggers = [];
      this.exit = this.tilePosToGameXY(params.exit);
      ref = params.monsters;
      for (j = 0, len = ref.length; j < len; j++) {
        pos = ref[j];
        monster = this.tilePosToGameXY(pos);
        monster.state = 0;
        this.monsters.push(monster);
      }
      ref1 = params.orbs;
      for (k = 0, len1 = ref1.length; k < len1; k++) {
        pos = ref1[k];
        this.orbs.push(this.tilePosToGameXY(pos));
      }
      ref2 = params.triggers;
      results = [];
      for (m = 0, len2 = ref2.length; m < len2; m++) {
        trigger = ref2[m];
        trigger.x *= this.tileSize;
        trigger.y *= this.tileSize;
        trigger.r = trigger.r * this.tileSize / 2;
        results.push(this.triggers.push(trigger));
      }
      return results;
    };

    Game.prototype.tilePosToGameXY = function(xy) {
      return {
        x: (xy[0] + .5) * this.tileSize,
        y: (xy[1] + .5) * this.tileSize
      };
    };

    Game.prototype.testTrigger = function(trigger) {
      this.testCount || (this.testCount = 1);
      console.log('trigger', this.testCount);
      return trigger.used = true;
    };

    Game.prototype.say = function(msg, holdTime, delay) {
      var el, o;
      msg = msg.replace(/\s/g, '&nbsp;').replace("'", '&rsquo;');
      holdTime = 2000 + holdTime * 1000;
      el = document.createElement('span');
      el.innerHTML = msg;
      el.className = 'text fade-in';
      o = document.getElementById('overlay');
      o.appendChild(el);
      setTimeout((function() {
        return el.className = 'text';
      }), 100);
      setTimeout((function() {
        return el.className = 'text fade-out';
      }), holdTime);
      return setTimeout((function() {
        return o.removeChild(el);
      }), holdTime + 4000 + delay);
    };

    Game.prototype.saySoon = function(msg, holdTime, delay) {
      return setTimeout(((function(_this) {
        return function() {
          return _this.say(msg, holdTime, 0);
        };
      })(this)), delay * 1000);
    };

    Game.prototype.openingText = function() {
      var j, len, messages, msg, results;
      messages = [['. . .', 0, 0], ["How did I end up here?", 0, 3]];
      results = [];
      for (j = 0, len = messages.length; j < len; j++) {
        msg = messages[j];
        results.push(this.saySoon(msg[0], msg[1], msg[2]));
      }
      return results;
    };

    return Game;

  })();

  window.randomX = function() {
    var x;
    x = Math.sin(randSeed++) * 10000;
    return x - Math.floor(x);
  };

  window.randInt = function(min, range) {
    return Math.floor(randomX() * range) + min;
  };

  window.update = function(timestamp) {
    game.update(timestamp);
    if (window.paused) {
      console.log('Game is paused');
    } else {
      window.requestAnimationFrame(update);
    }
    return true;
  };

  window.byId = function(elementId) {
    return document.getElementById(elementId);
  };

  window.up = window.right = window.down = window.left = false;

  window.onkeydown = function(e) {
    if (e.keyCode === 32) {
      window.toggleLight = true;
    }
    if (e.keyCode === 38 || e.keyCode === 90 || e.keyCode === 87) {
      window.up = true;
    }
    if (e.keyCode === 39 || e.keyCode === 68) {
      window.right = true;
    }
    if (e.keyCode === 40 || e.keyCode === 83) {
      window.down = true;
    }
    if (e.keyCode === 37 || e.keyCode === 65 || e.keyCode === 81) {
      window.left = true;
    }
    if (e.keyCode === 66) {
      window.paused = true;
      return console.log('Paused');
    }
  };

  window.onkeyup = function(e) {
    if (e.keyCode === 38 || e.keyCode === 90 || e.keyCode === 87) {
      window.up = false;
    }
    if (e.keyCode === 39 || e.keyCode === 68) {
      window.right = false;
    }
    if (e.keyCode === 40 || e.keyCode === 83) {
      window.down = false;
    }
    if (e.keyCode === 37 || e.keyCode === 65 || e.keyCode === 81) {
      return window.left = false;
    }
  };

  window.initGame = function() {
    var gameParams, mapParams;
    window.paused = false;
    mapParams = {
      seed: 559516,
      width: 120,
      height: 80,
      tileSize: 25,
      initialDensity: 47,
      reseedDensity: 51,
      smoothCorners: true,
      reseedMethod: 'top',
      emptyTolerance: 6,
      wallRoughness: 25,
      passes: ["combine-aggressive", "reseed-medium", "combine-aggressive", "reseed-small", "combine-aggressive", "remove-singles"]
    };
    gameParams = {
      start: [76, 49],
      exit: [37, 21],
      monsters: [[32, 49], [80, 18], [102, 19], [62, 21], [76, 38], [57, 24], [113, 72], [116, 75], [117, 72], [115, 63], [73, 67], [49, 72], [5, 70], [13, 35], [49, 75], [97, 70], [86, 12], [63, 59], [91, 22]],
      orbs: [[60, 61], [35, 33], [10, 62], [18, 48], [105, 77], [114, 50], [116, 16], [49, 29], [73, 38], [80, 5], [79, 72], [101, 58], [72, 45], [80, 49], [51, 46]],
      triggers: [
        {
          x: 70,
          y: 43,
          r: 3,
          msg: "Let's get out of here"
        }, {
          x: 85,
          y: 59,
          r: 7,
          msg: "I think we're headed in the right direction"
        }, {
          x: 117,
          y: 69,
          r: 5,
          msg: "I've got a bad feeling about this ..."
        }, {
          x: 52,
          y: 21,
          r: 7,
          msg: "I'm sure the air is fresher here"
        }, {
          x: 57,
          y: 60,
          r: 5,
          msg: "Do we need that light?"
        }
      ]
    };
    return window.game = new Game(mapParams, gameParams);
  };

  window.Game = Game;

}).call(this);
