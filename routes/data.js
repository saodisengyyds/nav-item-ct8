const express = require('express');
const db = require('../db');
const auth = require('./authMiddleware');
const router = express.Router();

// 导出数据
router.get('/export', auth, (req, res) => {
  const data = {
    version: 1,
    exportedAt: new Date().toISOString(),
    app: 'nav-item-ct8',
    data: {}
  };

  const promises = [
    new Promise(resolve => db.all('SELECT * FROM menus ORDER BY "order", id', (err, rows) => resolve({ key: 'menus', rows: rows || [] }))),
    new Promise(resolve => db.all('SELECT * FROM sub_menus ORDER BY parent_id, "order", id', (err, rows) => resolve({ key: 'sub_menus', rows: rows || [] }))),
    new Promise(resolve => db.all('SELECT * FROM cards ORDER BY COALESCE(menu_id, 0), COALESCE(sub_menu_id, 0), "order", id', (err, rows) => resolve({ key: 'cards', rows: rows || [] }))),
    new Promise(resolve => db.all('SELECT * FROM ads ORDER BY id', (err, rows) => resolve({ key: 'ads', rows: rows || [] }))),
    new Promise(resolve => db.all('SELECT * FROM friends ORDER BY id', (err, rows) => resolve({ key: 'friends', rows: rows || [] })))
  ];

  Promise.all(promises).then(results => {
    results.forEach(result => {
      data.data[result.key] = result.rows;
    });
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="nav-item-backup-${new Date().toISOString().slice(0, 10)}.json"`);
    res.json(data);
  }).catch(err => {
    res.status(500).json({ message: '导出失败: ' + err.message });
  });
});

// 导入数据
router.post('/import', auth, (req, res) => {
  const payload = req.body || {};
  const data = payload.data || payload;
  
  const menus = Array.isArray(data.menus) ? data.menus : [];
  const subMenus = Array.isArray(data.sub_menus) ? data.sub_menus : (Array.isArray(data.subMenus) ? data.subMenus : []);
  const cards = Array.isArray(data.cards) ? data.cards : [];
  const ads = Array.isArray(data.ads) ? data.ads : [];
  const friends = Array.isArray(data.friends) ? data.friends : [];

  if (!Array.isArray(menus) || !Array.isArray(subMenus) || !Array.isArray(cards)) {
    return res.status(400).json({ message: '导入文件格式错误' });
  }

  db.serialize(() => {
    db.run('BEGIN TRANSACTION');
    
    // 清空旧数据
    db.run('DELETE FROM cards');
    db.run('DELETE FROM sub_menus');
    db.run('DELETE FROM menus');
    db.run('DELETE FROM ads');
    db.run('DELETE FROM friends');

    // 插入新数据
    const insertMenu = db.prepare('INSERT INTO menus (id, name, "order") VALUES (?, ?, ?)');
    menus.forEach(r => {
      if (r.name) insertMenu.run([r.id || null, String(r.name), Number(r.order) || 0]);
    });
    insertMenu.finalize();

    const insertSubMenu = db.prepare('INSERT INTO sub_menus (id, parent_id, name, "order") VALUES (?, ?, ?, ?)');
    subMenus.forEach(r => {
      if (r.parent_id && r.name) insertSubMenu.run([r.id || null, r.parent_id, String(r.name), Number(r.order) || 0]);
    });
    insertSubMenu.finalize();

    const insertCard = db.prepare('INSERT INTO cards (id, menu_id, sub_menu_id, title, url, logo_url, custom_logo_path, desc, "order") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)');
    cards.forEach(r => {
      if (r.title && r.url) insertCard.run([r.id || null, r.menu_id || null, r.sub_menu_id || null, String(r.title), String(r.url), r.logo_url || '', r.custom_logo_path || '', r.desc || '', Number(r.order) || 0]);
    });
    insertCard.finalize();

    const insertAd = db.prepare('INSERT INTO ads (id, position, img, url) VALUES (?, ?, ?, ?)');
    ads.forEach(r => {
      if (r.position && r.img && r.url) insertAd.run([r.id || null, String(r.position), String(r.img), String(r.url)]);
    });
    insertAd.finalize();

    const insertFriend = db.prepare('INSERT INTO friends (id, title, url, logo) VALUES (?, ?, ?, ?)');
    friends.forEach(r => {
      if (r.title && r.url) insertFriend.run([r.id || null, String(r.title), String(r.url), r.logo || '']);
    });
    insertFriend.finalize();

    db.run('COMMIT', (err) => {
      if (err) {
        db.run('ROLLBACK');
        return res.status(500).json({ message: '导入失败: ' + err.message });
      }
      res.json({
        message: '导入成功',
        imported: { menus: menus.length, sub_menus: subMenus.length, cards: cards.length, ads: ads.length, friends: friends.length }
      });
    });
  });
});

module.exports = router;
