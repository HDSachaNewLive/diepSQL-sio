import processing.javafx.*;

import processing.sound.*;

// Variables globales
Tank player;
GameManager game;
ArrayList<Bullet> bullets;
ArrayList<Shape> shapes;
ArrayList<Enemy> enemies;
ArrayList<Particle> particles;
Spawner spawner;
UI ui;
Database db;
Shop shop;

SoundFile musiqueMenu;

// Camera et map 
float cameraX = 0;
float cameraY = 0;
float mapWidth = 3000;
float mapHeight = 3000;
float gridSize = 50;

// Joueur de demonstration pour le menu
Tank demoPlayer;
ArrayList<Bullet> demoBullets;
ArrayList<Shape> formesDemo;
ArrayList<Particle> demoParticles;

// Variable pour le fondu du Game Over
float gameOverFadeAlpha = 0;
int gameOverFadeStartFrame = 0;

// Visibilité du menu d'amélioration des stats
boolean menuUpgradeVisible = true;

// Saisie de nom
String playerName = "";
boolean nameInputActive = false;
int maxNameLength = 15;


// gameState peut être : "LOGIN", "REGISTER", "MENU", "PLAYING", "GAMEOVER"
String loginUsername = "";
String loginPassword = "";
boolean loginUsernameActive = false;
boolean loginPasswordActive = false;
String loginError = "";
int loginErrorTimer = 0;

String regUsername = "";
String regPassword = "";
String regPassword2 = "";
boolean regUsernameActive = false;
boolean regPasswordActive = false;
boolean regPassword2Active = false;
String regError = "";

PFont policeHSR;

void setup() {
  size(1600, 900, FX2D);
  smooth(8);
  frameRate(60);
  
  // Initialisation des objets
  db = new Database();   // BDD en premier
  game = new GameManager();
  bullets = new ArrayList<Bullet>();
  shapes = new ArrayList<Shape>();
  enemies = new ArrayList<Enemy>();
  particles = new ArrayList<Particle>();
  spawner = new Spawner();
  ui = new UI();
  shop = new Shop();
  
  // Démarrer sur l'écran de connexion
  game.gameState = "LOGIN";
  
  // Charger et lancer la musique du menu
  musiqueMenu = new SoundFile(this, "assets/NEVERNESS TO EVERNESS - 9°C Coffee OST Extended.mp3");
  musiqueMenu.loop();
  musiqueMenu.amp(0.5);
  
  // Charger et appliquer la police personnalisée
  policeHSR = createFont("HSR.ttf", 32, true);
  textFont(policeHSR);
  
  // Initialiser la demo pour le menu
  initMenuDemo();
  
  println("Setup termine -> gameState = " + game.gameState);
}

void initMenuDemo() {
  // Creer un joueur de demo au centre de l'ecran
  demoPlayer = new Tank(width/2, height/2, false); // false pour désactiver les inputs souris
  demoPlayer.level = 45;
  demoPlayer.xp = demoPlayer.xpNeeded * 0.7;
  
  demoBullets = new ArrayList<Bullet>();
  formesDemo = new ArrayList<Shape>();
  demoParticles = new ArrayList<Particle>();
  
  // Ajouter beaucoup plus de formes autour du joueur
  for (int i = 0; i < 25; i++) {
    float angle = random(TWO_PI);
    float dist = random(150, 450);
    float x = width/2 + cos(angle) * dist;
    float y = height/2 + sin(angle) * dist;
    int sides = (int)random(3, 6);
    formesDemo.add(new Shape(x, y, sides));
  }
}

void updateMenuDemo() {
  float centerX = width/2;
  float centerY = height/2;
  
  // Le joueur se deplace legerement en cercle
  float time = frameCount * 0.02;
  demoPlayer.x = centerX + cos(time) * 50;
  demoPlayer.y = centerY + sin(time) * 50;
  
  // Angle de tir suit le mouvement circulaire (pas la souris)
  float shootAngle = time * 2;
  demoPlayer.demoAngle = shootAngle;
  
  // Tir automatique dans la demo (plus lent)
  if (frameCount % 20 == 0) {
    float spawnX = demoPlayer.x + cos(shootAngle) * (demoPlayer.size + demoPlayer.barrelLength);
    float spawnY = demoPlayer.y + sin(shootAngle) * (demoPlayer.size + demoPlayer.barrelLength);
    Bullet b = new Bullet(spawnX, spawnY, shootAngle, 10, true, 8);
    demoBullets.add(b);
  }
  
  // Update bullets de demo
  for (int i = demoBullets.size()-1; i >= 0; i--) {
    Bullet b = demoBullets.get(i);
    b.update();
    
    boolean removed = false;
    
    // Collision avec formes
    for (int j = formesDemo.size()-1; j >= 0; j--) {
      Shape s = formesDemo.get(j);
      if (s.checkCollision(b)) {
        s.takeDamage(b.damage, true);
        demoBullets.remove(i);
        removed = true;
        if (s.isDead()) {
          formesDemo.remove(j);
          for (int k = 0; k < 8; k++) {
            demoParticles.add(new Particle(s.x, s.y, s.col));
          }
          float newAngle = random(TWO_PI);
          float newDist = random(150, 450);
          float newX = centerX + cos(newAngle) * newDist;
          float newY = centerY + sin(newAngle) * newDist;
          formesDemo.add(new Shape(newX, newY, (int)random(3, 6)));
        }
        break;
      }
    }
    
    if (!removed && (b.x < -100 || b.x > width + 100 || b.y < -100 || b.y > height + 100)) {
      demoBullets.remove(i);
    }
  }
  
  for (Shape s : formesDemo) {
    s.update();
  }
  
  for (int i = demoParticles.size()-1; i >= 0; i--) {
    Particle p = demoParticles.get(i);
    p.update();
    if (p.isDead()) {
      demoParticles.remove(i);
    }
  }
}

