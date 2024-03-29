pkg_name=python
pkg_distname=Python
pkg_version=3.7.4
pkg_origin=core
pkg_maintainer="The Habitat Maintainers <humans@habitat.sh>"
pkg_license=('Python-2.0')
pkg_description="Python is a programming language that lets you work quickly \
  and integrate systems more effectively."
pkg_upstream_url="https://www.python.org"
pkg_dirname="${pkg_distname}-${pkg_version}"
pkg_source="https://www.python.org/ftp/python/${pkg_version}/${pkg_dirname}.tgz"
pkg_shasum="d63e63e14e6d29e17490abbe6f7d17afb3db182dbd801229f14e55f4157c4ba3"

pkg_bin_dirs=(bin)
pkg_lib_dirs=(lib)
pkg_include_dirs=(include)
pkg_interpreters=(bin/python bin/python3 bin/python3.7)

pkg_deps=(
    core/bzip2/1.0.6/20180608091727
    core/expat/2.2.5/20180608094017
    core/gcc-libs/7.3.0/20180608091701
    core/gdbm/1.14.1/20180608094002
    core/glibc/2.27/20180608041157
    core/libffi/3.2.1/20180608141245
    core/ncurses/6.1/20180608091810
    core/openssl/1.0.2n/20180608102213
    core/readline/7.0.3/20180608092900
    core/sqlite/3130000/20180608141313
    core/zlib/1.2.11/20180608050617
)

pkg_build_deps=(
  core/coreutils
  core/diffutils
  core/gcc
  core/linux-headers
  core/make
  core/util-linux
)

do_prepare() {
  sed -i.bak 's/#zlib/zlib/' Modules/Setup.dist
  sed -i -re "/(SSL=|_ssl|-DUSE_SSL|-lssl).*/ s|^#||" Modules/Setup.dist
}

do_build() {
  export LDFLAGS="$LDFLAGS -lgcc_s"

  # TODO: We should build with `--enable-optimizations`
  ./configure --prefix="$pkg_prefix" \
              --enable-loadable-sqlite-extensions \
              --enable-shared \
              --with-threads \
              --with-system-expat \
              --with-system-ffi \
              --with-ensurepip

  make
}

do_check() {
  make test
}

do_install() {
  do_default_install

  # link pythonx.x to python for pkg_interpreters
  local minor=${pkg_version%.*}
  local major=${minor%.*}
  ln -rs "$pkg_prefix/bin/pip$minor" "$pkg_prefix/bin/pip"
  ln -rs "$pkg_prefix/bin/pydoc$minor" "$pkg_prefix/bin/pydoc"
  ln -rs "$pkg_prefix/bin/python$minor" "$pkg_prefix/bin/python"
  ln -rs "$pkg_prefix/bin/python$minor-config" "$pkg_prefix/bin/python-config"

  # Remove idle as we are not building with Tk/x11 support so it is useless
  rm -vf "$pkg_prefix/bin/idle$major"
  rm -vf "$pkg_prefix/bin/idle$minor"

  platlib=$(python -c "import sysconfig;print(sysconfig.get_path('platlib'))")
  cat <<EOF > "$platlib/_manylinux.py"
# Disable binary manylinux1(CentOS 5) wheel support
manylinux1_compatible = False
EOF
}
