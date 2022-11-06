# git-vsn

Bash script to generate a semver-compatible version number from git tags.

See https://blog.differentpla.net/blog/2022/11/05/git-vsn/

## Testing

To test it, we use 'bats', installed using git submodules, so:

```
git submodule update --init --recursive
```

Then:

```
make tests
```
