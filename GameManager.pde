public class GameManager {
  int score = 0;
  int highScore = 0;
  String highScoreName = "";
  boolean isPaused = false;
  String gameState = "LOGIN"; // LOGIN, REGISTER, MENU, PLAYING, GAMEOVER
  
  void update() {
    // Logique generale du jeu
    
    // Update high score
    if (score > highScore) {
      highScore = score;
      if (player != null) {
        highScoreName = player.playerName;
      }
    }
  }
  
  public void SetPause(boolean bool){
    isPaused = bool;
    return;
  }
  void gameOver() {
    gameState = "GAMEOVER";
    shop.close(); // Fermer le shop automatiquement
    
    // Démarrer le fondu du Game Over
    gameOverFadeStartFrame = frameCount;
    gameOverFadeAlpha = 0;
    
    // Update high score
    if (score > highScore) {
      highScore = score;
      if (player != null) {
        highScoreName = player.playerName;
      }
    }
    
    println("GAME OVER!");
    println("Score final de " + player.playerName + ": " + score);
    println("Meilleur score : " + highScore + " par " + highScoreName);
  }
  
  void addScore(int points) {
    score += points;
  }
  
  void reset() {
    score = 0;
    gameState = "PLAYING";
    isPaused = false;
  }
}
