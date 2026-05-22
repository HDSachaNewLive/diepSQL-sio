// =============================================================================
// Shop.pde - Boutique ingame (slide depuis la droite)
// =============================================================================

class Shop {
  
  // --- Positionnement ---
  float panelWidth  = 380;
  float panelX;       // Position X actuelle (animée)
  float targetX;      // Position X cible
  boolean isOpen    = false;
  float slideSpeed  = 25;
  
  // --- Items disponibles ---
  ArrayList<ShopItem> items;
  
  // --- Feedback d'achat ---
  String feedbackMsg   = "";
  int    feedbackTimer = 0;
  color  feedbackColor = color(255);
  
  Shop() {
    panelX  = width + panelWidth; // Hors écran par défaut
    targetX = width + panelWidth;
    
    items = new ArrayList<ShopItem>();
    
    // -----------------------------------------------------------------------
    // Catalogue des items
    // Format : ShopItem(id, nom, description, prix, couleur)
    // -----------------------------------------------------------------------
    items.add(new ShopItem("boost_speed",    "[SPD] Sprint",       "Vitesse x1.5\npendant 15 sec",   80,  color(100, 220, 255)));
    items.add(new ShopItem("boost_damage",   "[DMG] Surcharge",    "Degats x2\npendant 10 sec",      120, color(255, 120, 80)));
    items.add(new ShopItem("boost_regen",    "[REG] Soin Rapide",  "Regen x5\npendant 20 sec",        60,  color(80, 255, 120)));
    items.add(new ShopItem("boost_shield",   "[SHD] Bouclier",     "Invincible\npendant 5 sec",       200, color(200, 160, 255)));
    items.add(new ShopItem("boost_xp",       "[XP]  XP Boost",     "+50% XP\npendant 30 sec",         90,  color(255, 240, 80)));
    items.add(new ShopItem("boost_fire",     "[FIR] Rafale",       "Cadence x2\npendant 12 sec",      110, color(255, 180, 80)));
    items.add(new ShopItem("coin_magnet",    "[MAG] Aimant",       "Collecte auto\nles pieces 20s",    50,  color(255, 200, 120)));
    items.add(new ShopItem("bomb",           "[BOM] Bombe",        "Explose tout\na 300px",           150, color(255, 80, 80)));
  }
  
  // --- Toggle ouverture/fermeture ---
  void toggle() {
    isOpen  = !isOpen;
    targetX = isOpen ? (width - panelWidth) : (width + 10);
  }
  
  void open()  { isOpen = true;  targetX = width - panelWidth; }
  void close() { isOpen = false; targetX = width + 10; }
  
  // --- Update (animation slide) ---
  void update() {
    // Interpolation fluide vers la cible
    panelX += (targetX - panelX) * 0.18;
    
    if (feedbackTimer > 0) feedbackTimer--;
  }
  
