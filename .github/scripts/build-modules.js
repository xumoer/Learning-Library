#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const LIBRARY_DIR = path.join(__dirname, '..', '..', 'library');
const OUTPUT_FILE = path.join(__dirname, '..', '..', 'modules.js');

const META_FIELDS = ['title', 'blurb', 'type', 'category', 'code', 'tags', 'status', 'steps', 'progress'];

function findHtmlFiles(dir) {
  const results = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results.push(...findHtmlFiles(full));
    } else if (entry.name.endsWith('.html')) {
      results.push(full);
    }
  }
  return results.sort();
}

function parseMeta(html) {
  const meta = {};
  for (const field of META_FIELDS) {
    const re = new RegExp(`<meta\\s+name=["']${field}["']\\s+content="([^"]*)"`, 'i');
    const m = html.match(re);
    if (m) { meta[field] = m[1]; continue; }
    const re2 = new RegExp(`<meta\\s+name=["']${field}["']\\s+content='([^']*)'`, 'i');
    const m2 = html.match(re2);
    if (m2) meta[field] = m2[1];
  }
  return meta;
}

function buildModule(meta, href) {
  const m = {};
  if (!meta.title || !meta.type) return null;

  m.title = meta.title.replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"');
  m.blurb = (meta.blurb || '').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"');
  m.type = meta.type;
  if (meta.category) m.category = meta.category;
  if (meta.code) m.code = meta.code;
  if (meta.tags) m.tags = meta.tags.split(',').map(t => t.trim()).filter(Boolean);
  if (meta.status) m.status = meta.status;
  m.href = href;
  if (meta.steps) m.steps = parseInt(meta.steps, 10);
  if (meta.progress != null) m.progress = parseInt(meta.progress, 10);

  return m;
}

function formatValue(val, indent) {
  if (Array.isArray(val)) {
    const items = val.map(v => JSON.stringify(v)).join(', ');
    return `[${items}]`;
  }
  if (typeof val === 'number') return String(val);
  return JSON.stringify(val);
}

function formatModule(m) {
  const lines = [];
  const order = ['title', 'blurb', 'type', 'category', 'code', 'tags', 'status', 'href', 'steps', 'progress'];
  const maxKey = Math.max(...order.filter(k => k in m).map(k => k.length));
  for (const key of order) {
    if (!(key in m)) continue;
    const pad = ' '.repeat(maxKey - key.length);
    lines.push(`    ${key}:${pad}    ${formatValue(m[key])}`);
  }
  return `  {\n${lines.join(',\n')}\n  }`;
}

const files = findHtmlFiles(LIBRARY_DIR);
const modules = [];

for (const file of files) {
  const html = fs.readFileSync(file, 'utf8');
  const meta = parseMeta(html);
  const rel = path.relative(path.join(LIBRARY_DIR, '..'), file).replace(/\\/g, '/');
  const mod = buildModule(meta, rel);
  if (mod) modules.push(mod);
}

const header = `/*
 * ┌──────────────────────────────────────────────────────────────────┐
 * │  AUTO-GENERATED — do not edit by hand.                          │
 * │  Built by .github/scripts/build-modules.js from <meta> tags     │
 * │  in each library/ HTML file. Push to main and the workflow       │
 * │  regenerates this file automatically.                            │
 * │                                                                  │
 * │  To add a document: create your HTML in library/<name>/,         │
 * │  include the required <meta> tags, push, done.                   │
 * └──────────────────────────────────────────────────────────────────┘
 *
 * Required <meta> tags in each document:
 *   <meta name="title"    content="Your Title">
 *   <meta name="blurb"    content="Short description.">
 *   <meta name="type"     content="Tutorial|Info|Rules|Plan|…">
 *
 * Optional:
 *   <meta name="category" content="Topic">
 *   <meta name="code"     content="TUT">
 *   <meta name="tags"     content="tag1, tag2, tag3">
 *   <meta name="status"   content="solid|learning|planned">
 *   <meta name="steps"    content="10">
 *   <meta name="progress" content="0">
 */`;

const body = modules.map(formatModule).join(',\n');
const output = `${header}\nwindow.MODULES = [\n${body}\n];\n`;

fs.writeFileSync(OUTPUT_FILE, output, 'utf8');
console.log(`modules.js updated — ${modules.length} module(s) found.`);
