use crate::state::{APP_STATE, RomState};
use crate::structures::RomHeader;
use anyhow::{Context, Result};
use binrw::BinRead;
use std::fs;
use std::io::Cursor;

// This function is called from Flutter
pub fn load_rom(path: String) -> Result<String> {
    // 1. Read file from disk
    let data = fs::read(&path).context("Failed to read ROM file")?;

    // 2. Parse Header
    let mut reader = Cursor::new(&data);
    let header = RomHeader::read(&mut reader).context("Failed to parse ROM Header")?;

    // 3. Validation (Basic check)
    if header.game_code != "BPRE" && header.game_code != "BPEE" {
        return Err(anyhow::anyhow!("Unsupported Game Code: {}. Only BPRE (FireRed) and BPEE (Emerald) are supported.", header.game_code));
    }
    
    let game_title = header.game_title.clone();

    // 4. Update Global State
    {
        let mut state = APP_STATE.write().map_err(|_| anyhow::anyhow!("Failed to acquire write lock"))?;
        *state = Some(RomState::new(data, header));
    }

    Ok(format!("Loaded: {}", game_title))
}

pub fn get_rom_header_info() -> Result<String> {
    let state = APP_STATE.read().map_err(|_| anyhow::anyhow!("Failed to acquire read lock"))?;
    match &*state {
        Some(s) => Ok(format!("Code: {}, Title: {}", s.header.game_code, s.header.game_title)),
        None => Err(anyhow::anyhow!("No ROM loaded")),
    }
}

// Helper to resolve GBA pointer (0x08xxxxxx -> 0x0xxxxxxx)
fn resolve_pointer(ptr: u32) -> Result<usize> {
    if ptr < 0x08000000 || ptr > 0x09FFFFFF {
        // bail!("Invalid pointer: {:08x}", ptr);
        // Allow potentially raw offsets for now if needed, but usually it's 08
    }
    Ok((ptr & 0x01FFFFFF) as usize)
}

use crate::structures::{MapHeader, MapLayout, TilesetHeader};
use crate::compression::decompress_lz77;
use crate::graphics::decode_4bpp_tile;
use crate::scripting::{disassemble, ScriptCommand};

pub fn disassemble_script(offset: u32) -> Result<Vec<ScriptCommand>> {
    let state_guard = APP_STATE.read().map_err(|_| anyhow::anyhow!("Failed to lock"))?;
    let state = state_guard.as_ref().ok_or(anyhow::anyhow!("No ROM loaded"))?;

    let real_offset = resolve_pointer(offset)?;
    if real_offset >= state.data.len() {
        anyhow::bail!("Offset out of bounds");
    }

    disassemble(&state.data, real_offset)
}

