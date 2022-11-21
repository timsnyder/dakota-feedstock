#!/bin/bash

set -xe

# download without SSL to work around https://github.com/orgs/snl-dakota/discussions/12
curl --insecure -o dakota.tar.gz https://dakota.sandia.gov/sites/default/files/distributions/public/dakota-$PKG_VERSION-public-src-cli.tar.gz
echo 49684ade2a937465d85b0fc69c96408be38bc1603ed2e7e8156d93eee3567d2f dakota.tar.gz | sha256sum --check
tar --strip-components=1 -xf dakota.tar.gz

# apply patches using git because you don't have to worry about deducing arguments to patch to do
# the application the same way as conda-build does...
# apply the patches the way conda-build would
# see https://github.com/conda/conda-build/blob/32ac010d584a634fa80fde9877e1756d44025e65/conda_build/source.py#L796-L819
# I manually did
#   from conda_build.source import apply_one_patch
#   from conda_build.config import Config
#   apply_one_patch('.', os.environ['RECIPE_DIR']+'/patches', os.environ['RECIPE_DIR']+'/patches/link_librt.patch', Config(), False)
# in the build directory to see that it would do 'patch -Np1 -i <file> --binary` for all the
# existing patches.  And that it didn't need to force LF or CRLF, it used the 'native' format with
# --binary
for p in python tests link_librt boost_dll_import_symbol; do
  patch -Np1 -i $RECIPE_DIR/patches/${p}.patch --binary
done

mkdir -p build
cd build

if [ `uname` = "Linux" ]; then
    # there is a problem with NCSUopt when compiled with -fopenmp
    # so set the fflags manually:
    FFLAGS="-march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe"
    LDFLAGS="${LDFLAGS} -lrt"
fi

cmake -G "Ninja" \
      -D CMAKE_BUILD_TYPE:STRING=RELEASE \
      -D CMAKE_INSTALL_PREFIX:PATH=$PREFIX \
      -D DAKOTA_EXAMPLES_INSTALL:PATH=$PREFIX/share/dakota \
      -D DAKOTA_TEST_INSTALL:PATH=$PREFIX/share/dakota \
      -D DAKOTA_TOPFILES_INSTALL:PATH=$PREFIX/share/dakota \
      -D DAKOTA_PYTHON:BOOL=ON \
      -D DAKOTA_PYTHON_DIRECT_INTERFACE:BOOL=ON \
      -D DAKOTA_PYTHON_DIRECT_INTERFACE_NUMPY:BOOL=ON \
      -D HAVE_X_GRAPHICS:BOOL=OFF \
      -D DAKOTA_HAVE_MP:BOOL=ON \
      -D DAKOTA_HAVE_HDF5:BOOL=ON \
      -D HAVE_QUESO:BOOL=ON \
      -D DAKOTA_HAVE_GSL=ON \
      -D ACRO_HAVE_DLOPEN:BOOL=OFF \
      -D DAKOTA_CBLAS_LIBS:BOOL=OFF \
      -D DAKOTA_INSTALL_DYNAMIC_DEPS:BOOL=OFF \
      -D Boost_NO_BOOST_CMAKE:BOOL=ON \
      -D DAKOTA_ENABLE_TESTS:BOOL=ON \
      -D DAKOTA_PYTHON_SURROGATES:BOOL=ON \
      ..
ninja install

chmod u+x $PREFIX/share/dakota/test/dakota_test.perl
