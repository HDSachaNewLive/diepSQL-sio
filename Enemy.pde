class Enemy extends Tank {
  // --- États ---
  // PATROL, CHASE, ATTACK, STRAFE, FLEE, REGROUP, AMBUSH, ENCERCLE
  String state = "PATROL";
  String etatPrecedent = "";
  PVector targetPos;
  
  // --- Plages de détection ---
  float distanceDetection = 650;
  float distanceAttaque   = 550;
  float distanceAggro     = 260;
  float seuilFuiteSante   = 28;
  float seuilRegroupSante = 52;
  
  // --- Tir ---
  int   cooldownTir    = 0;
  int   delaiTirBase   = 50;
  int   delaiTirActuel = 50;
  
  // --- Fuite ---
  int   timerFuite    = 0;
  int   maxTempsFuite = 300;
  float derniereVie   = 0;
  
  // --- Patrouille ---
  float timerPatrouille  = 0;
  float dureePatrouille  = 120;
  
  // --- Strafing ---
  int   directionStrafe   = 1;
  int   timerStrafe       = 0;
  int   dureeStrafe       = 0;
  float distanceOptimale  = 185;
  
  // --- Esquive de balles ---
  boolean enEsquive       = false;
  PVector directionEsquive = new PVector(0, 0);
  int     timerEsquive    = 0;
  
  // --- Encerclement ---
  float angleEncerclement = 0;
  float rayonEncerclement = 200;
  float vitesseEncerclement = 0.025;
  
  // --- Ambush (embuscade) ---
  PVector pointEmbuscade = null;
  boolean embuscadePrete = false;
  int     timerEmbuscade = 0;
  
  // --- Tir prédictif ---
  boolean utiliseTirPredictif = false;
  
  // --- Personalité (varie d'un ennemi à l'autre) ---
  float agressivite;      // 0..1 : influence les seuils et cadences
  float impulsivite;      // 0..1 : chance de changer de comportement subitement
  float prudence;         // 0..1 : distance optimale, seuil de fuite
  
  // --- Mémoire du joueur ---
  PVector dernierePositionJoueur;
  PVector velociteEstimeeJoueur;
  PVector posJoueurAvant;
  
  // --- Bords de la map ---
  float margeMap = 100;
  
  // --- Répulsion entre ennemis ---
  float forceRepulsion = 2.5;
  
  Enemy(float x, float y) {
    super(x, y, false);
    
    this.maxHealth  = 80;
    this.health     = 80;
    this.derniereVie = 80;
    this.damage     = 8;
    this.bodyDamage = 15;
    this.maxSpeed   = 3.5;
    this.size       = 25;
    this.bulletSpeed = 7;
    
    // Personnalité aléatoire
    agressivite  = random(0.3, 1.0);
    impulsivite  = random(0.1, 0.8);
    prudence     = random(0.2, 0.9);
    
    // Ajustement des stats selon la personnalité
    distanceOptimale  = lerp(120, 260, prudence);
    seuilFuiteSante   = lerp(15, 45, prudence);
    delaiTirBase      = (int)lerp(30, 70, 1 - agressivite);
    delaiTirActuel    = delaiTirBase;
    
    utiliseTirPredictif = (agressivite > 0.6);
    
    targetPos = new PVector(random(mapWidth), random(mapHeight));
    dernierePositionJoueur = new PVector(player.x, player.y);
    velociteEstimeeJoueur  = new PVector(0, 0);
    posJoueurAvant         = new PVector(player.x, player.y);
    
    // Angle de strafe aléatoire pour chaque ennemi
    directionStrafe = (random(1) > 0.5) ? 1 : -1;
    dureeStrafe     = (int)random(60, 180);
    
    // Angle d'encerclement décalé entre ennemis
    angleEncerclement = random(TWO_PI);
  }
  
  void update() {
    super.update();
    mettreAJourMemoireJoueur();
    detecterEtEsquiverBalles();
    updateAI();
    separerDesAutresEnnemis();
    
    if (cooldownTir > 0) cooldownTir--;
    
    if (state.equals("FLEE")) {
      timerFuite++;
    } else {
      timerFuite = 0;
    }
    
    if (timerEsquive > 0) timerEsquive--;
    else enEsquive = false;
    
    derniereVie = health;
  }
  
  // Mémorise la vélocité estimée du joueur pour le tir prédictif
  void mettreAJourMemoireJoueur() {
    velociteEstimeeJoueur.set(
      player.x - posJoueurAvant.x,
      player.y - posJoueurAvant.y
    );
    posJoueurAvant.set(player.x, player.y);
  }
  
  // Détecte les balles proches et déclenche une esquive
  void detecterEtEsquiverBalles() {
    float rayonDetectionBalle = 120;
    
    for (int i = 0; i < bullets.size(); i++) {
      Bullet b = bullets.get(i);
      if (b.fromPlayer) {
        float d = dist(x, y, b.x, b.y);
        if (d < rayonDetectionBalle) {
          // Calcule la direction perpendiculaire à la trajectoire de la balle
          PVector trajBalle = b.velocity.copy();
          trajBalle.normalize();
          PVector perp = new PVector(-trajBalle.y, trajBalle.x);
          
          // Choisit le côté qui s'éloigne le plus du joueur
          PVector versJoueur = new PVector(player.x - x, player.y - y);
          if (perp.dot(versJoueur) > 0) perp.mult(-1);
          
          directionEsquive.set(perp);
          enEsquive    = true;
          timerEsquive = 25;
          break;
        }
      }
    }
  }
  
  void separerDesAutresEnnemis() {
    for (int i = 0; i < enemies.size(); i++) {
      Enemy autre = enemies.get(i);
      if (autre == this) continue;
      float d = dist(x, y, autre.x, autre.y);
      float distMin = size + autre.size;
      if (d < distMin && d > 0) {
        PVector repulsion = PVector.sub(new PVector(x, y), new PVector(autre.x, autre.y));
        repulsion.normalize();
        float intensite = (distMin - d) / distMin;
        repulsion.mult(forceRepulsion * intensite);
        velocity.add(repulsion);
      }
    }
  }
  
  void updateAI() {
    float distJoueur    = dist(x, y, player.x, player.y);
    float pctVie        = (health / maxHealth) * 100;
    boolean dansCoin    = estDansCoin();
    
    etatPrecedent = state;
    
    // --- Changement impulsif aléatoire (imprévisibilité) ---
    if (random(1) < impulsivite * 0.005 && state.equals("ATTACK")) {
      float choix = random(1);
      if (choix < 0.4)       state = "STRAFE";
      else if (choix < 0.7)  state = "ENCERCLE";
      else                   state = "AMBUSH";
    }
    
    // --- Logique de décision principale ---
    if (pctVie < seuilFuiteSante && timerFuite < maxTempsFuite && !dansCoin) {
      state = "FLEE";
    } else if (dansCoin || timerFuite >= maxTempsFuite || (pctVie < seuilRegroupSante && pctVie >= seuilFuiteSante)) {
      state = "REGROUP";
    } else if (distJoueur < distanceAggro) {
      // Près du joueur : choix entre ATTACK, STRAFE ou ENCERCLE
      if (!state.equals("STRAFE") && !state.equals("ENCERCLE") && !state.equals("AMBUSH")) {
        float choix = random(1);
        if (agressivite > 0.7 && choix < 0.4)       state = "ATTACK";
        else if (choix < 0.6)                         state = "STRAFE";
        else                                           state = "ENCERCLE";
      }
    } else if (distJoueur < distanceAttaque) {
      // Distance moyenne : CHASE ou AMBUSH pour les ennemis prudents
      if (prudence > 0.6 && pointEmbuscade == null && random(1) < 0.003) {
        preparerEmbuscade();
        state = "AMBUSH";
      } else if (!state.equals("AMBUSH")) {
        state = "CHASE";
      }
    } else {
      if (!state.equals("AMBUSH")) state = "PATROL";
    }
    
    // --- Exécution du comportement ---
    if (enEsquive && (state.equals("ATTACK") || state.equals("STRAFE") || state.equals("ENCERCLE"))) {
      esquiver();
    }
    
    switch(state) {
      case "PATROL":   patrouiller();  break;
      case "CHASE":    pourchasser();  break;
      case "ATTACK":   attaquer();     break;
      case "STRAFE":   strafer();      break;
      case "FLEE":     fuir();         break;
      case "REGROUP":  regroup();      break;
      case "ENCERCLE": encercler();    break;
      case "AMBUSH":   embuscade();    break;
    }
  }
  
  boolean estDansCoin() {
    boolean bordGauche  = x < margeMap;
    boolean bordDroit   = x > mapWidth  - margeMap;
    boolean bordHaut    = y < margeMap;
    boolean bordBas     = y > mapHeight - margeMap;
    return (bordGauche || bordDroit) && (bordHaut || bordBas);
  }
  
  void patrouiller() {
    PVector direction = PVector.sub(targetPos, new PVector(x, y));
    float d = direction.mag();
    if (d < 20) {
      timerPatrouille++;
      if (timerPatrouille > dureePatrouille) {
        targetPos = new PVector(random(100, mapWidth - 100), random(100, mapHeight - 100));
        timerPatrouille = 0;
        dureePatrouille = random(80, 180);
      }
    } else {
      direction.normalize();
      direction.mult(speed * 0.5);
      acceleration.add(direction);
    }
  }
  
  void pourchasser() {
    PVector direction = PVector.sub(new PVector(player.x, player.y), new PVector(x, y));
    direction.normalize();
    direction.mult(speed * (0.55 + agressivite * 0.2));
    acceleration.add(direction);
    
    // Tire en approchant si agressif
    if (agressivite > 0.65 && cooldownTir <= 0) {
      tirerSurJoueur();
      cooldownTir = delaiTirActuel + 20;
    }
  }
  
  void attaquer() {
    float distJoueur  = dist(x, y, player.x, player.y);
    PVector direction = PVector.sub(new PVector(player.x, player.y), new PVector(x, y));
    direction.normalize();
    
    if (distJoueur < distanceOptimale - 40) {
      // Trop près : recule
      direction.mult(-speed * 0.55);
      acceleration.add(direction);
    } else if (distJoueur > distanceOptimale + 40) {
      // Trop loin : avance
      direction.mult(speed * 0.7);
      acceleration.add(direction);
    }
    
    if (cooldownTir <= 0) {
      tirerSurJoueur();
      cooldownTir = delaiTirActuel;
    }
  }
  
  // Strafe latéral autour du joueur avec changement de direction aléatoire
  void strafer() {
    float distJoueur  = dist(x, y, player.x, player.y);
    PVector direction = PVector.sub(new PVector(player.x, player.y), new PVector(x, y));
    direction.normalize();
    
    PVector lateral = new PVector(-direction.y, direction.x);
    lateral.mult(speed * 0.65 * directionStrafe);
    acceleration.add(lateral);
    
    // Maintient une distance correcte
    if (distJoueur < distanceOptimale - 50) {
      PVector recul = direction.copy();
      recul.mult(-speed * 0.4);
      acceleration.add(recul);
    } else if (distJoueur > distanceOptimale + 50) {
      PVector approche = direction.copy();
      approche.mult(speed * 0.4);
      acceleration.add(approche);
    }
    
    timerStrafe++;
    if (timerStrafe >= dureeStrafe) {
      directionStrafe *= -1;
      timerStrafe = 0;
      dureeStrafe = (int)random(50, 160);
      // Chance de revenir en ATTACK après un strafe
      if (random(1) < 0.35) state = "ATTACK";
    }
    
    if (cooldownTir <= 0) {
      tirerSurJoueur();
      cooldownTir = delaiTirActuel + (int)random(-10, 10);
    }
  }
  
  // Encercle le joueur en tournant autour à distance
  void encercler() {
    angleEncerclement += vitesseEncerclement * directionStrafe * (1 + agressivite * 0.3);
    
    float cibleX = player.x + cos(angleEncerclement) * rayonEncerclement;
    float cibleY = player.y + sin(angleEncerclement) * rayonEncerclement;
    
    PVector versCible = new PVector(cibleX - x, cibleY - y);
    float d = versCible.mag();
    if (d > 5) {
      versCible.normalize();
      versCible.mult(speed * 0.8);
      acceleration.add(versCible);
    }
    
    // Tire en encerclant
    if (cooldownTir <= 0) {
      tirerSurJoueur();
      cooldownTir = delaiTirActuel + 15;
    }
    
    // Sort de l'encerclement après un moment
    timerStrafe++;
    if (timerStrafe > 300 + (int)(prudence * 100)) {
      timerStrafe = 0;
      state = (random(1) < 0.5) ? "ATTACK" : "STRAFE";
    }
  }
  
  // Prépare un point d'embuscade en face du déplacement du joueur
  void preparerEmbuscade() {
    float tempsAnticipation = 80;
    float px = player.x + velociteEstimeeJoueur.x * tempsAnticipation;
    float py = player.y + velociteEstimeeJoueur.y * tempsAnticipation;
    px = constrain(px, 150, mapWidth  - 150);
    py = constrain(py, 150, mapHeight - 150);
    pointEmbuscade  = new PVector(px, py);
    embuscadePrete  = false;
    timerEmbuscade  = 0;
  }
  
  void embuscade() {
    if (pointEmbuscade == null) {
      state = "PATROL";
      return;
    }
    
    float dPoint = dist(x, y, pointEmbuscade.x, pointEmbuscade.y);
    
    if (!embuscadePrete) {
      // Se déplace vers le point d'embuscade rapidement
      PVector direction = PVector.sub(pointEmbuscade, new PVector(x, y));
      direction.normalize();
      direction.mult(speed * 0.9);
      acceleration.add(direction);
      
      if (dPoint < 30) embuscadePrete = true;
    } else {
      // Attend que le joueur se rapproche puis attaque
      timerEmbuscade++;
      float distJoueur = dist(x, y, player.x, player.y);
      
      if (distJoueur < distanceAttaque || timerEmbuscade > 300) {
        // Déclenche l'attaque surprise
        if (cooldownTir <= 0) {
          tirerSurJoueur();
          cooldownTir = (int)(delaiTirActuel * 0.5); // Cadence doublée à la surprise
        }
        if (distJoueur < distanceAggro) {
          pointEmbuscade = null;
          embuscadePrete = false;
          state = "ATTACK";
        }
      }
    }
    
    // Abandonne si le joueur est trop loin trop longtemps
    if (timerEmbuscade > 500) {
      pointEmbuscade = null;
      embuscadePrete = false;
      state = "PATROL";
    }
  }
  
  void esquiver() {
    PVector esc = directionEsquive.copy();
    esc.mult(speed * 1.1);
    acceleration.add(esc);
  }
  
  void fuir() {
    PVector dirFuite = PVector.sub(new PVector(x, y), new PVector(player.x, player.y));
    dirFuite.normalize();
    
    // Évite les bords
    if (x < margeMap)             dirFuite.x =  abs(dirFuite.x);
    else if (x > mapWidth  - margeMap) dirFuite.x = -abs(dirFuite.x);
    if (y < margeMap)             dirFuite.y =  abs(dirFuite.y);
    else if (y > mapHeight - margeMap) dirFuite.y = -abs(dirFuite.y);
    
    dirFuite.mult(speed * 1.25);
    acceleration.add(dirFuite);
    
    // Tire rarement en fuyant, de manière imprévisible
    if (cooldownTir <= 0 && random(1) > (0.85 - agressivite * 0.2)) {
      tirerSurJoueur();
      cooldownTir = delaiTirActuel + (int)random(20, 60);
    }
  }
  
  void regroup() {
    PVector centreCarte = new PVector(mapWidth / 2, mapHeight / 2);
    PVector direction = PVector.sub(centreCarte, new PVector(x, y));
    float d = direction.mag();
    
    if (d < 100) {
      state = "PATROL";
      targetPos = new PVector(random(100, mapWidth - 100), random(100, mapHeight - 100));
      return;
    }
    
    direction.normalize();
    direction.mult(speed * 0.8);
    acceleration.add(direction);
  }
  
  // Tir prédictif : anticipe la position future du joueur
  void tirerSurJoueur() {
    float angle;
    
    if (utiliseTirPredictif) {
      // Estime où sera le joueur quand la balle arrivera
      float tempsVol = dist(x, y, player.x, player.y) / bulletSpeed;
      float cibleX   = player.x + velociteEstimeeJoueur.x * tempsVol * 0.85;
      float cibleY   = player.y + velociteEstimeeJoueur.y * tempsVol * 0.85;
      angle = atan2(cibleY - y, cibleX - x);
    } else {
      angle = atan2(player.y - y, player.x - x);
    }
    
    // Dispersion selon l'état : plus précis en embuscade, moins en fuite
    float dispersion = 0.12;
    if (state.equals("FLEE"))    dispersion = 0.30;
    if (state.equals("AMBUSH") && embuscadePrete) dispersion = 0.04;
    if (state.equals("STRAFE"))  dispersion = 0.18;
    angle += random(-dispersion, dispersion);
    
    float spawnX = x + cos(angle) * (size + barrelLength);
    float spawnY = y + sin(angle) * (size + barrelLength);
    
    Bullet b = new Bullet(spawnX, spawnY, angle, damage, false, bulletSpeed);
    bullets.add(b);
    
    PVector recul = new PVector(cos(angle), sin(angle));
    recul.mult(-1.5);
    velocity.add(recul);
  }
  
  void display() {
    pushMatrix();
    translate(x, y);
    
    float angle = atan2(player.y - y, player.x - x);
    
    // Canon
    pushMatrix();
    rotate(angle);
    fill(120, 50, 50);
    stroke(100, 40, 40);
    strokeWeight(2);
    rect(0, -barrelWidth/2, barrelLength, barrelWidth);
    popMatrix();
    
    // Corps rouge
    fill(255, 100, 100);
    stroke(200, 80, 80);
    strokeWeight(3);
    circle(0, 0, size * 2);
    
    // Barre de vie
    if (health < maxHealth) {
      float barWidth  = size * 2;
      float barHeight = 5;
      fill(255, 0, 0);
      noStroke();
      rect(-barWidth/2, -size - 15, barWidth, barHeight);
      fill(0, 255, 0);
      rect(-barWidth/2, -size - 15, barWidth * (health / maxHealth), barHeight);
    }
    
    // Indicateur d'état (décommenter pour debug)
    /*
    fill(255);
    textAlign(CENTER);
    textSize(10);
    text(state, 0, size + 25);
    */
    
    popMatrix();
  }
  
  void takeDamage(float amount) {
    health -= amount;
    createParticles(x, y, color(255, 100, 100));
    
    // Réaction au dégât : devient plus agressif ou fuit selon personnalité
    if (health > 0 && derniereVie - health > 15) {
      if (agressivite > 0.6 && state.equals("PATROL")) {
        state = "ATTACK";
      }
    }
    
    if (health <= 0) {
      health = 0;
      die();
    }
  }
  
  void die() {
    player.gainXP(50);
    game.addScore(100);
    db.addCoins(10);
    
    for (int i = 0; i < 20; i++) {
      particles.add(new Particle(x, y, color(255, 100, 100)));
    }
    
    enemies.remove(this);
  }
}
