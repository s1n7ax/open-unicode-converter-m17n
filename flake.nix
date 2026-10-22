{
  description = "si-ouc: Sinhala Singlish m17n input method with Open Unicode Converter rules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    open-unicode-converter = {
      url = "github:s1n7ax/open-unicode-converter/4b9bd6282311168016020326f52861fb117cfd80";
      flake = false;
    };
  };

  outputs =
    { nixpkgs, open-unicode-converter, ... }:
    let
      inherit (nixpkgs) lib;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      testTools = pkgs: [
        pkgs.esbuild
        pkgs.m17n_lib
        pkgs.nodejs
        pkgs.pkg-config
      ];
    in
    {
      packages = forAllSystems (pkgs: {
        default = pkgs.stdenvNoCC.mkDerivation {
          pname = "open-unicode-converter-m17n";
          version = "1.0.0";

          src = lib.fileset.toSource {
            root = ./.;
            fileset = ./si-ouc.mim;
          };

          installPhase = ''
            runHook preInstall
            install -Dm644 si-ouc.mim $out/share/m17n/si-ouc.mim
            runHook postInstall
          '';

          meta = {
            description = "Sinhala Singlish m17n input method with Open Unicode Converter rules";
            homepage = "https://github.com/s1n7ax/open-unicode-converter-m17n";
            license = lib.licenses.mit;
            platforms = lib.platforms.all;
          };
        };
      });

      checks = forAllSystems (pkgs: {
        default = pkgs.stdenv.mkDerivation {
          name = "si-ouc-tests";

          src = lib.fileset.toSource {
            root = ./.;
            fileset = lib.fileset.unions [
              ./si-ouc.mim
              ./tests
            ];
          };

          nativeBuildInputs = testTools pkgs;

          buildPhase = ''
            runHook preBuild
            mkdir -p build home/.m17n.d
            cp si-ouc.mim home/.m17n.d/
            $CC -Wall -Wextra -Werror -O2 -o build/driver tests/driver.c \
              $(pkg-config --cflags --libs m17n-shell)
            for script in reference generate; do
              esbuild tests/$script.ts --bundle --platform=node --log-level=warning \
                --alias:open-unicode-converter=${open-unicode-converter} \
                --outfile=build/$script.js
            done
            runHook postBuild
          '';

          doCheck = true;
          checkPhase = ''
            runHook preCheck
            if ! bash tests/run.sh build/driver build/reference.js build/generate.js "$PWD/home" \
              ${open-unicode-converter}/src/app/core/converters/singlish/singlish-converter.spec.ts \
              >report.txt; then
              cat report.txt
              exit 1
            fi
            cat report.txt
            runHook postCheck
          '';

          installPhase = ''
            runHook preInstall
            install -Dm644 report.txt $out/report.txt
            runHook postInstall
          '';
        };
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = testTools pkgs ++ [ pkgs.nixfmt-tree ];
        };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