public void drawMenuDemo() {
  background(200, 200, 200);
  
  stroke(180, 120);
  strokeWeight(1);
  for (int x = 0; x < width; x += 50) {
    line(x, 0, x, height);
  }
  for (int y = 0; y < height; y += 50) {
    line(0, y, width, y);
  }
  
  for (Shape s : formesDemo) {
    s.display();
  }
  
  for (Bullet b : demoBullets) {
    b.display();
  }
  
  for (Particle p : demoParticles) {
    p.display();
  }
  
  demoPlayer.display();
}

public void draw() {
  

  if (game.gameState.equals("LOGIN")) {
    updateMenuDemo();
    drawMenuDemo();
    fill(40, 45, 60, 220);
    noStroke();
    rect(0, 0, width, height);
    drawLoginScreen();
    return;
  }
  
  if (game.gameState.equals("REGISTER")) {
    updateMenuDemo();
    drawMenuDemo();
    fill(40, 45, 60, 220);
    noStroke();
    rect(0, 0, width, height);
    drawRegisterScreen();
    return;
  }
  
  if (game.gameState.equals("MENU")) {
    updateMenuDemo();
    drawMenuDemo();
    
    // Overlay semi-transparent
    fill(40, 45, 60, 220);
    noStroke();
    rect(0, 0, width, height);
    
    drawMenu();
    return;
  }
  
  // PLAYING ou GAMEOVER - le jeu continue dans les deux cas
  cameraX = player.x - width/2;
  cameraY = player.y - height/2;
  
  cameraX = constrain(cameraX, 0, mapWidth - width);
  cameraY = constrain(cameraY, 0, mapHeight - height);
  
  background(200, 200, 200);
  
  pushMatrix();
  translate(-cameraX, -cameraY);
  
  drawGrid();
  drawMapBorders();
  
  boolean enPause = (game.isPaused || (player != null && player.choixClasseEnAttente)) && game.gameState.equals("PLAYING");
  
  if (!enPause) {
    // Spawn ennemis (moins frequent) - SEULEMENT EN MODE PLAYING
    if (game.gameState.equals("PLAYING") && frameCount % 400 == 0 && enemies.size() < 4) {
      float spawnX = random(100, mapWidth - 100);
      float spawnY = random(100, mapHeight - 100);
      if (dist(spawnX, spawnY, player.x, player.y) > 500) {
        enemies.add(new Enemy(spawnX, spawnY));
      }
    }
    
    game.update();
    
    // Update joueur SEULEMENT en mode PLAYING
    if (game.gameState.equals("PLAYING")) {
      player.update();
      player.handleMovement();
      
      if (mousePressed) {
        player.shoot();
      }
    }
  }
  
  for (int i = bullets.size()-1; i >= 0; i--) {
    Bullet b = bullets.get(i);
    if (!enPause) {
      b.update();
      if (b.isOffScreen()) {
        bullets.remove(i);
        continue;
      }
    }
    b.display();
  }
  
  if (!enPause) {
    spawner.update();
    
    // Effet Magnet - collecte automatique de pièces des formes proches
    if (game.gameState.equals("PLAYING") && player.magnetActive) {
      float magnetRadius = 250;
      for (int i = shapes.size()-1; i >= 0; i--) {
        Shape s = shapes.get(i);
        if (dist(s.x, s.y, player.x, player.y) < magnetRadius) {
          player.gainXP(s.xpValue);
          db.addCoins((int)s.coinValue);
          createParticles(s.x, s.y, s.col);
          shapes.remove(i);
        }
      }
    }
  }
  
  for (int i = shapes.size()-1; i >= 0; i--) {
    Shape s = shapes.get(i);
    
    if (!enPause) {
      s.update();
      
      // Collision joueur / forme (body damage)
      if (game.gameState.equals("PLAYING")) {
        float distFormeJoueur = dist(s.x, s.y, player.x, player.y);
        if (distFormeJoueur < s.size + player.size) {
          float angleImpact = atan2(s.y - player.y, s.x - player.x);
          // Knockback léger pour ne pas éjecter la forme trop loin
          float forceKnockback = player.bodyDamage * 0.06;
          s.takeDamageAvecKnockback(player.bodyDamage / 60.0, angleImpact, forceKnockback);
          player.dureeImpact = player.maxDureeImpact;
          if (s.isDead()) {
            player.gainXP(s.xpValue);
            db.addCoins((int)s.coinValue);
            shapes.remove(i);
            createParticles(s.x, s.y, s.col);
            continue;
          }
        }
      }
      
      for (int j = bullets.size()-1; j >= 0; j--) {
        Bullet b = bullets.get(j);
        if (b.estImmunise(s)) continue;
        if (s.checkCollision(b)) {
          if (b.fromPlayer) {
            float angleImpact = atan2(s.y - b.y, s.x - b.x);
            float forceKnockback = b.damage * 0.3;
            s.takeDamageAvecKnockback(b.damage, angleImpact, forceKnockback);
            boolean balleDetruite = b.appliquerImpact(s);
            if (s.isDead()) {
              if (game.gameState.equals("PLAYING")) {
                player.gainXP(s.xpValue);
                db.addCoins((int)s.coinValue);
              }
              shapes.remove(i);
              createParticles(s.x, s.y, s.col);
            }
            if (balleDetruite) {
              bullets.remove(j);
            }
          } else {
            s.takeDamage(b.damage, false);
            b.declencherEffetImpact();
            bullets.remove(j);
            if (s.isDead()) {
              shapes.remove(i);
              createParticles(s.x, s.y, s.col);
            }
          }
          break;
        }
      }
    }
    
    s.display();
  }
  
  for (int i = enemies.size()-1; i >= 0; i--) {
    Enemy e = enemies.get(i);
    
    if (!enPause) {
      e.update();
      
      for (int j = bullets.size()-1; j >= 0; j--) {
        Bullet b = bullets.get(j);
        if (!b.fromPlayer) continue;
        if (b.estImmunise(e)) continue;
        float d = dist(e.x, e.y, b.x, b.y);
        if (d < e.size + b.taille) {
          e.takeDamage(b.damage);
          boolean balleDetruite = b.appliquerImpact(e);
          if (balleDetruite) {
            bullets.remove(j);
          }
          break;
        }
      }
      
      // Collisions avec le joueur SEULEMENT en mode PLAYING
      if (game.gameState.equals("PLAYING")) {
        for (int j = bullets.size()-1; j >= 0; j--) {
          Bullet b = bullets.get(j);
          if (!b.fromPlayer) {
            float d = dist(player.x, player.y, b.x, b.y);
            if (d < player.size + b.taille) {
              player.takeDamage(b.damage);
              player.dureeImpact = player.maxDureeImpact;
              b.declencherEffetImpact();
              bullets.remove(j);
              createParticles(player.x, player.y, color(0, 176, 255));
              break;
            }
          }
        }
        
        float distEnemy = dist(e.x, e.y, player.x, player.y);
        if (distEnemy < e.size + player.size) {
          player.takeDamage(e.bodyDamage / 60.0);
          e.takeDamage(player.bodyDamage / 60.0);
        }
      }
    }
    
    e.display();
  }
  
  for (int i = particles.size()-1; i >= 0; i--) {
    Particle p = particles.get(i);
    if (!enPause) {
      p.update();
      if (p.isDead()) {
        particles.remove(i);
        continue;
      }
    }
    p.display();
  }
  
  player.display();
  
  popMatrix();
  
  // UI SEULEMENT en mode PLAYING
  if (game.gameState.equals("PLAYING")) {
    ui.display();
    
    // Boutique (slide depuis la droite)
    shop.update();
    shop.display();
    
    // Panneau de choix de classe si en attente
    if (player.choixClasseEnAttente) {
      afficherChoixClasse();
    }
    

  }
  
  // En GAMEOVER, continuer à updater/afficher le shop pour qu'il puisse se fermer
  if (game.gameState.equals("GAMEOVER")) {
    shop.update();
    if (shop.panelX < width + shop.panelWidth) {
      shop.display();
    }
  }
  
  // Overlay de pause par-dessus le jeu (fond transparent)
  if (game.isPaused && game.gameState.equals("PLAYING")) {
    fill(0, 0, 0, 100);
    noStroke();
    rect(0, 0, width, height);
    
    float panneauL = 420;
    float panneauH = 200;
    float panneauX = width/2 - panneauL/2;
    float panneauY = height/2 - panneauH/2;
    
    fill(18, 22, 36, 160);
    stroke(0, 180, 255, 140);
    strokeWeight(2);
    rect(panneauX, panneauY, panneauL, panneauH, 16);
    
    fill(0, 200, 255);
    textAlign(CENTER, CENTER);
    textSize(52);
    text("PAUSE", width/2, panneauY + 72);
    
    fill(160);
    textSize(18);
    text("Appuyez sur [ESC] pour reprendre", width/2, panneauY + 140);
  }
  
  // Afficher Game Over en fondu par-dessus
  if (game.gameState.equals("GAMEOVER")) {
    // Calculer le fondu (0.5 secondes = 30 frames à 60fps)
    int framesSinceGameOver = frameCount - gameOverFadeStartFrame;
    gameOverFadeAlpha = min(230, framesSinceGameOver * (230.0 / 30.0));
    
    // Overlay semi-transparent qui s'intensifie
    fill(20, 20, 40, gameOverFadeAlpha);
    noStroke();
    rect(0, 0, width, height);
    
    // Afficher le menu Game Over avec la même opacité
    if (gameOverFadeAlpha > 50) { // Commence à afficher après un peu de fondu
      drawGameOver();
    }
  }
}

