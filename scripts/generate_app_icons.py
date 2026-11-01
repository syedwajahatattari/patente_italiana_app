#!/usr/bin/env python3
"""
scripts/generate_app_icons.py
Generates custom high-quality launcher icons for Patente B Italia.
Features an Italian road-sign motif:
- Premium rounded squircle badge in deep Italian navy (#0A2540)
- Circular regulatory road sign with bold red border (#DC2626) and crisp white field
- Distinctive, bold Italian Patente 'B' emblem (#1E40AF)
- Italian Tricolore flag accent bar (Verde #15803D, Bianco #FFFFFF, Rosso #DC2626)
Rendered with 4x supersampling (anti-aliasing) across all Android mipmap densities.
"""

import os
import struct
import zlib
import math

DENSITIES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

RES_DIR = "android/app/src/main/res"

def render_icon(size: int) -> bytes:
    # 4x supersampling for pristine antialiasing
    SS = 4
    W = size * SS
    H = size * SS
    cx = W / 2.0
    cy = H / 2.0

    raw_data = bytearray()

    # Precompute geometric bounds
    # Background squircle radius
    bg_corner = W * 0.22
    # Sign circle radius
    sign_outer_r = W * 0.42
    sign_inner_r = W * 0.33
    sign_center_r = W * 0.33

    # Tricolore bar dimensions
    flag_y_start = H * 0.81
    flag_y_end = H * 0.86
    flag_x_start = W * 0.25
    flag_x_end = W * 0.75
    flag_w = flag_x_end - flag_x_start

    # Letter 'B' proportions inside the sign center
    # B center is roughly cy - W * 0.02
    b_cx = cx
    b_cy = cy - W * 0.02
    b_h = W * 0.36
    b_w = W * 0.24
    stem_w = W * 0.065
    stem_left = b_cx - b_w / 2.0
    stem_right = stem_left + stem_w
    top_y = b_cy - b_h / 2.0
    bot_y = b_cy + b_h / 2.0
    mid_y = b_cy

    def point_in_b(px, py):
        if px < stem_left or px > stem_left + b_w or py < top_y or py > bot_y:
            return False
        # Main vertical stem
        if px <= stem_right:
            return True
        # Top loop
        if py <= mid_y:
            # Outer semi-ellipse
            rx_out = b_w - stem_w
            ry_out = (mid_y - top_y) / 2.0
            loop_cy = top_y + ry_out
            loop_cx = stem_right
            dx = (px - loop_cx) / rx_out
            dy = (py - loop_cy) / ry_out
            if dx * dx + dy * dy <= 1.0:
                # Check inner hole
                rx_in = rx_out - stem_w * 0.75
                ry_in = ry_out - stem_w * 0.65
                if rx_in > 0 and ry_in > 0:
                    dx_in = (px - loop_cx) / rx_in
                    dy_in = (py - loop_cy) / ry_in
                    if dx_in * dx_in + dy_in * dy_in < 1.0:
                        return False # Inside hole
                return True
        else: # Bottom loop (slightly wider)
            rx_out = b_w - stem_w + W * 0.01
            ry_out = (bot_y - mid_y) / 2.0
            loop_cy = mid_y + ry_out
            loop_cx = stem_right
            dx = (px - loop_cx) / rx_out
            dy = (py - loop_cy) / ry_out
            if dx * dx + dy * dy <= 1.0:
                # Check inner hole
                rx_in = rx_out - stem_w * 0.75
                ry_in = ry_out - stem_w * 0.65
                if rx_in > 0 and ry_in > 0:
                    dx_in = (px - loop_cx) / rx_in
                    dy_in = (py - loop_cy) / ry_in
                    if dx_in * dx_in + dy_in * dy_in < 1.0:
                        return False # Inside hole
                return True
        return False

    def in_squircle(px, py):
        # Margin around squircle
        m = W * 0.02
        if px < m or px > W - m or py < m or py > H - m:
            return False
        # Check 4 corners
        r = bg_corner
        if px < m + r and py < m + r:
            return (px - (m + r))**2 + (py - (m + r))**2 <= r**2
        if px > W - m - r and py < m + r:
            return (px - (W - m - r))**2 + (py - (m + r))**2 <= r**2
        if px < m + r and py > H - m - r:
            return (px - (m + r))**2 + (py - (H - m - r))**2 <= r**2
        if px > W - m - r and py > H - m - r:
            return (px - (W - m - r))**2 + (py - (H - m - r))**2 <= r**2
        return True

    # Color definitions (RGBA)
    BG_TOP = (15, 30, 65, 255)     # Deep Italian Navy
    BG_BOT = (10, 18, 40, 255)     # Darker Navy bottom
    SIGN_RED = (220, 38, 38, 255)  # Official European Road Sign Red
    SIGN_WHITE = (255, 255, 255, 255)
    LETTER_BLUE = (30, 64, 175, 255) # Italian Highway Blue
    FLAG_GREEN = (22, 163, 74, 255)  # Italian Tricolore Green
    FLAG_WHITE = (255, 255, 255, 255)
    FLAG_RED = (220, 38, 38, 255)    # Italian Tricolore Red
    GOLD_RING = (245, 158, 11, 255)

    def sample_pixel(sx, sy):
        px = sx + 0.5
        py = sy + 0.5

        if not in_squircle(px, py):
            return (0, 0, 0, 0)

        # Base background gradient
        grad = py / float(H)
        bg_r = int(BG_TOP[0] + (BG_BOT[0] - BG_TOP[0]) * grad)
        bg_g = int(BG_TOP[1] + (BG_BOT[1] - BG_TOP[1]) * grad)
        bg_b = int(BG_TOP[2] + (BG_BOT[2] - BG_TOP[2]) * grad)

        # Distance from center for sign
        d = math.hypot(px - cx, py - cy)

        # Subtle gold outer glow ring
        if d >= sign_outer_r and d <= sign_outer_r + W * 0.015:
            return GOLD_RING

        # Outer red ring of traffic sign
        if d <= sign_outer_r and d > sign_inner_r:
            return SIGN_RED

        # White inner circular field of sign
        if d <= sign_inner_r:
            # Check letter B
            if point_in_b(px, py):
                return LETTER_BLUE
            return SIGN_WHITE

        # Check Italian Tricolore flag accent bar
        if flag_y_start <= py <= flag_y_end and flag_x_start <= px <= flag_x_end:
            fx = px - flag_x_start
            if fx < flag_w / 3.0:
                return FLAG_GREEN
            elif fx < flag_w * 2.0 / 3.0:
                return FLAG_WHITE
            else:
                return FLAG_RED

        return (bg_r, bg_g, bg_b, 255)

    for y in range(size):
        raw_data.append(0) # Filter type None
        for x in range(size):
            r_acc, g_acc, b_acc, a_acc = 0, 0, 0, 0
            for sy in range(SS):
                for sx in range(SS):
                    pr, pg, pb, pa = sample_pixel(x * SS + sx, y * SS + sy)
                    r_acc += pr * pa // 255
                    g_acc += pg * pa // 255
                    b_acc += pb * pa // 255
                    a_acc += pa

            samples = SS * SS
            avg_a = a_acc // samples
            if avg_a > 0:
                avg_r = (r_acc * 255) // a_acc
                avg_g = (g_acc * 255) // a_acc
                avg_b = (b_acc * 255) // a_acc
            else:
                avg_r, avg_g, avg_b = 0, 0, 0

            raw_data.extend([avg_r, avg_g, avg_b, avg_a])

    compressed = zlib.compress(raw_data, 9)

    def chunk(tag, data):
        return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', zlib.crc32(tag + data) & 0xffffffff)

    png = b'\x89PNG\r\n\x1a\n'
    png += chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 6, 0, 0, 0)) # 8-bit RGBA
    png += chunk(b'IDAT', compressed)
    png += chunk(b'IEND', b'')
    return png

def main():
    for density, size in DENSITIES.items():
        out_dir = os.path.join(RES_DIR, density)
        os.makedirs(out_dir, exist_ok=True)
        out_path = os.path.join(out_dir, "ic_launcher.png")
        print(f"Generating {density} ({size}x{size}) -> {out_path} ...")
        png_bytes = render_icon(size)
        with open(out_path, "wb") as f:
            f.write(png_bytes)
        print(f"  Done ({len(png_bytes)} bytes)")

if __name__ == "__main__":
    main()
