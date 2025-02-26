{ stdenv, lib, buildFHSUserEnv, callPackage, makeDesktopItem, writeScript
, quartus-unwrapped
, supportedDevices ? [
    "Arria II"
    "Arria 10"
    "Arria V"
    "Arria V GZ"
    "Cyclone IV"
    "Cyclone 10 LP"
    "Cyclone V"
    "MAX II/V"
    "MAX 10 FPGA"
    "Stratix IV"
    "Stratix V"
  ]
}:

let
  desktopItem = makeDesktopItem {
    name = "quartus-prime";
    exec = "quartus";
    icon = "quartus";
    desktopName = "Quartus";
    genericName = "Quartus Prime";
    categories = [ "Development" ];
  };
in buildFHSUserEnv rec {
  name = "quartus-prime"; # wrapped

  targetPkgs = pkgs: with pkgs; [
    # quartus requirements
    glib
    xorg.libICE
    xorg.libSM
    zlib
    libxcrypt-legacy
    expat
    xorg.libXft
    # qsys requirements
    xorg.libXtst
    xorg.libXi
  ];
  multiPkgs = pkgs: with pkgs; let
    # This seems ugly - can we override `libpng = libpng12` for all `pkgs`?
    freetype = pkgs.freetype.override { libpng = libpng12; };
    fontconfig = pkgs.fontconfig.override { inherit freetype; };
    libXft = pkgs.xorg.libXft.override { inherit freetype fontconfig; };
  in [
    # common requirements
    freetype
    fontconfig
    xorg.libX11
    xorg.libXext
    xorg.libXrender
    libudev0-shim
  ];

  passthru = { inherit quartus-unwrapped; };

  extraInstallCommands = let
    quartusExecutables = (map (c: "quartus/bin/${c}") [
      "clearbox" "dmf_ver" "jtagconfig" "jtagd" "jtagquery" "juart-terminal" "mega_alt_fault_injection"
      "mega_symc" "mega_symcng" "mif2hex" "mw-regenerate" "nios2-flash-programmer" "nios2-gdb-server"
      "nios2-terminal" "openocd" "openocd-cfg-gen" "pll_cmd" "qatc" "qbnl" "qcmd" "qcrypt" "qemit" "qeslc"
      "qfid" "qmegawiz" "qmegawizq" "qnsm" "qnui" "qpgmt" "qppl" "qred" "qreg" "qsme" "quartus" "quartus_asm"
      "quartus_cdb" "quartus_cmd" "quartus_cpf" "quartus_drc" "quartus_dse" "quartus_dsew" "quartus_eda"
      "quartus_fid" "quartus_fif" "quartus_fit" "quartus_hps" "quartus-ip-catalog" "quartus_jbcc" "quartus_jli"
      "quartus_map" "quartus_npp" "quartus_pgm" "quartus_pgmw" "quartus_pow" "quartus_py" "quartus_sh"
      "quartus_si" "quartus_sim" "quartus_sta" "quartus_staw" "quartus_stp" "quartus_stp_tcl" "quartus_stpw"
      "quartus_syn" "quartus_template" "quartus_worker" "qwed" "tclsh" "uniphy_mcc" "wish" "xcvr_diffmifgen"
    ]);

    qsysExecutables = map (c: "quartus/sopc_builder/bin/qsys-${c}") [
      "generate" "edit" "script"
    ];

    questaExecutables = map (c: "questa_fse/bin/${c}") [
      "crd2bin" "dumplog64" "flps_util" "hdloffice" "hm_entity" "jobspy" "mc2com" "mc2perfanalyze" "mc2_util"
      "qhcvt" "qhdel" "qhdir" "qhgencomp" "qhlib" "qhmake" "qhmap" "qhsim" "qrun" "qverilog" "qvhcom" "qvlcom"
      "qwave2vcd" "qwaveman" "qwaveutils" "sccom" "scgenmod" "sdfcom" "sm_entity" "triage" "vcd2qwave" "vcd2wlf"
      "vcom" "vcover" "vdbg" "vdel" "vdir" "vencrypt" "verror" "vgencomp" "vhencrypt" "vis" "visualizer" "vlib"
      "vlog" "vmake" "vmap" "vopt" "vovl" "vrun" "vsim" "wlf2log" "wlf2vcd" "wlfman" "wlfrecover" "xml2ucdb"
    ];
  in /* bash */ ''
    mkdir -p $out/share/applications $out/share/icons/128x128
    ln -s ${desktopItem}/share/applications/* $out/share/applications
    ln -s ${quartus-unwrapped}/licenses/images/dc_quartus_panel_logo.png $out/share/icons/128x128/quartus.png

    mkdir -p $out/quartus/bin $out/quartus/sopc_builder/bin $out/questa_fse/bin
    WRAPPER=$out/bin/${name}
    EXECUTABLES="${lib.concatStringsSep " " (quartusExecutables ++ qsysExecutables ++ questaExecutables)}"
    for executable in $EXECUTABLES; do
        echo "#!${stdenv.shell}" >> $out/$executable
        echo "$WRAPPER ${quartus-unwrapped}/$executable \"\$@\"" >> $out/$executable
    done

    cd $out
    chmod +x $EXECUTABLES
    # link into $out/bin so executables become available on $PATH
    ln --symbolic --relative --target-directory ./bin $EXECUTABLES
  '';

  # LD_PRELOAD fixes issues in the licensing system that cause memory corruption and crashes when
  # starting most operations in many containerized environments, including WSL2, Docker, and LXC
  # (a similiar fix involving LD_PRELOADing tcmalloc did not solve the issue in my situation)
  # we use the name so that quartus can load the 64 bit verson and modelsim can load the 32 bit version
  # https://community.intel.com/t5/Intel-FPGA-Software-Installation/Running-Quartus-Prime-Standard-on-WSL-crashes-in-libudev-so/m-p/1189032
  runScript = writeScript "${name}-wrapper" ''
    exec env LD_PRELOAD=libudev.so.0 "$@"
  '';
}
