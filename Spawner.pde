class Spawner {
  // MODIFIE : Spawn rates beaucoup plus rapides pour plus de densite
  int triangleSpawnRate = 60; // MODIFIE : 60 au lieu de 120
  int squareSpawnRate = 90; // MODIFIE : 90 au lieu de 180
  int pentagonSpawnRate = 400; // MODIFIE : 400 au lieu de 600
  
  void update() {
    
    if (frameCount % triangleSpawnRate == 0 && shapes.size() < 120) { // MODIFIE : 120 au lieu de 50
      float x = random(50, mapWidth - 50);
      float y = random(50, mapHeight - 50);
      shapes.add(new Shape(x, y, 3));
    }
    
    if (frameCount % squareSpawnRate == 0 && shapes.size() < 120) { // MODIFIE : 120 au lieu de 50
      float x = random(50, mapWidth - 50);
      float y = random(50, mapHeight - 50);
      shapes.add(new Shape(x, y, 4));
    }
    
    // MODIFIE : Plus de pentagones aussi
    if (frameCount % pentagonSpawnRate == 0 && shapes.size() < 120) {
      float x = random(50, mapWidth - 50);
      float y = random(50, mapHeight - 50);
      shapes.add(new Shape(x, y, 5));
    }
  }
}
