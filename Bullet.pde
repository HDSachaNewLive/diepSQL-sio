class Bullet {
  float x, y;
  float taille = 12;
  float speed;
  PVector velocity;
  float damage;
  float degatsInitiaux;
  boolean fromPlayer;
  int lifetime = 180;
  float freinageBullet = 0.97;
  float opacite = 255;
  float vitesseInitiale;
  float seuilFade = 0.35;
  float seuilDegats = 0.75;

  // Pénétration : nombre de formes/ennemis que la balle peut encore traverser
  float pvPenetration;
  float pvPenetrationMax;

  // Immunité par objet touché : évite de frapper la même forme plusieurs frames de suite
  // On stocke un identifiant temporel : la frame à partir de laquelle cet objet est
  // à nouveau hittable. Clé = référence objet (hashCode), valeur = frameCount cible.
  java.util.HashMap<Integer, Integer> immunites = new java.util.HashMap<Integer, Integer>();
  int dureeImmunite = 20; // frames d'immunité après un impact

  // Effet d'impact visuel (agrandissement + fade)
  boolean enImpact = false;
  float tailleImpact = 0;
  float opaciteImpact = 0;
  int dureeAnimation = 8;
  int timerAnimation = 0;
  color couleurImpact;

  Bullet(float x, float y, float angle, float damage, boolean fromPlayer) {
    this(x, y, angle, damage, fromPlayer, 12, 1);
  }

  Bullet(float x, float y, float angle, float damage, boolean fromPlayer, float speed) {
    this(x, y, angle, damage, fromPlayer, speed, 1);
  }

  Bullet(float x, float y, float angle, float damage, boolean fromPlayer, float speed, float penetration) {
    this.x = x;
    this.y = y;
    this.damage = damage;
    this.degatsInitiaux = damage;
    this.fromPlayer = fromPlayer;
    this.speed = speed;
    this.vitesseInitiale = speed;
    this.pvPenetration = penetration;
    this.pvPenetrationMax = penetration;
    couleurImpact = fromPlayer ? color(0, 210, 255) : color(255, 140, 80);

    velocity = new PVector(cos(angle), sin(angle));
    velocity.mult(speed);
  }

  void update() {
    x += velocity.x;
    y += velocity.y;
    velocity.mult(freinageBullet);
    lifetime--;

    float vitesseActuelle = velocity.mag();
    float ratio = vitesseActuelle / vitesseInitiale;
    if (ratio < seuilFade) {
      opacite = map(ratio, 0, seuilFade, 0, 255);
    }
    if (ratio < seuilDegats) {
      damage = degatsInitiaux * map(ratio, 0, seuilDegats, 0, 1);
    } else {
      damage = degatsInitiaux;
    }

    if (enImpact) {
      timerAnimation++;
      float prog = (float)timerAnimation / dureeAnimation;
      tailleImpact  = lerp(taille * 1.2, taille * 2.8, prog);
      opaciteImpact = lerp(200, 0, prog);
      if (timerAnimation >= dureeAnimation) {
        enImpact = false;
        timerAnimation = 0;
      }
    }
  }

  // Vérifie si cet objet est encore immunisé (ne peut pas être retouché)
  boolean estImmunise(Object cible) {
    Integer cle = System.identityHashCode(cible);
    if (!immunites.containsKey(cle)) return false;
    return frameCount < immunites.get(cle);
  }

  // Enregistre l'impact sur cet objet et renvoie true si la balle est détruite
  boolean appliquerImpact(Object cible) {
    // Marquer l'immunité pour cet objet
    Integer cle = System.identityHashCode(cible);
    immunites.put(cle, frameCount + dureeImmunite);

    declencherEffetImpact();

    pvPenetration -= 1;
    // Ralentissement à l'impact : plus fort si pénétration faible
    float facteurRalentissement = map(pvPenetration, 0, pvPenetrationMax, 0.5, 0.85);
    facteurRalentissement = constrain(facteurRalentissement, 0.4, 0.9);
    velocity.mult(facteurRalentissement);

    return pvPenetration <= 0;
  }

  void declencherEffetImpact() {
    enImpact = true;
    timerAnimation = 0;
  }

  void display() {
    color couleurPrincipale = fromPlayer ? color(0, 176, 255) : color(255, 100, 100);
    color couleurBordure    = fromPlayer ? color(0, 141, 204) : color(200, 80, 80);

    if (enImpact && opaciteImpact > 0) {
      noFill();
      stroke(red(couleurImpact), green(couleurImpact), blue(couleurImpact), opaciteImpact);
      strokeWeight(2.5);
      circle(x, y, tailleImpact * 2);
    }

    fill(red(couleurPrincipale), green(couleurPrincipale), blue(couleurPrincipale), opacite);
    stroke(red(couleurBordure), green(couleurBordure), blue(couleurBordure), opacite);
    strokeWeight(2);
    circle(x, y, taille * 2);
  }

  boolean isOffScreen() {
    float maxDist = 1200;
    return dist(x, y, player.x, player.y) > maxDist || lifetime <= 0 || opacite <= 0;
  }

  boolean estDetruite() {
    return pvPenetration <= 0;
  }
}
