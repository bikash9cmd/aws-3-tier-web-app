/**
 * 3-Tier Web App – Application Tier
 * Node.js + Express REST API
 * Author: Bikash Kushwaha
 */

const express = require('express');
const mysql = require('mysql2/promise');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// ─── Middleware ───────────────────────────────
app.use(express.json());
app.use(express.static(path.join(__dirname, '..', 'public')));

// ─── DB Connection Pool ───────────────────────
let pool;

async function initDB() {
  if (!process.env.DB_HOST || process.env.DB_HOST === '') {
    console.log('⚠️  No DB_HOST set – running without database');
    return;
  }
  try {
    pool = await mysql.createPool({
      host:     process.env.DB_HOST,
      user:     process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
      port:     3306,
      waitForConnections: true,
      connectionLimit:    10,
      queueLimit:         0,
    });
    // Create table if not exists
    await pool.execute(`
      CREATE TABLE IF NOT EXISTS items (
        id        INT AUTO_INCREMENT PRIMARY KEY,
        name      VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Connected to RDS MySQL');
  } catch (err) {
    console.error('❌ DB connection failed:', err.message);
  }
}

// ─── Health Check ─────────────────────────────
app.get('/health', (req, res) => {
  res.json({
    status:      'healthy',
    tier:        'application',
    environment: process.env.NODE_ENV || 'development',
    timestamp:   new Date().toISOString(),
    db:          pool ? 'connected' : 'not configured',
  });
});

// ─── API: Get all items ───────────────────────
app.get('/api/items', async (req, res) => {
  if (!pool) return res.json({ items: [], message: 'DB not configured' });
  try {
    const [rows] = await pool.execute('SELECT * FROM items ORDER BY created_at DESC');
    res.json({ items: rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── API: Create item ─────────────────────────
app.post('/api/items', async (req, res) => {
  const { name } = req.body;
  if (!name) return res.status(400).json({ error: 'name is required' });
  if (!pool) return res.status(503).json({ error: 'DB not configured' });
  try {
    const [result] = await pool.execute('INSERT INTO items (name) VALUES (?)', [name]);
    res.status(201).json({ id: result.insertId, name });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── API: Delete item ─────────────────────────
app.delete('/api/items/:id', async (req, res) => {
  if (!pool) return res.status(503).json({ error: 'DB not configured' });
  try {
    await pool.execute('DELETE FROM items WHERE id = ?', [req.params.id]);
    res.json({ message: 'Deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── Catch-all: serve frontend ────────────────
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, '..', 'public', 'index.html'));
});

// ─── Start ────────────────────────────────────
initDB().then(() => {
  app.listen(PORT, () => {
    console.log(`🚀 App running on port ${PORT}`);
  });
});
