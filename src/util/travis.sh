set -x



# Install libev, if requested.
if [ "$LIBEV" != no ]
then
    case $TRAVIS_OS_NAME in
        "linux")
            sudo apt-get update -qq
            sudo apt-get install -qq libev-dev;;
        "osx")
            brew update > /dev/null
            brew install libev
    esac
fi



# Install opam.
case $TRAVIS_OS_NAME in
    "linux") OPAM_OS=linux;;
    "osx") OPAM_OS=macos;;
    *) echo Unsupported system $TRAVIS_OS_NAME; exit 1;;
esac

OPAM_VERSION=2.0.5
OPAM_PKG=opam-${OPAM_VERSION}-x86_64-${OPAM_OS}

wget https://github.com/ocaml/opam/releases/download/${OPAM_VERSION}/${OPAM_PKG}
sudo mv ${OPAM_PKG} /usr/local/bin/opam
sudo chmod a+x /usr/local/bin/opam



# Initialize opam.
opam init -y --bare --disable-sandboxing --disable-shell-hook
if [ ! -d _opam/bin ]
then
    rm -rf _opam
    opam switch create . $COMPILER $REPOSITORIES --no-install
fi
eval `opam env`
opam --version
ocaml -version



# Install Lwt's development dependencies.
make dev-deps

if [ "$LIBEV" != no ]
then
    opam install -y conf-libev
fi



# Build and run the tests.
if [ "$LIBEV" != no ]
then
    LIBEV_FLAG=true
else
    LIBEV_FLAG=false
fi

(cd src/unix && dune exec config/configure.exe -- -use-libev $LIBEV_FLAG)
make build
make test



# Run the packaging tests.
make clean
make install-for-packaging-test
make packaging-test
make uninstall-after-packaging-test



# Run the ppx_let integratio test.
if [ "$COMPILER" != "4.02.3" ]
then
    make ppx_let-test-deps
    make ppx_let-test
fi
