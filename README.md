A nix flake that builds [numen](https://git.sr.ht/~geb/numen).

To run this as a non-root user, you'll need to add a udev rule for
[dotool](https://git.sr.ht/~geb/dotool) and make yourself a member of `input` in
your Nix configuration:

```nix
services.udev.extraRules = ''
  KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
'';
users.users.<user> = {
  extraGroups = [
    "input"
  ];
};
```
