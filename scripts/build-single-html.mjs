#!/usr/bin/env node

import { execSync } from 'node:child_process'
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { dirname, extname, isAbsolute, relative, resolve } from 'node:path'
import { pathToFileURL } from 'node:url'

const MIME_TYPES = {
  '.avif': 'image/avif',
  '.bmp': 'image/bmp',
  '.css': 'text/css',
  '.eot': 'application/vnd.ms-fontobject',
  '.gif': 'image/gif',
  '.ico': 'image/x-icon',
  '.jpeg': 'image/jpeg',
  '.jpg': 'image/jpeg',
  '.js': 'text/javascript',
  '.json': 'application/json',
  '.mjs': 'text/javascript',
  '.mp3': 'audio/mpeg',
  '.mp4': 'video/mp4',
  '.ogg': 'audio/ogg',
  '.otf': 'font/otf',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.ttf': 'font/ttf',
  '.wav': 'audio/wav',
  '.webm': 'video/webm',
  '.webp': 'image/webp',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
}

function printHelp() {
  console.log(`
Build a self-contained HTML file from a Vite build.

Usage:
  node build-single-html.mjs [options]

Options:
  --project <dir>         Project directory (default: current directory)
  --dist <dir>            Vite output directory, relative to project (default: dist)
  --entry <file>          Built HTML entry inside dist (default: index.html)
  --output <file>         Output file, relative to project
                          (default: dist/<entry>.standalone.html)
  --build-command <cmd>   Build command (default: pnpm run build)
  --no-build              Skip the build step and package the existing dist
  --help                  Show this help

Examples:
  node build-single-html.mjs
  node build-single-html.mjs --entry dashboard.html
  node build-single-html.mjs --entry dashboard.html --output dist/大屏离线版.html
  node build-single-html.mjs --no-build --dist build --entry app.html
`)
}

function parseArgs(argv) {
  const options = {
    project: process.cwd(),
    dist: 'dist',
    entry: 'index.html',
    output: '',
    buildCommand: 'pnpm run build',
    build: true,
  }

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i]
    if (arg === '--help') {
      printHelp()
      process.exit(0)
    }
    if (arg === '--no-build') {
      options.build = false
      continue
    }
    const valueOptions = {
      '--project': 'project',
      '--dist': 'dist',
      '--entry': 'entry',
      '--output': 'output',
      '--build-command': 'buildCommand',
    }
    const key = valueOptions[arg]
    if (!key) throw new Error(`Unknown option: ${arg}`)
    const value = argv[i + 1]
    if (!value || value.startsWith('--')) throw new Error(`Missing value for ${arg}`)
    options[key] = value
    i += 1
  }

  return options
}

