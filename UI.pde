class UI {
  
  void display() {
    if (player == null) return;
    
    displayStats();
    displayScore();
    displayXPBar();
    
    // Le menu d'upgrade ne s'affiche pas pendant le choix de classe
    if (player.availablePoints > 0 && menuUpgradeVisible && !player.choixClasseEnAttente) {
      displayUpgradeMenu();
    }
  }
  
  void displayXPBar() {
    float barWidth = 450;
    float barHeight = 25;
    float barX = width/2 - barWidth/2;
    float barY = height - 40;
    
    stroke(120);
    strokeWeight(3);
    fill(40);
    rect(barX, barY, barWidth, barHeight, 12);
    
    noStroke();
    fill(255, 232, 105);
    float progress = player.xp / player.xpNeeded;
    rect(barX + 3, barY + 3, (barWidth - 6) * progress, barHeight - 6, 10);
    
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(16);
    text("Level " + player.level + "  —  " + player.tankClass, width/2, barY + barHeight/2);
  }
  
  void displayStats() {
    // Nom du joueur en haut à gauche
    fill(0, 176, 255);
    textAlign(LEFT, TOP);
    textSize(18);
    text(player.playerName, 12, 8);
    
    // Barre de vie sous le nom
    float barVieX = 12;
    float barVieY = 32;
    float barVieL = 180;
    float barVieH = 14;
    float ratioVie = player.health / player.maxHealth;
    
    noStroke();
    fill(60, 20, 20);
    rect(barVieX, barVieY, barVieL, barVieH, 4);
    fill(lerpColor(color(255, 60, 60), color(80, 255, 80), ratioVie));
    rect(barVieX, barVieY, barVieL * ratioVie, barVieH, 4);
    
    fill(255);
    textAlign(LEFT, CENTER);
    textSize(11);
    text(int(player.health) + " / " + int(player.maxHealth), barVieX + 4, barVieY + barVieH / 2);
    
    // Nombre d'ennemis
    fill(200, 80, 80);
    textAlign(LEFT, TOP);
    textSize(13);
    text("Ennemis : " + enemies.size(), 12, 52);
    
    displayCoins();
    displayActiveBoosts();
    
    // Rappel Tab si points dispo mais menu caché
    if (player.availablePoints > 0 && !menuUpgradeVisible && !player.choixClasseEnAttente) {
      fill(255, 220, 0, 200);
      textAlign(LEFT, CENTER);
      textSize(14);
      text("[TAB] améliorer (" + player.availablePoints + " pt" + (player.availablePoints > 1 ? "s" : "") + ")", 12, 138);
    }
  }
  
  void displayCoins() {
    float cx = 12;
    float cy = 72;
    float cw = 185;
    float ch = 30;
    
    fill(20, 25, 40, 200);
    noStroke();
    rect(cx, cy, cw, ch, 8);
    
    stroke(255, 215, 0, 180);
    strokeWeight(2);
    noFill();
    rect(cx, cy, cw, ch, 8);
    
    noStroke();
    fill(255, 215, 0);
    circle(cx + 18, cy + ch/2, 20);
    fill(220, 180, 0);
    textAlign(CENTER, CENTER);
    textSize(11);
    text("$", cx + 18, cy + ch/2);
    
    fill(255, 230, 80);
    textAlign(LEFT, CENTER);
    textSize(16);
    text(db.getCoins() + " pièces", cx + 32, cy + ch/2);
    
    fill(140);
    textSize(10);
    text("[ESPACE]", cx + cw - 58, cy + ch/2);
  }
  
  void displayActiveBoosts() {
    float bx = 12;
    float by = 110;
    float iconSize = 28;
    float spacing  = 6;
    int   col      = 0;
    
    if (player.boostSpeedActive)  { dessinerIconeBoost(bx + col*(iconSize+spacing), by, "SPD", color(100, 220, 255), player.boostSpeedTimer,  900);  col++; }
    if (player.boostDamageActive) { dessinerIconeBoost(bx + col*(iconSize+spacing), by, "DMG", color(255, 120, 80),  player.boostDamageTimer, 600);  col++; }
    if (player.boostRegenActive)  { dessinerIconeBoost(bx + col*(iconSize+spacing), by, "REG", color(80, 255, 120),  player.boostRegenTimer,  1200); col++; }
    if (player.shieldActive)      { dessinerIconeBoost(bx + col*(iconSize+spacing), by, "SHD", color(200, 160, 255), player.shieldTimer,      300);  col++; }
    if (player.boostXPActive)     { dessinerIconeBoost(bx + col*(iconSize+spacing), by, "XP",  color(255, 240, 80),  player.boostXPTimer,     1800); col++; }
    if (player.boostFireActive)   { dessinerIconeBoost(bx + col*(iconSize+spacing), by, "RLD", color(255, 180, 80),  player.boostFireTimer,   720);  col++; }
    if (player.magnetActive)      { dessinerIconeBoost(bx + col*(iconSize+spacing), by, "MAG", color(255, 200, 120), player.magnetTimer,      1200); col++; }
  }
  
  void dessinerIconeBoost(float bx, float by, String label, color c, int timer, int maxTimer) {
    float iconSize = 28;
    float progress = (float)timer / maxTimer;
    
    noStroke();
    fill(20, 25, 40, 200);
    circle(bx + iconSize/2, by + iconSize/2, iconSize + 4);
    
    stroke(c);
    strokeWeight(3);
    noFill();
    arc(bx + iconSize/2, by + iconSize/2, iconSize, iconSize, -HALF_PI, -HALF_PI + TWO_PI * progress);
    
    noStroke();
    fill(c);
    textAlign(CENTER, CENTER);
    textSize(8);
    text(label, bx + iconSize/2, by + iconSize/2);
  }
  
  void displayScore() {
    // Score uniquement en haut à droite (le niveau est déjà dans la barre XP)
    fill(20, 25, 40, 180);
    noStroke();
    rect(width - 185, 6, 175, 36, 8);
    
    fill(255);
    textAlign(RIGHT, CENTER);
    textSize(18);
    text("Score : " + game.score, width - 14, 24);
  }
  
  void displayUpgradeMenu() {
    fill(20, 25, 35, 220);
    noStroke();
    rect(0, height - 430, 380, 430);
    
    fill(255, 255, 0);
    textAlign(CENTER);
    textSize(22);
    text(">>> " + player.availablePoints + " POINT" + (player.availablePoints > 1 ? "S" : "") + " DISPONIBLE" + (player.availablePoints > 1 ? "S" : "") + " <<<", 190, height - 405);
    
    float startX = 15;
    float startY = height - 400;
    float buttonH = 45;
    float spacing = 5;
    
    dessinerBoutonUpgrade(startX, startY + (buttonH + spacing) * 0, "Health Regen",       "[1]", player.healthRegenLevel,        color(252, 177, 162));
    dessinerBoutonUpgrade(startX, startY + (buttonH + spacing) * 1, "Max Health",          "[2]", player.maxHealthLevel,           color(255, 150, 255));
    dessinerBoutonUpgrade(startX, startY + (buttonH + spacing) * 2, "Body Damage",         "[3]", player.bodyDamageLevel,          color(180, 150, 255));
    dessinerBoutonUpgrade(startX, startY + (buttonH + spacing) * 3, "Bullet Speed",        "[4]", player.bulletSpeedLevel,         color(150, 200, 255));
    dessinerBoutonUpgrade(startX, startY + (buttonH + spacing) * 4, "Bullet Penetration",  "[5]", player.bulletPenetrationLevel,   color(255, 255, 150));
    dessinerBoutonUpgrade(startX, startY + (buttonH + spacing) * 5, "Bullet Damage",       "[6]", player.bulletDamageLevel,        color(255, 150, 150));
    dessinerBoutonUpgrade(startX, startY + (buttonH + spacing) * 6, "Reload",              "[7]", player.reloadLevel,              color(150, 255, 150));
    dessinerBoutonUpgrade(startX, startY + (buttonH + spacing) * 7, "Movement Speed",      "[8]", player.movementSpeedLevel,       color(150, 255, 255));
  }
  
  void dessinerBoutonUpgrade(float x, float y, String nom, String touche, int niveau, color c) {
    float buttonW = 350;
    float buttonH = 45;
    
    stroke(100);
    strokeWeight(3);
    fill(50, 55, 70);
    rect(x, y, buttonW, buttonH, 8);
    
    fill(255);
    textAlign(LEFT, CENTER);
    textSize(17);
    text(nom, x + 12, y + buttonH/2);
    
    fill(200);
    textAlign(LEFT, CENTER);
    textSize(15);
    text(touche, x + 180, y + buttonH/2);
    
    float barX = x + 215;
    float barW = 85;
    float barH = 28;
    
    noStroke();
    fill(30);
    rect(barX, y + (buttonH - barH)/2, barW, barH, 4);
    
    if (niveau > 0) {
      fill(c);
      float progress = (float)niveau / 7.0;
      rect(barX, y + (buttonH - barH)/2, barW * progress, barH, 4);
    }
    
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(14);
    text(niveau + "/7", barX + barW/2, y + buttonH/2);
    
    float plusX    = x + 310;
    float plusSize = 35;
    
    if (niveau < 7) {
      fill(c);
      stroke(90);
      strokeWeight(3);
      rect(plusX, y + (buttonH - plusSize)/2, plusSize, plusSize, 5);
      fill(255);
      textAlign(CENTER, CENTER);
      textSize(24);
      text("+", plusX + plusSize/2, y + buttonH/2);
    } else {
      fill(70);
      stroke(50);
      strokeWeight(2);
      rect(plusX, y + (buttonH - plusSize)/2, plusSize, plusSize, 5);
      fill(120);
      textAlign(CENTER, CENTER);
      textSize(16);
      text("MAX", plusX + plusSize/2, y + buttonH/2);
    }
  }
}
