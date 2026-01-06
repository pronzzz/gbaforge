use binrw::{BinRead, BinWrite};

#[derive(BinRead, BinWrite, Debug)]
#[br(little)]
pub struct RomHeader {
    // Entry Point (4 bytes)
    pub entry_point: u32,
    // Nintendo Logo (156 bytes)
    #[br(count = 156)]
    pub logo: Vec<u8>,
    // Game Title (12 bytes)
    #[br(count = 12, map = |bytes: Vec<u8>| String::from_utf8_lossy(&bytes).to_string())]
    #[bw(map = |s: &String| s.as_bytes().to_vec(), pad_after = 12)]
    pub game_title: String,
    // Game Code (4 bytes, e.g. BPRE)
    #[br(count = 4, map = |bytes: Vec<u8>| String::from_utf8_lossy(&bytes).to_string())]
    #[bw(map = |s: &String| s.as_bytes().to_vec(), pad_after = 4)]
    pub game_code: String,
    // Maker Code (2 bytes)
    #[br(count = 2, map = |bytes: Vec<u8>| String::from_utf8_lossy(&bytes).to_string())]
    #[bw(map = |s: &String| s.as_bytes().to_vec(), pad_after = 2)]
    pub maker_code: String,
    // Fixed value 0x96
    pub fixed_value: u8,
    // Main Unit Code (00h for current GBA models)
    pub unit_code: u8,
    // Device Type
    pub device_type: u8,
    // Reserved (7 bytes)
    #[br(count = 7)]
    pub reserved_1: Vec<u8>,
    // Software Version
    pub version: u8,
    // Complement Check
    pub complement_check: u8,
    // Reserved (2 bytes)
    pub reserved_2: u16,
}

#[derive(BinRead, BinWrite, Debug, Clone)]
#[br(little)]
pub struct MapHeader {
    pub map_data_ptr: u32,
    pub event_data_ptr: u32,
    pub map_script_ptr: u32,
    pub connection_ptr: u32,
    pub music_index: u16,
    pub map_index: u16,
    pub label_id: u8,
    pub visibility: u8,
    pub weather: u8,
    pub map_type: u8,
    pub unused_2: u16,
    pub show_label: u8,
    pub battle_scene: u8,
}

#[derive(BinRead, BinWrite, Debug, Clone)]
#[br(little)]
pub struct MapLayout {
    pub width: u32,
    pub height: u32,
    pub border_ptr: u32,
    pub map_data_ptr: u32,
    pub primary_tileset_ptr: u32,
    pub secondary_tileset_ptr: u32,
    pub border_width: u8,
    pub border_height: u8,
    #[br(count = 2)] // padding
    pub unused: Vec<u8>, 
}

#[derive(BinRead, BinWrite, Debug, Clone)]
#[br(little)]
pub struct TilesetHeader {
    pub is_compressed: u8,
    pub is_secondary: u8,
    #[br(count = 2)]
    pub padding: Vec<u8>,
    pub graphics_ptr: u32,
    pub palette_ptr: u32,
    pub metatiles_ptr: u32,
    pub anim_ptr: u32,
    pub behavior_ptr: u32,
}
