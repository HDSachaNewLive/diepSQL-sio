class Tank {
  float x, y;
  float size = 30;
  float speed = 3;
  float maxSpeed = 5;
  PVector velocity;
  PVector acceleration;
  
  // Stats
  int level = 1;
  float xp = 0;
  float xpNeeded = 50;
  float maxHealth = 100;
  float health = 100;
  float damage = 10;
  
  // Stats ameliorables 
  float healthRegen = 0;
  float bodyDamage = 10;
  public float bulletSpeed = 20;
  public float bulletPenetration = 1;
  public float fireRate = 40;

  // Points de stats (max 7 par stat comme Diep.io)
  int healthRegenLevel = 0;
  int maxHealthLevel = 0;
  int bodyDamageLevel = 0;
  int bulletSpeedLevel = 0;
  int bulletPenetrationLevel = 0;
  int bulletDamageLevel = 0;
  int reloadLevel = 0;
  int movementSpeedLevel = 0;

  int maxStatLevel = 7;
  int availablePoints = 0;
  
  int chronometre = 0;
  
  // Controles
  boolean moveUp, moveDown, moveLeft, moveRight;
  boolean isPlayer;
  
  // Clignotement rouge lors d'un impact
  int dureeImpact = 0;
  int maxDureeImpact = 30;
  
  // Angle pour la démo (si isPlayer = false, ignorer la souris)
  float demoAngle = 0;
  
  // ---- BOOSTS (achetés en boutique) ----
  boolean boostSpeedActive  = false; int boostSpeedTimer  = 0;
  boolean boostDamageActive = false; int boostDamageTimer = 0;
  boolean boostRegenActive  = false; int boostRegenTimer  = 0;
  boolean shieldActive      = false; int shieldTimer      = 0;
  boolean boostXPActive     = false; int boostXPTimer     = 0;
  boolean boostFireActive   = false; int boostFireTimer   = 0;
  boolean magnetActive      = false; int magnetTimer      = 0;
  
  // ---- CLASSE DU TANK ----
  // Tier 1 : "Basic"
  // Tier 2 (niveau 15) : "Twin", "Sniper", "MachineGun"
  // Tier 3 (niveau 30) : selon la classe tier 2
  String tankClass = "Basic";
  boolean choixClasseEnAttente = false;   // true quand le joueur doit choisir
  String[] optionsClasse = {};             // options disponibles pour ce tier
  
  String playerName = "";
  int barrelLength = 54;
  int barrelWidth = 27;
  
  // Twin : deuxième canon décalé
  int barreauOffset = 14; // décalage vertical pour le twin
  
  Tank(float x, float y, boolean isPlayer) {
    this.x = x;
    this.y = y;
    this.isPlayer = isPlayer;
    velocity = new PVector(0, 0);
    acceleration = new PVector(0, 0);
  }
  
  void update() {
    velocity.add(acceleration);
    velocity.limit(maxSpeed);
    x += velocity.x;
    y += velocity.y;
    velocity.mult(0.9);
    acceleration.mult(0);
    
    x = constrain(x, size, mapWidth - size);
    y = constrain(y, size, mapHeight - size);
    
    if (health < maxHealth && healthRegen > 0) {
      health += healthRegen / 60.0;
      health = min(health, maxHealth);
    }
    
    if (isPlayer) {
      updateBoosts();
    }
    
    if (xp >= xpNeeded) {
      levelUp();
    }
    
    if (chronometre > 0) chronometre--;
    if (dureeImpact > 0) dureeImpact--;
  }
  
  void handleMovement() {
    if (!isPlayer) return;
    if (moveUp)    acceleration.add(0, -speed);
    if (moveDown)  acceleration.add(0, speed);
    if (moveLeft)  acceleration.add(-speed, 0);
    if (moveRight) acceleration.add(speed, 0);
  }
  
  void shoot() {
    if (chronometre > 0) return;
    if (choixClasseEnAttente) return; // Bloque le tir pendant le choix de classe
    
    float mouseWorldX = mouseX + cameraX;
    float mouseWorldY = mouseY + cameraY;
    float angle = atan2(mouseWorldY - y, mouseWorldX - x);
    float degatsReels = boostDamageActive ? damage * 2 : damage;
    
    switch(tankClass) {
      case "Twin":
        // Deux canons côte à côte
        tirerCanon(angle, degatsReels * 0.75, barreauOffset);
        tirerCanon(angle, degatsReels * 0.75, -barreauOffset);
        break;
      case "MachineGun":
        // Un seul canon, dispersion aléatoire
        float dispersion = 0.12;
        tirerCanon(angle + random(-dispersion, dispersion), degatsReels * 0.8, 0);
        break;
      case "Sniper":
        // Une balle plus grosse, plus rapide, plus de pénétration
        tirerCanonSniper(angle, degatsReels * 1.8);
        break;
      case "TripleShot":
        // Trois canons en éventail
        tirerCanon(angle,              degatsReels * 0.7, 0);
        tirerCanon(angle + 0.22,       degatsReels * 0.6, 0);
        tirerCanon(angle - 0.22,       degatsReels * 0.6, 0);
        break;
      case "Destroyer":
        // Une balle énorme, lente, très puissante
        tirerCanonDestroyer(angle, degatsReels * 3.0);
        break;
      case "Gatling":
        // Cadence très élevée, balles petites
        tirerCanon(angle + random(-0.08, 0.08), degatsReels * 0.5, 0);
        break;
      default:
        // Basic
        tirerCanon(angle, degatsReels, 0);
        break;
    }
    
    PVector recul = new PVector(cos(angle), sin(angle));
    recul.mult(-2);
    velocity.add(recul);
    
    chronometre = (int)fireRate;
  }
  
  void tirerCanon(float angle, float degats, float offsetPerp) {
    // offsetPerp = décalage perpendiculaire à la direction de tir
    float perpX = cos(angle + HALF_PI) * offsetPerp;
    float perpY = sin(angle + HALF_PI) * offsetPerp;
    float spawnX = x + cos(angle) * (size + barrelLength) + perpX;
    float spawnY = y + sin(angle) * (size + barrelLength) + perpY;
    bullets.add(new Bullet(spawnX, spawnY, angle, degats, isPlayer, bulletSpeed, bulletPenetration));
  }
  
  void tirerCanonSniper(float angle, float degats) {
    float spawnX = x + cos(angle) * (size + barrelLength);
    float spawnY = y + sin(angle) * (size + barrelLength);
    Bullet b = new Bullet(spawnX, spawnY, angle, degats, isPlayer, bulletSpeed * 1.6, bulletPenetration + 1);
    b.taille = 9; // Balle plus petite mais plus puissante
    b.freinageBullet = 0.992; // Peu de freinage
    bullets.add(b);
  }
  
  void tirerCanonDestroyer(float angle, float degats) {
    float spawnX = x + cos(angle) * (size + barrelLength);
    float spawnY = y + sin(angle) * (size + barrelLength);
    Bullet b = new Bullet(spawnX, spawnY, angle, degats, isPlayer, bulletSpeed * 0.65, bulletPenetration + 2);
    b.taille = 20; // Balle énorme
    b.freinageBullet = 0.96;
    bullets.add(b);
  }
  
  void display() {
    pushMatrix();
    translate(x, y);
    
    float angle;
    if (isPlayer) {
      float mouseWorldX = mouseX + cameraX;
      float mouseWorldY = mouseY + cameraY;
      angle = atan2(mouseWorldY - y, mouseWorldX - x);
    } else {
      angle = demoAngle;
    }
    
    dessinerCanons(angle);
    
    // Corps du tank
    if (isPlayer && dureeImpact > 0) {
      float ratioTemps = (float)dureeImpact / maxDureeImpact;
      float intensite;
      if (ratioTemps > 0.5) {
        intensite = map(ratioTemps, 1.0, 0.5, 0.0, 1.0);
      } else {
        intensite = map(ratioTemps, 0.5, 0.0, 1.0, 0.0);
      }
      float r  = lerp(0,   255, intensite);
      float g  = lerp(176, 80,  intensite);
      float bv = lerp(255, 80,  intensite);
      float rs = lerp(0,   200, intensite);
      float gs = lerp(141, 50,  intensite);
      float bs = lerp(204, 50,  intensite);
      fill(r, g, bv);
      stroke(rs, gs, bs);
    } else {
      fill(0, 176, 255);
      stroke(0, 141, 204);
    }
    strokeWeight(3);
    circle(0, 0, size * 2);
    
    // Indicateur de classe (petit label sous le tank)
    if (isPlayer && !tankClass.equals("Basic")) {
      fill(255, 230, 80);
      noStroke();
      textAlign(CENTER, CENTER);
      textSize(11);
      text(tankClass, 0, size + 12);
    }
    
    // Barre de vie
    if (health < maxHealth) {
      float barWidth = size * 2;
      float barHeight = 5;
      fill(255, 0, 0);
      noStroke();
      rect(-barWidth/2, -size - 15, barWidth, barHeight);
      fill(0, 255, 0);
      rect(-barWidth/2, -size - 15, barWidth * (health/maxHealth), barHeight);
    }
    
    popMatrix();
  }
  
  void dessinerCanons(float angle) {
    fill(100, 100, 100);
    stroke(80, 80, 80);
    strokeWeight(2);
    
    switch(tankClass) {
      case "Twin":
        // Canon haut
        pushMatrix();
        rotate(angle);
        rect(0, -barreauOffset - barrelWidth/2, barrelLength, barrelWidth - 6);
        popMatrix();
        // Canon bas
        pushMatrix();
        rotate(angle);
        rect(0, barreauOffset - barrelWidth/2 + 6, barrelLength, barrelWidth - 6);
        popMatrix();
        break;
        
      case "Sniper":
        // Canon long et fin
        pushMatrix();
        rotate(angle);
        rect(0, -barrelWidth/3, barrelLength + 24, barrelWidth * 2/3);
        popMatrix();
        break;
        
      case "MachineGun":
        // Canon légèrement évasé
        pushMatrix();
        rotate(angle);
        rect(0, -barrelWidth/2 - 3, barrelLength - 8, barrelWidth + 6);
        popMatrix();
        break;
        
      case "TripleShot":
        pushMatrix();
        rotate(angle);
        rect(0, -barrelWidth/2, barrelLength, barrelWidth - 8);
        popMatrix();
        pushMatrix();
        rotate(angle + 0.22);
        rect(0, -barrelWidth/2 + 4, barrelLength - 8, barrelWidth - 10);
        popMatrix();
        pushMatrix();
        rotate(angle - 0.22);
        rect(0, -barrelWidth/2 + 4, barrelLength - 8, barrelWidth - 10);
        popMatrix();
        break;
        
      case "Destroyer":
        // Canon court et très large
        pushMatrix();
        rotate(angle);
        rect(0, -barrelWidth/2 - 8, barrelLength - 12, barrelWidth + 16);
        popMatrix();
        break;
        
      case "Gatling":
        // Trois petits canons superposés
        pushMatrix();
        rotate(angle);
        rect(0, -10, barrelLength + 4, 8);
        rect(0, -1,  barrelLength + 8, 8);
        rect(0, 8,   barrelLength + 4, 8);
        popMatrix();
        break;
        
      default:
        // Basic
        pushMatrix();
        rotate(angle);
        rect(0, -barrelWidth/2, barrelLength, barrelWidth);
        popMatrix();
        break;
    }
  }
  
  void gainXP(float amount) {
    if (boostXPActive) amount *= 1.5;
    xp += amount;
  }
  
  void updateBoosts() {
    float baseMaxSpeed = 5 + movementSpeedLevel * 0.3;
    float baseFireRate = 40 - reloadLevel * 4;
    
    // Bonus de cadence selon la classe
    switch(tankClass) {
      case "MachineGun": baseFireRate *= 0.65; break;
      case "Gatling":    baseFireRate *= 0.40; break;
      case "Twin":       baseFireRate *= 0.80; break;
      case "Destroyer":  baseFireRate *= 1.60; break;
      case "Sniper":     baseFireRate *= 1.30; break;
    }
    baseFireRate = max(baseFireRate, 3);
    
    if (boostSpeedActive) {
      boostSpeedTimer--;
      maxSpeed = baseMaxSpeed * 1.5;
      if (boostSpeedTimer <= 0) { boostSpeedActive = false; maxSpeed = baseMaxSpeed; }
    }
    if (boostDamageActive) {
      boostDamageTimer--;
      if (boostDamageTimer <= 0) boostDamageActive = false;
    }
    if (boostRegenActive) {
      boostRegenTimer--;
      health += (healthRegen + 5) / 60.0;
      health = min(health, maxHealth);
      if (boostRegenTimer <= 0) boostRegenActive = false;
    }
    if (shieldActive) {
      shieldTimer--;
      if (shieldTimer <= 0) shieldActive = false;
    }
    if (boostXPActive) {
      boostXPTimer--;
      if (boostXPTimer <= 0) boostXPActive = false;
    }
    if (boostFireActive) {
      boostFireTimer--;
      fireRate = max(baseFireRate / 2.0, 3.0);
      if (boostFireTimer <= 0) { boostFireActive = false; fireRate = baseFireRate; }
    }
    if (magnetActive) {
      magnetTimer--;
      if (magnetTimer <= 0) magnetActive = false;
    }
    
    // Mise à jour permanente de fireRate selon la classe (hors boost)
    if (!boostFireActive) {
      fireRate = baseFireRate;
    }
  }
  
  void levelUp() {
    level++;
    xp = 0;
    xpNeeded *= 1.1;
    availablePoints++;
    println("LEVEL UP! Level " + level + " - Points: " + availablePoints);
    
    // Déclenchement du choix de classe aux paliers 15 et 30
    if (isPlayer) {
      if (level == 15) {
        optionsClasse = new String[]{"Twin", "Sniper", "MachineGun"};
        choixClasseEnAttente = true;
      } else if (level == 30) {
        // Options selon la classe tier 2
        switch(tankClass) {
          case "Twin":       optionsClasse = new String[]{"TripleShot", "Gatling"}; break;
          case "Sniper":     optionsClasse = new String[]{"Destroyer",  "Gatling"}; break;
          case "MachineGun": optionsClasse = new String[]{"Gatling",    "TripleShot"}; break;
          default:           optionsClasse = new String[]{"TripleShot", "Destroyer"}; break;
        }
        choixClasseEnAttente = true;
      }
    }
  }
  
  // Appelé depuis diep_game quand le joueur clique sur une option de classe
  void choisirClasse(String nouvelleClasse) {
    tankClass = nouvelleClasse;
    choixClasseEnAttente = false;
    appliquerBonusClasse();
    println("Classe choisie : " + tankClass);
  }
  
  void appliquerBonusClasse() {
    switch(tankClass) {
      case "Twin":
        damage        *= 0.75;
        bulletPenetration += 0.5;
        break;
      case "Sniper":
        bulletSpeed   *= 1.4;
        damage        *= 1.3;
        fireRate      = max(fireRate * 1.3, 5);
        bulletPenetration += 1;
        break;
      case "MachineGun":
        damage        *= 0.8;
        fireRate       = max(fireRate * 0.65, 5);
        break;
      case "TripleShot":
        damage        *= 0.7;
        bulletPenetration += 0.5;
        break;
      case "Destroyer":
        damage        *= 2.0;
        bulletSpeed   *= 0.65;
        size           = 34;
        break;
      case "Gatling":
        damage        *= 0.55;
        fireRate       = max(fireRate * 0.40, 3);
        break;
    }
  }
  
  void upgradeStat(String stat) {
    if (availablePoints <= 0) return;
    switch(stat) {
      case "healthRegen":
        if (healthRegenLevel < maxStatLevel) { healthRegenLevel++; healthRegen += 1; availablePoints--; }
        break;
      case "maxHealth":
        if (maxHealthLevel < maxStatLevel) { maxHealthLevel++; maxHealth += 20; health += 20; availablePoints--; }
        break;
      case "bodyDamage":
        if (bodyDamageLevel < maxStatLevel) { bodyDamageLevel++; bodyDamage += 5; availablePoints--; }
        break;
      case "bulletSpeed":
        if (bulletSpeedLevel < maxStatLevel) { bulletSpeedLevel++; bulletSpeed += 0.8; availablePoints--; }
        break;
      case "bulletPenetration":
        if (bulletPenetrationLevel < maxStatLevel) { bulletPenetrationLevel++; bulletPenetration += 0.5; availablePoints--; }
        break;
      case "bulletDamage":
        if (bulletDamageLevel < maxStatLevel) { bulletDamageLevel++; damage += 5; availablePoints--; }
        break;
      case "reload":
        if (reloadLevel < maxStatLevel) { reloadLevel++; fireRate -= 4; availablePoints--; }
        break;
      case "movementSpeed":
        if (movementSpeedLevel < maxStatLevel) { movementSpeedLevel++; maxSpeed += 0.3; availablePoints--; }
        break;
    }
  }
  
  void takeDamage(float amount) {
    if (shieldActive) return;
    health -= amount;
    if (health <= 0) {
      health = 0;
      die();
    }
  }
  
  void die() {
    println("Game Over! Score: " + game.score);
    db.updateHighScore(game.score);
    game.gameOver();
  }
  
  void handleKeyPress() {
    if (key == 'z' || key == 'Z' || keyCode == UP)    moveUp    = true;
    if (key == 's' || key == 'S' || keyCode == DOWN)  moveDown  = true;
    if (key == 'q' || key == 'Q' || keyCode == LEFT)  moveLeft  = true;
    if (key == 'd' || key == 'D' || keyCode == RIGHT) moveRight = true;
  }
  
  void handleKeyRelease() {
    if (key == 'z' || key == 'Z' || keyCode == UP)    moveUp    = false;
    if (key == 's' || key == 'S' || keyCode == DOWN)  moveDown  = false;
    if (key == 'q' || key == 'Q' || keyCode == LEFT)  moveLeft  = false;
    if (key == 'd' || key == 'D' || keyCode == RIGHT) moveRight = false;
  }
}
