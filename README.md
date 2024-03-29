# git-vsn

Bash script to generate a semver-compatible version number from git tags.

See https://blog.differentpla.net/blog/2022/11/05/git-vsn/

## Important

- `git-vsn` expects your repo to be using _annotated_ tags. Use `git tag -a`.
- They should look like semver tags: `1.2.3`.
- If you want to use `v1.2.3` or `release-1.2.3`, you can use `git-vsn -t` to tell `git-vsn` about the tag prefix.

## Using it

Run it from within a git repo that you want to generate a version for:

    cd path/to/your-repo

You can put `git-vsn` somewhere in `$PATH`; you can run it as `/path/to/git-vsn`;
you can put it somewhere in the repo and run it with (e.g.) `./scripts/git-vsn`. It doesn't care.

## Testing

To test it, we use 'bats', installed using git submodules, so:

```
git submodule update --init --recursive
```

Then:

```
make tests
```

You don't need to include the tests unless you're planning on hacking on `git-vsn` itself.
