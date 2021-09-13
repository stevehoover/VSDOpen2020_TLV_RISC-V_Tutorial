\m4_TLV_version 1d: tl-x.org
\SV
   // Cut-n-paste of shell.tlv, modified for ChipEXPO-2021.
   
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/warp-v_includes/2d6d36baa4d2bc62321f982f78c8fe1456641a43/risc-v_defs.tlv'])

m4+definitions(['
   m4_define_vector(['M4_WORD'], 32)
   m4_define(['M4_EXT_I'], 1)
   
   m4_define(['M4_NUM_INSTRS'], 0)
   
   m4_echo(m4tlv_riscv_gen__body())
   
   m4_define(['TBD'], [''0'])

'])
\TLV shell(@_viz, @_imem, @_rf_rd, @_rf_wr)
   // =======================================================================================================
   // THIS CODE IS PROVIDED. NO NEED TO LOOK BEHIND THE CURTAIN. LEARN MORE USING THE MAKERCHIP TUTORIALS.
   
   m4_define_hier(['M4_IMEM'], M4_NUM_INSTRS)
   
   
   |cpu
      @0
         $reset = *reset;
         // Instruction Memory containing program defined by m4_asm(...) instantiations.
      @_imem
         \SV_plus
            // The program in an instruction memory.
            logic [31:0] instrs [0:8-1];
            assign instrs = '{
               m4_instr0['']m4_forloop(['m4_instr_ind'], 1, M4_NUM_INSTRS, [', m4_echo(['m4_instr']m4_instr_ind)'])
            };
         /M4_IMEM_HIER
            $instr[31:0] = *instrs\[#imem\];
         $imem_rd_data[31:0] = /imem[$imem_rd_addr]$instr;
         `BOGUS_USE($imem_rd_data)
      @_rf_wr
         // Reg File
         /xreg[31:0]
            $wr = |cpu$rf_wr_en && (|cpu$rf_wr_index != 5'b0) && (|cpu$rf_wr_index == #xreg);
            $value[31:0] = |cpu$reset ? 32'b0           :
                           $wr        ? |cpu$rf_wr_data :
                                        $RETAIN;
      @_rf_rd
         $rf_rd_data1[31:0] = /xreg[$rf_rd_index1]>>m4_stage_eval(@_rf_wr - @_rf_rd + 1)$value;
         $rf_rd_data2[31:0] = /xreg[$rf_rd_index2]>>m4_stage_eval(@_rf_wr - @_rf_rd + 1)$value;
         `BOGUS_USE($rf_rd_data1 $rf_rd_data2)
         
         // Assert these to end simulation (before Makerchip cycle limit).
         *passed = /xreg[10]>>1$value == (1+2+3+4+5+6+7+8+9);
         *failed = *cyc_cnt > 75;
         
         
   |for_viz_only
      @_viz
         // String representations of the instructions for debug.
         \SV_plus
            logic [40*8-1:0] instr_strs [0:M4_NUM_INSTRS];
            assign instr_strs = '{m4_asm_mem_expr "END                                     "};
         $ANY = /top|cpu<>0$ANY;
         /M4_IMEM_HIER
            $ANY = /top|cpu/imem<>0$ANY;
            $instr_str[40*8-1:0] = *instr_strs[imem];

         $mnemonic[10*8-1:0] = $is_blt  ? "BLT       " :
                               $is_addi ? "ADDI      " :
                               $is_add  ? "ADD       " :  "UNKNOWN   ";
         //$valid = ! $reset;
         `BOGUS_USE($pc[4:0])  // Bug workaround to pull lower bits.
         $fetch_instr_str[40*8-1:0] = *instr_strs\[$pc[\$clog2(M4_NUM_INSTRS+1)+1:2]\];
         \viz_alpha
            initEach() {
               let imem_header = new fabric.Text("Instr. Memory", {
                     top: -29,
                     left: -440,
                     fontSize: 18,
                     fontWeight: 800,
                     fontFamily: "monospace"
                  })
               let decode_header = new fabric.Text("Instr. Decode", {
                     top: 0,
                     left: 65,
                     fontSize: 18,
                     fontWeight: 800,
                     fontFamily: "monospace"
                  })
               let rf_header = new fabric.Text("Reg. File", {
                     top: -29 - 40,
                     left: 307,
                     fontSize: 18,
                     fontWeight: 800,
                     fontFamily: "monospace"
                  })
               return {objects: {imem_header, decode_header, rf_header}};
            },
            renderEach: function() {
               //debugger
               //
               // PC instr_mem pointer
               //
               let $pc = '$pc';
               let color = !('$valid'.asBool()) ? "gray" :
                                                  "blue";
               let pcPointer = new fabric.Text("->", {
                  top: 18 * ($pc.asInt() / 4),
                  left: -295,
                  fill: color,
                  fontSize: 14,
                  fontFamily: "monospace"
               })
               let pc_arrow = new fabric.Line([23, 18 * ($pc.asInt() / 4) + 6, 46, 35], {
                  stroke: "#d0e8ff",
                  strokeWidth: 2
               })
               let rs1_arrow = new fabric.Line([330, 18 * '$rf_rd_index1'.asInt() + 6 - 40, 190, 75 + 18 * 2], {
                  stroke: "#d0e8ff",
                  strokeWidth: 2,
                  visible: '$rf_rd_en1'.asBool()
               })
               let rs2_arrow = new fabric.Line([330, 18 * '$rf_rd_index2'.asInt() + 6 - 40, 190, 75 + 18 * 3], {
                  stroke: "#d0e8ff",
                  strokeWidth: 2,
                  visible: '$rf_rd_en2'.asBool()
               })
               let rd_arrow = new fabric.Line([330, 18 * '$rf_wr_index'.asInt() + 6 - 40, 168, 75 + 18 * 0], {
                  stroke: "#d0d0ff",
                  strokeWidth: 3,
                  visible: '$rf_wr_en'.asBool() && '$valid'.asBool()
               })
               //
               // Fetch Instruction
               //
               // TODO: indexing only works in direct lineage.  let fetchInstr = new fabric.Text('|fetch/instr_mem[$Pc]$instr'.asString(), {  // TODO: make indexing recursive.
               //let fetchInstr = new fabric.Text('$raw'.asString("--"), {
               //   top: 50,
               //   left: 90,
               //   fill: color,
               //   fontSize: 14,
               //   fontFamily: "monospace"
               //});
               //
               // Instruction with values.
               //
               let regStr = (valid, regNum, regValue) => {
                  return valid ? `r${regNum}` : `rX`  // valid ? `r${regNum} (${regValue})` : `rX`
               };
               let srcStr = ($src, $valid, $reg, $value) => {
                  return $valid.asBool(false)
                             ? `\n      ${regStr(true, $reg.asInt(NaN), $value.asInt(NaN))}`
                             : "";
               };
               let str = `${regStr('$rd_valid'.asBool(false), '$rd'.asInt(NaN), '$result'.asInt(NaN))}\n` +
                         `  = ${'$mnemonic'.asString()}${srcStr(1, '$rs1_valid', '$rs1', '$src1_value')}${srcStr(2, '$rs2_valid', '$rs2', '$src2_value')}\n` +
                         ('$is_r_instr'.asBool() ? "" : `      i[${'$imm'.asInt(NaN)}]`);
               let instrWithValues = new fabric.Text(str, {
                  top: 70,
                  left: 65,
                  fill: color,
                  fontSize: 14,
                  fontFamily: "monospace"
               });
               // Animate fetch (and provide onChange behavior for other animation).
               
               let fetch_instr = new fabric.Text('$fetch_instr_str'.asString(), {
                  top: 18 * ($pc.asInt() / 4),
                  left: -272,
                  fill: color,
                  fontSize: 14,
                  fontFamily: "monospace"
               })
               fetch_instr.animate({top: 32, left: 50}, {
                    onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                    duration: 500
               });
               
               let src1_value = new fabric.Text('$src1_value'.asInt(0).toString(), {
                  left: 316 + 8 * 4,
                  top: 18 * '$rs1'.asInt(0) - 40,
                  fill: color,
                  fontSize: 14,
                  fontFamily: "monospace",
                  fontWeight: 800,
                  visible: '$rs1_valid'.asBool(false)
               })
               setTimeout(() => {src1_value.animate({left: 166, top: 70 + 18 * 2}, {
                    onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                    duration: 500
               })}, 500)
               let src2_value = new fabric.Text('$src2_value'.asInt(0).toString(), {
                  left: 316 + 8 * 4,
                  top: 18 * '$rs2'.asInt(0) - 40,
                  fill: color,
                  fontSize: 14,
                  fontFamily: "monospace",
                  fontWeight: 800,
                  visible: '$rs2_valid'.asBool(false)
               })
               setTimeout(() => {src2_value.animate({left: 166, top: 70 + 18 * 3}, {
                    onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                    duration: 500
               })}, 500)
               let result_shadow = new fabric.Text('$result'.asInt(0).toString(), {
                  left: 146,
                  top: 70,
                  fill: "#d0d0ff",
                  fontSize: 14,
                  fontFamily: "monospace",
                  fontWeight: 800,
                  visible: false
               })
               let result = new fabric.Text('$result'.asInt(0).toString(), {
                  left: 146,
                  top: 70,
                  fill: color,
                  fontSize: 14,
                  fontFamily: "monospace",
                  fontWeight: 800,
                  visible: false
               })
               if ('$rd_valid'.asBool() && '$valid'.asBool()) {
                  setTimeout(() => {
                     result.setVisible(true)
                     result_shadow.setVisible(true)
                     result.animate({left: 317 + 8 * 4, top: 18 * '$rd'.asInt(0) - 40}, {
                       onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                       duration: 500
                     })
                  }, 1000)
               }
               
               return {objects: [pcPointer, pc_arrow, rs1_arrow, rs2_arrow, rd_arrow, instrWithValues, fetch_instr, src1_value, src2_value, result_shadow, result]};
            }
         //
         // Register file
         //
         /imem[m4_eval(M4_NUM_INSTRS-1):0]  // TODO: Cleanly report non-integer ranges.
            $rd = ! |for_viz_only$reset && |for_viz_only$pc[4:2] == #imem;
            \viz_alpha
               initEach() {
                 let binary = new fabric.Text("", {
                    top: 18 * this.getIndex(),  // TODO: Add support for '#instr_mem'.
                    left: -600,
                    fontSize: 14,
                    fontFamily: "monospace"
                 })
                 let disassembled = new fabric.Text("", {
                    top: 18 * this.getIndex(),  // TODO: Add support for '#instr_mem'.
                    left: -270,
                    fontSize: 14,
                    fontFamily: "monospace"
                 })
                 return {objects: {binary: binary, disassembled: disassembled}}
               },
               renderEach: function() {
                  // Instruction memory is constant, so just create it once.
                  if (!global.instr_mem_drawn) {
                     global.instr_mem_drawn = [];
                  }
                  if (!global.instr_mem_drawn[this.getIndex()]) {
                     global.instr_mem_drawn[this.getIndex()] = true
                     let binary_str       = '$instr'.asBinaryStr(NaN)
                     let disassembled_str = '$instr_str'.asString()
                     disassembled_str = disassembled_str.slice(0, -5)
                     //debugger
                     this.getInitObject("binary").setText(binary_str)
                     this.getInitObject("disassembled").setText(disassembled_str)
                  }
                  this.getInitObject("disassembled").set({textBackgroundColor: '$rd'.asBool() ? "#b0ffff" : "white"})
               }
         /xreg[31:0]
            $ANY = /top|cpu/xreg<>0$ANY;
            $rd = (|for_viz_only$rf_rd_en1 && |for_viz_only$rf_rd_index1 == #xreg) ||
                  (|for_viz_only$rf_rd_en2 && |for_viz_only$rf_rd_index2 == #xreg);
            \viz_alpha
               initEach: function() {
                  return {}  // {objects: {reg: reg}};
               },
               renderEach: function() {
                  let rd = '$rd'.asBool(false);
                  let mod = '$wr'.asBool(false);
                  let reg = parseInt(this.getIndex());
                  let regIdent = reg.toString().padEnd(2, " ");
                  let newValStr = regIdent + ": " + (mod ? '$value'.asInt(NaN).toString() : "");
                  let reg_str = new fabric.Text(regIdent + ": " + '>>1$value'.asInt(NaN).toString(), {
                     top: 18 * this.getIndex() - 40,
                     left: 316,
                     fontSize: 14,
                     fill: mod ? "blue" : "black",
                     fontWeight: mod ? 800 : 400,
                     fontFamily: "monospace",
                     textBackgroundColor: rd ? "#b0ffff" : null
                  })
                  if (mod) {
                     setTimeout(() => {
                        console.log(`Reg ${this.getIndex()} written with: ${newValStr}.`)
                        reg_str.set({text: newValStr, dirty: true})
                        this.global.canvas.renderAll()
                     }, 1500)
                  }
                  return {objects: [reg_str]}
               }