void drawGrid() {
  stroke(180);
  strokeWeight(1);
  
  for (float x = 0; x <= mapWidth; x += gridSize) {
    line(x, 0, x, mapHeight);
  }
  
  for (float y = 0; y <= mapHeight; y += gridSize) {
    line(0, y, mapWidth, y);
  }
}

void drawMapBorders() {
  noFill();
  stroke(255, 0, 0);
  strokeWeight(10);
  rect(0, 0, mapWidth, mapHeight);
}

void drawMenu() {
  stroke(60, 70, 90, 100);
  strokeWeight(1);
  for (int x = 0; x < width; x += 60) {
    line(x, 0, x, height);
  }
  for (int y = 0; y < height; y += 60) {
    line(0, y, width, y);
  }
  
  fill(0, 180, 255);
  textAlign(CENTER);
  textSize(90);
  text("DIEP.IO", width/2, height/3 - 60);
  
  fill(220);
  textSize(28);
  text("GLOIRE AU SQL !!!!!!", width/2, height/3);
  
  // Champ de saisie du nom
  float inputW = 400;
  float inputH = 60;
  float inputX = width/2 - inputW/2;
  float inputY = height/2 - 20;
  
  if (nameInputActive) {
    stroke(0, 220, 255);
    strokeWeight(3);
  } else {
    stroke(100, 120, 140);
    strokeWeight(2);
  }
  fill(30, 35, 50);
  rect(inputX, inputY, inputW, inputH, 8);
  
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(28);
  if (playerName.length() > 0) {
    text(playerName, width/2, inputY + inputH/2);
  } else {
    fill(150);
    textSize(24);
    text("Entrez votre nom...", width/2, inputY + inputH/2);
  }
  
  if (nameInputActive && frameCount % 60 < 30) {
    fill(0, 220, 255);
    textAlign(LEFT, CENTER);
    textSize(28);
    float cursorX = width/2 + textWidth(playerName)/2 + 5;
    text("|", cursorX, inputY + inputH/2);
  }
  
  // Bouton PLAY
  float btnW = 280;
  float btnH = 80;
  float btnX = width/2 - btnW/2;
  float btnY = height/2 + 80;
  
  boolean canPlay = playerName.length() > 0;
  if (canPlay && isMouseOverButton(mouseX, mouseY, btnX, btnY, btnW, btnH)) {
    fill(0, 220, 255);
  } else if (canPlay) {
    fill(0, 200, 255);
  } else {
    fill(80, 100, 120);
  }
  
  stroke(0, 140, 220);
  strokeWeight(4);
  rect(btnX, btnY, btnW, btnH, 12);
  
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(48);
  text("PLAY!", width/2, btnY + btnH/2 + 5);
  
  fill(180);
  textSize(18);
  textAlign(CENTER);
  text("Cliquez sur le champ pour entrer votre nom", width/2, height - 100);
  text("ESC pour quitter", width/2, height - 70);
  
  if (game.highScore > 0) {
    fill(255, 220, 100);
    textSize(22);
    text("Meilleur score : " + game.highScore + " (" + game.highScoreName + ")", width/2, height - 140);
  }
  
  // Panneau des contrôles clavier (côté gauche)
  float controlesPanelX = 30;
  float controlesPanelY = height/2 - 160;
  float controlesPanelL = 260;
  float controlesPanelH = 320;
  
  fill(15, 20, 35, 210);
  stroke(0, 180, 255, 100);
  strokeWeight(1.5);
  rect(controlesPanelX, controlesPanelY, controlesPanelL, controlesPanelH, 10);
  
  fill(0, 200, 255);
  textAlign(LEFT, TOP);
  textSize(15);
  text("CONTRÔLES", controlesPanelX + 14, controlesPanelY + 12);
  
  fill(80, 130, 180);
  noStroke();
  rect(controlesPanelX + 10, controlesPanelY + 32, controlesPanelL - 20, 1);
  
  String[][] lignesControles = {
    {"Z / ↑",         "Avancer"},
    {"S / ↓",         "Reculer"},
    {"Q / ←",         "Aller à gauche"},
    {"D / →",         "Aller à droite"},
    {"Clic gauche",   "Tirer"},
    {"Souris",        "Viser"},
    {"ESPACE",        "Ouvrir la boutique"},
    {"1 – 8",         "Améliorer une stat"},
    {"TAB",           "Cacher/montrer stats"},
    {"ESC",           "Pause"},
  };
  
  float ligneY = controlesPanelY + 44;
  float ligneH = 26;
  for (String[] ligne : lignesControles) {
    fill(100, 200, 255);
    textAlign(LEFT, CENTER);
    textSize(13);
    text(ligne[0], controlesPanelX + 14, ligneY + ligneH / 2);
    fill(190, 210, 230);
    textAlign(RIGHT, CENTER);
    text(ligne[1], controlesPanelX + controlesPanelL - 12, ligneY + ligneH / 2);
    ligneY += ligneH;
  }
  
  // Bouton Déconnexion (coin supérieur droit)
  float decoL = 180;
  float decoH = 40;
  float decoX = width - decoL - 20;
  float decoY = 20;
  boolean decoSurvol = isMouseOverButton(mouseX, mouseY, decoX, decoY, decoL, decoH);
  
  fill(decoSurvol ? color(200, 60, 60) : color(160, 40, 40));
  stroke(decoSurvol ? color(255, 100, 100) : color(120, 30, 30));
  strokeWeight(2);
  rect(decoX, decoY, decoL, decoH, 8);
  
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(15);
  text("⏻  Déconnexion", decoX + decoL / 2, decoY + decoH / 2);
}

