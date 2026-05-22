# DIEP.IO - Version Améliorée v2.1

## 🆕 Nouvelles corrections (v2.1)

### ✅ 1. Barres de vie horizontales pour les polygones
**Shape.pde :**
- Les barres de vie restent **toujours horizontales** même quand les polygones tournent
- Utilisation de `popMatrix()` après la rotation du polygone
- Meilleure lisibilité de l'état de santé des formes

### ✅ 2. Game Over en fondu transparent par-dessus le jeu
**Comportement amélioré :**
- Le jeu **continue de tourner** après la mort du joueur (pas de démo séparée)
- Les ennemis continuent leurs actions
- Les formes continuent de spawner et d'être détruites
- **Fondu progressif** de 0.5 secondes (30 frames à 60fps)
- Overlay semi-transparent qui s'intensifie de 0 à 230 d'opacité
- Menu Game Over apparaît progressivement par-dessus l'action

**Fichiers modifiés :**
- `diep_game.pde` - Gestion du fondu et continuation du jeu
- `GameManager.pde` - Initialisation du timer de fondu au lieu de démo

### ✅ 3. Canon aligné avec les tirs dans la démo du menu
**Tank.pde :**
- Nouvelle variable `demoAngle` pour contrôler l'angle du canon
- Le canon pointe dans la **même direction** que les bullets
- Pas d'utilisation de la souris dans la démo (`isPlayer = false`)

**diep_game.pde :**
- `updateMenuDemo()` définit `demoAngle` pour synchroniser canon et tirs
- Rotation fluide du canon qui suit le mouvement circulaire

---

## 📋 Modifications v2.0

### ✅ 1. Correction de la classe Bullet
**Bullet.pde :**
- **Variable `speed` uniformisée** : Correction de `bulletSpeed` → `speed` pour cohérence
- Gestion correcte de la vitesse des projectiles
- Code plus propre et maintenable

### ✅ 2. IA des ennemis grandement améliorée
**Enemy.pde - Nouveaux états :**
- **PATROL** : Patrouille normale dans la zone
- **CHASE** : Détecte et suit le joueur sans tirer
- **ATTACK** : Combat actif avec esquives et tirs
- **FLEE** : Fuite intelligente quand vie basse
- **REGROUP** : Retour au centre de la map pour éviter les coins

**Améliorations intelligentes :**
- ✨ **Détection de coins** : L'ennemi détecte s'il est coincé dans un coin de la map
- ✨ **Timer de fuite** : Après 5 secondes de fuite, l'ennemi passe en mode REGROUP
- ✨ **Fuite intelligente** : Évite les bords de la map lors de la fuite
- ✨ **Mode REGROUP** : Retourne vers le centre de la map au lieu de rester coincé
- ✨ **Transitions automatiques** : Change de mode selon la situation (santé, position, distance au joueur)
- ✨ **Seuil de regroup** : Si vie < 50%, retour au centre pour se repositionner

---

## 📋 Modifications v1.0

