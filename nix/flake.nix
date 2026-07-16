{
  description = "local-repo — manage bare git repos on a self-hosted SSH server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # The tool's source lives one level up — this flake sits in the nix/ subdir.
    # A flake in a subdirectory can't read parent files with a `../` path literal
    # (pure evaluation forbids escaping the flake root), so we pull the repo in as
    # a non-flake relative-path input and read the files we need from it. When this
    # flake is consumed via `git+file://…?dir=nix`, this resolves to the same
    # git-fetched tree (so .gitignore is honoured and local-repo.conf is excluded).
    src = {
      url = "path:..";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, src }:
    let
      # Unix-y systems only: the tool is bash + git + ssh.
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        local-repo = pkgs.stdenv.mkDerivation {
          pname = "local-repo";
          version = "0.1.0";

          inherit src;

          nativeBuildInputs = [ pkgs.makeWrapper ];

          # Pure bash — nothing to configure or compile.
          dontConfigure = true;
          dontBuild = true;

          # Copy only the tracked files we ship — never the personal .conf, even
          # if a local `path:..` fetch happened to include it.
          installPhase = ''
            runHook preInstall

            install -Dm755 "$src/local-repo" "$out/bin/local-repo"

            # Rewrite `#!/usr/bin/env bash` to this build's bash, and put the
            # runtime tools on PATH so the binary is self-contained regardless of
            # the user's environment.
            patchShebangs "$out/bin/local-repo"
            wrapProgram "$out/bin/local-repo" \
              --prefix PATH : ${pkgs.lib.makeBinPath [
                pkgs.bash
                pkgs.git
                pkgs.openssh
                pkgs.coreutils
                pkgs.gnugrep
              ]}

            # Bash completion — discovered automatically by the standard
            # bash-completion loader (and by home-manager's completion setup).
            install -Dm644 "$src/completion/local-repo.bash" \
              "$out/share/bash-completion/completions/local-repo"

            runHook postInstall
          '';

          meta = {
            description = "Manage bare git repos on a self-hosted SSH server over SSH";
            longDescription = ''
              A small bash tool for solo developers who want git versioning
              self-hosted on a server they control (NAS, VPS, home Pi), reached
              over SSH — no third-party host. Manages bare git repos on the
              remote and prints the remote URL ready for `git remote add`.
            '';
            license = nixpkgs.lib.licenses.mit;
            mainProgram = "local-repo";
            platforms = nixpkgs.lib.platforms.unix;
          };
        };

        default = local-repo;
      });

      # `nix run .#local-repo` / `nix run github:you/local-repo?dir=nix`
      apps = forAllSystems (pkgs: rec {
        local-repo = {
          type = "app";
          program = "${self.packages.${pkgs.system}.local-repo}/bin/local-repo";
        };
        default = local-repo;
      });

      # Convenience for consumers who prefer overlaying nixpkgs.
      overlays.default = final: _prev: {
        local-repo = self.packages.${final.system}.local-repo;
      };
    };
}