void drawGameOver() {
  // PLUS de background opaque - la démo est visible derrière
  
  fill(255, 80, 80);
  textAlign(CENTER, CENTER);
  textSize(80);
  text("YOU DIED", width/2, height/3);
  
  fill(220);
  textSize(36);
  text("Joueur : " + playerName, width/2, height/2 - 40);
  text("Score : " + game.score, width/2, height/2 + 10);
  text("Niveau : " + player.level, width/2, height/2 + 60);
  
  // Pièces totales
  fill(255, 215, 0);
  textSize(24);
  text("Pieces : " + db.getCoins(), width/2, height/2 + 105);
  
  fill(180);
  textSize(24);
  text("Appuyez sur M ou cliquez pour revenir au menu", width/2, height - 80);
  
  float btnW = 300;
  float btnH = 70;
  float btnX = width/2 - btnW/2;
  float btnY = height/2 + 145;
  
  if (isMouseOverButton(mouseX, mouseY, btnX, btnY, btnW, btnH)) {
    fill(0, 220, 255);
  } else {
    fill(0, 180, 220);
  }
  stroke(0, 140, 180);
  strokeWeight(3);
  rect(btnX, btnY, btnW, btnH, 10);
  
  fill(255);
  textSize(28);
  text("MENU", width/2, btnY + btnH/2 + 5);
}

// =============================================================================
// ÉCRAN DE CONNEXION
// =============================================================================
void drawLoginScreen() {
  // Titre
  fill(0, 180, 255);
  textAlign(CENTER, CENTER);
  textSize(80);
  text("DIEP.IO", width/2, height/5);
  
  fill(200);
  textSize(22);
  text("GLOIRE AU SQL !!!!!!", width/2, height/5 + 55);
  
  float panelW = 480;
  float panelH = 400;
  float panelX = width/2 - panelW/2;
  float panelY = height/2 - panelH/2 + 20;
  
  // Fond du panneau
  fill(20, 25, 40, 230);
  stroke(0, 150, 200, 150);
  strokeWeight(2);
  rect(panelX, panelY, panelW, panelH, 14);
  
  // Titre panneau
  fill(0, 200, 255);
  textAlign(CENTER, TOP);
  textSize(26);
  text("CONNEXION", width/2, panelY + 18);
  
  // Champs de saisie
  float fieldW = panelW - 60;
  float fieldH = 50;
  float fieldX = panelX + 30;
  
  // --- Nom d'utilisateur ---
  float fieldY1 = panelY + 70;
  fill(160);
  textAlign(LEFT, CENTER);
  textSize(14);
  text("Nom d'utilisateur", fieldX, fieldY1 - 14);
  
  drawTextField(fieldX, fieldY1, fieldW, fieldH, loginUsername, loginUsernameActive, "Entrez votre nom...");
  
  // --- Mot de passe ---
  float fieldY2 = fieldY1 + fieldH + 30;
  fill(160);
  textAlign(LEFT, CENTER);
  textSize(14);
  text("Mot de passe", fieldX, fieldY2 - 14);
  
  drawTextField(fieldX, fieldY2, fieldW, fieldH, maskPassword(loginPassword), loginPasswordActive, "Entrez votre mot de passe...");
  
  // --- Bouton SE CONNECTER ---
  float btnW = fieldW;
  float btnH = 52;
  float btnY = fieldY2 + fieldH + 25;
  boolean canLogin = loginUsername.length() > 0 && loginPassword.length() > 0;
  
  drawActionButton(fieldX, btnY, btnW, btnH, "SE CONNECTER", canLogin, color(0, 200, 255));
  
  // --- Lien vers inscription ---
  fill(140);
  textAlign(CENTER, CENTER);
  textSize(15);
  text("Pas encore de compte ?", width/2, btnY + btnH + 20);
  
  float regBtnW = 200;
  float regBtnH = 36;
  drawActionButton(width/2 - regBtnW/2, btnY + btnH + 38, regBtnW, regBtnH, "CRÉER UN COMPTE", true, color(80, 180, 80));
  
  // --- Message d'erreur ---
  if (loginError.length() > 0) {
    fill(255, 80, 80);
    textAlign(CENTER, CENTER);
    textSize(15);
    text(loginError, width/2, panelY + panelH - 18);
  }
}

