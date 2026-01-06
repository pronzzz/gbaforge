use anyhow::Result;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ScriptCommand {
    End,
    Return,
    Call(u32),
    Goto(u32),
    If1(u32),
    If2(u32),
    Message {
        text_ptr: u32,
        type_id: u8,
    },
    GiveItem {
        item_id: u16,
        quantity: u16,
    },
    TrainerBattle {
        type_id: u8,
        trainer_id: u16,
        unk: u16,
        ptr_intro: u32,
        ptr_win: u32,
    },
    Unknown(u8, Vec<u8>), // Opcode + Params
}

/// Simple XSE Disassembler
/// Parsing GBA Scripting bytecode at `offset`.
pub fn disassemble(data: &[u8], start_offset: usize) -> Result<Vec<ScriptCommand>> {
    let mut commands = Vec::new();
    let mut pc = start_offset; // Program Counter

    loop {
        if pc >= data.len() {
            break;
        }

        let opcode = data[pc];
        pc += 1;

        match opcode {
            0x02 => {
                // end
                commands.push(ScriptCommand::End);
                break;
            }
            0x03 => {
                // return
                commands.push(ScriptCommand::Return);
                break;
            }
            0x04 => {
                // call pointer
                if pc + 4 > data.len() {
                    break;
                }
                let ptr = u32::from_le_bytes(data[pc..pc + 4].try_into()?);
                pc += 4;
                commands.push(ScriptCommand::Call(ptr));
            }
            0x05 => {
                // goto pointer
                if pc + 4 > data.len() {
                    break;
                }
                let ptr = u32::from_le_bytes(data[pc..pc + 4].try_into()?);
                pc += 4;
                commands.push(ScriptCommand::Goto(ptr));
            }
            0x06 => {
                // if1 (jump if true/result==1)
                if pc + 4 > data.len() {
                    break;
                }
                let ptr = u32::from_le_bytes(data[pc..pc + 4].try_into()?);
                pc += 4;
                commands.push(ScriptCommand::If1(ptr));
            }
            0x0F => {
                // msgbox pointer, type
                if pc + 5 > data.len() {
                    break;
                }
                let ptr = u32::from_le_bytes(data[pc..pc + 4].try_into()?);
                let type_id = data[pc + 4];
                pc += 5;
                commands.push(ScriptCommand::Message {
                    text_ptr: ptr,
                    type_id,
                });
            }
            0x1A => {
                // giveitem item_id, quantity
                if pc + 4 > data.len() {
                    break;
                }
                let item_id = u16::from_le_bytes(data[pc..pc + 2].try_into()?);
                let qty = u16::from_le_bytes(data[pc + 2..pc + 4].try_into()?);
                pc += 4;
                commands.push(ScriptCommand::GiveItem {
                    item_id,
                    quantity: qty,
                });
            }
            0x5C => {
                // trainerbattle type, id, unk, ptr_intro, ptr_win (simplified)
                // structure varies by type, assuming type 0 (standard)
                // byte type, hword id, hword unk, word intro, word win
                if pc + 13 > data.len() {
                    break;
                }
                let type_id = data[pc];
                let trainer_id = u16::from_le_bytes(data[pc + 1..pc + 3].try_into()?);
                let unk = u16::from_le_bytes(data[pc + 3..pc + 5].try_into()?);
                let ptr_intro = u32::from_le_bytes(data[pc + 5..pc + 9].try_into()?);
                let ptr_win = u32::from_le_bytes(data[pc + 9..pc + 13].try_into()?);
                pc += 13;
                commands.push(ScriptCommand::TrainerBattle {
                    type_id,
                    trainer_id,
                    unk,
                    ptr_intro,
                    ptr_win,
                });
            }
            _ => {
                // Unknown command, stop or heuristic?
                // For robustness, we should know lengths of all commands.
                // Here we just mark unknown and break to avoid desync.
                commands.push(ScriptCommand::Unknown(opcode, vec![]));
                break;
            }
        }
    }

    Ok(commands)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_disassemble_simple() {
        // MsgBox(0x08123456, 2) + End
        // MsgBox Opcode: 0F
        // Ptr: 56 34 12 08
        // Type: 02
        // End Opcode: 02
        let bytecode = vec![0x0F, 0x56, 0x34, 0x12, 0x08, 0x02, 0x02];
        let commands = disassemble(&bytecode, 0).unwrap();

        assert_eq!(commands.len(), 2);

        match &commands[0] {
            ScriptCommand::Message { text_ptr, type_id } => {
                assert_eq!(*text_ptr, 0x08123456);
                assert_eq!(*type_id, 2);
            }
            _ => panic!("Expected Message"),
        }

        match &commands[1] {
            ScriptCommand::End => {}
            _ => panic!("Expected End"),
        }
    }
}
