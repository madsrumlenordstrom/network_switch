{ stdenv, lib, unstick, fetchurl, gnutar, autoPatchelfHook
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
  version = "23.1std.1.993";

  deviceIds = {
    "Arria II" = "arria";
    "Arria 10" = "arria10";
    "Arria V" = "arriav";
    "Arria V GZ" = "arriavgz";
    "Cyclone IV" = "cyclone";
    "Cyclone 10 LP" = "cyclone10lp";
    "Cyclone V" = "cyclonev";
    "MAX II/V" = "max";
    "MAX 10 FPGA" = "max10";
    "Stratix IV" = "stratixiv";
    "Stratix V" = "stratixv";
  };

  supportedDeviceIds =
    assert lib.assertMsg (lib.all (name: lib.hasAttr name deviceIds) supportedDevices)
      "Supported devices are: ${lib.concatStringsSep ", " (lib.attrNames deviceIds)}";
    lib.listToAttrs (map (name: {
      inherit name;
      value = deviceIds.${name};
    }) supportedDevices);

  unsupportedDeviceIds = lib.filterAttrs (name: value:
    !(lib.hasAttr name supportedDeviceIds)
  ) deviceIds;

  installers = [
    "QuartusSetup-${version}-linux.run"
    "QuartusHelpSetup-${version}-linux.run"
    "RiscFreeSetup-${version}-linux.run"
    "QuestaSetup-${version}-linux.run"
  ];

in stdenv.mkDerivation rec {
  inherit version;
  pname = "quartus-prime-unwrapped";

  src = fetchurl {
    url = "https://downloads.intel.com/akdlm/software/acdsinst/23.1std.1/993/ib_tar/Quartus-23.1std.1.993-linux-complete.tar";
    hash = "sha256-xRkOEqxR0b345/fHLGF9hgVA/L7lyN1WZxzPid4oRBY=";
  };

  nativeBuildInputs = [ unstick gnutar autoPatchelfHook ];

  buildCommand = let
    copyInstaller = installer: ''
      # `$(cat $NIX_CC/nix-support/dynamic-linker) $src[0]` often segfaults, so cp + patchelf
      chmod u+w,+x $TEMP/components/${installer}
      patchelf --interpreter $(cat $NIX_CC/nix-support/dynamic-linker) $TEMP/components/${installer}
    '';
    disabledComponents = [
      "quartus_update"
    ] ++ (lib.attrValues unsupportedDeviceIds);
  in ''

      mkdir -p $TEMP
      cd $TEMP
      tar xvf ${src}
      ${lib.concatMapStringsSep "\n" copyInstaller installers}

      runHook preInstall
      unstick $TEMP/components/${builtins.head installers} \
      --disable-components ${lib.concatStringsSep "," disabledComponents} \
      --mode unattended --installdir $out --accept_eula 1
      runHook postInstall

      rm -r $out/uninstall $out/logs
    '';

  meta = with lib; {
    homepage = "https://fpgasoftware.intel.com";
    description = "FPGA design and simulation software";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ madsrumlenordstrom ];
  };
}
