# This file defines the environment for Project IDX
{ pkgs, ... }: {
  # Which nixpkgs channel to use.
  channel = "stable-23.11";

  # Use https://search.nixos.org/packages to find packages
  packages = [
    pkgs.jdk17
    pkgs.unzip
  ];

  # Sets environment variables in the workspace
  env = {};

  idx = {
    # Search for the extensions you want on https://open-vsx.org/ and use "publisher.id"
    extensions = [
      "Dart-Code.flutter"
      "Dart-Code.dart-code"
    ];

    # Enable previews
    previews = {
      enable = true;
      previews = {
        android = {
          command = ["flutter" "run" "--machine" "-d" "android" "-d" "localhost:5555"];
          manager = "flutter";
        };
      };
    };

    # Workspace lifecycle hooks
    workspace = {
      # Runs when a workspace is first created
      onCreate = {
        build-flutter = ''
          flutter create . --platforms=android,ios
        '';
      };
      # Runs when the workspace is (re)started
      onStart = {
        # Example: start a background task to watch builds
      };
    };
  };
}
