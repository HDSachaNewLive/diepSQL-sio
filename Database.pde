// =============================================================================
// Database.pde - Système de persistance des données
// =============================================================================
//
// ARCHITECTURE JDBC (pour intégration future avec SQLite) :
// ----------------------------------------------------------
// Pour activer JDBC, placer sqlite-jdbc-3.x.x.jar dans le dossier /code/
// du sketch Processing, puis décommenter la section JDBC ci-dessous.
//
// Schéma SQL :
//   CREATE TABLE IF NOT EXISTS users (
//     id       INTEGER PRIMARY KEY AUTOINCREMENT,
//     username TEXT UNIQUE NOT NULL,
//     password TEXT NOT NULL,           -- hashé en SHA-256
//     coins    INTEGER DEFAULT 0
//   );
//   CREATE TABLE IF NOT EXISTS purchases (
//     id        INTEGER PRIMARY KEY AUTOINCREMENT,
//     user_id   INTEGER NOT NULL,
//     item_id   TEXT NOT NULL,
//     bought_at DATETIME DEFAULT CURRENT_TIMESTAMP,
//     FOREIGN KEY(user_id) REFERENCES users(id)
//   );
//
// Exemple d'utilisation JDBC :
//   import java.sql.*;
//   Connection conn = DriverManager.getConnection("jdbc:sqlite:diep_data.db");
//   PreparedStatement ps = conn.prepareStatement(
//     "INSERT INTO users(username,password,coins) VALUES(?,?,?)");
//   ps.setString(1, username);
//   ps.setString(2, hashPassword(password));
//   ps.setInt(3, 0);
//   ps.executeUpdate();
//   Voir: https://docs.oracle.com/javase/tutorial/jdbc/basics/processingsqlstatements.html
//
// IMPLÉMENTATION ACTUELLE : Fichier texte structuré (JSON-like)
// Fichiers stockés à la racine du sketch (users.dat, purchases.dat)
// =============================================================================

import java.io.*;
import java.util.*;
import java.security.MessageDigest;

class Database {

  // --- Chemins des fichiers de données ---
  private String dataPath;
  private String usersFile;
  private String purchasesFile;

  // --- Cache en mémoire ---
  private ArrayList<UserRecord>    cachedUsers     = new ArrayList<UserRecord>();
  private ArrayList<PurchaseRecord> cachedPurchases = new ArrayList<PurchaseRecord>();

  // --- Utilisateur connecté ---
  UserRecord currentUser = null;

  Database() {
    dataPath       = sketchPath("");
    usersFile      = dataPath + "users.dat";
    purchasesFile  = dataPath + "purchases.dat";

    File dir = new File(dataPath);
    if (!dir.exists()) dir.mkdirs();

    loadAll();
    println("[DB] Initialisée. " + cachedUsers.size() + " utilisateurs chargés.");
  }

  // ===========================================================================
  // AUTHENTIFICATION
  // ===========================================================================

  // Retourne true si le compte a été créé, false si le nom existe déjà
  boolean registerUser(String username, String password) {
    username = username.trim();
    if (username.length() == 0 || password.length() == 0) return false;

    for (UserRecord u : cachedUsers) {
      if (u.username.equalsIgnoreCase(username)) return false; // Déjà pris
    }

    int newId = cachedUsers.size() + 1;
    UserRecord newUser = new UserRecord(newId, username, hashPassword(password), 0);
    cachedUsers.add(newUser);
    saveUsers();
    println("[DB] Nouveau compte : " + username);
    return true;
  }

  // Retourne l'utilisateur si login OK, null sinon
  UserRecord loginUser(String username, String password) {
    username = username.trim();
    String hashed = hashPassword(password);

    for (UserRecord u : cachedUsers) {
      if (u.username.equalsIgnoreCase(username) && u.password.equals(hashed)) {
        currentUser = u;
        println("[DB] Connecté : " + u.username + " | Pièces : " + u.coins);
        return u;
      }
    }
    return null;
  }

  void logout() {
    if (currentUser != null) {
      saveUsers(); // Sauvegarde avant déco
      println("[DB] Déconnecté : " + currentUser.username);
    }
    currentUser = null;
  }

  // ===========================================================================
  // PIÈCES (COINS)
  // ===========================================================================

  int getCoins() {
    if (currentUser == null) return 0;
    return currentUser.coins;
  }

  void addCoins(int amount) {
    if (currentUser == null) return;
    currentUser.coins += amount;
    // Synchronise dans la liste
    for (UserRecord u : cachedUsers) {
      if (u.id == currentUser.id) {
        u.coins = currentUser.coins;
        break;
      }
    }
    saveUsers();
  }

  // Retourne true si la dépense a réussi (assez de pièces)
  boolean spendCoins(int amount) {
    if (currentUser == null || currentUser.coins < amount) return false;
    currentUser.coins -= amount;
    for (UserRecord u : cachedUsers) {
      if (u.id == currentUser.id) {
        u.coins = currentUser.coins;
        break;
      }
    }
    saveUsers();
    return true;
  }

  // ===========================================================================
  // ACHATS
  // ===========================================================================

  // Enregistre un achat (item_id = identifiant de l'objet boutique)
  void recordPurchase(String itemId) {
    if (currentUser == null) return;
    PurchaseRecord p = new PurchaseRecord(cachedPurchases.size() + 1, currentUser.id, itemId, System.currentTimeMillis());
    cachedPurchases.add(p);
    savePurchases();
    println("[DB] Achat enregistré : " + itemId + " par " + currentUser.username);
  }

