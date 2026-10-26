#!/usr/bin/env python3
"""Generate SVG sources for the 44nova Plymouth (two-step) theme.

Writes into the directory given as argv[1]:
  throbber-NNNN.svg  breathing glow around the 44 mark (looping animation)
  lock.svg, entry.svg, bullet.svg, capslock.svg, keyboard.svg
"""
import math, os, sys

out = sys.argv[1]
os.makedirs(out, exist_ok=True)
MARK = 'M104 52 L44 152 H212 M104 52 V204 M188 52 L128 152 M188 52 V204'
GRAD = ('<linearGradient id="g" x1="40" y1="48" x2="216" y2="208" gradientUnits="userSpaceOnUse">'
        '<stop offset="0" stop-color="#9AD6FF"/><stop offset="0.5" stop-color="#65A8FF"/>'
        '<stop offset="1" stop-color="#8B7CFF"/></linearGradient>')
FRAMES = 36
for i in range(FRAMES):
    t = (1 - math.cos(2 * math.pi * i / FRAMES)) / 2          # 0..1..0
    glow = 0.15 + 0.55 * t
    blur = 10 + 8 * t
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="-32 -32 320 320" width="160" height="160">
  <defs>{GRAD}<filter id="b" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="{blur:.1f}"/></filter></defs>
  <path d="{MARK}" fill="none" stroke="#65A8FF" stroke-opacity="{glow:.3f}" stroke-width="34" stroke-linecap="round" stroke-linejoin="round" filter="url(#b)"/>
  <path d="{MARK}" fill="none" stroke="url(#g)" stroke-width="20" stroke-linecap="round" stroke-linejoin="round"/>
</svg>'''
    open(os.path.join(out, f'throbber-{i + 1:04d}.svg'), 'w').write(svg)

open(os.path.join(out, 'entry.svg'), 'w').write('''<svg xmlns="http://www.w3.org/2000/svg" width="320" height="44" viewBox="0 0 320 44">
  <rect x="1" y="1" width="318" height="42" rx="21" fill="#111A2B" stroke="#344765" stroke-width="2"/>
</svg>''')
open(os.path.join(out, 'bullet.svg'), 'w').write('''<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 14 14">
  <circle cx="7" cy="7" r="5" fill="#F1F5FF"/>
</svg>''')
open(os.path.join(out, 'lock.svg'), 'w').write('''<svg xmlns="http://www.w3.org/2000/svg" width="28" height="32" viewBox="0 0 28 32">
  <path d="M7 14 V10 a7 7 0 0 1 14 0 V14" fill="none" stroke="#65A8FF" stroke-width="3"/>
  <rect x="3" y="14" width="22" height="16" rx="4" fill="#65A8FF"/>
</svg>''')
open(os.path.join(out, 'capslock.svg'), 'w').write('''<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 28 28">
  <path d="M14 4 L24 15 H18 V24 H10 V15 H4 Z" fill="none" stroke="#FFBE70" stroke-width="2.5" stroke-linejoin="round"/>
</svg>''')
open(os.path.join(out, 'keyboard.svg'), 'w').write('''<svg xmlns="http://www.w3.org/2000/svg" width="32" height="22" viewBox="0 0 32 22">
  <rect x="1" y="1" width="30" height="20" rx="4" fill="none" stroke="#A7B5CC" stroke-width="2"/>
  <path d="M6 7h2M11 7h2M16 7h2M21 7h2M26 7h0M6 11h2M11 11h2M16 11h2M21 11h2M9 16h14" stroke="#A7B5CC" stroke-width="2" stroke-linecap="round"/>
</svg>''')