  // --- Display ---
  void display() {
    if (panelX > width + panelWidth) return; // Complètement hors écran
    
    float px = panelX;
    float py = 0;
    float ph = height;
    float pw = panelWidth;
    
    // ---- Fond du panneau ----
    noStroke();
    fill(15, 18, 28, 240);
    rect(px, py, pw, ph);
    
    // Bordure gauche lumineuse
    fill(0, 180, 255, 180);
    rect(px, py, 3, ph);
    
    // ---- En-tête ----
    fill(20, 25, 40);
    noStroke();
    rect(px, py, pw, 75);
    
    fill(0, 200, 255);
    textAlign(CENTER, CENTER);
    textSize(28);
    text("** BOUTIQUE **", px + pw/2, py + 30);
    
    fill(180);
    textSize(14);
    text("Appuyez sur [ESPACE] pour fermer", px + pw/2, py + 58);
    
    // ---- Solde de pièces ----
    float coinBarY = py + 80;
    fill(40, 45, 60);
    noStroke();
    rect(px + 10, coinBarY, pw - 20, 38, 8);
    
    fill(255, 215, 0);
    textAlign(LEFT, CENTER);
    textSize(20);
    text("$ " + db.getCoins() + " pieces", px + 20, coinBarY + 19);
    
    // ---- Liste des items ----
    float itemY      = coinBarY + 52;
    float itemH      = 82;
    float itemSpacing = 8;
    
    for (int i = 0; i < items.size(); i++) {
      ShopItem item = items.get(i);
      float iy = itemY + (itemH + itemSpacing) * i;
      
      if (iy + itemH > height - 10) break; // Débord d'écran
      
      drawItem(item, px + 10, iy, pw - 20, itemH);
    }
    
    // ---- Message de feedback ----
    if (feedbackTimer > 0) {
      float alpha = map(feedbackTimer, 0, 90, 0, 255);
      fill(feedbackColor, alpha);
      textAlign(CENTER, CENTER);
      textSize(16);
      text(feedbackMsg, px + pw/2, height - 30);
    }
    
    // ---- Onglet "SHOP" visible quand fermé ----
    if (!isOpen || panelX > width - 5) {
      drawTab();
    }
  }
  
  void drawTab() {
    float tabW = 36;
    float tabH = 90;
    float tabX = panelX - tabW;
    float tabY = height/2 - tabH/2;
    
    fill(20, 25, 40, 220);
    stroke(0, 180, 255, 150);
    strokeWeight(2);
    rect(tabX, tabY, tabW, tabH, 8);
    
    fill(0, 200, 255);
    textAlign(CENTER, CENTER);
    textSize(13);
    
    // Texte vertical
    pushMatrix();
    translate(tabX + tabW/2, tabY + tabH/2);
    rotate(-HALF_PI);
    text("[ SHOP ]", 0, 0);
    popMatrix();
    
    noStroke();
  }
  
  void drawItem(ShopItem item, float ix, float iy, float iw, float ih) {
    boolean canAfford = db.getCoins() >= item.price;
    boolean hovered   = isHovered(ix, iy, iw, ih);
    
    // Fond item
    color bgCol = hovered && canAfford ? color(30, 40, 60) : color(22, 28, 45);
    fill(bgCol);
    stroke(item.col, hovered ? 180 : 80);
    strokeWeight(hovered ? 2 : 1);
    rect(ix, iy, iw, ih, 8);
    
    // Bande de couleur gauche
    noStroke();
    fill(item.col, 200);
    rect(ix, iy, 5, ih, 4);
    
    // Nom de l'item
    fill(hovered ? item.col : color(230));
    textAlign(LEFT, TOP);
    textSize(16);
    text(item.name, ix + 14, iy + 9);
    
    // Description
    fill(160);
    textSize(11);
    text(item.description, ix + 14, iy + 30);
    
    // --- Bouton ACHETER ---
    float btnW = 85;
    float btnH = 30;
    float btnX = ix + iw - btnW - 8;
    float btnY = iy + ih/2 - btnH/2;
    
    if (canAfford) {
      fill(hovered ? color(0, 230, 120) : color(0, 180, 80));
    } else {
      fill(70, 80, 90);
    }
    noStroke();
    rect(btnX, btnY, btnW, btnH, 6);
    
    // Prix
    fill(canAfford ? 255 : 140);
    textAlign(CENTER, CENTER);
    textSize(13);
    text("$ " + item.price, btnX + btnW/2, btnY + btnH/2);
  }
  
  // --- Clic sur un item ---
  void handleClick(float mx, float my) {
    if (!isOpen) return;
    
    float px        = panelX;
    float itemY     = 80 + 52;
    float itemH     = 82;
    float itemSpacing = 8;
    float itemW     = panelWidth - 20;
    float itemX     = px + 10;
    
    for (int i = 0; i < items.size(); i++) {
      ShopItem item = items.get(i);
      float iy = itemY + (itemH + itemSpacing) * i;
      
      // Zone bouton ACHETER
      float btnW = 85;
      float btnH = 30;
      float btnX = itemX + itemW - btnW - 8;
      float btnY = iy + itemH/2 - btnH/2;
      
      if (mx > btnX && mx < btnX + btnW && my > btnY && my < btnY + btnH) {
        tryBuy(item);
        return;
      }
    }
  }
  