// =============================================================================
// ÉCRAN D'INSCRIPTION
// =============================================================================
void drawRegisterScreen() {
  fill(0, 180, 255);
  textAlign(CENTER, CENTER);
  textSize(60);
  text("DIEP.IO", width/2, height/6);
  
  float panelW = 480;
  float panelH = 460;
  float panelX = width/2 - panelW/2;
  float panelY = height/2 - panelH/2 + 10;
  
  fill(20, 25, 40, 230);
  stroke(80, 180, 80, 150);
  strokeWeight(2);
  rect(panelX, panelY, panelW, panelH, 14);
  
  fill(80, 220, 80);
  textAlign(CENTER, TOP);
  textSize(26);
  text("CRÉER UN COMPTE", width/2, panelY + 18);
  
  float fieldW = panelW - 60;
  float fieldH = 46;
  float fieldX = panelX + 30;
  
  float fieldY1 = panelY + 68;
  fill(160);
  textAlign(LEFT, CENTER);
  textSize(13);
  text("Nom d'utilisateur", fieldX, fieldY1 - 13);
  drawTextField(fieldX, fieldY1, fieldW, fieldH, regUsername, regUsernameActive, "Choisissez un nom...");
  
  float fieldY2 = fieldY1 + fieldH + 24;
  fill(160);
  textAlign(LEFT, CENTER);
  textSize(13);
  text("Mot de passe", fieldX, fieldY2 - 13);
  drawTextField(fieldX, fieldY2, fieldW, fieldH, maskPassword(regPassword), regPasswordActive, "Créez un mot de passe...");
  
  float fieldY3 = fieldY2 + fieldH + 24;
  fill(160);
  textAlign(LEFT, CENTER);
  textSize(13);
  text("Confirmer le mot de passe", fieldX, fieldY3 - 13);
  // Validation en temps réel
  color borderCol = (regPassword2.length() > 0 && !regPassword.equals(regPassword2)) ? color(255, 80, 80) : color(0, 200, 255);
  drawTextFieldColored(fieldX, fieldY3, fieldW, fieldH, maskPassword(regPassword2), regPassword2Active, "Confirmez...", borderCol);
  
  float btnW = fieldW;
  float btnH = 50;
  float btnY  = fieldY3 + fieldH + 22;
  boolean canRegister = regUsername.length() > 0 && regPassword.length() >= 4 && regPassword.equals(regPassword2);
  
  drawActionButton(fieldX, btnY, btnW, btnH, "CRÉER LE COMPTE", canRegister, color(80, 200, 80));
  
  // Retour connexion
  float backW = 180;
  float backH = 34;
  drawActionButton(width/2 - backW/2, btnY + btnH + 14, backW, backH, "← RETOUR", true, color(100, 120, 160));
  
  if (regError.length() > 0) {
    fill(255, 80, 80);
    textAlign(CENTER, CENTER);
    textSize(14);
    text(regError, width/2, panelY + panelH - 16);
  }
}

// ---- Helpers UI ----
void drawTextField(float fx, float fy, float fw, float fh, String val, boolean active, String placeholder) {
  drawTextFieldColored(fx, fy, fw, fh, val, active, placeholder, active ? color(0, 200, 255) : color(80, 100, 130));
}

void drawTextFieldColored(float fx, float fy, float fw, float fh, String val, boolean active, String placeholder, color borderCol) {
  fill(28, 34, 52);
  stroke(borderCol);
  strokeWeight(active ? 2.5 : 1.5);
  rect(fx, fy, fw, fh, 7);
  
  textAlign(LEFT, CENTER);
  textSize(18);
  if (val.length() > 0) {
    fill(255);
    text(val, fx + 12, fy + fh/2);
  } else {
    fill(90);
    text(placeholder, fx + 12, fy + fh/2);
  }
  
  // Curseur clignotant
  if (active && frameCount % 60 < 30) {
    fill(0, 200, 255);
    float cx = fx + 12 + textWidth(val);
    rect(cx, fy + 8, 2, fh - 16, 1);
  }
}

void drawActionButton(float bx, float by, float bw, float bh, String label, boolean enabled, color c) {
  boolean hovered = isMouseOverButton(mouseX, mouseY, bx, by, bw, bh) && enabled;
  if (enabled) {
    fill(hovered ? color(red(c)*1.1, green(c)*1.1, blue(c)*1.1) : c);
    stroke(red(c)*0.7, green(c)*0.7, blue(c)*0.7);
  } else {
    fill(50, 60, 80);
    stroke(40);
  }
  strokeWeight(2);
  rect(bx, by, bw, bh, 8);
  
  fill(enabled ? 255 : 100);
  textAlign(CENTER, CENTER);
  textSize(bh > 40 ? 18 : 14);
  text(label, bx + bw/2, by + bh/2);
}

