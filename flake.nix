{
  description = "local-repo — manage bare git repos on a self-hosted SSH server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs }:
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

          # Flake root == repo root now, so a plain path literal is legal and the
          # personal local-repo.conf is excluded by .gitignore on git-fetched builds.
          src = ./.;

          nativeBuildInputs = [ pkgs.makeWrapper ];

          # Pure bash — nothing to configure or compile.
          dontConfigure = true;
          dontBuild = true;

          # Install only the files we ship. On git-fetched builds the source is
          # tracked-files-only, so the personal .conf never enters the store.
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

      # `nix run .#local-repo` / `nix run github:smytheb/local-repo`
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
