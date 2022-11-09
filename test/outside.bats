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

    # we need a scratch dir that's NOT a git repo
    SCRATCH="$BATS_TEST_TMPDIR"
    cd $SCRATCH
}

@test ".git-vsn file is used outside work tree" {
    echo "1.2.0+0.5fcf07cb8e" > .git-vsn
    run git-vsn

    assert_output '1.2.0+0.5fcf07cb8e'
}

@test "otherwise fails outside work tree" {
    echo "1.2.0+0.5fcf07cb8e" > .git-vsn
    run git-vsn

    assert_output '1.2.0+0.5fcf07cb8e'
}
