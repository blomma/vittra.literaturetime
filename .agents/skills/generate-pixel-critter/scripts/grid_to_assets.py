#!/usr/bin/env python3
import sys
import os
import re
from PIL import Image

def parse_grid_file(content):
    palette = {}
    frames = {}
    
    current_row = None
    current_col = None
    current_frame_lines = []
    
    # Also collect legacy grid lines if no frame headers are present
    legacy_grid_lines = []
    
    # Process lines
    lines = content.strip().split('\n')
    
    for line in lines:
        line_stripped = line.strip()
        if not line_stripped:
            continue
        
        # Parse palette: char : color
        # e.g., ". : transparent" or "a : #3e3546"
        if ':' in line_stripped and not line_stripped.startswith('#'):
            clean_line = line_stripped.lstrip('#').strip()
            if ':' in clean_line:
                parts = clean_line.split(':', 1)
                char = parts[0].strip()
                color_part = parts[1].strip()
                # Find hex color or transparent/none
                color_match = re.search(r'(#[0-9a-fA-F]{6}|transparent|none)', color_part, re.IGNORECASE)
                if color_match:
                    palette[char] = color_match.group(1).lower()
                    continue
        
        # Check for frame header, e.g. "# FRAME 0,1" or "# FRAME 0 1"
        frame_match = re.match(r'^#\s*FRAME\s+(\d+)[,\s]+(\d+)', line_stripped, re.IGNORECASE)
        if frame_match:
            # Save the current frame before starting the next
            if current_row is not None and current_col is not None:
                frames[(current_row, current_col)] = current_frame_lines
                
            current_row = int(frame_match.group(1))
            current_col = int(frame_match.group(2))
            current_frame_lines = []
            continue
            
        # If we are inside a frame block and the line is not a comment, collect it
        if current_row is not None and current_col is not None:
            if not line_stripped.startswith('#'):
                current_frame_lines.append(line_stripped)
        else:
            # Legacy fallback: lines not starting with comments/palette lines are treated as a single grid
            if not line_stripped.startswith('#'):
                legacy_grid_lines.append(line_stripped)
                
    # Save the last parsed frame
    if current_row is not None and current_col is not None:
        frames[(current_row, current_col)] = current_frame_lines
        
    # If no frames were found via headers, check if we have legacy grid lines
    if not frames and legacy_grid_lines:
        frames[(0, 0)] = legacy_grid_lines
        
    return palette, frames

def render_assets(palette, grid, output_base_path, scale=8):
    if not grid:
        raise ValueError("Grid is empty")
        
    height = len(grid)
    width = max(len(row) for row in grid)
    
    if width % 32 != 0 or height % 32 != 0:
        print(f"Warning: Spritesheet size {width}x{height} is not a multiple of 32x32 cells!", file=sys.stderr)
        
    # 1. Create Pillow RGBA image
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    pixels = img.load()
    
    for y, row in enumerate(grid):
        for x, char in enumerate(row.ljust(width, '.')):
            color_str = palette.get(char, 'transparent')
            if color_str == 'transparent' or color_str.lower() == 'none':
                pixels[x, y] = (0, 0, 0, 0)
            else:
                # Parse hex
                hex_val = color_str.lstrip('#')
                r = int(hex_val[0:2], 16)
                g = int(hex_val[2:4], 16)
                b = int(hex_val[4:6], 16)
                pixels[x, y] = (r, g, b, 255)
                
    # Save original 1x PNG
    png_path = f"{output_base_path}.png"
    img.save(png_path)
    print(f"Saved 1x PNG to {png_path}")
    
    # Save scaled PNG
    if scale > 1:
        scaled_img = img.resize((width * scale, height * scale), Image.Resampling.NEAREST)
        scaled_png_path = f"{output_base_path}_x{scale}.png"
        scaled_img.save(scaled_png_path)
        print(f"Saved {scale}x scaled PNG to {scaled_png_path}")


def main():
    if len(sys.argv) < 3:
        print("Usage: python3 grid_to_assets.py <grid_file_path> <output_base_path> [scale]", file=sys.stderr)
        sys.exit(1)
        
    grid_file = sys.argv[1]
    output_base = sys.argv[2]
    scale = int(sys.argv[3]) if len(sys.argv) > 3 else 8
    
    with open(grid_file, 'r') as f:
        content = f.read()
        
    palette, frames = parse_grid_file(content)
    
    if not frames:
        print("Error: No frames found in the input grid file.", file=sys.stderr)
        sys.exit(1)
        
    max_row = max(r for r, c in frames.keys())
    max_col = max(c for r, c in frames.keys())
    
    num_rows = max_row + 1
    num_cols = max_col + 1
    
    pixel_width = num_cols * 32
    pixel_height = num_rows * 32
    
    # Build the merged grid
    merged_grid = [['.' for _ in range(pixel_width)] for _ in range(pixel_height)]
    
    for (r, c), frame_lines in frames.items():
        for y in range(32):
            line = frame_lines[y] if y < len(frame_lines) else ""
            line = line.ljust(32, '.')[:32]
            for x in range(32):
                global_x = c * 32 + x
                global_y = r * 32 + y
                merged_grid[global_y][global_x] = line[x]
                
    grid_to_render = [''.join(row) for row in merged_grid]
    
    render_assets(palette, grid_to_render, output_base, scale)

if __name__ == '__main__':
    main()
