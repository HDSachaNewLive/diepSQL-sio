class Shape {
  float x, y;
  float size;
  float maxHealth;
  float health;
  color col;
  int sides; // 3 = triangle, 4 = carré, 5 = pentagone
  float xpValue;
  float coinValue;
  float rotation = 0;
  float rotationSpeed;
  
  // Knockback lors d'une collision avec le joueur
  PVector velociteKnockback;
  
  Shape(float x, float y, int sides) {
    this.x = x;
    this.y = y;
    this.sides = sides;
    
    // Stats selon type
    switch(sides) {
      case 3: // Triangle
        size = 15;
        maxHealth = 10;
        col = color(252, 118, 119); // Rouge
        xpValue = 30;
        coinValue = 2;
        break;
      case 4: // Carré
        size = 20;
        maxHealth = 20;
        col = color(255, 232, 105); // Jaune
        xpValue = 75;
        coinValue = 5;
        break;
      case 5: // Pentagone
        size = 30;
        maxHealth = 100;
        col = color(118, 141, 252); // Bleu
        xpValue = 300;
        coinValue = 15;
        break;
    }
    
    health = maxHealth;
    rotationSpeed = random(-0.02, 0.02);
    velociteKnockback = new PVector(0, 0);
  }
  
  void update() {
    rotation += rotationSpeed;
    
    // Application et amortissement du knockback
    if (velociteKnockback.mag() > 0.05) {
      x += velociteKnockback.x;
      y += velociteKnockback.y;
      velociteKnockback.mult(0.85);
      x = constrain(x, size, mapWidth - size);
      y = constrain(y, size, mapHeight - size);
    } else {
      velociteKnockback.set(0, 0);
    }
  }
  
  void appliquerKnockback(float forceX, float forceY) {
    velociteKnockback.add(forceX, forceY);
  }
  
  void display() {
    pushMatrix();
    translate(x, y);
    
    // Dessiner polygone avec rotation
    pushMatrix();
    rotate(rotation);
    
    fill(col);
    stroke(red(col) * 0.8, green(col) * 0.8, blue(col) * 0.8);
    strokeWeight(3);
    
    beginShape();
    for (int i = 0; i < sides; i++) {
      float angle = TWO_PI / sides * i;
      float px = cos(angle) * size;
      float py = sin(angle) * size;
      vertex(px, py);
    }
    endShape(CLOSE);
    
    popMatrix(); // Fin de la rotation - la barre de vie ne tournera pas
    
    // Barre de vie SANS rotation (toujours horizontale)
    if (health < maxHealth) {
      float barWidth = size * 2;
      float barHeight = 4;
      
      fill(255, 0, 0);
      noStroke();
      rect(-barWidth/2, -size - 10, barWidth, barHeight);
      
      fill(0, 255, 0);
      rect(-barWidth/2, -size - 10, barWidth * (health/maxHealth), barHeight);
    }
    
    popMatrix();
  }
  
  boolean checkCollision(Bullet b) {
    float d = dist(x, y, b.x, b.y);
    return d < size + b.taille;
  }
  
  // Dégâts sans knockback (ex: balle ennemie sur forme, body damage ennemi)
  void takeDamage(float amount, boolean fromPlayer) {
    if (fromPlayer) {
      health -= amount;
    }
  }
  
  // Dégâts avec knockback directionnel (balle joueur ou body damage joueur)
  void takeDamageAvecKnockback(float amount, float angleImpact, float forceKnockback) {
    health -= amount;
    velociteKnockback.add(cos(angleImpact) * forceKnockback, sin(angleImpact) * forceKnockback);
  }
  
  boolean isDead() {
    return health <= 0;
  }
}
