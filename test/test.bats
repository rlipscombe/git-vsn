setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'

    # get the containing directory of this file
    # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
    # as those will point to the bats executable's location or the preprocessed file respectively
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    # make executables in top directory visible to PATH
    TOP="$(cd $DIR/.. && pwd)"
    PATH="$TOP:$PATH"

    # create a scratch git repo
    WORKTREE="$BATS_TEST_TMPDIR/work"
    mkdir -p "$WORKTREE"
    cd "$WORKTREE"
    git init --quiet

    # can't commit without a user/email
    git config user.email "bats@example.com"
    git config user.name "Barnaby Ats"

    # you can't tag an empty repo, so we need a commit
    GIT_COMMITTER_DATE='2022-11-06T17:07:45Z' \
    GIT_AUTHOR_DATE='2022-11-06T17:07:45Z' \
        git commit --allow-empty -m "Initial commit"

    # we need a remote
    REMOTE="$BATS_TEST_TMPDIR/remote"
    git init --quiet --bare "$REMOTE"

    git remote add origin "$REMOTE"
    git push -u origin master
}

@test "should fail if no tags" {
    run git-vsn -t v
    assert_failure
}

@test "single tag, at tag, clean" {
    git tag -a -m "v1.0.0" v1.0.0
    run git-vsn -t v

    # TODO: Doesn't spot that the tag is not pushed.
    assert_output '1.0.0+5fcf07cb8e'
}

@test "single tag, at tag, new file" {
    git tag -a -m "v1.0.0" v1.0.0
    touch new-file
    run git-vsn -t v

    # Note: we don't add '.dirty' for new files that aren't staged or committed; since your build process might generate
    # them, which would pollute the version number. Only changed files add '.dirty'.
    assert_output '1.0.0+5fcf07cb8e'
}

@test "single tag, at tag, staged changes" {
    git tag -a -m "v1.0.0" v1.0.0
    touch staged-change
    git add staged-change
    run git-vsn -t v

    assert_output '1.0.0+5fcf07cb8e.dirty'
}

@test "single tag, after tag, committed file, not pushed" {
    git tag -a -m "v1.0.0" v1.0.0
    touch committed-file
    git add committed-file

    GIT_COMMITTER_DATE='2022-11-06T17:24:45Z' \
    GIT_AUTHOR_DATE='2022-11-06T17:24:45Z' \
        git commit -m "committed-file"
    run git-vsn -t v

    assert_output '1.1.0-pre+f11a3c209b.dirty'
}

@test "single tag, at tag, changed file" {
    git tag -a -m "v1.0.0" v1.0.0
    touch changed-file
    git add changed-file

    GIT_COMMITTER_DATE='2022-11-06T17:24:45Z' \
    GIT_AUTHOR_DATE='2022-11-06T17:24:45Z' \
        git commit -m "changed-file"
    echo 'change' >> changed-file
    run git-vsn -t v

    assert_output '1.1.0-pre+ab51346374.dirty'
}

@test "single tag, after tag, pushed file" {
    git tag -a -m "v1.0.0" v1.0.0
    touch changed-file
    git add changed-file

    GIT_COMMITTER_DATE='2022-11-06T17:24:45Z' \
    GIT_AUTHOR_DATE='2022-11-06T17:24:45Z' \
        git commit -m "changed-file"
    echo 'change' >> changed-file

    git add changed-file

    GIT_COMMITTER_DATE='2022-11-06T17:30:45Z' \
    GIT_AUTHOR_DATE='2022-11-06T17:30:45Z' \
        git commit -m "changed-file"
    git push

    run git-vsn -t v

    assert_output '1.1.0-pre+c89fc10692'
}

@test "GIT_VSN environment variable overrides behaviour" {
    git tag -a -m "v1.0.0" v1.0.0
    export GIT_VSN=1.2.0+5fcf07cb8e
    run git-vsn -t v

    assert_output '1.2.0+5fcf07cb8e'
}

@test ".git-vsn file is ignored inside work tree" {
    # you only need the .git-vsn file if you're not inside the work tree
    # if you've just built a tarball and have a .git-vsn file, you want to
    # ignore it inside the work tree.
    git tag -a -m "v1.0.0" v1.0.0
    echo "1.2.0+5fcf07cb8e" > .git-vsn
    run git-vsn -t v

    assert_output '1.0.0+5fcf07cb8e'
}
