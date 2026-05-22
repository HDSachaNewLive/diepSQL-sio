class Particle {
  float x, y;
  PVector velocity;
  color col;
  float size;
  float alpha = 255;
  
  Particle(float x, float y, color c) {
    this.x = x;
    this.y = y;
    this.col = c;
    
    // VÃ©locitÃ© alÃ©atoire
    float angle = random(TWO_PI);
    float speed = random(2, 6);
    velocity = new PVector(cos(angle) * speed, sin(angle) * speed);
    
    size = random(3, 8);
  }
  
  void update() {
    x += velocity.x;
    y += velocity.y;
    velocity.mult(0.95); // Ralentissement
    alpha -= 8; // Fade out
  }
  
  void display() {
    noStroke();
    fill(col, alpha);
    circle(x, y, size);
  }
  
  boolean isDead() {
    return alpha <= 0;
  }
}