  void tryBuy(ShopItem item) {
    if (db.getCoins() < item.price) {
      showFeedback("Pieces insuffisantes !", color(255, 80, 80));
      return;
    }
    
    if (db.spendCoins(item.price)) {
      db.recordPurchase(item.id);
      applyBoost(item.id);
      showFeedback(item.name + " active !", color(80, 255, 120));
    }
  }
  
  // --- Application des effets des boosts ---
  void applyBoost(String itemId) {
    if (player == null) return;
    
    switch(itemId) {
      case "boost_speed":
        player.boostSpeedTimer   = 900; // 15 sec
        player.boostSpeedActive  = true;
        break;
        
      case "boost_damage":
        player.boostDamageTimer  = 600; // 10 sec
        player.boostDamageActive = true;
        break;
        
      case "boost_regen":
        player.boostRegenTimer   = 1200; // 20 sec
        player.boostRegenActive  = true;
        break;
        
      case "boost_shield":
        player.shieldTimer       = 300; // 5 sec
        player.shieldActive      = true;
        break;
        
      case "boost_xp":
        player.boostXPTimer      = 1800; // 30 sec
        player.boostXPActive     = true;
        break;
        
      case "boost_fire":
        player.boostFireTimer    = 720; // 12 sec
        player.boostFireActive   = true;
        break;
        
      case "coin_magnet":
        player.magnetTimer       = 1200; // 20 sec
        player.magnetActive      = true;
        break;
        
      case "bomb":
        triggerBomb();
        break;
    }
    
    println("[SHOP] Boost appliqué : " + itemId);
  }
  
  // Bombe : détruit tout dans un rayon de 300px
  void triggerBomb() {
    float bombRadius = 300;
    
    // Détruire les ennemis proches
    for (int i = enemies.size()-1; i >= 0; i--) {
      Enemy e = enemies.get(i);
      if (dist(e.x, e.y, player.x, player.y) < bombRadius) {
        createParticles(e.x, e.y, color(255, 100, 80));
        game.addScore(100);
        db.addCoins(5);
        enemies.remove(i);
      }
    }
    
    // Détruire les formes proches
    for (int i = shapes.size()-1; i >= 0; i--) {
      Shape s = shapes.get(i);
      if (dist(s.x, s.y, player.x, player.y) < bombRadius) {
        player.gainXP(s.xpValue);
        db.addCoins((int)(s.coinValue));
        createParticles(s.x, s.y, s.col);
        shapes.remove(i);
      }
    }
    
    // Effet visuel de la bombe (particules orange en cercle)
    for (int i = 0; i < 60; i++) {
      particles.add(new Particle(player.x, player.y, color(255, 160, 40)));
    }
  }
  
  boolean isHovered(float ix, float iy, float iw, float ih) {
    // Convertir mouseX en coordonnées écran (le shop n'est PAS dans la caméra)
    return mouseX > ix && mouseX < ix + iw && mouseY > iy && mouseY < iy + ih;
  }
  
  void showFeedback(String msg, color c) {
    feedbackMsg   = msg;
    feedbackColor = c;
    feedbackTimer = 90;
  }
}

// =============================================================================
// MODÈLE D'ITEM DE BOUTIQUE
// =============================================================================

class ShopItem {
  String id;
  String name;
  String description;
  int    price;
  color  col;
  
  ShopItem(String id, String name, String description, int price, color col) {
    this.id          = id;
    this.name        = name;
    this.description = description;
    this.price       = price;
    this.col         = col;
  }
}