String maskPassword(String pwd) {
  String masked = "";
  for (int i = 0; i < pwd.length(); i++) masked += "●";
  return masked;
}

void mousePressed() {
  // ---- LOGIN ----
  if (game.gameState.equals("LOGIN")) {
    float panelW = 480;
    float panelH = 400;
    float panelX = width/2 - panelW/2;
    float panelY = height/2 - panelH/2 + 20;
    float fieldW = panelW - 60;
    float fieldH = 50;
    float fieldX = panelX + 30;
    float fieldY1 = panelY + 70;
    float fieldY2 = fieldY1 + fieldH + 30;
    float btnY    = fieldY2 + fieldH + 25;
    float btnH    = 52;
    
    loginUsernameActive = isMouseOverButton(mouseX, mouseY, fieldX, fieldY1, fieldW, fieldH);
    loginPasswordActive = isMouseOverButton(mouseX, mouseY, fieldX, fieldY2, fieldW, fieldH);
    
    // Bouton SE CONNECTER
    if (isMouseOverButton(mouseX, mouseY, fieldX, btnY, fieldW, btnH)) {
      if (loginUsername.length() > 0 && loginPassword.length() > 0) {
        UserRecord u = db.loginUser(loginUsername, loginPassword);
        if (u != null) {
          playerName = u.username;
          loginError = "";
          game.gameState = "MENU";
          initMenuDemo();
        } else {
          loginError = "Nom ou mot de passe incorrect.";
        }
      }
    }
    
    // Lien créer un compte
    float regBtnW = 200;
    float regBtnH = 36;
    if (isMouseOverButton(mouseX, mouseY, width/2 - regBtnW/2, btnY + btnH + 38, regBtnW, regBtnH)) {
      game.gameState = "REGISTER";
      loginError = "";
    }
    return;
  }
  
  // ---- REGISTER ----
  if (game.gameState.equals("REGISTER")) {
    float panelW = 480;
    float panelH = 460;
    float panelX = width/2 - panelW/2;
    float panelY = height/2 - panelH/2 + 10;
    float fieldW = panelW - 60;
    float fieldH = 46;
    float fieldX = panelX + 30;
    float fieldY1 = panelY + 68;
    float fieldY2 = fieldY1 + fieldH + 24;
    float fieldY3 = fieldY2 + fieldH + 24;
    float btnH    = 50;
    float btnY    = fieldY3 + fieldH + 22;
    
    regUsernameActive  = isMouseOverButton(mouseX, mouseY, fieldX, fieldY1, fieldW, fieldH);
    regPasswordActive  = isMouseOverButton(mouseX, mouseY, fieldX, fieldY2, fieldW, fieldH);
    regPassword2Active = isMouseOverButton(mouseX, mouseY, fieldX, fieldY3, fieldW, fieldH);
    
    // Bouton CRÉER
    if (isMouseOverButton(mouseX, mouseY, fieldX, btnY, fieldW, btnH)) {
      if (regUsername.length() > 0 && regPassword.length() >= 4 && regPassword.equals(regPassword2)) {
        boolean ok = db.registerUser(regUsername, regPassword);
        if (ok) {
          regError = "";
          // Auto-login après inscription
          db.loginUser(regUsername, regPassword);
          playerName = regUsername;
          game.gameState = "MENU";
          initMenuDemo();
          // Réinitialiser les champs
          regUsername = ""; regPassword = ""; regPassword2 = "";
        } else {
          regError = "Ce nom d'utilisateur est deja pris.";
        }
      } else if (regPassword.length() < 4) {
        regError = "Mot de passe trop court (min. 4 caracteres)";
      } else if (!regPassword.equals(regPassword2)) {
        regError = "Les mots de passe ne correspondent pas.";
      }
    }
    
    // Bouton RETOUR
    float backW = 180;
    float backH = 34;
    if (isMouseOverButton(mouseX, mouseY, width/2 - backW/2, btnY + btnH + 14, backW, backH)) {
      game.gameState = "LOGIN";
      regError = "";
    }
    return;
  }
  




















  if (game.gameState.equals("MENU")) {
    // Bouton Déconnexion
    float decoL = 180;
    float decoH = 40;
    float decoX = width - decoL - 20;
    float decoY = 20;
    if (isMouseOverButton(mouseX, mouseY, decoX, decoY, decoL, decoH)) {
      db.logout();
      playerName = "";
      loginUsername = "";
      loginPassword = "";
      loginError = "";
      nameInputActive = false;
      game.gameState = "LOGIN";
      return;
    }
    
    float inputW = 400;
    float inputH = 60;
    float inputX = width/2 - inputW/2;
    float inputY = height/2 - 20;
    
    if (isMouseOverButton(mouseX, mouseY, inputX, inputY, inputW, inputH)) {
      nameInputActive = true;
    } else {
      nameInputActive = false;
    }
    
    float btnW = 280;
    float btnH = 80;
    float btnX = width/2 - btnW/2;
    float btnY = height/2 + 80;
    
    if (playerName.length() > 0 && isMouseOverButton(mouseX, mouseY, btnX, btnY, btnW, btnH)) {
      startNewGame();
    }
  } else if (game.gameState.equals("GAMEOVER")) {
    float btnW = 300;
    float btnH = 70;
    float btnX = width/2 - btnW/2;
    float btnY = height/2 + 145; // aligné avec drawGameOver()
    
    if (isMouseOverButton(mouseX, mouseY, btnX, btnY, btnW, btnH)) {
      game.gameState = "MENU";
      nameInputActive = false;
      initMenuDemo();
      musiqueMenu.loop();
    }
  } else if (game.gameState.equals("PLAYING")) {
    // Choix de classe en priorité
    if (player.choixClasseEnAttente) {
      gererClicChoixClasse(mouseX, mouseY);
      return;
    }
    
    // Déléguer au shop si ouvert
    if (shop.isOpen) {
      shop.handleClick(mouseX, mouseY);
    }
    
    if (player.availablePoints > 0) {
      float startX = 15;
      float startY = height - 400;
      float buttonW = 350;
      float buttonH = 45;
      float spacing = 5;
      float plusSize = 35;
      float plusXOffset = 310;
      
      for (int i = 0; i < 8; i++) {
        float btnY = startY + (buttonH + spacing) * i;
        float plusX = startX + plusXOffset;
        float plusY = btnY + (buttonH - plusSize)/2;
        
        if (isMouseOverButton(mouseX, mouseY, plusX, plusY, plusSize, plusSize)) {
          String stat = getStatByIndex(i);
          if (getStatLevel(stat) < player.maxStatLevel) {
            player.upgradeStat(stat);
            println("Upgrade effectue : " + stat);
          }
          break;
        }
      }
    }
  }
}

