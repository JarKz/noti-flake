# Noti flake

This flake provides the [`noti`](https://github.com/noti-rs/noti) appliation as package and options to enable it without manual install it.
### Features

- [ ] Minimal build size
- [X] Systemd service as option

> [!WARN]
> It's not easy to implement the minimal build size because of cargo build caveats. The nix flake is sandboxed and doesn't permit to fetch packages outside. And becuase of this building rust-std will be very painful. So I decided to left as potential option.

## Installation

Use this flake in your flake inputs:

```nix
inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    noti-flake = {
      url = "github:jarkz/noti-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
};
```

And use it for home manager:

```nix
# As a module
modules = [ 
  inputs.noti-flake.homeModules.default
  ./home
];

# Or use import it in specified .nix submodule
imports = [
  inputs.noti-flake.homeModules.default
];
```

To add as package:

```nix
home.packages = [
    noti-flake.packages."${system}".default
];
```

Or enable it with systemd service:

```nix
packages.noti-rs = {
    enable = true;
    service = true;
};
```

## Contribution

Want to make it better? — Open issue or pull request!
