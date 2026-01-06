use image::{Rgba, RgbaImage};

/// Converts a 15-bit GBA Color (BGR555) to 32-bit RGBA.
/// GBA Format: xBBBBBGGGGGRRRRR (x is unused)
pub fn bgr555_to_rgba(color: u16) -> [u8; 4] {
    let r = (color & 0x1F) as u8;
    let g = ((color >> 5) & 0x1F) as u8;
    let b = ((color >> 10) & 0x1F) as u8;

    // Expand 5-bit to 8-bit (x * 255) / 31
    // Cast to u32 to avoid overflow during multiplication (31 * 255 > 255)
    let r8 = ((r as u32 * 255) / 31) as u8;
    let g8 = ((g as u32 * 255) / 31) as u8;
    let b8 = ((b as u32 * 255) / 31) as u8;

    [r8, g8, b8, 255]
}

/// Decodes a 4bpp tile (32 bytes) into an RgbaImage (8x8).
/// input: 32 bytes of 4bpp data.
/// palette: 16 colors (RGBA array or similar, here we take &[u16] raw palette).
pub fn decode_4bpp_tile(input: &[u8], palette: &[u16]) -> RgbaImage {
    let mut image = RgbaImage::new(8, 8);
    if input.len() < 32 || palette.len() < 16 {
        return image; // Return transparent/empty
    }

    for y in 0..8 {
        for x in 0..8 {
            // In 4bpp, each byte holds 2 pixels.
            // Byte 0: Pixel 0 (low nibble), Pixel 1 (high nibble)
            // Stored as: [P1 P0] [P3 P2]
            
            // Index in byte array
            let pixel_idx = (y * 8 + x) as usize;
            let byte_idx = pixel_idx / 2;
            let byte = input[byte_idx];
            
            // If x is even (0, 2..), it's low nibble. If odd, high nibble.
            let palette_index = if x % 2 == 0 {
                byte & 0xF
            } else {
                (byte >> 4) & 0xF
            } as usize;

            if palette_index == 0 {
                // Color 0 is always transparent
                image.put_pixel(x as u32, y as u32, Rgba([0, 0, 0, 0]));
            } else {
                let color = palette[palette_index];
                let rgba = bgr555_to_rgba(color);
                image.put_pixel(x as u32, y as u32, Rgba(rgba));
            }
        }
    }
    image
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_bgr555_to_rgba() {
        // Red: 0x001F (0000 0000 0001 1111) -> R=31, G=0, B=0
        let red_gba = 0x001F;
        let red_rgba = bgr555_to_rgba(red_gba);
        assert_eq!(red_rgba, [255, 0, 0, 255]); // 31 * 255 / 31 = 255

        // Green: 0x03E0 (0000 0011 1110 0000) -> R=0, G=31, B=0
        let green_gba = 0x03E0;
        let green_rgba = bgr555_to_rgba(green_gba);
        assert_eq!(green_rgba, [0, 255, 0, 255]);

        // White: 0x7FFF
        let white_gba = 0x7FFF;
        let white_rgba = bgr555_to_rgba(white_gba);
        assert_eq!(white_rgba, [255, 255, 255, 255]);
    }
}