pub fn render_map_preview(map_header_ptr: u32) -> Result<Vec<u8>> {
    let state_guard = APP_STATE.read().map_err(|_| anyhow::anyhow!("Failed to lock"))?;
    let state = state_guard.as_ref().ok_or(anyhow::anyhow!("No ROM loaded"))?;
    
    // 1. Read Map Header
    let map_header_offset = resolve_pointer(map_header_ptr)?;
    let mut reader = Cursor::new(&state.data);
    reader.set_position(map_header_offset as u64);
    let map_header = MapHeader::read(&mut reader).context("Failed to read MapHeader")?;

    // 2. Read Map Layout
    let layout_offset = resolve_pointer(map_header.map_data_ptr)?;
    reader.set_position(layout_offset as u64);
    let layout = MapLayout::read(&mut reader).context("Failed to read MapLayout")?;

    // 3. Read Primary Tileset Header
    let tileset_offset = resolve_pointer(layout.primary_tileset_ptr)?;
    reader.set_position(tileset_offset as u64);
    let tileset = TilesetHeader::read(&mut reader).context("Failed to read TilesetHeader")?;

    // 4. Read Palette (assuming standard 16 palettes of 16 colors)
    // The palette pointer points to 512 bytes (16 * 16 * 2 bytes)
    // But map usually uses specific palette slots.
    // simpler: Read the primary palette (first 16 colors)
    let palette_offset = resolve_pointer(tileset.palette_ptr)?;
    let mut palette = Vec::new();
    reader.set_position(palette_offset as u64);
    for _ in 0..16 {
        // BinRead for u16 (Little Endian)
        let mut buf = [0u8; 2];
        use std::io::Read;
        reader.read_exact(&mut buf)?;
        let color = u16::from_le_bytes(buf);
        palette.push(color);
    }

    // 5. Read Graphics
    let gfx_offset = resolve_pointer(tileset.graphics_ptr)?;
    
    let raw_gfx = if tileset.is_compressed == 1 {
        // Read from ROM at offset
        // We need to slice from gfx_offset to end?
        if gfx_offset >= state.data.len() {
            anyhow::bail!("Graphics ptr out of bounds");
        }
        decompress_lz77(&state.data[gfx_offset..])?
    } else {
        // Uncompressed, assume fixed size? or read until something?
        // Usually 4bpp tiles. Let's read 128 tiles (128 * 32 bytes = 4KB)
        let size = 128 * 32;
        if gfx_offset + size > state.data.len() {
             anyhow::bail!("Graphics ptr out of bounds for uncompressed read");
        }
        state.data[gfx_offset..gfx_offset+size].to_vec()
    };

    // 6. Decode first 128 tiles into a grid (16 tiles wide, 8 high)
    // 16 * 8 = 128 pixels wide
    // 8 * 8 = 64 pixels high
    let tiles_wide = 16;
    let tiles_high = 8;
    let mut output_img = image::RgbaImage::new(tiles_wide * 8, tiles_high * 8);

    for i in 0..(tiles_wide * tiles_high) {
        if i * 32 >= raw_gfx.len() as u32 { break; }
        
        let tile_data = &raw_gfx[(i as usize * 32)..((i as usize + 1) * 32)];
        let tile_img = decode_4bpp_tile(tile_data, &palette);
        
        let x_pos = (i % tiles_wide) * 8;
        let y_pos = (i / tiles_wide) * 8;
        
        // Copy pixels
        for ty in 0..8 {
            for tx in 0..8 {
                let p = tile_img.get_pixel(tx, ty);
                output_img.put_pixel(x_pos + tx, y_pos + ty, *p);
            }
        }
    }

    Ok(output_img.into_raw())
}

/// Updates the Header Checksum (byte at 0xBD)
/// The checksum is the 2's complement of the sum of bytes 0xA0 to 0xBC.
fn calculate_header_checksum(data: &[u8]) -> u8 {
    let mut sum: u8 = 0;
    for i in 0xA0..0xBD {
        sum = sum.wrapping_add(data[i]);
    }
    // Standard GBA checksum algorithm: -(sum + 0x19)
    (0u8).wrapping_sub(sum).wrapping_sub(0x19)
}

/// Saves the current ROM state to a new file.
pub fn save_rom(output_path: String) -> Result<String> {
    let state_guard = APP_STATE.read().map_err(|_| anyhow::anyhow!("Failed to lock"))?;
    let state = state_guard.as_ref().ok_or(anyhow::anyhow!("No ROM loaded"))?;

    // Clone data to modify it
    let mut new_data = state.data.clone();

    // 1. Apply any pending modifications (from BTreeMap)
    for (offset, bytes) in &state.modifications {
        let start = *offset as usize;
        let end = start + bytes.len();
        if end > new_data.len() {
             // Handle expansion
             new_data.resize(end, 0xFF);
        }
        new_data[start..end].copy_from_slice(bytes);
    }

    // 2. Recalculate Checksum
    let checksum = calculate_header_checksum(&new_data);
    new_data[0xBD] = checksum;

    // 3. Write to Disk
    use std::fs;
    fs::write(&output_path, &new_data).context("Failed to write ROM file")?;

    Ok(format!("Saved to {}", output_path))
}

pub fn apply_patch(offset: u32, data: Vec<u8>) -> Result<()> {
     let mut state_guard = APP_STATE.write().map_err(|_| anyhow::anyhow!("Failed to lock"))?;
     let state = state_guard.as_mut().ok_or(anyhow::anyhow!("No ROM loaded"))?;

     // In a real scenario, we might want to check if data fits or needs repointing.
     // For now, we update the modification map.
     state.modifications.insert(offset, data);
     Ok(())
}