function stripQueryAndHash(value) {
  return value.split(/[?#]/, 1)[0]
}

function isRemoteOrEmbedded(value) {
  return /^(?:data:|blob:|https?:|mailto:|tel:|javascript:|#|\/\/)/i.test(value)
}

function looksLikeLocalFile(value) {
  const clean = stripQueryAndHash(value)
  return /^(?:\/|\.{1,2}\/)/.test(clean) || /\.[a-z0-9]{1,8}$/i.test(clean)
}

function resolveBuiltFile(reference, fromFile, distDir) {
  const clean = decodeURIComponent(stripQueryAndHash(reference))
  if (!clean || isRemoteOrEmbedded(clean)) return null
  const candidate = clean.startsWith('/')
    ? resolve(distDir, `.${clean}`)
    : resolve(dirname(fromFile), clean)
  return candidate
}

function toDataUri(file) {
  const extension = extname(file).toLowerCase()
  const mime = MIME_TYPES[extension] || 'application/octet-stream'
  return `data:${mime};base64,${readFileSync(file).toString('base64')}`
}

function assertInsideDist(file, distDir, reference) {
  const relativePath = relative(distDir, file)
  if (relativePath.startsWith('..') || isAbsolute(relativePath)) {
    throw new Error(`Refusing to inline a file outside dist: ${reference}`)
  }
}

function inlineCssReferences(css, cssFile, distDir) {
  return css.replace(/url\(\s*(["']?)([^"'()]+)\1\s*\)/g, (match, _quote, reference) => {
    if (isRemoteOrEmbedded(reference)) return match
    const file = resolveBuiltFile(reference, cssFile, distDir)
    if (!file) return match
    assertInsideDist(file, distDir, reference)
    if (!existsSync(file)) throw new Error(`Missing CSS asset: ${reference} (from ${cssFile})`)
    return `url("${toDataUri(file)}")`
  })
}

function inlineModuleReferences(code, moduleFile, distDir, moduleCache, stack = []) {
  const replaceLocalReference = (reference) => {
    if (isRemoteOrEmbedded(reference)) return reference
    const file = resolveBuiltFile(reference, moduleFile, distDir)
    if (!file) return reference
    assertInsideDist(file, distDir, reference)
    if (!existsSync(file)) return reference

    const extension = extname(stripQueryAndHash(file)).toLowerCase()
    if (extension === '.js' || extension === '.mjs') {
      if (stack.includes(file)) {
        throw new Error(`Circular JavaScript chunk import is not supported: ${[...stack, file].join(' -> ')}`)
      }
      if (moduleCache.has(file)) return moduleCache.get(file)
      const nestedCode = inlineModuleReferences(
        readFileSync(file, 'utf8'),
        file,
        distDir,
        moduleCache,
        [...stack, moduleFile],
      )
      const uri = `data:text/javascript;base64,${Buffer.from(nestedCode).toString('base64')}`
      moduleCache.set(file, uri)
      return uri
    }
    return toDataUri(file)
  }

  let output = code

  // Vite/Rollup chunk imports: import("..."), from "...", import "..."
  output = output.replace(
    /(\b(?:from|import)\s*(?:\(\s*)?)(["'])([^"']+)\2(\s*\)?)/g,
    (match, prefix, quote, reference, suffix) => {
      const replacement = replaceLocalReference(reference)
      return replacement === reference ? match : `${prefix}${quote}${replacement}${quote}${suffix}`
    },
  )

  // Vite asset constants and new URL("...", import.meta.url) references.
  output = output.replace(
    /(["'])(\/?\.?\.?\/?assets\/[^"'?#]+(?:[?#][^"']*)?)\1/g,
    (match, quote, reference) => {
      const replacement = replaceLocalReference(reference)
      return replacement === reference ? match : `${quote}${replacement}${quote}`
    },
  )

  return output
}

function replaceTags(html, pattern, replacer) {
  let output = html
  const matches = [...html.matchAll(pattern)]
  for (const match of matches.reverse()) {
    const replacement = replacer(match)
    output = `${output.slice(0, match.index)}${replacement}${output.slice(match.index + match[0].length)}`
  }
  return output
}

function main() {
  const options = parseArgs(process.argv.slice(2))
  const projectDir = resolve(options.project)
  const distDir = resolve(projectDir, options.dist)
  const entryFile = resolve(distDir, options.entry)
  const entryBase = options.entry.replace(/\.html?$/i, '')
  const outputFile = resolve(projectDir, options.output || `${options.dist}/${entryBase}.standalone.html`)

  if (options.build) {
    console.log(`[single-html] Building project: ${options.buildCommand}`)
    execSync(options.buildCommand, {
      cwd: projectDir,
      stdio: 'inherit',
      shell: true,
    })
  }

  if (!existsSync(entryFile)) {
    throw new Error(`Built entry not found: ${entryFile}`)
  }

  let html = readFileSync(entryFile, 'utf8')
  const moduleCache = new Map()

  html = replaceTags(html, /<link\b[^>]*>/gi, (match) => {
    const relation = match[0].match(/\brel=["']([^"']+)["']/i)?.[1]?.toLowerCase()
    const href = match[0].match(/\bhref=["']([^"']+)["']/i)?.[1]
    if (!href || isRemoteOrEmbedded(href)) return match[0]
    if (relation === 'modulepreload') return ''
    const cssFile = resolveBuiltFile(href, entryFile, distDir)
    if (!cssFile) return match[0]
    assertInsideDist(cssFile, distDir, href)
    if (!existsSync(cssFile)) throw new Error(`Missing linked asset: ${href}`)
    if (relation !== 'stylesheet') {
      return match[0].replace(href, toDataUri(cssFile))
    }
    const css = inlineCssReferences(readFileSync(cssFile, 'utf8'), cssFile, distDir)
    return `<style>\n${css}\n</style>`
  })

  html = replaceTags(
    html,
    /<script\b([^>]*)\bsrc=["']([^"']+)["']([^>]*)>\s*<\/script>/gi,
    (match) => {
      const reference = match[2]
      if (isRemoteOrEmbedded(reference)) return match[0]
      const scriptFile = resolveBuiltFile(reference, entryFile, distDir)
      if (!scriptFile) return match[0]
      assertInsideDist(scriptFile, distDir, reference)
      if (!existsSync(scriptFile)) throw new Error(`Missing script: ${reference}`)
      const code = inlineModuleReferences(
        readFileSync(scriptFile, 'utf8'),
        scriptFile,
        distDir,
        moduleCache,
      ).replace(/<\/script/gi, '<\\/script')
      const isModule = /\btype=["']module["']/i.test(match[0])
      return `<script${isModule ? ' type="module"' : ''}>\n${code}\n</script>`
    },
  )

  html = html.replace(
    /\b(src|poster)=["']([^"']+)["']/gi,
    (match, attribute, reference) => {
      if (isRemoteOrEmbedded(reference)) return match
      const file = resolveBuiltFile(reference, entryFile, distDir)
      if (!file) return match
      assertInsideDist(file, distDir, reference)
      if (!existsSync(file)) throw new Error(`Missing HTML asset: ${reference}`)
      return `${attribute}="${toDataUri(file)}"`
    },
  )

  html = html.replace(/\bsrcset=["']([^"']+)["']/gi, (match, value) => {
    const items = value.split(',').map((item) => {
      const [reference, ...descriptor] = item.trim().split(/\s+/)
      if (isRemoteOrEmbedded(reference)) return item.trim()
      const file = resolveBuiltFile(reference, entryFile, distDir)
      if (!file) return item.trim()
      assertInsideDist(file, distDir, reference)
      if (!existsSync(file)) throw new Error(`Missing srcset asset: ${reference}`)
      return [toDataUri(file), ...descriptor].join(' ')
    })
    return `srcset="${items.join(', ')}"`
  })

  const unresolved = []
  for (const match of html.matchAll(/\b(?:src|poster)=["']([^"']+)["']/gi)) {
    if (!isRemoteOrEmbedded(match[1]) && looksLikeLocalFile(match[1])) unresolved.push(match[1])
  }
  for (const match of html.matchAll(/url\(\s*["']?([^"'()]+)["']?\s*\)/gi)) {
    if (!isRemoteOrEmbedded(match[1]) && looksLikeLocalFile(match[1])) unresolved.push(match[1])
  }
  for (const match of html.matchAll(/["']((?:\/|\.{1,2}\/)assets\/[^"']+)["']/gi)) {
    unresolved.push(match[1])
  }
  if (unresolved.length) {
    throw new Error(`Unresolved local resources remain:\n${[...new Set(unresolved)].join('\n')}`)
  }

  mkdirSync(dirname(outputFile), { recursive: true })
  writeFileSync(outputFile, html, 'utf8')

  const sizeMb = (Buffer.byteLength(html) / 1024 / 1024).toFixed(2)
  console.log(`[single-html] Created: ${outputFile}`)
  console.log(`[single-html] Size: ${sizeMb} MB`)
  console.log(`[single-html] File URL: ${pathToFileURL(outputFile).href}`)
}

try {
  main()
} catch (error) {
  console.error(`[single-html] ${error instanceof Error ? error.message : error}`)
  process.exit(1)
}