### ✅ 1. Menu transparent avec démo animée
- Le menu principal affiche une démo en arrière-plan
- Un joueur tourne en cercle et tire automatiquement
- Des formes destructibles autour du joueur
- Overlay semi-transparent (220 d'opacité)

### ✅ 2. Saisie de nom dans le menu
- Champ de saisie cliquable
- Maximum 15 caractères
- Curseur clignotant quand actif
- Support de BACKSPACE et ENTER
- Bouton PLAY actif uniquement si nom entré
- Nom affiché en haut à gauche pendant la partie

### ✅ 3. Densité augmentée des formes destructibles
**Spawner.pde :**
- Triangles : spawn toutes les 60 frames (au lieu de 120)
- Carrés : spawn toutes les 90 frames (au lieu de 180)
- Pentagones : spawn toutes les 400 frames (au lieu de 600)
- Limite totale : 120 formes maximum (au lieu de 50)

### ✅ 4. Cadence de tir et vitesse des bullets réduites
**Tank.pde :**
- `fireRate = 20` (au lieu de 10) - tire 2x moins vite
- `bulletSpeed = 8` (au lieu de 12) - bullets 33% plus lentes
- Amélioration Reload : `-2` par niveau (au lieu de -1), minimum 5 frames
- Amélioration Bullet Speed : `+0.8` par niveau (au lieu de +1)

### ✅ 5. Interface d'amélioration plus grande et belle
**UI.pde - Menu d'amélioration :**
- Boutons : **350x45 pixels** (au lieu de 280x35)
- Texte nom de stat : **17pt** (au lieu de 14pt)
- Texte touche : **15pt** (au lieu de 12pt)
- Barre de progression : **85x28 pixels** (au lieu de 70x20)
- Texte niveau : **14pt** (au lieu de 11pt)
- Bouton + : **35x35 pixels** (au lieu de 25x25)
- Texte bouton + : **24pt** (au lieu de 18pt)

---

## 🎮 Comment jouer

1. **Lancez le jeu** avec Processing
2. **Cliquez sur le champ** de saisie et entrez votre nom
3. Cliquez sur **"PLAY!"** ou appuyez sur **ENTER**
4. Utilisez **ZQSD** ou les **flèches** pour vous déplacer
5. **Visez avec la souris** et maintenez le clic pour tirer
6. **Détruisez les formes** pour gagner de l'XP
7. **Améliorez vos stats** avec les touches **1-8** ou en cliquant sur les boutons **+**

---

## 📊 Statistiques disponibles

1. **Health Regen** [1] - Régénération de vie
2. **Max Health** [2] - Vie maximale
3. **Body Damage** [3] - Dégâts au contact
4. **Bullet Speed** [4] - Vitesse des projectiles
5. **Bullet Penetration** [5] - Pénétration des projectiles
6. **Bullet Damage** [6] - Dégâts des projectiles
7. **Reload** [7] - Cadence de tir
8. **Movement Speed** [8] - Vitesse de déplacement

---

## 🤖 Comportement de l'IA ennemie

### États et transitions :
```
PATROL → Détecte joueur → CHASE → Joueur proche → ATTACK
                                              ↓
                                         Vie basse
                                              ↓
                    REGROUP ← Timer max ← FLEE
                       ↓
                  Retour centre
                       ↓
                    PATROL
```

### Logique de décision :
1. **Vie < 30% ET pas dans un coin** → **FLEE**
2. **Dans un coin OU fuite trop longue OU vie < 50%** → **REGROUP**
3. **Joueur < 250px** → **ATTACK**
4. **Joueur < 350px** → **CHASE**
5. **Sinon** → **PATROL**

---

## 🎯 Détails techniques

### Game Over en fondu :
```java
// Calcul du fondu sur 0.5 secondes (30 frames à 60fps)
int framesSinceGameOver = frameCount - gameOverFadeStartFrame;
gameOverFadeAlpha = min(230, framesSinceGameOver * (230.0 / 30.0));
```

### Barres de vie des polygones :
```java
// Le polygone tourne
pushMatrix();
rotate(rotation);
// ... dessiner le polygone ...
popMatrix(); // Fin de rotation

// La barre de vie reste horizontale
rect(-barWidth/2, -size - 10, barWidth, barHeight);
```

### Canon de la démo :
```java
// Dans Tank.display()
if (isPlayer) {
  angle = atan2(mouseWorldY - y, mouseWorldX - x); // Souris
} else {
  angle = demoAngle; // Angle fixé pour la démo
}
```

---

## 📁 Fichiers modifiés

### Version 2.1 (nouvelles corrections) :
- ✏️ `Shape.pde` - Barres de vie horizontales
- ✏️ `diep_game.pde` - Game Over en fondu + canon démo aligné
- ✏️ `GameManager.pde` - Timer de fondu au lieu de démo
- ✏️ `Tank.pde` - Variable demoAngle pour la démo

### Version 2.0 :
- ✏️ `Bullet.pde` - Correction de la variable `speed`
- ✏️ `Enemy.pde` - IA complètement refaite avec 5 états intelligents

### Version 1.0 :
- ✏️ `diep_game.pde` - Menu transparent avec démo + saisie de nom
- ✏️ `Tank.pde` - Cadence et vitesse de tir réduites
- ✏️ `Spawner.pde` - Densité augmentée
- ✏️ `UI.pde` - Interface plus grande et belle

### Fichiers inchangés :
- ✅ `Particle.pde`
- ✅ `sketch.properties`

---

## 🎯 Objectifs du projet

Ce projet est réalisé dans le cadre du **BTS SIO 1ère année** (DEV SLAM) et vise à :
- Maîtriser la POO (Programmation Orientée Objet) en Java/Processing
- Implémenter des systèmes de jeu complexes (IA, collisions, particules)
- Créer des interfaces utilisateur intuitives
- Gérer des états de jeu et des transitions fluides
- Optimiser l'expérience utilisateur (animations, fondus, feedback visuel)

---

## 🐛 Debug et développement

Pour activer l'affichage de l'état de l'IA, décommentez dans `Enemy.pde` :
```java
// Dans la méthode display()
fill(255);
textAlign(CENTER);
textSize(10);
text(state, 0, size + 25);
```

---

## ✨ Points forts de cette version

1. **Barres de vie lisibles** - Toujours horizontales, faciles à lire
2. **Game Over immersif** - Le jeu continue, effet de fondu cinématique
3. **Démo menu cohérente** - Canon et tirs parfaitement synchronisés
4. **IA ennemie intelligente** - 5 états avec transitions naturelles
5. **Interface soignée** - Grands boutons, animations fluides

---

Bon jeu ! 🎮 🚀

**Version 2.1** - Février 2026