  // Retourne tous les achats de l'utilisateur courant
  ArrayList<String> getUserPurchases() {
    ArrayList<String> result = new ArrayList<String>();
    if (currentUser == null) return result;
    for (PurchaseRecord p : cachedPurchases) {
      if (p.userId == currentUser.id) result.add(p.itemId);
    }
    return result;
  }

  // ===========================================================================
  // HIGHSCORES
  // ===========================================================================

  int getUserHighScore() {
    if (currentUser == null) return 0;
    return currentUser.highScore;
  }

  void updateHighScore(int score) {
    if (currentUser == null || score <= currentUser.highScore) return;
    currentUser.highScore = score;
    for (UserRecord u : cachedUsers) {
      if (u.id == currentUser.id) {
        u.highScore = score;
        break;
      }
    }
    saveUsers();
  }

  // Top 5 scores toutes pièces confondues
  ArrayList<UserRecord> getLeaderboard() {
    ArrayList<UserRecord> sorted = new ArrayList<UserRecord>(cachedUsers);
    // Tri à bulles simple (liste courte)
    for (int i = 0; i < sorted.size(); i++) {
      for (int j = i+1; j < sorted.size(); j++) {
        if (sorted.get(j).highScore > sorted.get(i).highScore) {
          UserRecord tmp = sorted.get(i);
          sorted.set(i, sorted.get(j));
          sorted.set(j, tmp);
        }
      }
    }
    ArrayList<UserRecord> top5 = new ArrayList<UserRecord>();
    for (int i = 0; i < min(5, sorted.size()); i++) top5.add(sorted.get(i));
    return top5;
  }

  // ===========================================================================
  // PERSISTANCE FICHIER
  // ===========================================================================

  private void loadAll() {
    cachedUsers     = new ArrayList<UserRecord>();
    cachedPurchases = new ArrayList<PurchaseRecord>();

    // --- Charger les utilisateurs ---
    try {
      BufferedReader br = new BufferedReader(new FileReader(usersFile));
      String line;
      while ((line = br.readLine()) != null) {
        line = line.trim();
        if (line.startsWith("#") || line.length() == 0) continue;
        String[] parts = line.split("\\|");
        if (parts.length >= 4) {
          int id        = int(parts[0]);
          String uname  = parts[1];
          String passwd = parts[2];
          int coins     = int(parts[3]);
          int hs        = parts.length >= 5 ? int(parts[4]) : 0;
          cachedUsers.add(new UserRecord(id, uname, passwd, coins, hs));
        }
      }
      br.close();
    }
    catch (Exception e) {
      println("[DB] Fichier users.dat absent ou vide, création.");
    }

    // --- Charger les achats ---
    try {
      BufferedReader br = new BufferedReader(new FileReader(purchasesFile));
      String line;
      while ((line = br.readLine()) != null) {
        line = line.trim();
        if (line.startsWith("#") || line.length() == 0) continue;
        String[] parts = line.split("\\|");
        if (parts.length >= 3) {
          long ts = parts.length >= 4 ? Long.parseLong(parts[3]) : 0L;
          cachedPurchases.add(new PurchaseRecord(int(parts[0]), int(parts[1]), parts[2], ts));
        }
      }
      br.close();
    }
    catch (Exception e) {
      println("[DB] Fichier purchases.dat absent ou vide.");
    }
  }

  private void saveUsers() {
    try {
      PrintWriter pw = new PrintWriter(new FileWriter(usersFile));
      pw.println("# id|username|password_hash|coins|highscore");
      for (UserRecord u : cachedUsers) {
        pw.println(u.id + "|" + u.username + "|" + u.password + "|" + u.coins + "|" + u.highScore);
      }
      pw.close();
    }
    catch (Exception e) {
      println("[DB] Erreur sauvegarde users : " + e.getMessage());
    }
  }

  private void savePurchases() {
    try {
      PrintWriter pw = new PrintWriter(new FileWriter(purchasesFile));
      pw.println("# id|user_id|item_id|timestamp");
      for (PurchaseRecord p : cachedPurchases) {
        pw.println(p.id + "|" + p.userId + "|" + p.itemId + "|" + p.timestamp);
      }
      pw.close();
    }
    catch (Exception e) {
      println("[DB] Erreur sauvegarde achats : " + e.getMessage());
    }
  }

  // ===========================================================================
  // UTILITAIRES
  // ===========================================================================

  // Hash SHA-256 simple du mot de passe
  private String hashPassword(String pwd) {
    try {
      MessageDigest md = MessageDigest.getInstance("SHA-256");
      byte[] hash = md.digest(pwd.getBytes("UTF-8"));
      StringBuilder sb = new StringBuilder();
      for (byte b : hash) sb.append(String.format("%02x", b));
      return sb.toString();
    }
    catch (Exception e) {
      return pwd; // Fallback si SHA-256 indisponible
    }
  }
}

// ===========================================================================
// MODÈLES DE DONNÉES (équivalent des lignes SQL)
// ===========================================================================

class UserRecord {
  int    id;
  String username;
  String password; // SHA-256
  int    coins;
  int    highScore;

  UserRecord(int id, String username, String password, int coins) {
    this(id, username, password, coins, 0);
  }

  UserRecord(int id, String username, String password, int coins, int highScore) {
    this.id        = id;
    this.username  = username;
    this.password  = password;
    this.coins     = coins;
    this.highScore = highScore;
  }
}

class PurchaseRecord {
  int    id;
  int    userId;
  String itemId;
  long   timestamp;

  PurchaseRecord(int id, int userId, String itemId, long timestamp) {
    this.id        = id;
    this.userId    = userId;
    this.itemId    = itemId;
    this.timestamp = timestamp;
  }
}