boolean isMouseOverButton(float mx, float my, float btnX, float btnY, float btnW, float btnH) {
  return mx > btnX && mx < btnX + btnW && my > btnY && my < btnY + btnH;
}

void createParticles(float x, float y, color c) {
  for (int i = 0; i < 8; i++) {
    particles.add(new Particle(x, y, c));
  }
}

String getStatByIndex(int index) {
  String[] stats = {"healthRegen", "maxHealth", "bodyDamage", "bulletSpeed", 
                    "bulletPenetration", "bulletDamage", "reload", "movementSpeed"};
  return stats[index];
}

int getStatLevel(String stat) {
  switch(stat) {
    case "healthRegen": return player.healthRegenLevel;
    case "maxHealth": return player.maxHealthLevel;
    case "bodyDamage": return player.bodyDamageLevel;
    case "bulletSpeed": return player.bulletSpeedLevel;
    case "bulletPenetration": return player.bulletPenetrationLevel;
    case "bulletDamage": return player.bulletDamageLevel;
    case "reload": return player.reloadLevel;
    case "movementSpeed": return player.movementSpeedLevel;
  }
  return 0;
}

void keyPressed() {
  // F11 = basculer plein ecran
  if (keyCode == 122) {
    if (sketchFullScreen()) {
      surface.setSize(1600, 900);
    } else {
      surface.setSize(displayWidth, displayHeight);
    }
    return;
  }

  // ---- LOGIN ----
  if (game.gameState.equals("LOGIN")) {
    if (loginUsernameActive) {
      if (key == BACKSPACE && loginUsername.length() > 0) loginUsername = loginUsername.substring(0, loginUsername.length()-1);
      else if (key == TAB) { loginUsernameActive = false; loginPasswordActive = true; }
      else if ((key == ENTER || key == RETURN) && loginPassword.length() > 0) {
        UserRecord u = db.loginUser(loginUsername, loginPassword);
        if (u != null) { playerName = u.username; game.gameState = "MENU"; initMenuDemo(); } else loginError = "Nom ou mot de passe incorrect.";
      } else if (key >= 32 && key <= 126 && loginUsername.length() < 20) loginUsername += key;
    } else if (loginPasswordActive) {
      if (key == BACKSPACE && loginPassword.length() > 0) loginPassword = loginPassword.substring(0, loginPassword.length()-1);
      else if (key == TAB) { loginPasswordActive = false; loginUsernameActive = true; }
      else if (key == ENTER || key == RETURN) {
        UserRecord u = db.loginUser(loginUsername, loginPassword);
        if (u != null) { playerName = u.username; game.gameState = "MENU"; initMenuDemo(); } else loginError = "Nom ou mot de passe incorrect.";
      } else if (key >= 32 && key <= 126 && loginPassword.length() < 30) loginPassword += key;
    }
    if (key == ESC) { key = 0; exit(); }
    return;
  }
  
  // ---- REGISTER ----
  if (game.gameState.equals("REGISTER")) {
    if (regUsernameActive) {
      if (key == BACKSPACE && regUsername.length() > 0) regUsername = regUsername.substring(0, regUsername.length()-1);
      else if (key == TAB) { regUsernameActive = false; regPasswordActive = true; }
      else if (key >= 32 && key <= 126 && regUsername.length() < 20) regUsername += key;
    } else if (regPasswordActive) {
      if (key == BACKSPACE && regPassword.length() > 0) regPassword = regPassword.substring(0, regPassword.length()-1);
      else if (key == TAB) { regPasswordActive = false; regPassword2Active = true; }
      else if (key >= 32 && key <= 126 && regPassword.length() < 30) regPassword += key;
    } else if (regPassword2Active) {
      if (key == BACKSPACE && regPassword2.length() > 0) regPassword2 = regPassword2.substring(0, regPassword2.length()-1);
      else if (key == TAB) { regPassword2Active = false; regUsernameActive = true; }
      else if ((key == ENTER || key == RETURN) && regUsername.length() > 0 && regPassword.equals(regPassword2) && regPassword.length() >= 4) {
        boolean ok = db.registerUser(regUsername, regPassword);
        if (ok) { db.loginUser(regUsername, regPassword); playerName = regUsername; game.gameState = "MENU"; initMenuDemo(); regUsername=""; regPassword=""; regPassword2=""; } else regError = "Nom deja pris.";
      } else if (key >= 32 && key <= 126 && regPassword2.length() < 30) regPassword2 += key;
    }
    if (key == ESC) { game.gameState = "LOGIN"; key = 0; }
    return;
  }
  
  if (game.gameState.equals("MENU")) {
    if (nameInputActive) {
      if (key == BACKSPACE && playerName.length() > 0) {
        playerName = playerName.substring(0, playerName.length() - 1);
      } else if (key == ENTER || key == RETURN) {
        if (playerName.length() > 0) {
          nameInputActive = false;
          startNewGame();
        }
      } else if (key >= 32 && key <= 126 && playerName.length() < maxNameLength) {
        playerName += key;
      }
    } else {
      if (key == 'p' || key == 'P') {
        if (playerName.length() > 0) {
          startNewGame();
        }
      } else if (key == ESC) {
        key = 0;
        exit();
      }
    }
  } else if (game.gameState.equals("GAMEOVER")) {
    if (key == 'm' || key == 'M') {
      game.gameState = "MENU";
      nameInputActive = false;
      initMenuDemo();
      musiqueMenu.loop();
    } else if (key == ESC) {
      key = 0;
      exit();
    }
  } else if (game.gameState.equals("PLAYING")) {
    // ESPACE = toggle boutique
    if (key == ' ') {
      shop.toggle();
      return;
    }
    
    // TAB = cacher/afficher le menu d'amélioration des stats
    if (key == TAB) {
      key = 0;
      if (player.availablePoints > 0) {
        menuUpgradeVisible = !menuUpgradeVisible;
      }
      return;
    }
    
    player.handleKeyPress();
    
    if (player.availablePoints > 0) {
      if (key == '1' && player.healthRegenLevel < player.maxStatLevel) player.upgradeStat("healthRegen");
      else if (key == '2' && player.maxHealthLevel < player.maxStatLevel) player.upgradeStat("maxHealth");
      else if (key == '3' && player.bodyDamageLevel < player.maxStatLevel) player.upgradeStat("bodyDamage");
      else if (key == '4' && player.bulletSpeedLevel < player.maxStatLevel) player.upgradeStat("bulletSpeed");
      else if (key == '5' && player.bulletPenetrationLevel < player.maxStatLevel) player.upgradeStat("bulletPenetration");
      else if (key == '6' && player.bulletDamageLevel < player.maxStatLevel) player.upgradeStat("bulletDamage");
      else if (key == '7' && player.reloadLevel < player.maxStatLevel) player.upgradeStat("reload");
      else if (key == '8' && player.movementSpeedLevel < player.maxStatLevel) player.upgradeStat("movementSpeed");
    }
    
    if (key == ESC) {
      key = 0;
      game.isPaused = !game.isPaused;
    }
  }
}

