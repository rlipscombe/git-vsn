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

@test "maintenance branch" {
    touch existing-feature
    git add existing-feature

    GIT_COMMITTER_DATE='2022-11-09T21:15:45Z' \
    GIT_AUTHOR_DATE='2022-11-09T21:15:45Z' \
        git commit -m "existing-feature"

    git push

    # release it
    git tag -a -m "v1.2.0" v1.2.0

    run git-vsn
    assert_output '1.2.0+b4c2e3eac7'

    # work on something new
    touch new-feature
    git add new-feature

    GIT_COMMITTER_DATE='2022-11-09T21:16:45Z' \
    GIT_AUTHOR_DATE='2022-11-09T21:16:45Z' \
        git commit -m "new-feature"

    git push

    run git-vsn
    assert_output '1.3.0-pre+7c407000af'

    # oh no, a bug
    git -c advice.detachedHead=false checkout v1.2.0
    git switch -c v1.2
    git push -u origin v1.2

    echo 'fixed it' > existing-feature

    git add existing-feature

    GIT_COMMITTER_DATE='2022-11-09T21:17:45Z' \
    GIT_AUTHOR_DATE='2022-11-09T21:17:45Z' \
        git commit -m "fixed it"

    git push

    run git-vsn
    assert_output '1.2.1-pre+4da5c5dd06'
}
