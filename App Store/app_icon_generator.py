#!/usr/bin/env python3
"""
アプリアイコン生成スクリプト
1024x1024のマスター画像から全サイズのアイコンを生成
"""

import os
from PIL import Image, ImageDraw, ImageFont
import math

# アイコンサイズ定義
ICON_SIZES = [
    (1024, "AppIcon-1024.png", "App Store"),
    (180, "AppIcon-180.png", "iPhone @3x"),
    (120, "AppIcon-120.png", "iPhone @2x"),
    (87, "AppIcon-87.png", "iPhone @3x Settings"),
    (80, "AppIcon-80.png", "iPad @2x 40pt"),
    (60, "AppIcon-60.png", "iPhone @2x Notification"),
    (58, "AppIcon-58.png", "iPhone @2x Settings"),
    (40, "AppIcon-40.png", "Spotlight"),
    (167, "AppIcon-167.png", "iPad Pro @2x"),
    (152, "AppIcon-152.png", "iPad @2x"),
    (76, "AppIcon-76.png", "iPad @1x"),
    (29, "AppIcon-29.png", "iPad Settings"),
    (20, "AppIcon-20.png", "iPad @1x Notification"),
]

# カラー定義
COLORS = {
    'main_bg': (78, 205, 196),      # #4ECDC4
    'sub_bg': (69, 183, 170),       # #45B7AA
    'yellow': (255, 217, 61),       # #FFD93D
    'pink': (255, 107, 107),        # #FF6B6B
    'white': (255, 255, 255),       # #FFFFFF
    'shadow': (0, 0, 0, 51),        # 20% opacity
}

def create_master_icon(size=1024):
    """マスターアイコンを作成"""
    # 背景を作成
    img = Image.new('RGBA', (size, size), COLORS['main_bg'])
    draw = ImageDraw.Draw(img)
    
    # グラデーション背景（簡易版）
    center_x, center_y = size // 2, size // 2
    for i in range(size // 2, 0, -5):
        alpha = int(255 * (1 - i / (size // 2)))
        color = (*COLORS['sub_bg'], alpha)
        draw.ellipse([center_x - i, center_y - i, center_x + i, center_y + i], 
                     fill=color)
    
    # 中央の円
    main_circle_radius = int(size * 0.35)
    draw.ellipse([center_x - main_circle_radius, center_y - main_circle_radius,
                  center_x + main_circle_radius, center_y + main_circle_radius],
                 fill=COLORS['white'])
    
    # 「く」の文字を描画（簡易版）
    # 実際の実装では日本語フォントが必要
    font_size = int(size * 0.4)
    # フォントファイルがない場合はスキップ
    try:
        # macOSの日本語フォントパス
        font_path = "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc"
        if os.path.exists(font_path):
            font = ImageFont.truetype(font_path, font_size)
            text = "く"
            bbox = draw.textbbox((0, 0), text, font=font)
            text_width = bbox[2] - bbox[0]
            text_height = bbox[3] - bbox[1]
            text_x = center_x - text_width // 2
            text_y = center_y - text_height // 2 - font_size * 0.1
            draw.text((text_x, text_y), text, fill=COLORS['main_bg'], font=font)
    except:
        # フォントが読み込めない場合は代替図形
        draw.arc([center_x - font_size//3, center_y - font_size//3,
                  center_x + font_size//3, center_y + font_size//3],
                 start=45, end=315, fill=COLORS['main_bg'], width=int(size * 0.08))
    
    # 周囲の動物アイコン（簡易的な円で表現）
    animal_positions = []
    num_animals = 6
    animal_radius = int(size * 0.08)
    orbit_radius = int(size * 0.38)
    
    for i in range(num_animals):
        angle = (2 * math.pi * i) / num_animals - math.pi / 2
        x = center_x + int(orbit_radius * math.cos(angle))
        y = center_y + int(orbit_radius * math.sin(angle))
        
        # 動物の色を交互に変える
        color = COLORS['yellow'] if i % 2 == 0 else COLORS['pink']
        
        # 影を描画
        shadow_offset = int(size * 0.01)
        draw.ellipse([x - animal_radius + shadow_offset, 
                      y - animal_radius + shadow_offset,
                      x + animal_radius + shadow_offset, 
                      y + animal_radius + shadow_offset],
                     fill=(0, 0, 0, 30))
        
        # 動物の円を描画
        draw.ellipse([x - animal_radius, y - animal_radius,
                      x + animal_radius, y + animal_radius],
                     fill=color)
        
        # 簡単な顔を描画
        eye_size = int(animal_radius * 0.2)
        eye_offset = int(animal_radius * 0.3)
        draw.ellipse([x - eye_offset - eye_size//2, y - eye_size//2,
                      x - eye_offset + eye_size//2, y + eye_size//2],
                     fill=(0, 0, 0))
        draw.ellipse([x + eye_offset - eye_size//2, y - eye_size//2,
                      x + eye_offset + eye_size//2, y + eye_size//2],
                     fill=(0, 0, 0))
    
    return img

def generate_all_icons(master_img, output_dir="generated_icons"):
    """全サイズのアイコンを生成"""
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    for size, filename, description in ICON_SIZES:
        # リサイズ
        resized = master_img.resize((size, size), Image.Resampling.LANCZOS)
        
        # RGBに変換（透過を削除）
        rgb_img = Image.new('RGB', (size, size), COLORS['main_bg'])
        rgb_img.paste(resized, (0, 0), resized)
        
        # 保存
        output_path = os.path.join(output_dir, filename)
        rgb_img.save(output_path, 'PNG', optimize=True)
        print(f"生成完了: {filename} ({size}x{size}) - {description}")

def main():
    """メイン処理"""
    print("アプリアイコン生成を開始します...")
    
    # マスターアイコンを作成
    master = create_master_icon()
    
    # プレビュー保存
    master.save("master_icon_preview.png", 'PNG')
    print("マスターアイコンを master_icon_preview.png に保存しました")
    
    # 全サイズ生成
    generate_all_icons(master)
    
    print("\nすべてのアイコンの生成が完了しました！")
    print("generated_iconsフォルダを確認してください。")

if __name__ == "__main__":
    main()