void keyReleased() {
  if (game.gameState.equals("PLAYING")) {
    player.handleKeyRelease();
  }
}

void startNewGame() {
  player = new Tank(mapWidth/2, mapHeight/2, true);
  player.playerName = playerName;
  bullets.clear();
  shapes.clear();
  enemies.clear();
  particles.clear();
  menuUpgradeVisible = true;
  game.reset();
  game.gameState = "PLAYING";
  shop.close();
  musiqueMenu.stop();
  println("Nouvelle partie demarree ! Joueur: " + playerName);
}

// =============================================================================
// PANNEAU DE CHOIX DE CLASSE
// =============================================================================

void afficherChoixClasse() {
  // Overlay sombre
  fill(0, 0, 0, 170);
  noStroke();
  rect(0, 0, width, height);
  
  String titrePalier = (player.level == 15) ? "ÉVOLUTION — NIVEAU 15" : "ÉVOLUTION — NIVEAU 30";
  
  // Titre
  fill(255, 230, 80);
  textAlign(CENTER, CENTER);
  textSize(38);
  text(titrePalier, width/2, height/2 - 180);
  
  fill(200);
  textSize(18);
  text("Choisissez votre classe :", width/2, height/2 - 135);
  
  int nbOptions = player.optionsClasse.length;
  float carteL = 210;
  float carteH = 240;
  float espacement = 30;
  float totalL = nbOptions * carteL + (nbOptions - 1) * espacement;
  float debutX = width/2 - totalL/2;
  float carteY = height/2 - carteH/2 - 20;
  
  for (int i = 0; i < nbOptions; i++) {
    String classe = player.optionsClasse[i];
    float cx = debutX + i * (carteL + espacement);
    boolean survol = isMouseOverButton(mouseX, mouseY, cx, carteY, carteL, carteH);
    
    // Fond de la carte
    fill(survol ? color(30, 50, 80) : color(18, 25, 45));
    stroke(survol ? color(100, 200, 255) : color(60, 90, 130));
    strokeWeight(survol ? 3 : 2);
    rect(cx, carteY, carteL, carteH, 12);
    
    // Nom de la classe
    fill(survol ? color(100, 220, 255) : color(220, 240, 255));
    textAlign(CENTER, CENTER);
    textSize(24);
    text(classe, cx + carteL/2, carteY + 38);
    
    // Description de la classe
    fill(170);
    textSize(13);
    textAlign(CENTER, TOP);
    String desc = descriptionClasse(classe);
    text(desc, cx + 12, carteY + 70, carteL - 24, carteH - 110);
    
    // Bouton CHOISIR
    float btnY = carteY + carteH - 52;
    float btnL = carteL - 30;
    fill(survol ? color(0, 220, 130) : color(0, 170, 100));
    noStroke();
    rect(cx + 15, btnY, btnL, 38, 8);
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(16);
    text("CHOISIR", cx + carteL/2, btnY + 19);
  }
}

String descriptionClasse(String classe) {
  switch(classe) {
    case "Twin":       return "Deux canons simultanés.\nDégâts par balle réduits,\nmais cadence doublée.";
    case "Sniper":     return "Balle unique rapide\net très puissante.\nPénétration accrue.";
    case "MachineGun": return "Cadence très élevée,\nléger éparpillement.\nDégâts modérés.";
    case "TripleShot": return "Trois balles en éventail.\nCouverture maximale.";
    case "Destroyer":  return "Balle énorme et lente.\nDégâts massifs.\nCadence faible.";
    case "Gatling":    return "Pluie de petites balles.\nCadence extrême.";
    default:           return "";
  }
}

void gererClicChoixClasse(float mx, float my) {
  int nbOptions = player.optionsClasse.length;
  float carteL = 210;
  float carteH = 240;
  float espacement = 30;
  float totalL = nbOptions * carteL + (nbOptions - 1) * espacement;
  float debutX = width/2 - totalL/2;
  float carteY = height/2 - carteH/2 - 20;
  
  for (int i = 0; i < nbOptions; i++) {
    String classe = player.optionsClasse[i];
    float cx = debutX + i * (carteL + espacement);
    float btnY = carteY + carteH - 52;
    float btnL = carteL - 30;
    
    if (isMouseOverButton(mx, my, cx + 15, btnY, btnL, 38)) {
      player.choisirClasse(classe);
      return;
    }
  }
}

