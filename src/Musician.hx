//@ ugl.bgcolor = 0x444444

import vault.ugl.*;
import vault.EMath;
import vault.Vec2;
import vault.ugl.PixelArt.C;

class Musician extends Game {
  public var score: Int;
  var display: Text;
  public var bpm: Float;
  public var level: Int;
  static public function main() {
    // Game.debug = true;
    new Musician("Street Musician", "");
  }

  public var player: Player;
  public var hat: Hat;
  public var holder: Holder;

  override public function initialize() {
    Game.orderGroups(["Hat", "Holder", "Coin", "Tomato", "Note", "Player", "Text"]);
  }

  override public function end() {
    player.remove();
  }

  override public function begin() {
    player = new Player();
    hat = new Hat();

    holder = new Holder();

    var n = new Note();
    score = 0;
    display = new Text().xy(20, 10).align(TOP_LEFT).size(2);
    bpm = 60.0;
    level = 0;
  }

  var tempo = 0.0;
  var n = 0;
  override public function update() {
    tempo += Game.time;

    var spb = 60.0/(4*bpm);
    if (tempo >= spb) {
      tempo -= spb;
      if (Math.random() < 0.2) {
        new Note();
      }
    }

    display.text("$" + score);

    if (Game.key.b1_pressed) {
      new Sound(n).explosion().play();
      trace(n);
      n++;
    }


  }
}

class Holder extends Entity {
  var FORMAT = "..0..
       .0.0.
       0...0
       .0.0.
       .000.";

  override public function begin() {
    art.size(4, 5, 5).obj([0x000000], FORMAT);
    pos.x = 240;
    pos.y = 80;
    addHitBox(Rect(0, 0, 20, 20));
  }

  override public function update() {
    var minx = 1e99;
    var bestn: Note = null;
    for (n in Game.get("Note")) {
      var no: Note = cast n;
      no.front = false;
      if (no.missed || no.good) continue;
      if (no.pos.x < minx) {
        minx = no.pos.x;
        bestn = no;
      }
    }
    if (bestn != null) {
      bestn.front = true;
    }
  }
}


class Note extends Entity {
  var NOTE = "..0..
       .000.
       00000
       .000.
       .000.";
  public var front = false;
  public var onhit = false;
  public var missed = false;
  public var good = false;
  var snd: Sound;
  override public function begin() {
    art.size(4, 5, 5).obj([C.orange], NOTE);
    pos.x = 500;
    pos.y = 80;
    addHitBox(Rect(0, 0, 20, 20));
    snd = new Sound(0).blip();
  }

  override public function update() {
    if (hit(Game.main.holder)) {
      if (front) {
        art.size(4, 5, 5).obj([C.red], NOTE);
      }

      onhit = true;
      if (Game.key.up_pressed && front) {
        good = true;
        snd.play();
        var dist = Math.abs(pos.x  - Game.main.holder.pos.x)/20.0;
        new Coin(dist);
      }
    } else if (front) {
      if (onhit) {
        onhit = false;
        missed = true;
        new Tomato();
      }
      if (Game.key.up_pressed) {
        missed = true;
        new Tomato();
      }
    }

    if (!good && !missed) {
      pos.x -= Game.main.bpm*Game.time;
    } else {
      sprite.alpha -= Game.time/0.5;
    }

    if (good) {
      pos.y -= 100*Game.time;
    }

    if (missed) {
      pos.y += 100*Game.time;
    }
    if (sprite.alpha == 0) {
      remove();
    }
  }
}

class Player extends Entity {
  override public function begin() {
    art.size(8, 5, 5).obj([C.darkgrey, C.red, C.orange, C.pink],
      "..1..
       .111.
       .3322
       .000.
       .0.0.
      ");
    pos.x = 240;
    pos.y = 140;
    addHitBox(Rect(0, 0, 40, 40));
  }

  override public function update() {
    if (Game.key.left) angle -= Math.PI*2*Game.time/3.0;
    if (Game.key.right) angle += Math.PI*2*Game.time/3.0;
    if (angle != 0) {
      angle -= angle*0.02;
    }
    angle = EMath.clamp(angle, -Math.PI/5, Math.PI/5);

    pos.x = 240 + 200*Math.sin(angle);
    pos.y = 340 - 200*Math.cos(angle);

  }
}

class Tomato extends Entity {
  override public function begin() {
    pos.x = Math.random()*480;
    pos.y = 500;

    var tx = 140 + 200*Math.random();

    vel.x = (tx-pos.x)/2.0;
    vel.y = (140-500)/2.0;

    art.size(4, 5, 5).color(C.red).circle(2.5, 2.5, 2.5);
    addHitBox(Circle(10, 10, 10));
  }

  override public function update() {
    if (hit(Game.main.player)) {
      new Particle().color(C.red).xy(pos.x, pos.y).count(Const(500))
        .size(Rand(10, 5)).speed(Rand(0, vel.length/2.0))
        .delay(Const(0)).duration(Rand(0.5, 0.5));
      remove();
      new Sound(16).explosion().play();
      Game.endGame();
    }
  }
}

class Coin extends Entity {
  var value: Int;
  override public function new(dist: Float) {
    super();
    value = Math.round(1 + (1.0 - dist)*9);
  }
  override public function begin() {
    pos.x = Math.random()*480;
    pos.y = 500;

    var tx = 140 + 200*Math.random();

    vel.x = (tx-pos.x)/1.0;
    vel.y = (140-500)/1.0;

    art.size(2, 5, 5).color(C.yellow).circle(2.5, 2.5, 2.5);
    addHitBox(Circle(5, 5, 5));
  }

  override public function update() {
    if (hit(Game.main.player)) {
      Game.main.score += value;
      new Text().text("$" + value).duration(1).xy(pos.x, pos.y).move(0, -20);
      new Sound(12).coin().play();
      remove();
    }
  }
}

class Hat extends Entity {
  var HAT = "....0000.00.";
  override public function begin() {
    art.size(8, 4, 3).obj([C.black], HAT);
    pos.x = pos.y = 240;
  }

  override public function update() {
    var s = 5.0*((Game.main.score - Game.main.level*50)/50.0);

    art.clear().obj([C.black], HAT);
    if (s >= 1.0) {
      art.color(C.yellow).hline(0, s-1, 0);
    }
    if (s >= 5.0) {
      Game.main.level ++;
      Game.main.bpm *= 1.1;
    }
  }
}

